// // ============================================================================
// // FIRST MINTING POLICY WITH TESTS - Simple NFT Collection Minter
// // ============================================================================
// // This file contains the same NFT minting policy as first_mint.ak, but now
// // includes a comprehensive test suite. Testing minting policies is critical
// // because once tokens are minted, they exist permanently on the blockchain.
// // Bugs in minting logic could allow unlimited token creation or prevent
// // legitimate minting.
// //
// // Real-world importance: Many NFT projects have suffered from exploits where
// // attackers minted more tokens than intended, devaluing entire collections.
// // Proper testing prevents such disasters.
// // ============================================================================

// use aiken/transaction.{ScriptContext, Mint, Transaction, Output, InlineDatum}
// use aiken/transaction/credential.{VerificationKey, Address, ScriptCredential}
// use aiken/transaction/value.{PolicyId}
// use aiken/interval

// // ----------------------------------------------------------------------------
// // REDEEMER - Minting action parameters
// // ----------------------------------------------------------------------------
// type MintRedeemer {
//   token_name: ByteArray,
//   quantity: Int,
// }

// // ----------------------------------------------------------------------------
// // VALIDATOR - Minting policy logic
// // ----------------------------------------------------------------------------
// validator {
//   fn nft_collection(
//     redeemer: MintRedeemer,
//     context: ScriptContext,
//   ) -> Bool {
//     expect Mint(policy_id) = context.purpose
//     let tx = context.transaction
//     let signatories = tx.extra_signatories
//     // The authorized minter's public key
//     let authorized_minter: VerificationKey = 
//       VerificationKey(#"abcd1234")
//     let max_supply = 100
//     let token_name = redeemer.token_name
//     let mint_quantity = redeemer.quantity
//     // Check authorization
//     let authorized = list.has(signatories, authorized_minter)
//     // Validate quantity (must be 1 for minting, -1 for burning)
//     let valid_quantity = if mint_quantity > 0 {
//       mint_quantity == 1
//     } else if mint_quantity < 0 {
//       mint_quantity == -1
//     } else {
//       False
//     }
//     // Check supply cap
//     let minted_value = value.from_minted_value(tx.mint)
//     let tokens_in_tx = value.quantity_of(minted_value, policy_id, token_name)
//     let within_supply_cap = tokens_in_tx <= max_supply
//     // Validate token name (must be at least 1 byte)
//     let valid_token_name = builtin.length_of_bytearray(token_name) >= 1
//     // All conditions must be true
//     authorized && valid_quantity && within_supply_cap && valid_token_name
//   }
// }

// // ============================================================================
// // TEST SUITE
// // ============================================================================

// // ----------------------------------------------------------------------------
// // HELPER FUNCTIONS FOR TESTS
// // ----------------------------------------------------------------------------

// // The authorized minter (Sarah the artist)
// fn authorized_minter() -> VerificationKey {
//   VerificationKey(#"abcd1234")
// }

// // An unauthorized user trying to mint
// fn unauthorized_user() -> VerificationKey {
//   VerificationKey(#"deadbeef")
// }

// // Sample policy ID for the NFT collection
// fn sample_policy_id() -> PolicyId {
//   #"policy123"
// }

// // Create a test context for minting operations
// fn sample_mint_context(
//   policy_id: PolicyId,
//   token_name: ByteArray,
//   quantity: Int,
//   signatories: List<VerificationKey>,
// ) -> ScriptContext {
//   // Create the minting value for this transaction
//   let mint_value = 
//     value.from_lovelace(0)
//     |> value.add(policy_id, token_name, quantity)
//   let output_address = Address {
//     payment_credential: ScriptCredential(#"script123"),
//     stake_credential: None,
//   }
//   let output = Output {
//     address: output_address,
//     value: mint_value,
//     datum: InlineDatum(Void),
//     reference_script: None,
//   }
//   ScriptContext {
//     purpose: Mint(policy_id),
//     transaction: Transaction {
//       inputs: [],
//       reference_inputs: [],
//       outputs: [output],
//       fee: value.from_lovelace(170_000),
//       mint: value.to_minted_value(mint_value),
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(0, 100),
//       extra_signatories: signatories,
//       redeemers: [],
//       datums: [],
//       id: #"tx123",
//     },
//   }
// }

// // ----------------------------------------------------------------------------
// // TEST 1: Authorized minter can mint valid NFT
// // ----------------------------------------------------------------------------
// // This tests the happy path where Sarah (authorized minter) mints a single
// // NFT with a valid token name.
// test authorized_minter_can_mint() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"4172745069656365303031"  // "ArtPiece001" in hex
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: 1,
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     1,
//     [authorized_minter()],  // Sarah signs
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should succeed because:
//   // 1. Signed by authorized minter
//   // 2. Quantity is exactly 1 (valid for NFT)
//   // 3. Token name is valid (non-empty)
//   // 4. Within supply cap
//   result == True
// }

// // ----------------------------------------------------------------------------
// // TEST 2: Unauthorized user cannot mint
// // ----------------------------------------------------------------------------
// // This tests that a random person cannot mint NFTs in Sarah's collection.
// // This is a critical security test.
// test unauthorized_user_cannot_mint() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"4172745069656365303031"
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: 1,
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     1,
//     [unauthorized_user()],  // Random person signs (not Sarah)
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should fail because:
//   // 1. NOT signed by authorized minter
//   // 2. Even though quantity and token name are valid
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 3: Cannot mint quantity greater than 1
// // ----------------------------------------------------------------------------
// // This tests that we cannot mint multiple copies of an NFT at once.
// // NFTs must be unique (quantity = 1).
// test cannot_mint_multiple_copies() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"4172745069656365303031"
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: 5,  // Trying to mint 5 copies!
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     5,
//     [authorized_minter()],
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should fail because:
//   // 1. Quantity is 5, not 1
//   // 2. NFTs must be minted one at a time
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 4: Cannot mint with quantity of 0
// // ----------------------------------------------------------------------------
// // This tests that minting zero tokens is invalid (doesn't make sense).
// test cannot_mint_zero() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"4172745069656365303031"
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: 0,  // Zero quantity
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     0,
//     [authorized_minter()],
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should fail because:
//   // 1. Quantity is 0 (invalid)
//   // 2. Must be 1 (mint) or -1 (burn)
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 5: Authorized minter can burn tokens
// // ----------------------------------------------------------------------------
// // This tests that Sarah can burn (destroy) an NFT if needed (e.g., to fix
// // a mistake or remove a defective NFT).
// test authorized_minter_can_burn() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"4172745069656365303031"
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: -1,  // Negative = burn
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     -1,
//     [authorized_minter()],
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should succeed because:
//   // 1. Signed by authorized minter
//   // 2. Quantity is exactly -1 (valid for burning)
//   // 3. Token name is valid
//   result == True
// }

// // ----------------------------------------------------------------------------
// // TEST 6: Cannot burn multiple tokens at once
// // ----------------------------------------------------------------------------
// // This tests that burning must be done one token at a time (quantity = -1).
// test cannot_burn_multiple() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"4172745069656365303031"
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: -5,  // Trying to burn 5 at once
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     -5,
//     [authorized_minter()],
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should fail because:
//   // 1. Quantity is -5, not -1
//   // 2. Must burn one at a time
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 7: Unauthorized user cannot burn
// // ----------------------------------------------------------------------------
// // This tests that random users cannot burn NFTs from the collection.
// // Only the authorized minter can burn.
// test unauthorized_user_cannot_burn() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"4172745069656365303031"
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: -1,
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     -1,
//     [unauthorized_user()],  // Not Sarah
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should fail because:
//   // 1. NOT signed by authorized minter
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 8: Cannot mint with empty token name
// // ----------------------------------------------------------------------------
// // This tests that token names must be at least 1 byte long.
// // Empty token names are not allowed.
// test cannot_mint_empty_token_name() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #""  // Empty ByteArray
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: 1,
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     1,
//     [authorized_minter()],
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should fail because:
//   // 1. Token name is empty (length = 0)
//   // 2. Minimum length is 1 byte
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 9: Can mint with single-byte token name
// // ----------------------------------------------------------------------------
// // This tests the boundary condition where token name is exactly 1 byte.
// // This should be valid (minimum allowed length).
// test can_mint_single_byte_token_name() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"41"  // Just "A" in hex (1 byte)
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: 1,
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     1,
//     [authorized_minter()],
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should succeed because:
//   // 1. Token name is 1 byte (minimum valid length)
//   // 2. All other conditions are met
//   result == True
// }

// // ----------------------------------------------------------------------------
// // TEST 10: Can mint with long token name
// // ----------------------------------------------------------------------------
// // This tests that longer token names (within reasonable limits) work fine.
// test can_mint_long_token_name() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   // "ArtPiece001_Limited_Edition_Collection_2024" in hex (long but valid)
//   let token_name = #"41727450696563653030315f4c696d697465645f45646974696f6e5f436f6c6c656374696f6e5f32303234"
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: 1,
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     1,
//     [authorized_minter()],
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should succeed because:
//   // 1. Token name is valid (> 1 byte)
//   // 2. All other conditions are met
//   result == True
// }

// // ----------------------------------------------------------------------------
// // TEST 11: Minting with no signatures fails
// // ----------------------------------------------------------------------------
// // This tests that transactions with no signatures at all are rejected.
// test minting_with_no_signatures_fails() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"4172745069656365303031"
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: 1,
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     1,
//     [],  // No signatures!
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should fail because:
//   // 1. No signatures provided
//   // 2. Authorized minter must sign
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 12: Extra signatures don't break minting
// // ----------------------------------------------------------------------------
// // This tests that having additional signatures (beyond the authorized minter)
// // doesn't prevent valid minting operations.
// test extra_signatures_dont_break_minting() {
//   // SETUP
//   let policy_id = sample_policy_id()
//   let token_name = #"4172745069656365303031"
//   let redeemer = MintRedeemer {
//     token_name: token_name,
//     quantity: 1,
//   }
//   let context = sample_mint_context(
//     policy_id,
//     token_name,
//     1,
//     [authorized_minter(), unauthorized_user()],  // Multiple signatures
//   )
//   // ACTION
//   let result = nft_collection(redeemer, context)
//   // ASSERT
//   // Should succeed because:
//   // 1. Authorized minter signed (that's what matters)
//   // 2. Extra signatures are allowed
//   result == True
// }

// // ============================================================================
// // RUNNING THE TESTS
// // ============================================================================
// //
// // To run these tests, use the Aiken CLI:
// //
// //   aiken check
// //
// // Example output:
// //   ✓ authorized_minter_can_mint
// //   ✓ unauthorized_user_cannot_mint
// //   ✓ cannot_mint_multiple_copies
// //   ✓ cannot_mint_zero
// //   ✓ authorized_minter_can_burn
// //   ✓ cannot_burn_multiple
// //   ✓ unauthorized_user_cannot_burn
// //   ✓ cannot_mint_empty_token_name
// //   ✓ can_mint_single_byte_token_name
// //   ✓ can_mint_long_token_name
// //   ✓ minting_with_no_signatures_fails
// //   ✓ extra_signatures_dont_break_minting
// //
// //   12 tests passed, 0 failed
// //
// // ============================================================================
// // TEST COVERAGE ANALYSIS
// // ============================================================================
// //
// // Our test suite covers:
// //
// // ✓ Happy path minting (authorized user mints 1 NFT)
// // ✓ Happy path burning (authorized user burns 1 NFT)
// // ✓ Authorization checks (unauthorized users rejected)
// // ✓ Quantity validation (must be 1 or -1)
// // ✓ Token name validation (empty vs valid names)
// // ✓ Boundary conditions (minimum/maximum token name lengths)
// // ✓ Edge cases (no signatures, extra signatures)
// //
// // What's NOT covered (would add in production):
// // ✗ Supply cap enforcement across multiple transactions
// // ✗ Duplicate token name prevention
// // ✗ Time-based restrictions (minting windows)
// // ✗ Integration with metadata standards (CIP-25)
// // ✗ Royalty information (CIP-27)
// //
// // ============================================================================
// // BEST PRACTICES FOR MINTING POLICY TESTS
// // ============================================================================
// //
// // 1. TEST AUTHORIZATION THOROUGHLY: Minting policies are often exploited
// //    through authorization bypasses. Test every combination of authorized
// //    and unauthorized users.
// //
// // 2. TEST QUANTITY BOUNDS: Test positive quantities (minting), negative
// //    quantities (burning), zero, and out-of-bounds values.
// //
// // 3. TEST TOKEN NAME EDGE CASES: Empty strings, single characters, maximum
// //    length names, special characters, etc.
// //
// // 4. TEST SIGNATURE VARIATIONS: No signatures, correct signatures, incorrect
// //    signatures, multiple signatures.
// //
// // 5. THINK LIKE AN ATTACKER: What would you try if you wanted to exploit
// //    this minting policy? Test those attack vectors.
// //
// // 6. TEST REALISTIC SCENARIOS: Use actual hex-encoded token names, realistic
// //    policy IDs, and proper signature formats.
// //
// // 7. VERIFY BOTH MINTING AND BURNING: If your policy allows burning, test
// //    those paths just as thoroughly as minting.
// //
// // ============================================================================
// // COMMON MINTING EXPLOITS TO TEST AGAINST
// // ============================================================================
// //
// // 1. UNAUTHORIZED MINTING: Attacker tries to mint without authorization
// //    → Our Test 2 covers this
// //
// // 2. OVER-MINTING: Attacker tries to mint more than the supply cap
// //    → Our Test 3 partially covers this (needs improvement)
// //
// // 3. DUPLICATE MINTING: Attacker tries to mint the same token name twice
// //    → Not covered in this simplified version (needs tracking)
// //
// // 4. ZERO/NEGATIVE MINTING: Attacker tries invalid quantities
// //    → Our Tests 4, 6 cover this
// //
// // 5. SIGNATURE FORGERY: Attacker tries to forge authorization
// //    → Handled by Cardano's cryptography, but we test signature checks
// //
// // 6. FRONT-RUNNING: Attacker sees a pending mint and tries to mint first
// //    → Not testable at validator level (handled by blockchain ordering)
// //
// // ============================================================================
