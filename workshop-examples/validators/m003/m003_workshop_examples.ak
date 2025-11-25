// =============================================================================
// Module M003 Workshop Examples
// Smart Contracts with Validation Logic
// =============================================================================

use aiken/collection/list
use cardano/address.{Address, Script, VerificationKey}
use cardano/assets.{from_lovelace, lovelace_of}
use cardano/transaction.{
  Input, NoDatum, Output, OutputReference, Transaction, placeholder,
}
use cocktail.{valid_after}
use mocktail.{
  complete, invalid_before, invalid_hereafter, mock_utxo_ref, mocktail_tx,
}

// -----------------------------------------------------------------------------
// Example 1: Password Validator (Exercise 1)
// Demonstrates: Redeemer validation with pattern matching
// -----------------------------------------------------------------------------

pub type PasswordRedeemer {
  password: ByteArray,
}

validator password_validator {
  spend(
    _datum: Option<Data>,
    redeemer: PasswordRedeemer,
    _input: OutputReference,
    _self: Transaction,
  ) {
    // Only allow if password matches "secret123"
    redeemer.password == #"736563726574313233"
    // hex for "secret123"
  }

  else(_) {
    fail
  }
}

// Tests for password validator
test test_password_correct() {
  let redeemer = PasswordRedeemer { password: #"736563726574313233" }
  password_validator.spend(None, redeemer, mock_utxo_ref(0, 0), placeholder)
}

test test_password_incorrect() fail {
  let redeemer = PasswordRedeemer { password: #"77726f6e67" }
  // "wrong"
  password_validator.spend(None, redeemer, mock_utxo_ref(0, 0), placeholder)
}

test test_password_empty() fail {
  let redeemer = PasswordRedeemer { password: #"" }
  password_validator.spend(None, redeemer, mock_utxo_ref(0, 0), placeholder)
}

// -----------------------------------------------------------------------------
// Example 2: Owner-Based Access Control (Exercise 2)
// Demonstrates: Datum + signature validation
// -----------------------------------------------------------------------------

pub type OwnerDatum {
  owner: ByteArray,
  admin: ByteArray,
}

pub type OwnerAction {
  OwnerWithdraw
  AdminWithdraw
}

validator ownership_validator {
  spend(
    datum: Option<OwnerDatum>,
    redeemer: OwnerAction,
    _input: OutputReference,
    self: Transaction,
  ) {
    // Extract datum
    expect Some(owner_datum) = datum
    when redeemer is {
      // Only owner can perform owner withdrawal
      OwnerWithdraw -> list.has(self.extra_signatories, owner_datum.owner)
      // Only admin can perform admin withdrawal
      AdminWithdraw -> list.has(self.extra_signatories, owner_datum.admin)
    }
  }

  else(_) {
    fail
  }
}

// Tests for ownership validator
test test_owner_withdraw_success() {
  let datum = Some(OwnerDatum { owner: #"aabbcc", admin: #"112233" })
  let tx = Transaction { ..placeholder, extra_signatories: [#"aabbcc"] }
  ownership_validator.spend(datum, OwnerWithdraw, mock_utxo_ref(0, 0), tx)
}

test test_owner_cannot_do_admin_action() fail {
  let datum = Some(OwnerDatum { owner: #"aabbcc", admin: #"112233" })
  let tx = Transaction { ..placeholder, extra_signatories: [#"aabbcc"] }
  ownership_validator.spend(datum, AdminWithdraw, mock_utxo_ref(0, 0), tx)
}

test test_admin_withdraw_success() {
  let datum = Some(OwnerDatum { owner: #"aabbcc", admin: #"112233" })
  let tx = Transaction { ..placeholder, extra_signatories: [#"112233"] }
  ownership_validator.spend(datum, AdminWithdraw, mock_utxo_ref(0, 0), tx)
}

test test_unsigned_transaction_fails() fail {
  let datum = Some(OwnerDatum { owner: #"aabbcc", admin: #"112233" })
  ownership_validator.spend(
    datum,
    OwnerWithdraw,
    mock_utxo_ref(0, 0),
    placeholder,
  )
}

// -----------------------------------------------------------------------------
// Example 3: Time-Locked Withdrawal (Exercise 3)
// Demonstrates: Signature + time validation
// -----------------------------------------------------------------------------

pub type TimeLockDatum {
  beneficiary: ByteArray,
  deadline: Int,
}

pub type TimeLockRedeemer {
  Claim
}

validator timelock_validator {
  spend(
    datum: Option<TimeLockDatum>,
    redeemer: TimeLockRedeemer,
    _input: OutputReference,
    self: Transaction,
  ) {
    expect Some(lock_datum) = datum
    let Claim = redeemer
    // Check 1: Must be signed by beneficiary
    let signed_by_beneficiary =
      list.has(self.extra_signatories, lock_datum.beneficiary)
    // Check 2: Current time must be after deadline
    let time_passed = valid_after(self.validity_range, lock_datum.deadline)
    // Both conditions must be true
    signed_by_beneficiary && time_passed
  }

  else(_) {
    fail
  }
}

// Tests for timelock validator
test test_claim_success_after_deadline() {
  let datum = Some(TimeLockDatum { beneficiary: #"aabbcc", deadline: 1000 })
  let tx =
    mocktail_tx()
      |> invalid_before(True, 1001)
      |> complete()
  let tx_with_sig = Transaction { ..tx, extra_signatories: [#"aabbcc"] }
  timelock_validator.spend(datum, Claim, mock_utxo_ref(0, 0), tx_with_sig)
}

test test_claim_fails_before_deadline() fail {
  let datum = Some(TimeLockDatum { beneficiary: #"aabbcc", deadline: 1000 })
  let tx =
    mocktail_tx()
      |> invalid_hereafter(True, 999)
      |> complete()
  let tx_with_sig = Transaction { ..tx, extra_signatories: [#"aabbcc"] }
  timelock_validator.spend(datum, Claim, mock_utxo_ref(0, 0), tx_with_sig)
}

test test_claim_fails_wrong_signature() fail {
  let datum = Some(TimeLockDatum { beneficiary: #"aabbcc", deadline: 1000 })
  let tx =
    mocktail_tx()
      |> invalid_before(True, 1001)
      |> complete()
  let tx_with_sig = Transaction { ..tx, extra_signatories: [#"112233"] }
  timelock_validator.spend(datum, Claim, mock_utxo_ref(0, 0), tx_with_sig)
}

// -----------------------------------------------------------------------------
// Example 4: Input/Output Validation (Exercise 4)
// Demonstrates: Transaction structure validation
// -----------------------------------------------------------------------------

validator io_validator {
  spend(
    _datum: Option<Data>,
    _redeemer: Data,
    input_ref: OutputReference,
    self: Transaction,
  ) {
    // Check 1: Exactly one script input
    let script_inputs =
      list.filter(
        self.inputs,
        fn(input) {
          when input.output.address.payment_credential is {
            Script(_) -> True
            _ -> False
          }
        },
      )
    let single_script_input = list.length(script_inputs) == 1
    // Check 2: Verify it's the expected input
    let correct_input =
      list.any(script_inputs, fn(input) { input.output_reference == input_ref })
    // Check 3: At least one output to specific address
    // (In real scenario, you'd check specific address)
    let has_output = list.length(self.outputs) >= 1
    // Check 4: First output has minimum value
    expect Some(first_output) = list.head(self.outputs)
    let minimum_value = lovelace_of(first_output.value) >= 5_000_000
    // All checks must pass
    single_script_input && correct_input && has_output && minimum_value
  }

  else(_) {
    fail
  }
}

// Tests for I/O validator
test test_io_valid_transaction() {
  let script_addr =
    Address {
      payment_credential: Script(
        #"aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd",
      ),
      stake_credential: None,
    }
  let wallet_addr =
    Address {
      payment_credential: VerificationKey(
        #"11223344556677881122334455667788112233445566778811223344",
      ),
      stake_credential: None,
    }
  let input_ref =
    OutputReference {
      transaction_id: #"0000000000000000000000000000000000000000000000000000000000000000",
      output_index: 0,
    }
  let input =
    Input {
      output_reference: input_ref,
      output: Output {
        address: script_addr,
        value: from_lovelace(10_000_000),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let output =
    Output {
      address: wallet_addr,
      value: from_lovelace(5_000_000),
      datum: NoDatum,
      reference_script: None,
    }
  let tx = Transaction { ..placeholder, inputs: [input], outputs: [output] }
  io_validator.spend(None, Void, input_ref, tx)
}

test test_io_fails_with_low_output_value() fail {
  let script_addr =
    Address {
      payment_credential: Script(
        #"aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd",
      ),
      stake_credential: None,
    }
  let wallet_addr =
    Address {
      payment_credential: VerificationKey(
        #"11223344556677881122334455667788112233445566778811223344",
      ),
      stake_credential: None,
    }
  let input_ref =
    OutputReference {
      transaction_id: #"0000000000000000000000000000000000000000000000000000000000000000",
      output_index: 0,
    }
  let input =
    Input {
      output_reference: input_ref,
      output: Output {
        address: script_addr,
        value: from_lovelace(10_000_000),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let output =
    Output {
      address: wallet_addr,
      value: from_lovelace(1_000_000),
      // Too low!
      datum: NoDatum,
      reference_script: None,
    }
  let tx = Transaction { ..placeholder, inputs: [input], outputs: [output] }
  io_validator.spend(None, Void, input_ref, tx)
}

// -----------------------------------------------------------------------------
// Example 5: Comprehensive Vault (Exercise 5)
// Demonstrates: Combining ALL validation techniques
// -----------------------------------------------------------------------------

pub type VaultDatum {
  owner: ByteArray,
  unlock_time: Int,
  minimum_withdrawal: Int,
}

pub type VaultRedeemer {
  Withdraw
  Cancel
}

validator comprehensive_vault {
  spend(
    datum: Option<VaultDatum>,
    redeemer: VaultRedeemer,
    _input_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(vault_datum) = datum
    when redeemer is {
      Withdraw -> {
        // Validation 1: Must be signed by owner
        let signed_by_owner =
          list.has(self.extra_signatories, vault_datum.owner)
        // Validation 2: Current time must be after unlock_time
        let time_passed =
          valid_after(self.validity_range, vault_datum.unlock_time)
        // Validation 3: Exactly one script input (prevent double satisfaction)
        let script_inputs =
          list.filter(
            self.inputs,
            fn(input) {
              when input.output.address.payment_credential is {
                Script(_) -> True
                _ -> False
              }
            },
          )
        let single_input = list.length(script_inputs) == 1
        // Validation 4: At least one output meets minimum withdrawal
        let has_minimum_output =
          list.any(
            self.outputs,
            fn(output) {
              lovelace_of(output.value) >= vault_datum.minimum_withdrawal
            },
          )
        // ALL validations must pass
        signed_by_owner && time_passed && single_input && has_minimum_output
      }
      Cancel ->
        // Only owner can cancel, no other restrictions
        list.has(self.extra_signatories, vault_datum.owner)
    }
  }

  else(_) {
    fail
  }
}

// Comprehensive tests for vault validator
test test_vault_withdraw_success() {
  let datum =
    Some(
      VaultDatum {
        owner: #"aabbcc",
        unlock_time: 1000,
        minimum_withdrawal: 5_000_000,
      },
    )
  let script_addr =
    Address {
      payment_credential: Script(
        #"aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd",
      ),
      stake_credential: None,
    }
  let wallet_addr =
    Address {
      payment_credential: VerificationKey(
        #"11223344556677881122334455667788112233445566778811223344",
      ),
      stake_credential: None,
    }
  let input_ref =
    OutputReference {
      transaction_id: #"0000000000000000000000000000000000000000000000000000000000000000",
      output_index: 0,
    }
  let input =
    Input {
      output_reference: input_ref,
      output: Output {
        address: script_addr,
        value: from_lovelace(10_000_000),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let output =
    Output {
      address: wallet_addr,
      value: from_lovelace(9_000_000),
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    mocktail_tx()
      |> invalid_before(True, 1001)
      |> complete()
  let tx_final =
    Transaction {
      ..tx,
      inputs: [input],
      outputs: [output],
      extra_signatories: [#"aabbcc"],
    }
  comprehensive_vault.spend(datum, Withdraw, input_ref, tx_final)
}

test test_vault_withdraw_fails_no_signature() fail {
  let datum =
    Some(
      VaultDatum {
        owner: #"aabbcc",
        unlock_time: 1000,
        minimum_withdrawal: 5_000_000,
      },
    )
  let script_addr =
    Address {
      payment_credential: Script(
        #"aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd",
      ),
      stake_credential: None,
    }
  let wallet_addr =
    Address {
      payment_credential: VerificationKey(
        #"11223344556677881122334455667788112233445566778811223344",
      ),
      stake_credential: None,
    }
  let input_ref =
    OutputReference {
      transaction_id: #"0000000000000000000000000000000000000000000000000000000000000000",
      output_index: 0,
    }
  let input =
    Input {
      output_reference: input_ref,
      output: Output {
        address: script_addr,
        value: from_lovelace(10_000_000),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let output =
    Output {
      address: wallet_addr,
      value: from_lovelace(9_000_000),
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    mocktail_tx()
      |> invalid_before(True, 1001)
      |> complete()
  let tx_final =
    Transaction {
      ..tx,
      inputs: [input],
      outputs: [output],
      extra_signatories: [],
    }
  // No signature!
  comprehensive_vault.spend(datum, Withdraw, input_ref, tx_final)
}

test test_vault_withdraw_fails_before_unlock() fail {
  let datum =
    Some(
      VaultDatum {
        owner: #"aabbcc",
        unlock_time: 1000,
        minimum_withdrawal: 5_000_000,
      },
    )
  let script_addr =
    Address {
      payment_credential: Script(
        #"aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd",
      ),
      stake_credential: None,
    }
  let wallet_addr =
    Address {
      payment_credential: VerificationKey(
        #"11223344556677881122334455667788112233445566778811223344",
      ),
      stake_credential: None,
    }
  let input_ref =
    OutputReference {
      transaction_id: #"0000000000000000000000000000000000000000000000000000000000000000",
      output_index: 0,
    }
  let input =
    Input {
      output_reference: input_ref,
      output: Output {
        address: script_addr,
        value: from_lovelace(10_000_000),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let output =
    Output {
      address: wallet_addr,
      value: from_lovelace(9_000_000),
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    mocktail_tx()
      |> invalid_hereafter(True, 999)
      // Before unlock time!
      |> complete()
  let tx_final =
    Transaction {
      ..tx,
      inputs: [input],
      outputs: [output],
      extra_signatories: [#"aabbcc"],
    }
  comprehensive_vault.spend(datum, Withdraw, input_ref, tx_final)
}

test test_vault_withdraw_fails_below_minimum() fail {
  let datum =
    Some(
      VaultDatum {
        owner: #"aabbcc",
        unlock_time: 1000,
        minimum_withdrawal: 5_000_000,
      },
    )
  let script_addr =
    Address {
      payment_credential: Script(
        #"aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd",
      ),
      stake_credential: None,
    }
  let wallet_addr =
    Address {
      payment_credential: VerificationKey(
        #"11223344556677881122334455667788112233445566778811223344",
      ),
      stake_credential: None,
    }
  let input_ref =
    OutputReference {
      transaction_id: #"0000000000000000000000000000000000000000000000000000000000000000",
      output_index: 0,
    }
  let input =
    Input {
      output_reference: input_ref,
      output: Output {
        address: script_addr,
        value: from_lovelace(10_000_000),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let output =
    Output {
      address: wallet_addr,
      value: from_lovelace(1_000_000),
      // Below minimum!
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    mocktail_tx()
      |> invalid_before(True, 1001)
      |> complete()
  let tx_final =
    Transaction {
      ..tx,
      inputs: [input],
      outputs: [output],
      extra_signatories: [#"aabbcc"],
    }
  comprehensive_vault.spend(datum, Withdraw, input_ref, tx_final)
}

test test_vault_cancel_success() {
  let datum =
    Some(
      VaultDatum {
        owner: #"aabbcc",
        unlock_time: 1000,
        minimum_withdrawal: 5_000_000,
      },
    )
  let tx = Transaction { ..placeholder, extra_signatories: [#"aabbcc"] }
  comprehensive_vault.spend(datum, Cancel, mock_utxo_ref(0, 0), tx)
}

test test_vault_cancel_fails_no_signature() fail {
  let datum =
    Some(
      VaultDatum {
        owner: #"aabbcc",
        unlock_time: 1000,
        minimum_withdrawal: 5_000_000,
      },
    )
  comprehensive_vault.spend(datum, Cancel, mock_utxo_ref(0, 0), placeholder)
}
// =============================================================================
// Summary:
// 
// These examples demonstrate:
// 1. Redeemer validation with pattern matching
// 2. Datum extraction and field validation
// 3. Signature checking with extra_signatories
// 4. Time-based validation with validity_range using Vodka utilities
// 5. Input/output structure validation
// 6. Combining multiple validation techniques
// 7. Comprehensive test coverage (passing and failing cases)
// 
// Students should:
// - Study each example to understand the validation patterns
// - Run the tests to see them pass/fail
// - Modify the examples to experiment
// - Use these as templates for their own validators
// =============================================================================
