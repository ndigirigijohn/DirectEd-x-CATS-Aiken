// // ============================================================================
// // FIRST SPENDING VALIDATOR WITH TESTS - Simple Escrow Contract
// // ============================================================================
// // This file contains the same escrow validator as first_spend.ak, but now
// // includes a comprehensive test suite. Testing is crucial for smart contracts
// // because bugs can lead to loss of funds. Unlike traditional software where
// // you can patch bugs after deployment, blockchain smart contracts are immutable.
// //
// // Real-world importance: In 2016, the Ethereum DAO hack resulted in $60M loss
// // due to a bug in the smart contract. Thorough testing prevents such disasters.
// // ============================================================================

// use aiken/transaction.{ScriptContext, Spend, Transaction, InlineDatum, Output}
// use aiken/transaction/credential.{VerificationKey, Address, ScriptCredential}
// use aiken/transaction/value
// use aiken/interval.{Finite}

// // ----------------------------------------------------------------------------
// // DATUM - Data stored with locked funds
// // ----------------------------------------------------------------------------
// type EscrowDatum {
//   buyer: VerificationKey,
//   seller: VerificationKey,
//   amount: Int,
// }

// // ----------------------------------------------------------------------------
// // REDEEMER - Actions that can be taken
// // ----------------------------------------------------------------------------
// type EscrowRedeemer {
//   Release
//   Cancel
// }

// // ----------------------------------------------------------------------------
// // VALIDATOR - The security logic
// // ----------------------------------------------------------------------------
// validator {
//   fn escrow(
//     datum: EscrowDatum,
//     redeemer: EscrowRedeemer,
//     context: ScriptContext,
//   ) -> Bool {
//     expect Spend(_) = context.purpose
//     let signatories = context.transaction.extra_signatories
//     when redeemer is {
//       Release -> {
//         list.has(signatories, datum.buyer)
//       }
//       Cancel -> {
//         let buyer_signed = list.has(signatories, datum.buyer)
//         let seller_signed = list.has(signatories, datum.seller)
//         buyer_signed && seller_signed
//       }
//     }
//   }
// }

// // ============================================================================
// // TEST SUITE
// // ============================================================================
// // Aiken uses the 'test' keyword to define tests. Tests run during compilation
// // and help verify your validator logic works as expected before deployment.
// //
// // Test structure:
// // test test_name() {
// //   // Setup: Create test data
// //   // Action: Call validator with test data
// //   // Assert: Verify the result is correct
// // }
// //
// // Tests either pass (return True) or fail (return False or error)
// // ============================================================================

// // ----------------------------------------------------------------------------
// // HELPER FUNCTIONS FOR TESTS
// // ----------------------------------------------------------------------------
// // These functions create test data to make our tests more readable

// // Create a sample buyer public key for testing
// fn sample_buyer() -> VerificationKey {
//   VerificationKey(#"aa")  // Shortened hex for testing
// }

// // Create a sample seller public key for testing
// fn sample_seller() -> VerificationKey {
//   VerificationKey(#"bb")  // Different from buyer
// }

// // Create a sample third party (unauthorized user)
// fn sample_intruder() -> VerificationKey {
//   VerificationKey(#"cc")  // Not buyer or seller
// }

// // Create a standard test datum with 1000 ADA (1,000,000,000 lovelace)
// fn sample_datum() -> EscrowDatum {
//   EscrowDatum {
//     buyer: sample_buyer(),
//     seller: sample_seller(),
//     amount: 1_000_000_000,  // 1000 ADA in lovelace
//   }
// }

// // Create a minimal valid transaction context for testing
// // In real usage, this would be provided by the blockchain
// fn sample_context(signatories: List<VerificationKey>) -> ScriptContext {
//   let output_address = Address {
//     payment_credential: ScriptCredential(#"dd"),
//     stake_credential: None,
//   }
//   let output = Output {
//     address: output_address,
//     value: value.from_lovelace(1_000_000_000),
//     datum: InlineDatum(Void),
//     reference_script: None,
//   }
//   ScriptContext {
//     purpose: Spend(#"ee"),
//     transaction: Transaction {
//       inputs: [],
//       reference_inputs: [],
//       outputs: [output],
//       fee: value.from_lovelace(170_000),  // Typical fee
//       mint: value.zero(),
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(0, 100),
//       extra_signatories: signatories,
//       redeemers: [],
//       datums: [],
//       id: #"ff",
//     },
//   }
// }

// // ----------------------------------------------------------------------------
// // TEST 1: Buyer can successfully release funds
// // ----------------------------------------------------------------------------
// // This tests the happy path where the buyer (Alice) releases funds to the
// // seller (Bob) after receiving the goods/services.
// test buyer_can_release() {
//   // SETUP
//   let datum = sample_datum()
//   let redeemer = Release
//   let context = sample_context([sample_buyer()])  // Only buyer signs
//   // ACTION
//   let result = escrow(datum, redeemer, context)
//   // ASSERT
//   // The validator should return True because:
//   // 1. The redeemer is Release
//   // 2. The transaction is signed by the buyer
//   result == True
// }

// // ----------------------------------------------------------------------------
// // TEST 2: Seller alone cannot release funds
// // ----------------------------------------------------------------------------
// // This tests that the seller (Bob) cannot release funds to himself without
// // the buyer's (Alice's) approval. This is a critical security check.
// test seller_cannot_release_alone() {
//   // SETUP
//   let datum = sample_datum()
//   let redeemer = Release
//   let context = sample_context([sample_seller()])  // Only seller signs
//   // ACTION
//   let result = escrow(datum, redeemer, context)
//   // ASSERT
//   // The validator should return False because:
//   // 1. The redeemer is Release
//   // 2. But the transaction is NOT signed by the buyer
//   // 3. Only the seller signed, which is not authorized for Release
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 3: Unauthorized party cannot release funds
// // ----------------------------------------------------------------------------
// // This tests that a random third party (not buyer or seller) cannot release
// // the escrowed funds. This prevents theft.
// test intruder_cannot_release() {
//   // SETUP
//   let datum = sample_datum()
//   let redeemer = Release
//   let context = sample_context([sample_intruder()])  // Random person signs
//   // ACTION
//   let result = escrow(datum, redeemer, context)
//   // ASSERT
//   // The validator should return False because:
//   // 1. The transaction is not signed by the buyer
//   // 2. Only an unauthorized party signed
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 4: Both parties can cancel successfully
// // ----------------------------------------------------------------------------
// // This tests the cancellation path where both buyer and seller agree to
// // cancel the escrow and return funds to the buyer.
// test both_parties_can_cancel() {
//   // SETUP
//   let datum = sample_datum()
//   let redeemer = Cancel
//   // Both buyer and seller sign the transaction
//   let context = sample_context([sample_buyer(), sample_seller()])
//   // ACTION
//   let result = escrow(datum, redeemer, context)
//   // ASSERT
//   // The validator should return True because:
//   // 1. The redeemer is Cancel
//   // 2. Both required parties (buyer AND seller) signed
//   result == True
// }

// // ----------------------------------------------------------------------------
// // TEST 5: Buyer alone cannot cancel
// // ----------------------------------------------------------------------------
// // This tests that the buyer cannot unilaterally cancel and get a refund.
// // Both parties must agree to a cancellation.
// test buyer_alone_cannot_cancel() {
//   // SETUP
//   let datum = sample_datum()
//   let redeemer = Cancel
//   let context = sample_context([sample_buyer()])  // Only buyer signs
//   // ACTION
//   let result = escrow(datum, redeemer, context)
//   // ASSERT
//   // The validator should return False because:
//   // 1. The redeemer is Cancel
//   // 2. Only the buyer signed
//   // 3. Cancel requires BOTH buyer AND seller signatures
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 6: Seller alone cannot cancel
// // ----------------------------------------------------------------------------
// // This tests that the seller cannot unilaterally cancel the escrow.
// // This prevents the seller from canceling after shipping goods.
// test seller_alone_cannot_cancel() {
//   // SETUP
//   let datum = sample_datum()
//   let redeemer = Cancel
//   let context = sample_context([sample_seller()])  // Only seller signs
//   // ACTION
//   let result = escrow(datum, redeemer, context)
//   // ASSERT
//   // The validator should return False because:
//   // 1. The redeemer is Cancel
//   // 2. Only the seller signed
//   // 3. Cancel requires BOTH buyer AND seller signatures
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 7: Intruder cannot cancel
// // ----------------------------------------------------------------------------
// // This tests that an unauthorized third party cannot cancel the escrow
// // even if they somehow know about it.
// test intruder_cannot_cancel() {
//   // SETUP
//   let datum = sample_datum()
//   let redeemer = Cancel
//   let context = sample_context([sample_intruder()])
//   // ACTION
//   let result = escrow(datum, redeemer, context)
//   // ASSERT
//   // The validator should return False because:
//   // 1. Neither buyer nor seller signed
//   // 2. Cancel requires both authorized parties
//   result == False
// }

// // ----------------------------------------------------------------------------
// // TEST 8: Multiple signatures work correctly for release
// // ----------------------------------------------------------------------------
// // This tests that having extra signatures doesn't break the Release logic.
// // If both buyer and seller sign, but redeemer is Release, it should still work.
// test release_works_with_extra_signatures() {
//   // SETUP
//   let datum = sample_datum()
//   let redeemer = Release
//   // Both parties sign (buyer signature is sufficient, seller is extra)
//   let context = sample_context([sample_buyer(), sample_seller()])
//   // ACTION
//   let result = escrow(datum, redeemer, context)
//   // ASSERT
//   // The validator should return True because:
//   // 1. The redeemer is Release
//   // 2. The buyer signed (which is the requirement)
//   // 3. Extra signatures don't invalidate the transaction
//   result == True
// }

// // ----------------------------------------------------------------------------
// // TEST 9: Empty signatures fail for both operations
// // ----------------------------------------------------------------------------
// // This tests that transactions with no signatures at all are rejected.
// test no_signatures_fails() {
//   // SETUP
//   let datum = sample_datum()
//   let redeemer_release = Release
//   let redeemer_cancel = Cancel
//   let context = sample_context([])  // No signatures!
//   // ACTION & ASSERT for Release
//   let release_result = escrow(datum, redeemer_release, context)
//   let cancel_result = escrow(datum, redeemer_cancel, context)
//   // Both should fail
//   release_result == False && cancel_result == False
// }

// // ============================================================================
// // RUNNING THE TESTS
// // ============================================================================
// //
// // To run these tests, use the Aiken CLI:
// //
// //   aiken check
// //
// // This command will:
// // 1. Compile your validator code
// // 2. Run all test functions
// // 3. Report which tests passed and which failed
// // 4. Show any error messages for failed tests
// //
// // Example output:
// //   ✓ buyer_can_release
// //   ✓ seller_cannot_release_alone
// //   ✓ intruder_cannot_release
// //   ✓ both_parties_can_cancel
// //   ✓ buyer_alone_cannot_cancel
// //   ✓ seller_alone_cannot_cancel
// //   ✓ intruder_cannot_cancel
// //   ✓ release_works_with_extra_signatures
// //   ✓ no_signatures_fails
// //
// //   9 tests passed, 0 failed
// //
// // ============================================================================
// // TEST COVERAGE ANALYSIS
// // ============================================================================
// //
// // Our test suite covers:
// //
// // ✓ Happy paths (expected successful operations)
// // ✓ Unauthorized access attempts (security tests)
// // ✓ Single-party authorization violations
// // ✓ Multi-party authorization requirements
// // ✓ Edge cases (no signatures, extra signatures)
// //
// // What's NOT covered (would add in production):
// // ✗ Output validation (checking funds go to correct addresses)
// // ✗ Amount validation (checking correct amounts are transferred)
// // ✗ Time-based tests (deadlines, expiration)
// // ✗ Multiple concurrent escrows
// // ✗ Datum validation (malformed or invalid data)
// //
// // ============================================================================
// // BEST PRACTICES FOR TESTING
// // ============================================================================
// //
// // 1. TEST BOTH SUCCESS AND FAILURE: Don't just test that valid transactions
// //    work - test that invalid transactions are properly rejected.
// //
// // 2. TEST BOUNDARY CONDITIONS: Test edge cases like empty lists, zero values,
// //    maximum values, etc.
// //
// // 3. TEST SECURITY PROPERTIES: Specifically test that unauthorized actions
// //    are rejected. Think like an attacker.
// //
// // 4. USE DESCRIPTIVE TEST NAMES: Test names should clearly describe what
// //    they're testing (e.g., "buyer_can_release" not "test1").
// //
// // 5. KEEP TESTS INDEPENDENT: Each test should be self-contained and not
// //    depend on other tests running first.
// //
// // 6. TEST REALISTIC SCENARIOS: Use realistic values (actual ADA amounts,
// //    proper key formats, etc.) not just placeholder data.
// //
// // 7. DOCUMENT YOUR TESTS: Add comments explaining what each test validates
// //    and why it's important.
// //
// // ============================================================================
