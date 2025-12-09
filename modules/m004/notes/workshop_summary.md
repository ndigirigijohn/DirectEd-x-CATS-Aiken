# Module M004: Advanced Input Validation - Workshop Summary

## What is This Module About?

This workshop teaches you how to write **secure smart contracts** on Cardano by focusing on **input validation** - checking the funds (UTxOs) that transactions try to spend. Think of it like building a secure vault: you need to verify who's trying to open it, what they're taking out, and make sure nobody can trick the system.

### Why Input Validation Matters

Most smart contract hacks happen because of poor input validation. It's like having a bouncer at a club who doesn't check IDs properly - bad actors can exploit the weakness. In this module, you'll learn how to be a good "bouncer" for your smart contracts.

---

## Real-World Analogy: The Bank Vault

Imagine you're building a digital bank vault. Here's what you need to check:

1. **Who's trying to access it?** (Address Filtering)
2. **Are they trying to access multiple vaults at once?** (Double-Satisfaction Prevention)
3. **Do they have the right amount of money/tokens?** (Value Validation)
4. **Do they have the correct authorization?** (Datum Validation)

Let's see how this works in code!

---

## 1. Address Filtering: Knowing Which Vault is Yours

### Real-World Example
Imagine you work at a bank with 100 safety deposit boxes. When someone wants to open box #42, you need to:
- Find box #42 specifically
- Make sure they're only trying to open ONE box at a time
- Verify the box belongs to your bank

### The Code

```aiken
validator address_filter_validator {
  spend(
    _datum: Option<Data>,
    _redeemer: Data,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    // Step 1: Find OUR specific input (like finding box #42)
    expect Some(own_input) = find_input(self.inputs, own_ref)
    let our_address = own_input.output.address

    // Step 2: Filter all inputs at our address
    let script_inputs = inputs_at(self.inputs, our_address)

    // Step 3: Make sure there's exactly ONE
    when script_inputs is {
      [_single] -> True  // ✅ Good! Only one input
      _ -> False         // ❌ Bad! Zero or multiple inputs
    }
  }
}
```

### What's Happening Here?

1. **`find_input(self.inputs, own_ref)`** - Like scanning all safety deposit boxes to find box #42
2. **`inputs_at(self.inputs, our_address)`** - Like filtering only boxes that belong to your bank
3. **Pattern matching `[_single]`** - Like verifying there's exactly one box being opened

---

## 2. Preventing Double-Satisfaction: The Critical Security Issue

### Real-World Example: The ATM Exploit

Imagine an ATM that checks: "Did the customer deposit $100?" 

**The Vulnerable ATM:**
- Customer puts $100 in the deposit slot
- Customer simultaneously withdraws from Account A ($50 balance)
- Customer simultaneously withdraws from Account B ($75 balance)
- ATM checks: "Is there $100 deposited?" ✅ Yes!
- ATM allows BOTH withdrawals even though only $100 was deposited!
- Customer walks away with $125 from a $100 deposit! 💰

This is called a **double-satisfaction attack** - using the same proof (the $100 deposit) to satisfy multiple checks.

### The Vulnerable Code (DON'T USE THIS!)

```aiken
// ❌ VULNERABLE - Can be exploited!
validator vulnerable_payment {
  spend(datum, redeemer, _own_ref, self) {
    expect Some(payment_datum) = datum
    
    // Find outputs to beneficiary
    let outputs_to_beneficiary = outputs_at(self.outputs, beneficiary_addr)
    
    // Check total paid
    let total_paid = sum_all_outputs(outputs_to_beneficiary)
    
    // ⚠️ PROBLEM: Multiple inputs can share the same output!
    lovelace_of(total_paid) >= payment_datum.price
  }
}
```

### The Attack Scenario

**Bob's Setup:**
- UTxO #1: 20 SCOIN, requires 5 ADA payment to Bob
- UTxO #2: 20 XCOIN, requires 10 ADA payment to Bob

**Alice's Attack Transaction:**
```
Inputs:
  1. UTxO #1 (20 SCOIN - validator checks: "Is 5 ADA paid to Bob?")
  2. UTxO #2 (20 XCOIN - validator checks: "Is 10 ADA paid to Bob?")
  3. Alice's wallet: 15 ADA

Outputs:
  1. To Bob: 10 ADA ✅
  2. To Alice: 20 SCOIN + 20 XCOIN

Result:
  - Validator #1 sees 10 ADA to Bob → PASSES (needs 5)
  - Validator #2 sees SAME 10 ADA → PASSES (needs 10)
  - Alice paid 10 ADA but got tokens worth 15 ADA!
```

### The Secure Code (USE THIS!)

```aiken
// ✅ SECURE - Prevents double-satisfaction
validator secure_payment {
  spend(datum, redeemer, own_ref, self) {
    expect Some(payment_datum) = datum
    
    // CRITICAL SECURITY CHECK: Ensure only ONE input from our validator
    expect Some(own_input) = find_input(self.inputs, own_ref)
    let our_address = own_input.output.address
    let script_inputs = inputs_at(self.inputs, our_address)
    expect [_single] = script_inputs  // Must be exactly 1!
    
    // Now it's safe to check outputs
    let outputs_to_beneficiary = outputs_at(self.outputs, beneficiary_addr)
    let total_paid = sum_all_outputs(outputs_to_beneficiary)
    
    lovelace_of(total_paid) >= payment_datum.price
  }
}
```

### What Changed?

The secure version adds this critical check:
```aiken
expect [_single] = script_inputs
```

This is like the ATM saying: "I'll only process ONE withdrawal at a time, not multiple simultaneous ones!"

---

## 3. Value Validation: Checking the Money

### Real-World Example: The Minimum Balance Requirement

Your bank account requires:
- Minimum $1,000 balance in USD
- At least 10 shares of stock XYZ

The teller needs to verify BOTH requirements before approving a transaction.

### The Code

```aiken
pub type ValueRequirements {
  minimum_lovelace: Int,           // Minimum ADA (like USD requirement)
  required_token_policy: PolicyId, // Which token (like Stock XYZ)
  required_token_name: ByteArray,  // Token name
  minimum_token_amount: Int,       // How many tokens needed
}

validator value_validator {
  spend(datum, _redeemer, own_ref, self) {
    expect Some(requirements) = datum
    
    // Find our input (the account being spent)
    expect Some(own_input) = find_input(self.inputs, own_ref)
    let input_value = own_input.output.value
    
    // Check 1: Do we have enough ADA? (enough USD?)
    let has_minimum_ada = 
      lovelace_of(input_value) >= requirements.minimum_lovelace
    
    // Check 2: Do we have enough tokens? (enough stock shares?)
    let token_qty = quantity_of(
      input_value,
      requirements.required_token_policy,
      requirements.required_token_name
    )
    let has_minimum_tokens = token_qty >= requirements.minimum_token_amount
    
    // Both checks must pass!
    has_minimum_ada && has_minimum_tokens
  }
}
```

### Breaking It Down

**`lovelace_of(input_value)`** - Extracts ADA amount (1 ADA = 1,000,000 lovelace)
```aiken
// Example: If input has 10 ADA
lovelace_of(input_value) == 10_000_000
```

**`quantity_of(value, policy, name)`** - Counts specific tokens
```aiken
// Example: Counting "MyToken" tokens
let qty = quantity_of(input_value, policy_id, "MyToken")
// Returns: 150 (if there are 150 MyTokens)
```

### Test Example

```aiken
test test_value_sufficient_ada_and_tokens_passes() {
  let policy = mock_policy_id(0)
  let token_name = "MyToken"
  
  // Requirement: 5 ADA + 100 tokens
  let datum = Some(ValueRequirements {
    minimum_lovelace: 5_000_000,      // 5 ADA
    required_token_policy: policy,
    required_token_name: token_name,
    minimum_token_amount: 100,        // 100 tokens
  })
  
  // Create input with 10 ADA + 150 tokens
  let value = zero
    |> add(#"", #"", 10_000_000)      // 10 ADA (more than 5)
    |> add(policy, token_name, 150)   // 150 tokens (more than 100)
  
  // Build transaction
  let tx = mocktail_tx()
    |> tx_in(True, mock_tx_hash(0), 0, value, script_addr)
    |> complete()
  
  // Should pass! ✅
  value_validator.spend(datum, Void, mock_utxo_ref(0, 0), tx)
}

test test_value_insufficient_ada_fails() fail {
  // Same setup but only 2 ADA (less than 5 required)
  let value = zero
    |> add(#"", #"", 2_000_000)       // Only 2 ADA ❌
    |> add(policy, token_name, 150)   // 150 tokens ✅
  
  // Should fail! ❌
  value_validator.spend(datum, Void, mock_utxo_ref(0, 0), tx)
}
```

---

## Key Functions Explained

### `find_input(inputs, reference)`
**Purpose:** Find a specific UTxO in the transaction

**Analogy:** Like finding a specific receipt in a stack of receipts
```aiken
expect Some(my_input) = find_input(self.inputs, own_ref)
// Returns the Input that matches the reference, or None if not found
```

### `inputs_at(inputs, address)`
**Purpose:** Filter all inputs that came from a specific address

**Analogy:** Like sorting mail by sender address
```aiken
let script_inputs = inputs_at(self.inputs, our_address)
// Returns a list of all inputs from 'our_address'
```

### `lovelace_of(value)`
**Purpose:** Extract the ADA amount from a Value

**Analogy:** Like checking how many dollars are in your wallet
```aiken
let ada_amount = lovelace_of(input_value)
// Returns: 10_000_000 (meaning 10 ADA)
```

### `quantity_of(value, policy, name)`
**Purpose:** Count how many of a specific token you have

**Analogy:** Like counting how many shares of Apple stock you own
```aiken
let token_count = quantity_of(value, policy_id, "MyToken")
// Returns: 150 (if you have 150 MyTokens)
```

---

## Complete Security Checklist

When writing a secure validator, ALWAYS do these checks in order:

```aiken
validator secure_validator {
  spend(datum, redeemer, own_ref, self) {
    // ✅ STEP 1: Prevent double-satisfaction (ALWAYS FIRST!)
    expect Some(own_input) = find_input(self.inputs, own_ref)
    let our_address = own_input.output.address
    let script_inputs = inputs_at(self.inputs, our_address)
    expect [_single] = script_inputs
    
    // ✅ STEP 2: Validate who can spend (signatures)
    expect list.has(self.extra_signatories, owner_pkh)
    
    // ✅ STEP 3: Validate input values
    let input_value = own_input.output.value
    expect lovelace_of(input_value) >= minimum_ada
    expect quantity_of(input_value, policy, name) >= minimum_tokens
    
    // ✅ STEP 4: Validate outputs (where money is going)
    let outputs_to_recipient = outputs_at(self.outputs, recipient_addr)
    expect list.length(outputs_to_recipient) == 1
    
    // ✅ STEP 5: All checks passed!
    True
  }
}
```

---

## Common Mistakes to Avoid

### ❌ Mistake #1: Forgetting Double-Satisfaction Prevention
```aiken
// BAD - No single input check!
validator bad {
  spend(datum, redeemer, own_ref, self) {
    // Missing: expect [_single] = inputs_at(...)
    check_outputs_only(self.outputs)  // ⚠️ Exploitable!
  }
}
```

### ❌ Mistake #2: Only Checking Outputs
```aiken
// BAD - Only validates outputs, not inputs
validator bad {
  spend(datum, redeemer, own_ref, self) {
    // Should also check: How much is IN the input?
    check_outputs(self.outputs) >= required_amount
  }
}
```

### ❌ Mistake #3: Wrong Address Type
```aiken
// BAD - Using wrong address constructor
let beneficiary_addr = mock_pub_key_address(0, None)  // ❌ Wrong!

// GOOD - Construct address from PKH in datum
let beneficiary_addr = Address {
  payment_credential: VerificationKey(datum.beneficiary),
  stake_credential: None,
}  // ✅ Correct!
```

---

## Workshop Exercises Summary

### Exercise 1: Address Filtering
**Goal:** Learn to find and filter inputs
**Skills:** `find_input()`, `inputs_at()`, pattern matching

### Exercise 2: Prevent Double-Satisfaction
**Goal:** Understand and prevent the most critical vulnerability
**Skills:** Single input validation, security patterns

### Exercise 3: Value Validation
**Goal:** Check ADA and token amounts
**Skills:** `lovelace_of()`, `quantity_of()`, value comparison

---

## Real-World Application Example

Let's build a **Token Gated Content Vault**:

```aiken
// Only people with 100+ "MembershipNFT" tokens can unlock
pub type VaultDatum {
  owner: ByteArray,                    // Who created the vault
  required_token_policy: PolicyId,     // Membership NFT policy
  required_token_name: ByteArray,      // "MembershipNFT"
  minimum_token_amount: Int,           // 100 tokens required
}

validator membership_vault {
  spend(datum, redeemer, own_ref, self) {
    expect Some(vault_datum) = datum
    
    // Security Step 1: Prevent double-satisfaction
    expect Some(own_input) = find_input(self.inputs, own_ref)
    let script_inputs = inputs_at(self.inputs, own_input.output.address)
    expect [_single] = script_inputs
    
    // Step 2: Check they have membership tokens
    let input_value = own_input.output.value
    let member_tokens = quantity_of(
      input_value,
      vault_datum.required_token_policy,
      vault_datum.required_token_name
    )
    
    // Step 3: Verify minimum token requirement
    expect member_tokens >= vault_datum.minimum_token_amount
    
    // Step 4: Verify owner signature
    expect list.has(self.extra_signatories, vault_datum.owner)
    
    True
  }
}
```

**Use Case:** 
- NFT-gated content (need 100 NFTs to access premium content)
- DAO voting (need 1000 tokens to submit proposals)
- VIP access (need special tokens to unlock features)

---

## Key Takeaways

1. **Always prevent double-satisfaction** - Check for single input FIRST
2. **Validate both inputs AND outputs** - Check what's coming in and going out
3. **Use proper address construction** - Match the datum's credentials
4. **Test all scenarios** - Write tests for pass AND fail cases
5. **Think like an attacker** - Try to break your own code

---

## Next Steps

After mastering input validation in M004, you'll move to:
- **Module M005:** Output validation and state machines
- **Module M006:** Minting policies and NFTs
- **Module M007:** Complete DApp architecture

---

## Additional Resources

- **Aiken Documentation:** https://aiken-lang.org/
- **Cardano Docs:** https://docs.cardano.org/
- **Vodka Library:** https://github.com/sidan-lab/vodka
- **Workshop Repository:** [Your GitHub Link]

---

## Questions?

If you're stuck or confused:
1. Review the code examples in `m004_examples.ak`
2. Run the tests with `aiken check`
3. Ask in the workshop Discord
4. Check the troubleshooting section in the main documentation

Remember: Security is not optional in smart contracts. Take your time to understand these patterns deeply! 🔒
