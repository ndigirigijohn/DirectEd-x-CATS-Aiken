# Module M007: Advanced DApp Architecture

**DirectEd x CATS Hackathon Aiken Development Workshops**

**Duration:** 3 hours  
**Format:** 1.5 hours lecture + 1.5 hours hands-on exercises  
**Prerequisites:** Completed Modules M000-M006, Understanding of all previous validator patterns

## Module Overview

Welcome to Module M007 - the capstone module of the DirectEd x CATS Hackathon Aiken Development Workshop Series! Over the past six modules, you've built a comprehensive foundation in Cardano smart contract development. You've written validators (M001), tested them with mock transactions (M002), implemented validation logic (M003), mastered input validation (M004), built state machines (M005), and created minting policies (M006).

Now it's time to bring it all together. In this final module, you'll learn how to architect complete, production-ready decentralized applications (DApps). You'll discover how multiple validators interact in complex systems, design secure marketplace contracts, implement staking and rewards mechanisms, build DAO governance systems, and understand the critical bridge between on-chain validators and off-chain applications through the plutus.json blueprint.

### This module focuses on two major areas:

1. **Blueprint & Off-Chain Integration**: Understanding how your compiled validators communicate with off-chain transaction builders through the plutus.json blueprint file.
2. **Advanced DApp Architecture**: Designing and implementing complex multi-validator systems that solve real-world problems.

By the end of this module, you'll have the knowledge and skills to build sophisticated, production-ready decentralized applications on Cardano. You'll understand not just how to write individual validators, but how to architect entire systems that are secure, efficient, and maintainable.

## Learning Objectives

### 1. Blueprint Structure & Interpretation

- 1.1 Understand plutus.json blueprint format and purpose  
- 1.2 Read compiled validator code (CBOR hex)  
- 1.3 Extract validator hashes for addresses and policy IDs  
- 1.4 Interpret datum and redeemer schema definitions  
- 1.5 Understand constructor indexing for off-chain use

### 2. Off-Chain Integration Fundamentals

- 2.1 Map on-chain types to off-chain representations  
- 2.2 Understand transaction builder requirements  
- 2.3 Generate script addresses from validator hashes  
- 2.4 Generate policy IDs from minting validators  
- 2.5 Apply parameters to parameterized validators

### 3. Multi-Validator System Design

- 3.1 Design systems with multiple interacting validators  
- 3.2 Create parameter dependency trees  
- 3.3 Understand validator communication patterns  
- 3.4 Implement token-based validator relationships  
- 3.5 Design initialization and setup procedures

### 4. Marketplace Contract Patterns

- 4.1 Implement listing and delisting logic  
- 4.2 Build purchase validation  
- 4.3 Handle royalty distribution  
- 4.4 Implement offer and counter-offer systems  
- 4.5 Design marketplace state management

### 5. Staking & Rewards Systems

- 5.1 Design staking datum structures  
- 5.2 Implement stake deposit and withdrawal  
- 5.3 Calculate time-based rewards  
- 5.4 Build reward distribution logic  
- 5.5 Handle stake delegation patterns

### 6. DAO Governance Systems

- 6.1 Implement proposal creation and validation  
- 6.2 Build voting mechanisms with token-weighted votes  
- 6.3 Design vote tallying and execution  
- 6.4 Implement timelock and quorum requirements  
- 6.5 Create treasury management patterns

### 7. Production Considerations

- 7.1 Optimize validators for transaction costs  
- 7.2 Handle upgradability and versioning  
- 7.3 Implement comprehensive error handling  
- 7.4 Design deployment and initialization procedures  
- 7.5 Plan testing strategies for complex systems

---

## Part 1: Blueprint Structure & Off-Chain Integration (45-50 minutes)

### 1.1 Understanding the plutus.json Blueprint

After running `aiken build`, your project generates a `plutus.json` file. This blueprint is the critical interface between your on-chain Aiken code and off-chain transaction builders written in JavaScript, TypeScript, Python, or other languages.

#### What's in the Blueprint?

```json
{
  "preamble": {
    "title": "my_project",
    "description": "Aiken contracts for my_project",
    "version": "0.0.0",
    "plutusVersion": "v3",
    "license": "Apache-2.0"
  },
  "validators": [
    {
      "title": "my_validator.spend",
      "datum": {
        "title": "datum",
        "schema": {
          "$ref": "#/definitions/my_validator/Datum"
        }
      },
      "redeemer": {
        "title": "redeemer",
        "schema": {
          "$ref": "#/definitions/my_validator/Redeemer"
        }
      },
      "compiledCode": "590a3f0100003232323...",
      "hash": "69b9758387079fd00c05c7daa8fde367acdb84dbd9c35dfd05b701ad"
    }
  ],
  "definitions": {
    "my_validator/Datum": {
      "title": "Datum",
      "anyOf": [...]
    },
    "my_validator/Redeemer": {
      "title": "Redeemer",
      "anyOf": [...]
    }
  }
}
```

#### Key Components:

1. **compiledCode**: Your validator as CBOR-encoded Plutus script (hex string)
2. **hash**: Validator hash used to generate script addresses (spending) or policy IDs (minting)
3. **datum/redeemer schemas**: JSON schema describing the structure of your custom types
4. **definitions**: Complete type definitions with constructor indexes

#### Why is this Important?

The blueprint allows off-chain code to:
- Construct correctly formatted datums and redeemers
- Identify which constructor index to use
- Build transactions that your validators will accept
- Generate proper script addresses and policy IDs

### 1.2 Constructor Indexing - The Bridge Between On-Chain and Off-Chain

One of the most critical concepts for off-chain integration is **constructor indexing**. In Aiken, when you define custom types with multiple constructors, each constructor gets assigned an index starting from 0.

#### On-Chain Aiken Code:

```aiken
pub type Redeemer {
  IncrementCount        // Constructor index: 0
  DecrementCount        // Constructor index: 1
  CloseState            // Constructor index: 2
}

pub type StateDatum {
  Initialize            // Constructor index: 0
  Active { count: Int } // Constructor index: 1
  Closed                // Constructor index: 2
}
```

#### In plutus.json:

```json
"my_validator/Redeemer": {
  "title": "Redeemer",
  "anyOf": [
    {
      "title": "IncrementCount",
      "dataType": "constructor",
      "index": 0,
      "fields": []
    },
    {
      "title": "DecrementCount",
      "dataType": "constructor",
      "index": 1,
      "fields": []
    },
    {
      "title": "CloseState",
      "dataType": "constructor",
      "index": 2,
      "fields": []
    }
  ]
}
```

#### Off-Chain JavaScript (using Mesh SDK):

```javascript
// To call IncrementCount redeemer
const redeemer = {
  data: {
    alternative: 0,  // Constructor index
    fields: []
  }
};

// To call DecrementCount redeemer
const redeemer = {
  data: {
    alternative: 1,  // Constructor index
    fields: []
  }
};

// For Active datum with count: 5
const datum = {
  alternative: 1,  // Active constructor index
  fields: [5]      // The count field
};
```

#### Critical Understanding:

Off-chain code doesn't use constructor names like "IncrementCount" - it uses numeric indexes. When building transactions, you must reference constructors by their index number. This is why understanding the blueprint is essential.

### 1.3 Generating Script Addresses and Policy IDs

#### For Spending Validators:

The validator hash in the blueprint is used to create a script address where funds can be locked.

```javascript
import { serializePlutusScript } from "@meshsdk/core";

const blueprint = JSON.parse(fs.readFileSync("./plutus.json"));
const scriptCbor = blueprint.validators[0].compiledCode;

const scriptAddress = serializePlutusScript(
  { code: scriptCbor, version: "V3" },
  undefined,
  0  // 0 for Preview testnet, 1 for mainnet
).address;

console.log("Script Address:", scriptAddress);
// Output: addr_test1wz4me4szhp7l0qhd9yrlr0dvhe5kx70m2q3y7aw4ql2w7gssu5qwr
```

#### For Minting Validators:

The validator hash becomes the policy ID for tokens minted under this policy.

```javascript
const blueprint = JSON.parse(fs.readFileSync("./plutus.json"));
const mintingValidator = blueprint.validators.find(
  v => v.title.includes("mint")
);

const policyId = mintingValidator.hash;

console.log("Policy ID:", policyId);
// Output: 69b9758387079fd00c05c7daa8fde367acdb84dbd9c35dfd05b701ad
```

### 1.4 Parameterized Validators in Off-Chain Code

Many validators use parameters that must be applied before generating addresses or policy IDs.

**On-Chain Aiken Code:**

```aiken
validator marketplace(owner_pkh: ByteArray, fee_percentage: Int) {
  spend(
    datum: Option<ListingDatum>,
    redeemer: MarketplaceAction,
    _input: OutputReference,
    self: Transaction,
  ) {
    // Validator logic using owner_pkh and fee_percentage
    todo
  }
}
```

**Off-Chain Parameter Application:**

```javascript
import { applyParamsToScript } from "@meshsdk/core-csl";

const blueprint = JSON.parse(fs.readFileSync("./plutus.json"));
const validator = blueprint.validators[0];

// Define parameters (must match order and types in Aiken)
const params = [
  owner_pkh,      // ByteArray
  fee_percentage  // Int
];

// Apply parameters to get the actual script code
const scriptCbor = applyParamsToScript(
  validator.compiledCode,
  params
);

// Now generate address with parameterized script
const scriptAddress = serializePlutusScript(
  { code: scriptCbor, version: "V3" },
  undefined,
  0
).address;
```

**Important:** Different parameters produce different script addresses! This is how you can create multiple independent instances of the same validator logic.

### 1.5 Reading Datum and Redeemer Schemas

Understanding the schema is crucial for building correct transactions.

**Example Schema from Blueprint:**

```json
"marketplace/ListingDatum": {
  "title": "ListingDatum",
  "anyOf": [
    {
      "title": "ListingDatum",
      "dataType": "constructor",
      "index": 0,
      "fields": [
        {
          "title": "seller",
          "$ref": "#/definitions/ByteArray"
        },
        {
          "title": "price",
          "$ref": "#/definitions/Int"
        },
        {
          "title": "nft_policy",
          "$ref": "#/definitions/ByteArray"
        },
        {
          "title": "nft_name",
          "$ref": "#/definitions/ByteArray"
        }
      ]
    }
  ]
}
```

**Building This Datum Off-Chain:**

```javascript
const listingDatum = {
  alternative: 0,  // ListingDatum constructor index
  fields: [
    { bytes: sellerPkh },           // seller
    { int: 10000000 },              // price (10 ADA in lovelace)
    { bytes: nftPolicyId },         // nft_policy
    { bytes: nftAssetName }         // nft_name
  ]
};
```

**Key Points:**
- ByteArray fields use `{ bytes: hexString }`
- Int fields use `{ int: number }`
- Lists use `{ list: [...] }`
- Field order must match exactly

## Part 2: Multi-Validator DApp Architecture (45-50 minutes)

### 2.1 Designing Multi-Validator Systems

Real-world DApps rarely use just one validator. Complex systems require multiple validators working together, each with specific responsibilities.

**Common Multi-Validator Patterns:**

1. **Oracle + Consumer Pattern**: Reference token (oracle) maintains state, multiple validators consume that state
2. **Vault + Policy Pattern**: Spending validator holds assets, minting policy controls access
3. **Registry + Entry Pattern**: Central registry tracks entries, each entry has its own validator
4. **Governance + Treasury Pattern**: Voting validator makes decisions, treasury validator executes them

**Example: NFT Marketplace System**

```
┌─────────────────────────────────────────────────────────────┐
│                    NFT Marketplace DApp                      │
└─────────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
    ┌──────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
    │   Listing   │ │   Offer    │ │  Royalty   │
    │  Validator  │ │  Validator │ │  Validator │
    └──────┬──────┘ └─────┬──────┘ └─────┬──────┘
           │               │               │
           │   Params:     │               │
           │   - fee_addr  │               │
           │   - fee_pct   │               │
           └───────────────┴───────────────┘
                           │
                    ┌──────▼──────┐
                    │  Collection │
                    │   Policy    │
                    └─────────────┘
```

**Validator Responsibilities:**

- **Listing Validator**: Manages NFT listings, validates purchases, handles delisting
- **Offer Validator**: Manages offers on listed NFTs, validates acceptance/rejection
- **Royalty Validator**: Ensures creator royalties are paid on secondary sales
- **Collection Policy**: Validates that NFTs are authentic members of the collection

### 2.2 Parameter Dependency Trees

Parameters create dependencies between validators. Understanding these dependencies is crucial for initialization and deployment.

**Example Dependency Tree:**

```
                    Root: System Deployer
                            │
                    ┌───────┴───────┐
                    │               │
            Oracle NFT Policy    Admin PKH
           (uses: utxo_ref)         │
                    │               │
                    ▼               │
            Oracle Validator        │
          (param: oracle_nft) ──────┤
                    │               │
                    ▼               ▼
          Collection NFT Policy
          (params: oracle_nft, admin_pkh, collection_name)
```

**Initialization Sequence:**

1. Deploy system with unique UTxO reference
2. Mint oracle NFT using that UTxO (creates unique policy ID)
3. Lock oracle NFT at oracle validator with initial state
4. Deploy collection policy using oracle NFT policy ID as parameter
5. System is ready for user interactions

**Documentation Format:**

```markdown
## Parameter Dependencies

### Oracle NFT Policy
- **utxo_ref**: OutputReference
  - Source: Deployer's UTxO (must be consumed in minting transaction)
  - Purpose: Ensures one-time minting

### Oracle Validator  
- **oracle_nft**: ByteArray (PolicyId)
  - Source: Oracle NFT Policy hash
  - Purpose: Identifies the authentic oracle token

### Collection NFT Policy
- **oracle_nft**: ByteArray (PolicyId)
  - Source: Oracle NFT Policy hash
  - Purpose: Reference input validation
- **admin_pkh**: ByteArray (PubKeyHash)
  - Source: System administrator's public key hash
  - Purpose: Emergency controls
- **collection_name**: ByteArray
  - Source: Configuration
  - Purpose: Token name prefix
```

### 2.3 Validator Communication Patterns

Validators don't directly call each other, but they communicate through transactions.

**Pattern 1: Reference Input Communication**

```aiken
// Oracle validator holds state
pub type OracleState {
  counter: Int,
  authorized_contracts: List<ByteArray>,
}

// Consumer validator reads oracle state
validator consumer(oracle_policy: ByteArray) {
  spend(
    datum: Option<MyDatum>,
    redeemer: MyAction,
    _input: OutputReference,
    self: Transaction,
  ) {
    // Find oracle as reference input
    expect Some(oracle_input) = list.find(
      self.reference_inputs,
      fn(input) {
        assets.quantity_of(
          input.output.value,
          oracle_policy,
          ""
        ) == 1
      }
    )
    
    // Extract oracle state
    expect InlineDatum(oracle_datum) = oracle_input.output.datum
    expect oracle_state: OracleState = oracle_datum
    
    // Use oracle state in validation
    oracle_state.counter > 0
  }
}
```

**Pattern 2: Token-Based Authorization**

```aiken
// Admin token policy (one-time mint)
validator admin_token(init_utxo: OutputReference) {
  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    let is_minting_one = 
      assets.tokens(self.mint, policy_id) 
      |> dict.to_pairs()
      |> list.length() == 1
    
    let utxo_consumed = 
      list.any(self.inputs, fn(input) { 
        input.output_reference == init_utxo 
      })
    
    is_minting_one && utxo_consumed
  }
}

// Protected validator requires admin token
validator protected_action(admin_policy: ByteArray) {
  spend(
    datum: Option<MyDatum>,
    redeemer: MyAction,
    input: OutputReference,
    self: Transaction,
  ) {
    when redeemer is {
      AdminAction -> {
        // Require admin token in transaction
        expect Some(_admin_input) = list.find(
          self.inputs,
          fn(input) {
            assets.quantity_of(
              input.output.value,
              admin_policy,
              ""
            ) >= 1
          }
        )
        True
      }
      NormalAction -> {
        // Normal validation logic
        todo
      }
    }
  }
}
```

**Pattern 3: Datum Chain Communication**

```aiken
// Validator 1 outputs datum with message for Validator 2
pub type MessageDatum {
  recipient_validator: ByteArray,
  message_data: ByteArray,
  timestamp: Int,
}

validator sender {
  spend(
    datum: Option<SenderDatum>,
    redeemer: SendMessage,
    _input: OutputReference,
    self: Transaction,
  ) {
    // Create output with message datum
    let message = MessageDatum {
      recipient_validator: redeemer.target,
      message_data: redeemer.data,
      timestamp: get_current_time(self),
    }
    
    // Validate output exists with this datum
    expect Some(_) = list.find(
      self.outputs,
      fn(output) {
        expect InlineDatum(datum) = output.datum
        expect msg: MessageDatum = datum
        msg == message
      }
    )
    
    True
  }
}

// Validator 2 reads and processes message
validator receiver(expected_sender: ByteArray) {
  spend(
    datum: Option<MessageDatum>,
    redeemer: ProcessMessage,
    _input: OutputReference,
    self: Transaction,
  ) {
    expect Some(msg_datum) = datum
    
    // Validate message is from expected sender
    msg_datum.recipient_validator == expected_sender
  }
}
```

## Part 3: Marketplace Contract Implementation (30-35 minutes)

### 3.1 Marketplace Architecture

A marketplace allows users to list NFTs for sale and other users to purchase them. The marketplace takes a small fee on each sale.

**System Components:**

1. **Listing Validator**: Holds listed NFTs with seller information and price
2. **Marketplace Parameters**: Fee address and fee percentage
3. **Royalty System**: Optional creator royalties on secondary sales

**Data Structures:**

```aiken
pub type ListingDatum {
  seller: ByteArray,
  price: Int,
  nft_policy: ByteArray,
  nft_name: ByteArray,
  royalty_address: Option<Address>,
  royalty_percentage: Int,  // Basis points (100 = 1%)
}

pub type MarketplaceAction {
  List
  UpdatePrice { new_price: Int }
  Delist
  Purchase
}
```

### 3.2 Marketplace Validator Implementation

```aiken
use aiken/collection/list
use aiken/collection/dict
use cardano/transaction.{Transaction, Output, OutputReference, InlineDatum}
use cardano/address.{Address}
use cardano/assets.{PolicyId, AssetName, quantity_of, lovelace_of}

validator marketplace(
  fee_address: Address,
  fee_percentage: Int,  // Basis points (100 = 1%)
) {
  spend(
    datum_opt: Option<ListingDatum>,
    redeemer: MarketplaceAction,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(listing) = datum_opt
    
    when redeemer is {
      // Seller lists NFT
      List -> {
        // Validate seller signature
        list.has(self.extra_signatories, listing.seller)
      }
      
      // Seller updates price
      UpdatePrice { new_price } -> {
        // Must be signed by seller
        let is_signed = list.has(self.extra_signatories, listing.seller)
        
        // Must have continuing output with updated datum
        expect Some(continuing_output) = find_continuing_output(
          self.outputs,
          own_ref,
        )
        
        expect InlineDatum(new_datum_data) = continuing_output.datum
        expect new_listing: ListingDatum = new_datum_data
        
        // Validate updated datum
        let valid_datum = and {
          new_listing.seller == listing.seller,
          new_listing.price == new_price,
          new_listing.nft_policy == listing.nft_policy,
          new_listing.nft_name == listing.nft_name,
        }
        
        is_signed && valid_datum
      }
      
      // Seller delists NFT
      Delist -> {
        // Must be signed by seller
        let is_signed = list.has(self.extra_signatories, listing.seller)
        
        // NFT must return to seller
        let nft_returned = list.any(
          self.outputs,
          fn(output) {
            and {
              output.address.payment_credential == 
                address.from_verification_key(listing.seller).payment_credential,
              quantity_of(output.value, listing.nft_policy, listing.nft_name) >= 1,
            }
          }
        )
        
        is_signed && nft_returned
      }
      
      // Buyer purchases NFT
      Purchase -> {
        // Calculate fees
        let marketplace_fee = listing.price * fee_percentage / 10000
        let royalty_fee = when listing.royalty_address is {
          Some(_) -> listing.price * listing.royalty_percentage / 10000
          None -> 0
        }
        let seller_payment = listing.price - marketplace_fee - royalty_fee
        
        // Validate seller receives payment
        let seller_paid = list.any(
          self.outputs,
          fn(output) {
            and {
              output.address.payment_credential == 
                address.from_verification_key(listing.seller).payment_credential,
              lovelace_of(output.value) >= seller_payment,
            }
          }
        )
        
        // Validate marketplace fee paid
        let marketplace_fee_paid = list.any(
          self.outputs,
          fn(output) {
            and {
              output.address == fee_address,
              lovelace_of(output.value) >= marketplace_fee,
            }
          }
        )
        
        // Validate royalty paid (if applicable)
        let royalty_paid = when listing.royalty_address is {
          Some(royalty_addr) -> 
            list.any(
              self.outputs,
              fn(output) {
                and {
                  output.address == royalty_addr,
                  lovelace_of(output.value) >= royalty_fee,
                }
              }
            )
          None -> True
        }
        
        seller_paid && marketplace_fee_paid && royalty_paid
      }
    }
  }
}

// Helper function to find continuing output
fn find_continuing_output(
  outputs: List<Output>,
  spent_ref: OutputReference,
) -> Option<Output> {
  // In practice, match by address and datum structure
  list.head(outputs)
}
```

### 3.3 Marketplace Usage Patterns

**Listing an NFT:**

```javascript
// Off-chain transaction building
const listingDatum = {
  alternative: 0,
  fields: [
    { bytes: sellerPkh },
    { int: 50000000 },  // 50 ADA
    { bytes: nftPolicyId },
    { bytes: nftAssetName },
    { constructor: 0, fields: [{ bytes: royaltyAddress }] },
    { int: 250 }  // 2.5% royalty
  ]
};

const tx = await mesh
  .txOut(marketplaceAddress, [
    { unit: "lovelace", quantity: "2000000" },
    { unit: nftPolicyId + nftAssetName, quantity: "1" }
  ])
  .txOutInlineDatum(listingDatum)
  .changeAddress(sellerAddress)
  .selectUtxosFrom(sellerUtxos)
  .complete();
```

**Purchasing an NFT:**

```javascript
const purchaseRedeemer = {
  data: { alternative: 3, fields: [] }  // Purchase constructor
};

const tx = await mesh
  .txIn(
    listingUtxoTxHash,
    listingUtxoIndex,
    listingUtxoAssets,
    marketplaceAddress
  )
  .txInScript(marketplaceScriptCbor)
  .txInRedeemerValue(purchaseRedeemer)
  .txInDatumValue(listingDatum)
  .txOut(sellerAddress, [
    { unit: "lovelace", quantity: sellerPayment.toString() }
  ])
  .txOut(marketplaceFeeAddress, [
    { unit: "lovelace", quantity: marketplaceFee.toString() }
  ])
  .txOut(buyerAddress, [
    { unit: nftPolicyId + nftAssetName, quantity: "1" }
  ])
  .changeAddress(buyerAddress)
  .selectUtxosFrom(buyerUtxos)
  .complete();
```

## Part 4: Staking & Rewards Implementation (30-35 minutes)

### 4.1 Staking System Architecture

A staking system allows users to lock tokens for a period and earn rewards based on time staked.

**System Design:**

```
User Stakes Tokens → Stake Validator (with datum) → Time Passes → User Withdraws with Rewards
```

**Data Structures:**

```aiken
pub type StakeDatum {
  staker: ByteArray,
  staked_amount: Int,
  stake_token_policy: ByteArray,
  stake_token_name: ByteArray,
  stake_start_time: Int,
  last_claim_time: Int,
}

pub type StakeAction {
  Stake { amount: Int }
  ClaimRewards
  Unstake
  IncreaseStake { additional_amount: Int }
}
```

### 4.2 Staking Validator Implementation

```aiken
use aiken/collection/list
use aiken/interval
use cardano/transaction.{Transaction, OutputReference, InlineDatum}
use cardano/assets.{quantity_of, lovelace_of}

validator staking_rewards(
  reward_rate: Int,  // Lovelace per token per day (scaled by 1000000)
  minimum_stake_period: Int,  // Milliseconds
) {
  spend(
    datum_opt: Option<StakeDatum>,
    redeemer: StakeAction,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(stake) = datum_opt
    
    when redeemer is {
      // User stakes tokens
      Stake { amount } -> {
        // Must be signed by staker
        let is_signed = list.has(self.extra_signatories, stake.staker)
        
        // Validate initial stake setup
        let valid_initial = and {
          stake.staked_amount == amount,
          amount > 0,
          stake.stake_start_time > 0,
          stake.last_claim_time == stake.stake_start_time,
        }
        
        is_signed && valid_initial
      }
      
      // User claims rewards without unstaking
      ClaimRewards -> {
        // Must be signed by staker
        let is_signed = list.has(self.extra_signatories, stake.staker)
        
        // Calculate time staked since last claim
        expect Some(current_time) = get_lower_bound(self.validity_range)
        let time_staked = current_time - stake.last_claim_time
        
        // Calculate rewards
        let days_staked = time_staked / 86400000  // Convert ms to days
        let rewards = stake.staked_amount * reward_rate * days_staked / 1000000
        
        // Validate reward payment
        let rewards_paid = list.any(
          self.outputs,
          fn(output) {
            and {
              output.address.payment_credential == 
                address.from_verification_key(stake.staker).payment_credential,
              lovelace_of(output.value) >= rewards,
            }
          }
        )
        
        // Validate continuing output with updated datum
        expect Some(continuing_output) = find_continuing_output(
          self.outputs,
          own_ref,
        )
        
        expect InlineDatum(new_datum_data) = continuing_output.datum
        expect new_stake: StakeDatum = new_datum_data
        
        let valid_continuation = and {
          new_stake.staker == stake.staker,
          new_stake.staked_amount == stake.staked_amount,
          new_stake.last_claim_time == current_time,
        }
        
        is_signed && rewards_paid && valid_continuation
      }
      
      // User unstakes and claims all rewards
      Unstake -> {
        // Must be signed by staker
        let is_signed = list.has(self.extra_signatories, stake.staker)
        
        // Check minimum stake period
        expect Some(current_time) = get_lower_bound(self.validity_range)
        let time_staked = current_time - stake.stake_start_time
        let minimum_period_met = time_staked >= minimum_stake_period
        
        // Calculate total rewards
        let total_time = current_time - stake.last_claim_time
        let days_staked = total_time / 86400000
        let rewards = stake.staked_amount * reward_rate * days_staked / 1000000
        
        // Validate staker receives tokens + rewards
        let tokens_and_rewards_returned = list.any(
          self.outputs,
          fn(output) {
            and {
              output.address.payment_credential == 
                address.from_verification_key(stake.staker).payment_credential,
              quantity_of(
                output.value,
                stake.stake_token_policy,
                stake.stake_token_name
              ) >= stake.staked_amount,
              lovelace_of(output.value) >= rewards,
            }
          }
        )
        
        is_signed && minimum_period_met && tokens_and_rewards_returned
      }
      
      // User increases stake
      IncreaseStake { additional_amount } -> {
        // Must be signed by staker
        let is_signed = list.has(self.extra_signatories, stake.staker)
        
        // Validate continuing output with increased stake
        expect Some(continuing_output) = find_continuing_output(
          self.outputs,
          own_ref,
        )
        
        expect InlineDatum(new_datum_data) = continuing_output.datum
        expect new_stake: StakeDatum = new_datum_data
        
        let valid_increase = and {
          new_stake.staker == stake.staker,
          new_stake.staked_amount == stake.staked_amount + additional_amount,
          new_stake.last_claim_time == stake.last_claim_time,
        }
        
        is_signed && valid_increase
      }
    }
  }
}

// Helper to get current time from validity range
fn get_lower_bound(range: ValidityRange) -> Option<Int> {
  when range.lower_bound.bound_type is {
    Finite(time) -> Some(time)
    _ -> None
  }
}
```

### 4.3 Reward Calculation Strategies

**Linear Time-Based Rewards:**

```
rewards_per_day = staked_amount * reward_rate
total_rewards = rewards_per_day * days_staked
```

**Compound Interest Rewards:**

```aiken
fn calculate_compound_rewards(
  principal: Int,
  rate: Int,
  time_periods: Int,
) -> Int {
  // A = P(1 + r)^t
  // Implemented with fixed-point arithmetic
  let compound_factor = power((10000 + rate), time_periods) / power(10000, time_periods)
  principal * compound_factor / 10000 - principal
}
```

**Token-Weighted Rewards Pool:**

```aiken
fn calculate_pool_rewards(
  user_staked: Int,
  total_staked: Int,
  reward_pool: Int,
) -> Int {
  // User's share = (user_staked / total_staked) * reward_pool
  user_staked * reward_pool / total_staked
}
```

## Part 5: DAO Governance Implementation (35-40 minutes)

### 5.1 DAO Architecture

A Decentralized Autonomous Organization (DAO) allows token holders to vote on proposals that govern the protocol.

**System Components:**

1. **Governance Token**: Voting power is proportional to token holdings
2. **Proposal Validator**: Manages proposal lifecycle
3. **Treasury Validator**: Holds protocol funds
4. **Voting Validator**: Tracks votes
5. **Execution Validator**: Executes passed proposals

**Data Structures:**

```aiken
pub type ProposalDatum {
  proposal_id: Int,
  proposer: ByteArray,
  title: ByteArray,
  description: ByteArray,
  execution_script: ByteArray,  // What to execute if passed
  creation_time: Int,
  voting_deadline: Int,
  execution_deadline: Int,
  votes_for: Int,
  votes_against: Int,
  status: ProposalStatus,
}

pub type ProposalStatus {
  Active
  Passed
  Rejected
  Executed
  Expired
}

pub type GovernanceAction {
  CreateProposal
  Vote { in_favor: Bool, voting_power: Int }
  FinalizeVoting
  ExecuteProposal
  CancelProposal  // Only proposer before voting starts
}

pub type VoteDatum {
  proposal_id: Int,
  voter: ByteArray,
  voting_power: Int,
  in_favor: Bool,
  vote_time: Int,
}
```

### 5.2 Proposal Validator Implementation

```aiken
validator governance(
  governance_token: PolicyId,
  quorum_percentage: Int,  // Basis points (5000 = 50%)
  approval_percentage: Int,  // Basis points (6666 = 66.66%)
  minimum_voting_period: Int,  // Milliseconds
) {
  spend(
    datum_opt: Option<ProposalDatum>,
    redeemer: GovernanceAction,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(proposal) = datum_opt
    
    when redeemer is {
      // User creates new proposal
      CreateProposal -> {
        // Must be signed by proposer
        let is_signed = list.has(self.extra_signatories, proposal.proposer)
        
        // Must hold minimum governance tokens
        let proposer_voting_power = get_voting_power(
          self.inputs,
          proposal.proposer,
          governance_token,
        )
        let minimum_tokens_held = proposer_voting_power >= 100000000  // Example: 100 tokens
        
        // Validate initial proposal state
        let valid_initial = and {
          proposal.status == Active,
          proposal.votes_for == 0,
          proposal.votes_against == 0,
          proposal.voting_deadline > proposal.creation_time + minimum_voting_period,
        }
        
        is_signed && minimum_tokens_held && valid_initial
      }
      
      // User votes on proposal
      Vote { in_favor, voting_power } -> {
        // Must be during voting period
        expect Some(current_time) = get_lower_bound(self.validity_range)
        let is_active = and {
          current_time < proposal.voting_deadline,
          proposal.status == Active,
        }
        
        // Validate voter hasn't voted before
        let voter_pkh = expect_single_signatory(self.extra_signatories)
        let hasnt_voted = !has_voted(self.reference_inputs, proposal.proposal_id, voter_pkh)
        
        // Validate voting power matches tokens held
        let actual_voting_power = get_voting_power(
          self.inputs,
          voter_pkh,
          governance_token,
        )
        let valid_voting_power = voting_power == actual_voting_power
        
        // Create vote record output
        let vote_recorded = list.any(
          self.outputs,
          fn(output) {
            expect InlineDatum(datum) = output.datum
            expect vote: VoteDatum = datum
            and {
              vote.proposal_id == proposal.proposal_id,
              vote.voter == voter_pkh,
              vote.voting_power == voting_power,
              vote.in_favor == in_favor,
            }
          }
        )
        
        // Update proposal datum with vote
        expect Some(continuing_output) = find_continuing_output(
          self.outputs,
          own_ref,
        )
        
        expect InlineDatum(new_datum_data) = continuing_output.datum
        expect new_proposal: ProposalDatum = new_datum_data
        
        let valid_vote_tally = if in_favor {
          new_proposal.votes_for == proposal.votes_for + voting_power
        } else {
          new_proposal.votes_against == proposal.votes_against + voting_power
        }
        
        is_active && hasnt_voted && valid_voting_power && vote_recorded && valid_vote_tally
      }
      
      // Finalize voting and determine outcome
      FinalizeVoting -> {
        // Voting period must be over
        expect Some(current_time) = get_lower_bound(self.validity_range)
        let voting_ended = current_time >= proposal.voting_deadline
        
        // Calculate if proposal passed
        let total_votes = proposal.votes_for + proposal.votes_against
        let total_supply = get_total_token_supply(governance_token)
        
        // Check quorum (minimum participation)
        let quorum_met = total_votes * 10000 / total_supply >= quorum_percentage
        
        // Check approval threshold
        let approval_met = proposal.votes_for * 10000 / total_votes >= approval_percentage
        
        let new_status = if quorum_met && approval_met {
          Passed
        } else {
          Rejected
        }
        
        // Update proposal status
        expect Some(continuing_output) = find_continuing_output(
          self.outputs,
          own_ref,
        )
        
        expect InlineDatum(new_datum_data) = continuing_output.datum
        expect new_proposal: ProposalDatum = new_datum_data
        
        let valid_finalization = and {
          new_proposal.status == new_status,
          new_proposal.votes_for == proposal.votes_for,
          new_proposal.votes_against == proposal.votes_against,
        }
        
        voting_ended && valid_finalization
      }
      
      // Execute passed proposal
      ExecuteProposal -> {
        // Must be in Passed status
        let is_passed = proposal.status == Passed
        
        // Must be before execution deadline
        expect Some(current_time) = get_lower_bound(self.validity_range)
        let before_deadline = current_time < proposal.execution_deadline
        
        // Execute the proposal action (this would interact with treasury, etc.)
        let execution_valid = validate_execution(proposal.execution_script, self)
        
        // Update status to Executed
        expect Some(continuing_output) = find_continuing_output(
          self.outputs,
          own_ref,
        )
        
        expect InlineDatum(new_datum_data) = continuing_output.datum
        expect new_proposal: ProposalDatum = new_datum_data
        
        let status_updated = new_proposal.status == Executed
        
        is_passed && before_deadline && execution_valid && status_updated
      }
      
      // Proposer cancels before voting starts
      CancelProposal -> {
        // Must be signed by proposer
        let is_proposer = list.has(self.extra_signatories, proposal.proposer)
        
        // No votes can have been cast
        let no_votes = and {
          proposal.votes_for == 0,
          proposal.votes_against == 0,
        }
        
        is_proposer && no_votes
      }
    }
  }
}

// Helper functions
fn get_voting_power(
  inputs: List<Input>,
  voter: ByteArray,
  token: PolicyId,
) -> Int {
  list.foldl(
    inputs,
    0,
    fn(input, total) {
      if has_credential(input.output.address, voter) {
        total + quantity_of(input.output.value, token, "")
      } else {
        total
      }
    }
  )
}

fn has_voted(
  ref_inputs: List<Input>,
  proposal_id: Int,
  voter: ByteArray,
) -> Bool {
  list.any(
    ref_inputs,
    fn(input) {
      expect InlineDatum(datum) = input.output.datum
      expect vote: VoteDatum = datum
      and {
        vote.proposal_id == proposal_id,
        vote.voter == voter,
      }
    }
  )
}

fn validate_execution(script: ByteArray, tx: Transaction) -> Bool {
  // In production, this would validate that the execution
  // script's requirements are met in the transaction
  True
}
```

### 5.3 DAO Governance Patterns

**Time-Locked Execution:**

```aiken
// Proposal must wait before execution
let time_lock_met = 
  current_time >= proposal.voting_deadline + execution_delay
```

**Multi-Stage Voting:**

```aiken
pub type VotingStage {
  Discussion
  Voting
  Execution
}

// Enforce stage progression
fn valid_stage_transition(current: VotingStage, next: VotingStage) -> Bool {
  when (current, next) is {
    (Discussion, Voting) -> True
    (Voting, Execution) -> True
    _ -> False
  }
}
```

**Delegation Support:**

```aiken
pub type DelegationDatum {
  delegator: ByteArray,
  delegate: ByteArray,
  voting_power: Int,
}

// Delegate can vote with delegator's tokens
fn get_delegated_voting_power(
  ref_inputs: List<Input>,
  delegate: ByteArray,
) -> Int {
  list.foldl(
    ref_inputs,
    0,
    fn(input, total) {
      expect InlineDatum(datum) = input.output.datum
      expect delegation: DelegationDatum = datum
      if delegation.delegate == delegate {
        total + delegation.voting_power
      } else {
        total
      }
    }
  )
}
```

## Part 6: Production Considerations (25-30 minutes)

### 6.1 Transaction Cost Optimization

**Minimize Script Size:**

```aiken
// Instead of repeating validation logic
fn validate_common_checks(datum: MyDatum, tx: Transaction) -> Bool {
  and {
    list.has(tx.extra_signatories, datum.owner),
    get_current_time(tx) < datum.deadline,
    has_minimum_value(tx.inputs),
  }
}

validator optimized {
  spend(datum: Option<MyDatum>, redeemer: Action, input: OutputReference, tx: Transaction) {
    expect Some(d) = datum
    
    // Reuse common checks
    let common_valid = validate_common_checks(d, tx)
    
    when redeemer is {
      Action1 -> common_valid && specific_check_1(tx)
      Action2 -> common_valid && specific_check_2(tx)
      Action3 -> common_valid && specific_check_3(tx)
    }
  }
}
```

**Optimize Datum Sizes:**

```aiken
// Use compact representations
pub type CompactDatum {
  // Instead of storing full ByteArray addresses (28 bytes each)
  // Store indices into a known list
  seller_index: Int,  // 4 bytes
  price: Int,         // 8 bytes
  
  // Use bit flags instead of multiple bools
  flags: Int,  // Each bit represents a boolean flag
}

fn get_flag(flags: Int, position: Int) -> Bool {
  (flags / power(2, position)) % 2 == 1
}
```

**Batch Operations:**

```aiken
// Instead of individual transactions
validator batch_processor {
  spend(datum: Option<BatchDatum>, redeemer: BatchAction, input: OutputReference, tx: Transaction) {
    expect Some(batch) = datum
    
    // Process multiple items in one transaction
    list.all(
      batch.items,
      fn(item) { validate_item(item, tx) }
    )
  }
}
```

### 6.2 Upgradability Patterns

**Version Control:**

```aiken
pub type ValidatorVersion {
  V1
  V2
  V3
}

pub type VersionedDatum {
  version: ValidatorVersion,
  data: Data,
}

validator versioned {
  spend(datum: Option<VersionedDatum>, redeemer: Action, input: OutputReference, tx: Transaction) {
    expect Some(vdatum) = datum
    
    when vdatum.version is {
      V1 -> validate_v1(vdatum.data, redeemer, tx)
      V2 -> validate_v2(vdatum.data, redeemer, tx)
      V3 -> validate_v3(vdatum.data, redeemer, tx)
    }
  }
}
```

**Migration Actions:**

```aiken
pub type SystemAction {
  NormalOperation { action: UserAction }
  Migrate { new_version: Int }
  EmergencyShutdown
}

validator upgradeable(admin_pkh: ByteArray) {
  spend(datum: Option<SystemDatum>, redeemer: SystemAction, input: OutputReference, tx: Transaction) {
    expect Some(d) = datum
    
    when redeemer is {
      NormalOperation { action } -> {
        // Regular validation
        validate_user_action(action, d, tx)
      }
      
      Migrate { new_version } -> {
        // Only admin can migrate
        let is_admin = list.has(tx.extra_signatories, admin_pkh)
        
        // Validate migration to new validator
        expect Some(migration_output) = find_migration_output(tx.outputs)
        
        is_admin && valid_migration(migration_output, d, new_version)
      }
      
      EmergencyShutdown -> {
        // Only admin can shutdown
        list.has(tx.extra_signatories, admin_pkh)
      }
    }
  }
}
```

### 6.3 Comprehensive Error Handling

**Explicit Error Messages:**

```aiken
validator with_errors {
  spend(datum: Option<MyDatum>, redeemer: Action, input: OutputReference, tx: Transaction) {
    expect Some(d) = datum
    
    // Signature check with error
    expect True = list.has(tx.extra_signatories, d.owner)
      |> trace_if_false(@"Error: Transaction not signed by owner")
    
    // Time check with error
    expect Some(current_time) = get_lower_bound(tx.validity_range)
      |> trace_if_false(@"Error: Invalid validity range")
    
    expect True = current_time < d.deadline
      |> trace_if_false(@"Error: Deadline has passed")
    
    // Value check with error
    let input_value = get_own_input_value(tx.inputs, input)
    expect True = lovelace_of(input_value) >= d.minimum_value
      |> trace_if_false(@"Error: Insufficient value locked")
    
    True
  }
}

fn trace_if_false(result: Bool, message: String) -> Bool {
  if !result {
    trace message
    False
  } else {
    result
  }
}
```

### 6.4 Testing Complex Systems

**Test Pyramid for DApps:**

```
                  ┌─────────────┐
                  │ Integration │  <- Full system tests
                  │    Tests    │
                  └─────────────┘
              ┌───────────────────┐
              │  Multi-Validator  │  <- Cross-validator tests
              │      Tests        │
              └───────────────────┘
          ┌─────────────────────────┐
          │   Single Validator      │  <- Individual validator tests
          │       Tests             │
          └─────────────────────────┘
      ┌───────────────────────────────┐
      │      Unit Tests               │  <- Helper function tests
      │   (Helper Functions)          │
      └───────────────────────────────┘
```

**Integration Test Example:**

```aiken
test marketplace_full_lifecycle() {
  // Setup: Deploy system
  let admin_pkh = #"aabbcc"
  let fee_address = mock_address(admin_pkh)
  
  // Test 1: List NFT
  let seller_pkh = #"112233"
  let listing_datum = ListingDatum {
    seller: seller_pkh,
    price: 50000000,
    nft_policy: mock_policy_id,
    nft_name: "TestNFT",
    royalty_address: None,
    royalty_percentage: 0,
  }
  
  let list_tx = mock_list_transaction(listing_datum, seller_pkh)
  marketplace.spend(Some(listing_datum), List, mock_ref, list_tx)
  
  // Test 2: Update price
  let update_tx = mock_update_transaction(listing_datum, 60000000, seller_pkh)
  marketplace.spend(Some(listing_datum), UpdatePrice { new_price: 60000000 }, mock_ref, update_tx)
  
  // Test 3: Purchase
  let buyer_pkh = #"445566"
  let purchase_tx = mock_purchase_transaction(listing_datum, buyer_pkh, fee_address)
  marketplace.spend(Some(listing_datum), Purchase, mock_ref, purchase_tx)
}
```

### 6.5 Deployment Checklist

**Pre-Deployment:**

- [ ] All validators compile successfully
- [ ] Comprehensive test suite passes (100% coverage)
- [ ] Security audit completed (if applicable)
- [ ] Parameter values finalized
- [ ] Deployment scripts tested on testnet
- [ ] Off-chain code tested with testnet
- [ ] Documentation complete
- [ ] Emergency procedures defined

**Deployment Steps:**

1. **Generate Initialization UTxO**: Create unique UTxO for one-time minting
2. **Mint Admin/Oracle Tokens**: Execute one-time minting policies
3. **Lock Initial State**: Send oracle tokens to oracle validators with initial datums
4. **Deploy Parameterized Validators**: Generate addresses with proper parameters
5. **Test Live System**: Perform end-to-end tests on testnet
6. **Monitor First Transactions**: Watch for unexpected behavior
7. **Document Deployed Addresses**: Record all script addresses and policy IDs

**Post-Deployment:**

- [ ] Monitor validator activity
- [ ] Track transaction costs
- [ ] Collect user feedback
- [ ] Plan upgrades/improvements
- [ ] Maintain documentation

## Part 7: Hands-On Exercises (1.5 hours)

### Exercise 1: Blueprint Reading & Off-Chain Integration (20 minutes)

**Objective**: Practice reading plutus.json and building off-chain transaction code.

**Tasks**:
1. Compile a validator from previous modules
2. Locate the validator hash in plutus.json
3. Generate the script address
4. Identify constructor indexes for datum and redeemer
5. Write off-chain code to build a locking transaction

**Files**: validators/ex1_blueprint_reading.ak

```aiken
// Use a validator from M005 (state machine)
pub type CounterDatum {
  Initialize
  Active { count: Int }
  Closed
}

pub type CounterAction {
  Increment
  Decrement
  Close
}

validator counter {
  spend(
    datum_opt: Option<CounterDatum>,
    redeemer: CounterAction,
    _input: OutputReference,
    self: Transaction,
  ) {
    // Implementation from M005
    todo
  }
}
```

**Off-Chain Task** (JavaScript):
```javascript
// Read blueprint
const blueprint = JSON.parse(fs.readFileSync("./plutus.json"));

// TODO: Extract validator hash
// TODO: Generate script address
// TODO: Identify constructor indexes
// TODO: Build initialization transaction
```

**Success Criteria**:
✅ Script address generated correctly
✅ Constructor indexes documented
✅ Off-chain datum matches on-chain structure
✅ Transaction builds successfully

### Exercise 2: Multi-Validator System Design (30 minutes)

**Objective**: Design a complete multi-validator system with proper parameter dependencies.

**Scenario**: Create a simple escrow marketplace where users can create escrow contracts for any NFT.

**Components**:
1. **Escrow Validator**: Holds NFT and payment
2. **Escrow Registry**: Tracks active escrows
3. **Receipt NFT Policy**: Mints unique receipt for each escrow

**Tasks**:
1. Define all datum and redeemer types
2. Create parameter dependency tree
3. Implement validator interactions
4. Write initialization sequence

**Files**: validators/ex2_escrow_system.ak

```aiken
// TODO: Design complete system with:
// - EscrowDatum
// - RegistryDatum  
// - All redeemer types
// - Parameter dependencies

pub type EscrowDatum {
  // TODO: Define fields
  // seller, buyer, arbiter, nft_info, price, deadline
  todo
}

pub type RegistryDatum {
  // TODO: Define fields
  // escrow_count, active_escrows
  todo
}

// Receipt NFT Policy (one-time per escrow)
validator receipt_nft(registry_policy: ByteArray, escrow_id: Int) {
  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    // TODO: Implement one-time minting
    // Validate escrow_id matches registry
    todo
  }
}

// Escrow Validator
validator escrow(receipt_policy: ByteArray) {
  spend(
    datum_opt: Option<EscrowDatum>,
    redeemer: EscrowAction,
    _input: OutputReference,
    self: Transaction,
  ) {
    // TODO: Implement escrow logic
    // Release, Cancel, Arbitrate
    todo
  }
}

// Registry Validator
validator escrow_registry {
  spend(
    datum_opt: Option<RegistryDatum>,
    redeemer: RegistryAction,
    _input: OutputReference,
    self: Transaction,
  ) {
    // TODO: Implement registry logic
    // RegisterEscrow, CloseEscrow
    todo
  }
}
```

**Success Criteria**:
✅ Complete type definitions
✅ Parameter dependency tree documented
✅ Validators properly interact
✅ Initialization sequence defined
✅ All three validators implemented

### Exercise 3: Simple Marketplace Implementation (30 minutes)

**Objective**: Implement a functional NFT marketplace validator.

**Files**: validators/ex3_marketplace.ak

```aiken
pub type ListingDatum {
  seller: ByteArray,
  price: Int,
  nft_policy: ByteArray,
  nft_name: ByteArray,
}

pub type MarketplaceAction {
  List
  Delist
  Purchase
  UpdatePrice { new_price: Int }
}

// TODO: Implement complete marketplace validator
validator nft_marketplace(
  fee_address: Address,
  fee_percentage: Int,
) {
  spend(
    datum_opt: Option<ListingDatum>,
    redeemer: MarketplaceAction,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(listing) = datum_opt
    
    when redeemer is {
      List -> {
        // TODO: Validate listing
        todo
      }
      
      Delist -> {
        // TODO: Validate delisting
        todo
      }
      
      Purchase -> {
        // TODO: Validate purchase with fees
        todo
      }
      
      UpdatePrice { new_price } -> {
        // TODO: Validate price update
        todo
      }
    }
  }
}

// Write comprehensive tests
test list_nft_success() {
  // TODO: Test successful listing
  todo
}

test delist_nft_by_seller() {
  // TODO: Test delisting
  todo
}

test purchase_nft_with_fees() {
  // TODO: Test purchase with fee calculation
  todo
}

test update_price() {
  // TODO: Test price update
  todo
}
```

**Success Criteria**:
✅ All four actions implemented
✅ Fee calculation correct
✅ Signature validation works
✅ Value validation works
✅ 8+ tests passing

### Exercise 4: Basic Staking System (30 minutes)

**Objective**: Implement a time-based staking rewards system.

**Files**: validators/ex4_staking.ak

```aiken
pub type StakeDatum {
  staker: ByteArray,
  staked_amount: Int,
  stake_start_time: Int,
  last_claim_time: Int,
}

pub type StakeAction {
  Stake
  ClaimRewards
  Unstake
}

// TODO: Implement staking validator
validator staking_pool(
  reward_rate: Int,  // Lovelace per day per token
  minimum_stake_period: Int,  // Days
) {
  spend(
    datum_opt: Option<StakeDatum>,
    redeemer: StakeAction,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(stake) = datum_opt
    
    when redeemer is {
      Stake -> {
        // TODO: Validate initial stake
        todo
      }
      
      ClaimRewards -> {
        // TODO: Calculate and validate rewards
        // Update last_claim_time
        todo
      }
      
      Unstake -> {
        // TODO: Validate unstake
        // Check minimum period
        // Return tokens + rewards
        todo
      }
    }
  }
}

// Helper: Calculate rewards
fn calculate_rewards(
  amount: Int,
  rate: Int,
  days: Int,
) -> Int {
  // TODO: Implement reward calculation
  todo
}

// Write tests
test stake_tokens() {
  // TODO: Test staking
  todo
}

test claim_rewards_after_time() {
  // TODO: Test reward claiming
  todo
}

test unstake_after_minimum_period() {
  // TODO: Test unstaking
  todo
}
```

**Success Criteria**:
✅ Stake validation implemented
✅ Reward calculation works
✅ Time-based logic correct
✅ All tests passing

### Exercise 5: DAO Proposal System (30 minutes)

**Objective**: Implement a simplified DAO governance system.

**Files**: validators/ex5_dao.ak

```aiken
pub type ProposalDatum {
  proposal_id: Int,
  proposer: ByteArray,
  description: ByteArray,
  voting_deadline: Int,
  votes_for: Int,
  votes_against: Int,
  status: ProposalStatus,
}

pub type ProposalStatus {
  Active
  Passed
  Rejected
}

pub type GovernanceAction {
  CreateProposal
  Vote { in_favor: Bool, voting_power: Int }
  FinalizeVoting
}

// TODO: Implement DAO governance
validator dao_governance(
  governance_token: PolicyId,
  quorum_percentage: Int,
  approval_threshold: Int,
) {
  spend(
    datum_opt: Option<ProposalDatum>,
    redeemer: GovernanceAction,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(proposal) = datum_opt
    
    when redeemer is {
      CreateProposal -> {
        // TODO: Validate proposal creation
        // Check proposer holds minimum tokens
        todo
      }
      
      Vote { in_favor, voting_power } -> {
        // TODO: Validate vote
        // Check voting period
        // Validate voting power
        // Update vote tally
        todo
      }
      
      FinalizeVoting -> {
        // TODO: Finalize voting
        // Check quorum
        // Check approval
        // Update status
        todo
      }
    }
  }
}

// Helper: Get voting power
fn get_voting_power(
  inputs: List<Input>,
  voter: ByteArray,
  token: PolicyId,
) -> Int {
  // TODO: Calculate total token holdings
  todo
}

// Write tests
test create_proposal() {
  // TODO
  todo
}

test vote_on_proposal() {
  // TODO
  todo
}

test finalize_with_quorum() {
  // TODO
  todo
}
```

**Success Criteria**:
✅ Proposal creation works
✅ Voting logic correct
✅ Quorum calculation accurate
✅ Status transitions valid
✅ Tests comprehensive

## Assignment M007

**Objective**: Design and implement a complete, production-ready multi-validator DApp system that demonstrates mastery of advanced architecture patterns, off-chain integration, and complex validator interactions.

**Choose ONE of the following systems to implement:**

### Option A: NFT Marketplace with Offers**

Build a complete NFT marketplace that supports:
- Listing NFTs for direct sale
- Creating offers on listed NFTs
- Counter-offers from sellers
- Royalty payments on sales
- Marketplace fee distribution

#### Requirements:
- 3+ validators (Listing, Offer, Royalty Distribution)
- Parameter dependency tree
- Complete off-chain integration code
- Comprehensive test suite (20+ tests)
- Deployment documentation

### Option B: Token Staking & Governance DAO**

Build a complete staking + governance system that supports:
- Token staking with time-based rewards
- Proposal creation and voting
- Token-weighted voting power
- Quorum and approval thresholds
- Treasury management for executed proposals

#### Requirements:
- 4+ validators (Staking, Governance, Treasury, Vote Registry)
- Parameter dependency tree
- Complete off-chain integration code
- Comprehensive test suite (20+ tests)
- Deployment documentation

### Option C: Decentralized Freelancing Platform**

Build a freelancing escrow system that supports:
- Creating freelance job contracts
- Milestone-based payments
- Dispute resolution with arbitration
- Reputation tracking
- Service provider registration

#### Requirements:
- 4+ validators (Escrow, Registry, Reputation, Arbitration)
- Parameter dependency tree
- Complete off-chain integration code
- Comprehensive test suite (20+ tests)
- Deployment documentation

### Submission Requirements

1. **Complete Aiken Implementation**
   - All validators implemented and compiling
   - Comprehensive test suite with 20+ tests
   - All tests passing
   - Code well-commented

2. **Blueprint Documentation**
   - plutus.json generated
   - Constructor indexes documented
   - Datum/redeemer schemas explained
   - Script addresses and policy IDs listed

3. **Parameter Dependency Tree**
   - Visual diagram showing validator relationships
   - Initialization sequence documented
   - Parameter values and sources identified

4. **Off-Chain Integration Code**
   - JavaScript/TypeScript transaction builders
   - All user actions covered
   - Working examples on testnet
   - Transaction submission code

5. **Architecture Document**
   - System overview and component descriptions
   - User action flows with diagrams
   - Security considerations
   - Known limitations

6. **Deployment Guide**
   - Step-by-step deployment instructions
   - Testnet deployment evidence
   - Script addresses and policy IDs from testnet
   - Monitoring and maintenance procedures

7. **Testing Report**
   - Test coverage summary
   - Edge cases tested
   - Security test results
   - Performance considerations

### Submission Format:

Submit via the provided form:
- **Personal Details**: Name and contact information
- **GitHub URL**: Link to your m007-assignment repository with:
  - `/validators` - All Aiken validator code
  - `/offchain` - JavaScript/TypeScript integration code
  - `/docs` - Architecture document and deployment guide
  - `/tests` - Test results and coverage report
  - `README.md` - Project overview and setup instructions
  - `ARCHITECTURE.md` - Complete architecture documentation
  - `DEPLOYMENT.md` - Deployment guide
- **Testnet Deployment**: Links to testnet transactions demonstrating functionality
- **Video Demo** (optional): 5-10 minute walkthrough of your system
- **Description**: Brief summary including:
  - Which option you chose (A, B, or C)
  - Key architectural decisions
  - Challenges faced and solutions
  - What you learned about DApp architecture
  - Future improvements planned

### Deadline: Submit before the Final Workshop Presentations

### Grading Criteria:

- **Functionality** (30%): Does the system work as specified?
- **Code Quality** (20%): Is the code well-structured, documented, and following best practices?
- **Testing** (15%): Comprehensive test coverage and edge cases
- **Architecture** (15%): Sound design decisions and validator interactions
- **Off-Chain Integration** (10%): Complete and functional transaction builders
- **Documentation** (10%): Clear, comprehensive documentation

## Troubleshooting Guide

### Issue 1: "Cannot find validator hash in blueprint"**

#### Cause: Wrong validator name or multiple validators

#### Solution:
```javascript
// List all validators first
const blueprint = JSON.parse(fs.readFileSync("./plutus.json"));
console.log("Available validators:");
blueprint.validators.forEach(v => {
  console.log(`- ${v.title}: ${v.hash}`);
});

// Then access specific one
const myValidator = blueprint.validators.find(
  v => v.title === "my_validator.spend"
);
```

### Issue 2: "Constructor index mismatch"**

#### Cause: Off-chain index doesn't match on-chain definition

#### Solution:
```aiken
// In Aiken - check constructor order
pub type MyRedeemer {
  Action1  // index: 0
  Action2  // index: 1
  Action3  // index: 2
}

// In JavaScript - verify index
const redeemer = {
  data: {
    alternative: 0,  // Must match Action1
    fields: []
  }
};

// Cross-reference with plutus.json
console.log(blueprint.definitions["my_validator/MyRedeemer"]);
```

### Issue 3: "Applied parameters produce wrong address"**

#### Cause: Parameter order or type mismatch

#### Solution:
```aiken
// Aiken validator with parameters
validator my_validator(
  param1: ByteArray,  // Must be first
  param2: Int,        // Must be second
  param3: ByteArray,  // Must be third
) {
  // ...
}

// Off-chain parameter application
const params = [
  param1,  // ByteArray first
  param2,  // Int second  
  param3,  // ByteArray third
];

// Check parameter types match
console.log("Param types in blueprint:");
console.log(blueprint.validators[0].parameters);
```

### Issue 4: "Multi-validator transaction fails"**

#### Cause: Missing reference inputs or incorrect validator ordering

#### Solution:
```javascript
// Ensure reference inputs are included
tx.txInReference(
  oracleUtxoTxHash,
  oracleUtxoIndex,
  oracleUtxoAssets,
  oracleAddress
);

// Spend inputs in correct order
// 1. First: inputs that other validators depend on
// 2. Then: dependent validator inputs

// Check redeemer indices match input order
```

### Issue 5: "Deployment fails - validator not found"**

#### Cause: Script not properly serialized or wrong network

#### Solution:
```javascript
// Ensure correct network ID
const scriptAddress = serializePlutusScript(
  { code: scriptCbor, version: "V3" },
  undefined,
  0  // 0 = preview testnet, 1 = mainnet
).address;

// Verify script is valid
console.log("Script length:", scriptCbor.length);
console.log("Script starts with:", scriptCbor.substring(0, 10));
```

### Issue 6: "Integration test fails but unit tests pass"**

#### Cause: Mock transactions don't match real transaction structure

#### Solution:
```aiken
// Build more realistic mock transactions
use mocktail.{
  mocktail_tx,
  tx_in,
  tx_out,
  tx_out_inline_datum,
  tx_extra_signatories,
  tx_valid_range,
  complete
}

let realistic_tx = mocktail_tx()
  |> tx_in(True, input_ref, input_value, input_addr, Some(input_datum))
  |> tx_out(True, output_addr, output_value)
  |> tx_out_inline_datum(True, output_datum)
  |> tx_extra_signatories([signer_pkh])
  |> tx_valid_range(interval.after(current_time))
  |> complete()
```

## Additional Resources

### Documentation
- [Aiken Language Tour](https://aiken-lang.org/language-tour)
- [Aiken Standard Library](https://aiken-lang.github.io/stdlib/)
- [Mesh SDK Documentation](https://meshjs.dev/)
- [Lucid Evolution](https://anastasia-labs.github.io/lucid-evolution/)
- [Cardano Developer Portal](https://developers.cardano.org/)

### CIPs (Cardano Improvement Proposals)
- [CIP-25: NFT Metadata Standard](https://cips.cardano.org/cips/cip25/)
- [CIP-27: CNFT Community Royalties Standard](https://cips.cardano.org/cips/cip27/)
- [CIP-30: Cardano dApp-Wallet Web Bridge](https://cips.cardano.org/cips/cip30/)
- [CIP-57: Plutus Blueprint](https://cips.cardano.org/cips/cip57/)

### Video Tutorials
- "Building Multi-Validator Systems" (DirectEd Workshop Series)
- "Off-Chain Integration Deep Dive" (DirectEd Workshop Series)
- "DAO Governance on Cardano" (DirectEd Workshop Series)
- "Production DApp Deployment" (DirectEd Workshop Series)

### Community Resources
- Workshop Discord - #module-m007 channel
- [Cardano Stack Exchange](https://cardano.stackexchange.com/)
- [Aiken GitHub Discussions](https://github.com/aiken-lang/aiken/discussions)
- [Mesh Community Discord](https://discord.gg/mesh)

### Production DApp Examples
- [JPG Store](https://www.jpg.store/) - NFT Marketplace
- [SundaeSwap](https://sundaeswap.finance/) - DEX
- [MinSwap](https://minswap.org/) - DEX & Staking
- [Liqwid Finance](https://liqwid.finance/) - Lending Protocol

## Key Takeaways

By completing this module, you should now:

✅ Understand plutus.json blueprint structure and purpose
✅ Know how to read and interpret compiled validator data
✅ Be able to map on-chain types to off-chain representations
✅ Understand constructor indexing for transaction building
✅ Know how to generate script addresses and policy IDs
✅ Be able to design multi-validator DApp architectures
✅ Understand parameter dependency trees and initialization
✅ Know how validators communicate through transactions
✅ Be able to implement marketplace contracts
✅ Understand staking and rewards system patterns
✅ Know how to build DAO governance systems
✅ Understand production optimization techniques
✅ Know how to handle upgradability and versioning
✅ Be able to write comprehensive tests for complex systems
✅ Understand deployment procedures and monitoring
✅ Be ready to build production-ready DApps on Cardano!

## Congratulations!

You've completed the DirectEd x CATS Hackathon Aiken Development Workshop Series! Over seven modules, you've built a comprehensive foundation in Cardano smart contract development:

- **M000**: Set up your development environment and learned Cardano fundamentals
- **M001**: Wrote your first validators and understood the basics
- **M002**: Mastered testing with mock transactions
- **M003**: Implemented validation logic with datums and redeemers
- **M004**: Learned advanced input validation and security patterns
- **M005**: Built state machines and output validation
- **M006**: Created minting policies and NFT systems
- **M007**: Designed complete production-ready DApp architectures

**You're now equipped to:**
- Design and implement sophisticated multi-validator systems
- Build secure, efficient smart contracts on Cardano
- Integrate on-chain validators with off-chain applications
- Deploy and maintain production DApps
- Contribute to the Cardano ecosystem

**Next Steps:**
1. Complete your M007 assignment and showcase your work
2. Deploy your DApp to mainnet
3. Join the Cardano developer community
4. Build the future of decentralized applications!

**Keep Learning:**
- Explore advanced patterns in the Aiken documentation
- Study production DApps on Cardano
- Participate in hackathons and build projects
- Share your knowledge with others

Thank you for participating in the DirectEd x CATS Hackathon Aiken Development Workshop Series. We're excited to see what you build!

Questions? Ask in the workshop chat, visit office hours, or post in the workshop Discord server!

Document Version: 1.0
Last Updated: December 2025
DirectEd Development Foundation
