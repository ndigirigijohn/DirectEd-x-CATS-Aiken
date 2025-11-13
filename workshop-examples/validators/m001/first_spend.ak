// // ============================================================================
// // FIRST SPENDING VALIDATOR - Simple Escrow Contract
// // ============================================================================
// // This is a beginner-friendly spending validator that implements a basic
// // escrow service. An escrow is a financial arrangement where a third party
// // holds funds until certain conditions are met.
// //
// // Real-world scenario: Alice wants to buy a laptop from Bob online. Neither
// // trusts the other. They use this escrow contract:
// // 1. Alice locks her payment (e.g., 500 ADA) in the contract
// // 2. Bob ships the laptop
// // 3. Once Alice confirms receipt, she releases the funds to Bob
// // 4. If there's a dispute, they can cancel and Alice gets a refund
// //
// // This validator ensures funds can only be released under agreed conditions.
// // ============================================================================

// use aiken/transaction.{ScriptContext, Spend}
// use aiken/transaction/credential.{VerificationKey}

// // ----------------------------------------------------------------------------
// // DATUM - Data stored with locked funds
// // ----------------------------------------------------------------------------
// // This defines what information is stored with the escrowed funds
// // Think of it as the "contract terms" written on paper
// type EscrowDatum {
//   // The buyer who locked the funds (Alice in our example)
//   buyer: VerificationKey,
//   // The seller who should receive funds when conditions are met (Bob)
//   seller: VerificationKey,
//   // The amount being held in escrow (in lovelace - 1 ADA = 1,000,000 lovelace)
//   amount: Int,
// }

// // ----------------------------------------------------------------------------
// // REDEEMER - Actions that can be taken
// // ----------------------------------------------------------------------------
// // These are the possible ways to unlock the escrowed funds
// // Like buttons on an ATM - each triggers a different operation
// type EscrowRedeemer {
//   // Buyer confirms receipt and releases funds to seller
//   Release
//   // Both parties agree to cancel - funds return to buyer
//   Cancel
// }

// // ----------------------------------------------------------------------------
// // VALIDATOR - The security logic
// // ----------------------------------------------------------------------------
// // This function decides if a transaction attempting to spend the escrowed
// // funds should be allowed or rejected.
// validator {
//   fn escrow(
//     datum: EscrowDatum,      // The contract terms
//     redeemer: EscrowRedeemer, // The action being attempted
//     context: ScriptContext,   // Full transaction details
//   ) -> Bool {
//     // First, verify this is a spending transaction
//     // (not minting, withdrawing, or certifying)
//     expect Spend(_) = context.purpose
//     // Get the list of public keys that signed this transaction
//     // This is how we verify WHO is trying to perform the action
//     let signatories = context.transaction.extra_signatories
//     // Now check which action is being attempted
//     when redeemer is {
//       // ------------------------------------------------------------------
//       // RELEASE: Buyer releases funds to seller
//       // ------------------------------------------------------------------
//       // Real-world: Alice received her laptop and confirms it's as described
//       // She now wants to release the 500 ADA to Bob
//       Release -> {
//         // Security check: Only the BUYER can release funds
//         // This prevents Bob from releasing funds to himself without Alice's approval
//         // We verify that Alice's public key signed this transaction
//         list.has(signatories, datum.buyer)
//         // In a production contract, we'd also verify that:
//         // 1. The output sends the correct amount to the seller's address
//         // 2. No funds are being stolen or redirected
//         // (Omitted here for simplicity - covered in advanced modules)
//       }
//       // ------------------------------------------------------------------
//       // CANCEL: Return funds to buyer
//       // ------------------------------------------------------------------
//       // Real-world: The laptop never arrived, or there's a major issue
//       // Both parties agree to cancel the deal
//       Cancel -> {
//         // Security check: BOTH buyer AND seller must sign to cancel
//         // This prevents one party from unilaterally canceling
//         // Both Alice and Bob must agree to the cancellation
//         let buyer_signed = list.has(signatories, datum.buyer)
//         let seller_signed = list.has(signatories, datum.seller)
//         // Both conditions must be true (AND logic)
//         buyer_signed && seller_signed
//         // In a production contract, we'd verify the funds return to the buyer
//       }
//     }
//   }
// }

// // ============================================================================
// // HOW THIS WORKS IN PRACTICE
// // ============================================================================
// //
// // STEP 1 - CREATING THE ESCROW:
// // Alice creates a transaction that:
// // - Sends 500 ADA to this validator's address
// // - Attaches a Datum with her public key, Bob's public key, and the amount
// // - This locks the funds in the smart contract
// //
// // STEP 2 - BOB SHIPS THE LAPTOP:
// // Bob sees the funds are locked and ships the laptop to Alice
// // The blockchain guarantees the funds can only be released per contract rules
// //
// // STEP 3 - HAPPY PATH (Release):
// // Alice receives the laptop and is satisfied
// // She creates a transaction that:
// // - Spends the UTxO holding the escrowed funds
// // - Uses "Release" as the Redeemer
// // - Signs the transaction with her private key
// // - Sends the 500 ADA output to Bob's address
// // The validator checks: Is this signed by the buyer? YES → APPROVED
// //
// // STEP 4 - DISPUTE PATH (Cancel):
// // The laptop never arrives or is damaged
// // Alice and Bob both agree to cancel
// // They create a transaction that:
// // - Spends the UTxO holding the escrowed funds
// // - Uses "Cancel" as the Redeemer
// // - Is signed by BOTH Alice and Bob
// // - Returns the 500 ADA to Alice
// // The validator checks: Signed by both parties? YES → APPROVED
// //
// // ============================================================================
// // SECURITY FEATURES
// // ============================================================================
// //
// // 1. NO UNILATERAL RELEASE: Only the buyer can approve the release.
// //    The seller cannot release funds to himself.
// //
// // 2. MUTUAL CANCELLATION: Both parties must agree to cancel. One party
// //    cannot unilaterally get a refund or keep funds locked forever.
// //
// // 3. IMMUTABLE TERMS: Once the Datum is set, the terms cannot be changed.
// //    The buyer, seller, and amount are fixed.
// //
// // 4. TRANSPARENT: Anyone can see the contract code and verify how it works.
// //    No hidden backdoors or surprise clauses.
// //
// // ============================================================================
// // LIMITATIONS & IMPROVEMENTS
// // ============================================================================
// //
// // This is a simplified educational example. A production escrow would add:
// //
// // 1. DEADLINE: A time limit for the buyer to confirm receipt, after which
// //    the seller can claim funds automatically.
// //
// // 2. ARBITER: A third party who can resolve disputes if buyer and seller
// //    cannot agree to cancel.
// //
// // 3. OUTPUT VALIDATION: Verify outputs actually send funds to correct addresses
// //    with correct amounts.
// //
// // 4. PARTIAL RELEASES: Allow the buyer to release only part of the funds
// //    (useful for milestone-based payments).
// //
// // 5. MULTIPLE ITEMS: Support escrow for multiple items/services in one contract.
// //
// // These improvements will be covered in advanced modules.
// // ============================================================================
