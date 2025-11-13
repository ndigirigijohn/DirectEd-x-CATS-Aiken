// ============================================================================
// VALIDATOR STRUCTURE - Educational Example
// ============================================================================
// This file demonstrates the anatomy of Aiken validators with both
// spending and minting examples.
// ============================================================================

use cardano/transaction.{OutputReference, Transaction}

// ----------------------------------------------------------------------------
// SPENDING VALIDATOR EXAMPLE
// ----------------------------------------------------------------------------

// Custom types for the spending validator
pub type VendingMachineDatum {
  owner: ByteArray,
  price_per_item: Int,
  items_remaining: Int,
}

pub type VendingMachineRedeemer {
  Purchase { quantity: Int }
  Restock { additional_items: Int }
  Withdraw
}

// Spending validator: controls how UTxOs are spent
// Parameters: datum, redeemer, input reference, transaction context
validator vending_machine {
  spend(
    datum_opt: Option<VendingMachineDatum>,
    redeemer: VendingMachineRedeemer,
    _input: OutputReference,
    _tx: Transaction,
  ) {
    // Extract datum from Option type
    expect Some(datum) = datum_opt
    // Pattern match on redeemer to handle different actions
    when redeemer is {
      Purchase { quantity } ->
        // Check if enough items available
        quantity <= datum.items_remaining
      Restock { additional_items } ->
        // Items to add must be positive
        additional_items > 0
      Withdraw ->
        // Allow withdrawal
        True
    }
  }

  // Catch any other purpose (minting, staking, etc.)
  else(_) {
    fail
  }
}

// ----------------------------------------------------------------------------
// MINTING VALIDATOR EXAMPLE
// ----------------------------------------------------------------------------

// Custom type for minting redeemer
pub type MintRedeemer {
  TokenName { name: ByteArray }
}

// Minting validator: controls when tokens can be minted/burned
// Parameters: redeemer, policy_id, transaction context
validator nft_policy {
  mint(redeemer: MintRedeemer, _policy_id: ByteArray, _tx: Transaction) {
    // Extract token name from redeemer
    let TokenName { name } = redeemer
    // Token name must not be empty
    name != ""
  }

  // Catch any other purpose
  else(_) {
    fail
  }
}
// ============================================================================
// KEY POINTS
// ============================================================================
// 1. Validators must return Bool (True/False)
// 2. Spending validators have 4 parameters: datum, redeemer, input, tx
// 3. Minting validators have 3 parameters: redeemer, policy_id, tx
// 4. Use 'expect' to safely extract from Option types
// 5. Use 'when...is' for pattern matching on custom types
// 6. Always include 'else(_) { fail }' clause
// 7. Prefix unused parameters with underscore (_)
// 8. Custom types used in validators must be marked 'pub' (public)
// 9. Use 'let' for single-clause pattern matching instead of 'when'
// ============================================================================
