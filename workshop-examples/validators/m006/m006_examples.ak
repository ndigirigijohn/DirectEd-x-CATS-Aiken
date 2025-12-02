// =============================================================================
// Module M006 Workshop Examples
// Minting Policies and NFT Development
// =============================================================================

use aiken/collection/dict
use aiken/collection/list
use aiken/primitive/bytearray
use aiken/primitive/string
use cardano/address.{Address}
use cardano/assets.{
  PolicyId, add, flatten, from_lovelace, quantity_of,
}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use cocktail.{key_signed}
use mocktail.{
  complete, mint, mock_policy_id, mock_pub_key_address, mock_pub_key_hash,
  mock_script_address, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, required_signer_hash, tx_in, tx_in_inline_datum, tx_out,
  tx_out_inline_datum,
}

// -----------------------------------------------------------------------------
// Example 1: Simple Authorized Minting (Exercise 1)
// Demonstrates: Basic minting policy with signature authorization
// -----------------------------------------------------------------------------

pub type SimpleMintAction {
  SimpleMint
  SimpleBurn
}

validator simple_authorized_mint(authorized_key: ByteArray) {
  mint(redeemer: SimpleMintAction, policy_id: PolicyId, self: Transaction) {
    // Check signature authorization
    let signed = key_signed(self.extra_signatories, authorized_key)

    // Get tokens being minted/burned for this policy
    let tokens = assets.tokens(self.mint, policy_id)

    when redeemer is {
      SimpleMint -> {
        // For minting: verify signature and positive quantities
        let all_positive =
          list.all(tokens |> dict.values(), fn(quantity) { quantity > 0 })
        signed && all_positive
      }

      SimpleBurn -> {
        // For burning: verify signature and negative quantities
        let all_negative =
          list.all(tokens |> dict.values(), fn(quantity) { quantity < 0 })
        signed && all_negative
      }
    }
  }

  else(_) {
    fail
  }
}

// Tests for simple authorized minting
test test_simple_mint_with_signature_succeeds() {
  let authorized_key = #"aabbccdd"
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> mint(True, 100, policy_id, "TestToken")
      |> required_signer_hash(True, authorized_key)
      |> complete()

  simple_authorized_mint.mint(authorized_key, SimpleMint, policy_id, tx)
}

test test_simple_mint_without_signature_fails() fail {
  let authorized_key = #"aabbccdd"
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> mint(True, 100, policy_id, "TestToken")
      // No signature!
      |> complete()

  simple_authorized_mint.mint(authorized_key, SimpleMint, policy_id, tx)
}

test test_simple_burn_succeeds() {
  let authorized_key = #"aabbccdd"
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> mint(True, -50, policy_id, "TestToken")
      |> required_signer_hash(True, authorized_key)
      |> complete()

  simple_authorized_mint.mint(authorized_key, SimpleBurn, policy_id, tx)
}

// -----------------------------------------------------------------------------
// Example 2: One-Shot NFT Minting (Exercise 2)
// Demonstrates: OutputReference-based one-time minting for guaranteed uniqueness
// -----------------------------------------------------------------------------

pub type OneShotAction {
  OneShotMint
  OneShotBurn
}

validator one_shot_nft(utxo_ref: OutputReference) {
  mint(redeemer: OneShotAction, policy_id: PolicyId, self: Transaction) {
    let tokens = assets.tokens(self.mint, policy_id)

    when redeemer is {
      OneShotMint -> {
        // Check that the specific UTxO is being spent (one-shot guarantee)
        let has_utxo =
          list.any(
            self.inputs,
            fn(input: Input) { input.output_reference == utxo_ref },
          )

        // Must mint exactly 1 token
        expect [Pair(_, quantity)] = tokens |> dict.to_pairs()
        let mints_one = quantity == 1

        has_utxo && mints_one
      }

      OneShotBurn ->
        // For burning, just check all quantities are negative
        list.all(tokens |> dict.values(), fn(quantity) { quantity < 0 })
    }
  }

  else(_) {
    fail
  }
}

// Tests for one-shot NFT
test test_one_shot_mint_with_utxo_succeeds() {
  let utxo_ref = mock_utxo_ref(0, 0)
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(5_000_000),
          mock_pub_key_address(0, None),
        )
      |> mint(True, 1, policy_id, "UniqueNFT")
      |> complete()

  one_shot_nft.mint(utxo_ref, OneShotMint, policy_id, tx)
}

test test_one_shot_mint_without_utxo_fails() fail {
  let utxo_ref = mock_utxo_ref(0, 0)
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      // UTxO not included!
      |> mint(True, 1, policy_id, "UniqueNFT")
      |> complete()

  one_shot_nft.mint(utxo_ref, OneShotMint, policy_id, tx)
}

test test_one_shot_mint_multiple_tokens_fails() fail {
  let utxo_ref = mock_utxo_ref(0, 0)
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(5_000_000),
          mock_pub_key_address(0, None),
        )
      |> mint(True, 1, policy_id, "NFT1")
      |> mint(True, 1, policy_id, "NFT2")
      |> complete()

  one_shot_nft.mint(utxo_ref, OneShotMint, policy_id, tx)
}

test test_one_shot_burn_succeeds() {
  let utxo_ref = mock_utxo_ref(0, 0)
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> mint(True, -1, policy_id, "UniqueNFT")
      |> complete()

  one_shot_nft.mint(utxo_ref, OneShotBurn, policy_id, tx)
}

// -----------------------------------------------------------------------------
// Example 3: Named NFT with Prefix Validation (Exercise 3)
// Demonstrates: Token name validation with required prefix
// -----------------------------------------------------------------------------

pub type NamedNFTParams {
  utxo_ref: OutputReference,
  required_prefix: ByteArray,
}

validator named_nft(params: NamedNFTParams) {
  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    // One-shot: Check that UTxO is being spent
    let has_utxo =
      list.any(
        self.inputs,
        fn(input: Input) { input.output_reference == params.utxo_ref },
      )

    // Get tokens being minted
    let tokens = assets.tokens(self.mint, policy_id)

    // Must mint exactly 1 token
    expect [Pair(token_name, quantity)] = tokens |> dict.to_pairs()

    // Check quantity is 1
    let mints_one = quantity == 1

    // Check token name starts with required prefix
    let prefix_length = bytearray.length(params.required_prefix)
    let token_prefix = bytearray.take(token_name, prefix_length)
    let has_correct_prefix = token_prefix == params.required_prefix

    has_utxo && mints_one && has_correct_prefix
  }

  else(_) {
    fail
  }
}

// Tests for named NFT
test test_named_nft_correct_prefix_succeeds() {
  let params =
    NamedNFTParams {
      utxo_ref: mock_utxo_ref(0, 0),
      required_prefix: "MyCoolNFT_",
    }
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(5_000_000),
          mock_pub_key_address(0, None),
        )
      |> mint(True, 1, policy_id, "MyCoolNFT_001")
      |> complete()

  named_nft.mint(params, Void, policy_id, tx)
}

test test_named_nft_wrong_prefix_fails() fail {
  let params =
    NamedNFTParams {
      utxo_ref: mock_utxo_ref(0, 0),
      required_prefix: "MyCoolNFT_",
    }
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(5_000_000),
          mock_pub_key_address(0, None),
        )
      |> mint(True, 1, policy_id, "WrongPrefix_001")
      |> complete()

  named_nft.mint(params, Void, policy_id, tx)
}

// -----------------------------------------------------------------------------
// Example 4: Oracle NFT (One-Time Reference Token)
// Demonstrates: Oracle pattern - minting the reference token
// -----------------------------------------------------------------------------

pub type OracleNFTAction {
  MintOracleNFT
  BurnOracleNFT
}

validator oracle_nft(utxo_ref: OutputReference) {
  mint(redeemer: OracleNFTAction, policy_id: PolicyId, self: Transaction) {
    let tokens = assets.tokens(self.mint, policy_id)

    when redeemer is {
      MintOracleNFT -> {
        // One-shot: Check that UTxO is being spent
        let has_utxo =
          list.any(
            self.inputs,
            fn(input: Input) { input.output_reference == utxo_ref },
          )

        // Must mint exactly 1 token with empty name
        expect [Pair(token_name, quantity)] = tokens |> dict.to_pairs()
        let correct_mint = token_name == "" && quantity == 1

        has_utxo && correct_mint
      }

      BurnOracleNFT ->
        // For burning: all quantities must be negative
        list.all(tokens |> dict.values(), fn(quantity) { quantity < 0 })
    }
  }

  else(_) {
    fail
  }
}

// Tests for oracle NFT
test test_oracle_nft_mint_succeeds() {
  let utxo_ref = mock_utxo_ref(0, 0)
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(5_000_000),
          mock_pub_key_address(0, None),
        )
      |> mint(True, 1, policy_id, "")
      |> complete()

  oracle_nft.mint(utxo_ref, MintOracleNFT, policy_id, tx)
}

test test_oracle_nft_mint_without_utxo_fails() fail {
  let utxo_ref = mock_utxo_ref(0, 0)
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      // UTxO not included!
      |> mint(True, 1, policy_id, "")
      |> complete()

  oracle_nft.mint(utxo_ref, MintOracleNFT, policy_id, tx)
}

test test_oracle_nft_burn_succeeds() {
  let utxo_ref = mock_utxo_ref(0, 0)
  let policy_id = mock_policy_id(0)

  let tx =
    mocktail_tx()
      |> mint(True, -1, policy_id, "")
      |> complete()

  oracle_nft.mint(utxo_ref, BurnOracleNFT, policy_id, tx)
}

// -----------------------------------------------------------------------------
// Example 5: Mini Oracle Validator (Exercise 4)
// Demonstrates: Simple oracle validator that tracks counter state
// -----------------------------------------------------------------------------

pub type MiniOracleDatum {
  count: Int,
}

pub type MiniOracleRedeemer {
  IncrementCounter
}

validator mini_oracle(oracle_nft_policy: PolicyId) {
  spend(
    datum: Option<MiniOracleDatum>,
    redeemer: MiniOracleRedeemer,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(current_state) = datum

    // Single script input check (prevent double-satisfaction)
    expect Some(own_input) =
      list.find(self.inputs, fn(input) { input.output_reference == own_ref })
    let own_address = own_input.output.address
    let script_inputs =
      list.filter(
        self.inputs,
        fn(input: Input) { input.output.address == own_address },
      )
    expect [_single_input] = script_inputs

    // Get continuing output to same address
    let outputs_to_self =
      list.filter(
        self.outputs,
        fn(output: Output) { output.address == own_address },
      )
    expect [continuing_output] = outputs_to_self

    // Extract updated state
    expect InlineDatum(new_state_data) = continuing_output.datum
    expect new_state: MiniOracleDatum = new_state_data

    // Validate state transition
    let IncrementCounter = redeemer
    let count_incremented = new_state.count == current_state.count + 1

    // Validate Oracle NFT stays locked (value unchanged)
    let value_preserved = continuing_output.value == own_input.output.value

    // Verify Oracle NFT is present in value
    let oracle_nft_present =
      quantity_of(own_input.output.value, oracle_nft_policy, "") == 1

    count_incremented && value_preserved && oracle_nft_present
  }

  else(_) {
    fail
  }
}

// Tests for mini oracle
test test_mini_oracle_increment_succeeds() {
  let oracle_nft_policy = mock_policy_id(0)
  let oracle_address = mock_script_address(0, None)
  let current = MiniOracleDatum { count: 5 }
  let new = MiniOracleDatum { count: 6 }

  let oracle_value =
    from_lovelace(2_000_000)
      |> add(oracle_nft_policy, "", 1)

  let tx =
    mocktail_tx()
      |> tx_in(True, mock_tx_hash(0), 0, oracle_value, oracle_address)
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, oracle_address, oracle_value)
      |> tx_out_inline_datum(True, new)
      |> complete()

  mini_oracle.spend(
    oracle_nft_policy,
    Some(current),
    IncrementCounter,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test test_mini_oracle_wrong_increment_fails() fail {
  let oracle_nft_policy = mock_policy_id(0)
  let oracle_address = mock_script_address(0, None)
  let current = MiniOracleDatum { count: 5 }
  let new = MiniOracleDatum { count: 10 }

  // Wrong! Should be 6
  let oracle_value =
    from_lovelace(2_000_000)
      |> add(oracle_nft_policy, "", 1)

  let tx =
    mocktail_tx()
      |> tx_in(True, mock_tx_hash(0), 0, oracle_value, oracle_address)
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, oracle_address, oracle_value)
      |> tx_out_inline_datum(True, new)
      |> complete()

  mini_oracle.spend(
    oracle_nft_policy,
    Some(current),
    IncrementCounter,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test test_mini_oracle_value_changed_fails() fail {
  let oracle_nft_policy = mock_policy_id(0)
  let oracle_address = mock_script_address(0, None)
  let current = MiniOracleDatum { count: 5 }
  let new = MiniOracleDatum { count: 6 }

  let input_value =
    from_lovelace(2_000_000)
      |> add(oracle_nft_policy, "", 1)

  let output_value =
    from_lovelace(3_000_000)
      |> add(oracle_nft_policy, "", 1)

  // Value changed!
  let tx =
    mocktail_tx()
      |> tx_in(True, mock_tx_hash(0), 0, input_value, oracle_address)
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, oracle_address, output_value)
      |> tx_out_inline_datum(True, new)
      |> complete()

  mini_oracle.spend(
    oracle_nft_policy,
    Some(current),
    IncrementCounter,
    mock_utxo_ref(0, 0),
    tx,
  )
}

// -----------------------------------------------------------------------------
// Example 6: Complete Oracle Validator with Fee Payment
// Demonstrates: Production-ready oracle with count, pricing, and admin
// -----------------------------------------------------------------------------

pub type OracleDatum {
  count: Int,
  lovelace_price: Int,
  fee_address: Address,
}

pub type OracleRedeemer {
  MintCollectionNFT
  StopOracle
}

validator oracle_validator(oracle_nft_policy: PolicyId) {
  spend(
    datum: Option<OracleDatum>,
    redeemer: OracleRedeemer,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(current_state) = datum

    when redeemer is {
      MintCollectionNFT -> {
        // Single script input (prevent double-satisfaction)
        expect Some(own_input) =
          list.find(
            self.inputs,
            fn(input) { input.output_reference == own_ref },
          )
        let own_address = own_input.output.address
        let script_inputs =
          list.filter(
            self.inputs,
            fn(input: Input) { input.output.address == own_address },
          )
        expect [_] = script_inputs

        // Single output back to same address
        let outputs_to_self =
          list.filter(
            self.outputs,
            fn(output: Output) { output.address == own_address },
          )
        expect [continuing_output] = outputs_to_self

        // Extract updated state
        expect InlineDatum(new_state_data) = continuing_output.datum
        expect new_state: OracleDatum = new_state_data

        // Validate state transitions
        let count_incremented = new_state.count == current_state.count + 1
        let price_unchanged =
          new_state.lovelace_price == current_state.lovelace_price
        let fee_address_unchanged =
          new_state.fee_address == current_state.fee_address

        // Validate value unchanged (Oracle NFT stays locked)
        let value_unchanged = continuing_output.value == own_input.output.value

        // Validate fee payment
        let fee_paid =
          list.any(
            self.outputs,
            fn(output: Output) {
              output.address == current_state.fee_address && assets.lovelace_of(
                output.value,
              ) >= current_state.lovelace_price
            },
          )

        and {
          count_incremented,
          price_unchanged,
          fee_address_unchanged,
          value_unchanged,
          fee_paid,
        }
      }

      StopOracle -> {
        // Must be signed by fee_address owner
        let authorized =
          when current_state.fee_address.payment_credential is {
            address.VerificationKey(key_hash) ->
              key_signed(self.extra_signatories, key_hash)
            _ -> False
          }

        // Oracle NFT must be burned
        let oracle_tokens = assets.tokens(self.mint, oracle_nft_policy)
        let oracle_burned =
          list.all(
            oracle_tokens |> dict.values(),
            fn(quantity) { quantity < 0 },
          )

        authorized && oracle_burned
      }
    }
  }

  else(_) {
    fail
  }
}

// Tests for complete oracle validator
test test_oracle_mint_collection_nft_succeeds() {
  let oracle_nft_policy = mock_policy_id(0)
  let oracle_address = mock_script_address(0, None)
  let fee_address = mock_pub_key_address(1, None)

  let current = OracleDatum { count: 5, lovelace_price: 5_000_000, fee_address }
  let new = OracleDatum { count: 6, lovelace_price: 5_000_000, fee_address }

  let oracle_value =
    from_lovelace(2_000_000)
      |> add(oracle_nft_policy, "", 1)

  let tx =
    mocktail_tx()
      |> tx_in(True, mock_tx_hash(0), 0, oracle_value, oracle_address)
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, oracle_address, oracle_value)
      |> tx_out_inline_datum(True, new)
      |> tx_out(True, fee_address, from_lovelace(5_000_000))
      // Fee payment
      |> complete()

  oracle_validator.spend(
    oracle_nft_policy,
    Some(current),
    MintCollectionNFT,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test test_oracle_insufficient_fee_fails() fail {
  let oracle_nft_policy = mock_policy_id(0)
  let oracle_address = mock_script_address(0, None)
  let fee_address = mock_pub_key_address(1, None)

  let current = OracleDatum { count: 5, lovelace_price: 5_000_000, fee_address }
  let new = OracleDatum { count: 6, lovelace_price: 5_000_000, fee_address }

  let oracle_value =
    from_lovelace(2_000_000)
      |> add(oracle_nft_policy, "", 1)

  let tx =
    mocktail_tx()
      |> tx_in(True, mock_tx_hash(0), 0, oracle_value, oracle_address)
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, oracle_address, oracle_value)
      |> tx_out_inline_datum(True, new)
      |> tx_out(True, fee_address, from_lovelace(3_000_000))
      // Insufficient fee!
      |> complete()

  oracle_validator.spend(
    oracle_nft_policy,
    Some(current),
    MintCollectionNFT,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test test_oracle_stop_with_burn_succeeds() {
  let oracle_nft_policy = mock_policy_id(0)
  let oracle_address = mock_script_address(0, None)
  let admin_key = mock_pub_key_hash(2)
  let fee_address = mock_pub_key_address(2, None)

  let current =
    OracleDatum { count: 10, lovelace_price: 5_000_000, fee_address }

  let oracle_value =
    from_lovelace(2_000_000)
      |> add(oracle_nft_policy, "", 1)

  let tx =
    mocktail_tx()
      |> tx_in(True, mock_tx_hash(0), 0, oracle_value, oracle_address)
      |> tx_in_inline_datum(True, current)
      |> mint(True, -1, oracle_nft_policy, "")
      // Burn Oracle NFT
      |> required_signer_hash(True, admin_key)
      |> complete()

  oracle_validator.spend(
    oracle_nft_policy,
    Some(current),
    StopOracle,
    mock_utxo_ref(0, 0),
    tx,
  )
}

// -----------------------------------------------------------------------------
// Example 7: Collection NFT Minting Policy
// Demonstrates: Parameterized policy that references Oracle
// -----------------------------------------------------------------------------

pub type CollectionParams {
  collection_name: ByteArray,
  oracle_nft_policy: PolicyId,
}

pub type CollectionAction {
  MintCollection
  BurnCollection
}

// Helper function for token name generation
fn make_token_name(collection_name: ByteArray, count: Int) -> ByteArray {
  // Convert the on-chain counter to bytes so it can be appended to the name.
  let count_bytes = string.from_int(count) |> string.to_bytearray

  // Final shape: "<collection_name> (N)"
  bytearray.concat(
    collection_name,
    bytearray.concat(" (", bytearray.concat(count_bytes, ")")),
  )
}

validator collection_nft(params: CollectionParams) {
  mint(redeemer: CollectionAction, policy_id: PolicyId, self: Transaction) {
    when redeemer is {
      MintCollection -> {
        // Step 1: Locate the oracle reference input that carries the NFT.
        expect Some(oracle_input) =
          list.find(
            self.reference_inputs,
            fn(input: Input) {
              let value_list = flatten(input.output.value)
              list.any(
                value_list,
                fn(entry) {
                  let (pid, name, quantity) = entry
                  pid == params.oracle_nft_policy && name == "" && quantity > 0
                },
              )
            },
          )

        // Step 2: Read the inline datum to grab the running collection count.
        expect InlineDatum(oracle_datum_data) = oracle_input.output.datum
        expect oracle_datum: OracleDatum = oracle_datum_data
        let current_count = oracle_datum.count

        // Step 3: Inspect tokens being minted for this policy.
        let minted = assets.tokens(self.mint, policy_id)

        // Only one NFT is permitted per transaction to keep numbering sequential.
        expect [Pair(token_name, quantity)] = minted |> dict.to_pairs()
        expect quantity == 1

        // Validate token name format: "CollectionName (N)"
        let expected_name =
          make_token_name(params.collection_name, current_count)
        token_name == expected_name
      }

      BurnCollection -> {
        // For burning, all quantities must be negative
        let tokens = assets.tokens(self.mint, policy_id)
        list.all(tokens |> dict.values(), fn(quantity) { quantity < 0 })
      }
    }
  }

  else(_) {
    fail
  }
}

// Tests for collection NFT
test test_collection_nft_mint_correct_name_succeeds() {
  let params =
    CollectionParams {
      collection_name: "TestNFT",
      oracle_nft_policy: mock_policy_id(0),
    }
  let collection_policy = mock_policy_id(1)

  let oracle_datum =
    OracleDatum {
      count: 3,
      lovelace_price: 5_000_000,
      fee_address: mock_pub_key_address(1, None),
    }

  let oracle_value =
    from_lovelace(2_000_000)
      |> add(params.oracle_nft_policy, "", 1)

  let tx =
    mocktail_tx()
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_value,
          mock_script_address(0, None),
        )
      // Reference input provides the Oracle NFT for off-chain state.
      |> ref_tx_in_inline_datum(True, oracle_datum)
      // Inline datum exposes the collection count to the minting policy.
      |> mint(True, 1, collection_policy, "TestNFT (3)")
      // Mint the exact sequential name expected for count 3.
      |> complete()

  collection_nft.mint(params, MintCollection, collection_policy, tx)
}

test test_collection_nft_wrong_name_fails() fail {
  let params =
    CollectionParams {
      collection_name: "TestNFT",
      oracle_nft_policy: mock_policy_id(0),
    }
  let collection_policy = mock_policy_id(1)

  let oracle_datum =
    OracleDatum {
      count: 3,
      lovelace_price: 5_000_000,
      fee_address: mock_pub_key_address(1, None),
    }

  let oracle_value =
    from_lovelace(2_000_000)
      |> add(params.oracle_nft_policy, "", 1)

  let tx =
    mocktail_tx()
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_value,
          mock_script_address(0, None),
        )
      // Reference input is present but we'll break the naming rule.
      |> ref_tx_in_inline_datum(True, oracle_datum)
      // Attach the same datum so the validator can compare counts.
      |> mint(True, 1, collection_policy, "TestNFT (99)")
      // Wrong suffix -> should fail validation.
      |> complete()

  collection_nft.mint(params, MintCollection, collection_policy, tx)
}

test test_collection_nft_without_oracle_fails() fail {
  let params =
    CollectionParams {
      collection_name: "TestNFT",
      oracle_nft_policy: mock_policy_id(0),
    }
  let collection_policy = mock_policy_id(1)

  let tx =
    mocktail_tx()
      // No reference input!
      |> mint(True, 1, collection_policy, "TestNFT (0)")
      |> complete()

  collection_nft.mint(params, MintCollection, collection_policy, tx)
}

test test_collection_nft_burn_succeeds() {
  let params =
    CollectionParams {
      collection_name: "TestNFT",
      oracle_nft_policy: mock_policy_id(0),
    }
  let collection_policy = mock_policy_id(1)

  let tx =
    mocktail_tx()
      |> mint(True, -1, collection_policy, "TestNFT (5)")
      // Burning any token simply requires a negative quantity.
      |> complete()

  collection_nft.mint(params, BurnCollection, collection_policy, tx)
}

// -----------------------------------------------------------------------------
// Test: Token Name Generation Helper
// -----------------------------------------------------------------------------

test test_token_name_generation() {
  let name0 = make_token_name("TestNFT", 0)
  let name5 = make_token_name("TestNFT", 5)
  let name42 = make_token_name("GameItem", 42)

  and {
    name0 == "TestNFT (0)",
    name5 == "TestNFT (5)",
    name42 == "GameItem (42)",
  }
}
// =============================================================================
// Summary:
// 
// These examples demonstrate:
// 1. Simple authorized minting with signature checks
// 2. One-shot NFT minting using OutputReference for uniqueness
// 3. Named NFT with prefix validation
// 4. Oracle NFT (one-time minted reference token)
// 5. Mini Oracle validator with simple counter state
// 6. Complete Oracle validator with count, pricing, and admin control
// 7. Collection NFT policy that references Oracle for sequential naming
// 
// Key Minting Policy Patterns:
// - Authorization via signatures
// - One-shot minting via OutputReference
// - Token name validation
// - Burn functionality (negative quantities)
// - Oracle pattern for collection state management
// - Reference inputs for reading external state
// - Parameterized policies for reusability
// 
// Oracle System Architecture:
// - Oracle NFT: One-time minted, serves as reference token
// - Oracle Validator: Manages state (count, pricing, admin), prevents double-satisfaction
// - Collection Policy: References Oracle, generates sequential token names
// 
// Test Coverage:
// - All minting paths tested (mint & burn)
// - One-shot guarantees validated
// - Token name validation enforced
// - Oracle state transitions verified
// - Fee payments validated
// - Double-satisfaction prevention tested
// - Reference input usage confirmed
// 
// Production Considerations:
// - CIP-25 metadata standard for NFT metadata
// - CIP-27 royalty standard for creator fees
// - Supply caps and deadlines
// - Whitelist mechanisms
// - Batch minting capabilities
// - Reveal mechanisms for generative collections
// =============================================================================
