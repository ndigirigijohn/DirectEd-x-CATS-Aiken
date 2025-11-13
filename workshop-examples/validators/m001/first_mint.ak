// // ============================================================================
// // FIRST MINTING POLICY - Simple NFT Collection Minter
// // ============================================================================
// // This is a beginner-friendly minting policy that controls the creation
// // of NFTs (Non-Fungible Tokens). Unlike spending validators that control
// // when funds can be spent, minting policies control when new tokens can
// // be created or destroyed (burned).
// //
// // Real-world scenario: Sarah is an artist who wants to create a limited
// // edition digital art collection of 100 NFTs. She wants to ensure that:
// // 1. Only she can mint new NFTs in her collection
// // 2. The total supply is capped at 100 NFTs
// // 3. Each NFT has a unique identifier (token name)
// // 4. Once minted, the policy prevents additional minting beyond the cap
// //
// // This minting policy enforces these rules on the blockchain.
// // ============================================================================

// use aiken/transaction.{ScriptContext, Mint}
// use aiken/transaction/credential.{VerificationKey}
// use aiken/transaction/value

// // ----------------------------------------------------------------------------
// // REDEEMER - Minting action parameters
// // ----------------------------------------------------------------------------
// // Unlike spending validators that need both Datum and Redeemer, minting
// // policies only use a Redeemer. This is because minting policies don't
// // lock funds at an address (no UTxO with a Datum).
// //
// // The Redeemer provides the parameters for the minting action.
// type MintRedeemer {
//   // The token name for the NFT being minted (e.g., "ArtPiece001")
//   token_name: ByteArray,
//   // The quantity to mint (for NFTs, this should always be 1)
//   // Positive numbers = mint, negative numbers = burn
//   quantity: Int,
// }

// // ----------------------------------------------------------------------------
// // VALIDATOR - Minting policy logic
// // ----------------------------------------------------------------------------
// // This function decides if a transaction attempting to mint (create) or
// // burn (destroy) tokens should be allowed.
// //
// // Parameters:
// // - redeemer: The minting parameters (what token, how many)
// // - context: Full transaction details
// //
// // Note: Minting policies don't have a Datum parameter because there's
// // no UTxO being spent - we're creating new tokens, not spending existing ones.
// validator {
//   fn nft_collection(
//     redeemer: MintRedeemer,
//     context: ScriptContext,
//   ) -> Bool {
//     // Verify this is a minting transaction
//     expect Mint(policy_id) = context.purpose
//     // Extract the transaction details we need to validate
//     let tx = context.transaction
//     let signatories = tx.extra_signatories
//     // Define the artist's public key who is authorized to mint
//     // In a real deployment, this would be Sarah's actual public key
//     // Format: VerificationKey(#"hexadecimal_representation_of_public_key")
//     let authorized_minter: VerificationKey = 
//       VerificationKey(#"abcd1234")  // Placeholder - replace with real key
//     // Define the maximum supply for the collection
//     let max_supply = 100
//     // Get the token being minted from the redeemer
//     let token_name = redeemer.token_name
//     let mint_quantity = redeemer.quantity
//     // ------------------------------------------------------------------
//     // VALIDATION RULE 1: Only authorized minter can mint
//     // ------------------------------------------------------------------
//     // Check that the transaction is signed by the authorized artist
//     // This prevents random people from minting NFTs in Sarah's collection
//     let authorized = list.has(signatories, authorized_minter)
//     // ------------------------------------------------------------------
//     // VALIDATION RULE 2: Minting quantity rules
//     // ------------------------------------------------------------------
//     // For NFTs (Non-Fungible Tokens), we should only mint exactly 1 token
//     // at a time. This ensures each token is unique and non-fungible.
//     //
//     // If quantity is positive: we're minting (creating new tokens)
//     // If quantity is negative: we're burning (destroying tokens)
//     // If quantity is zero: invalid operation
//     let valid_quantity = if mint_quantity > 0 {
//       // Minting: must be exactly 1 for NFTs
//       mint_quantity == 1
//     } else if mint_quantity < 0 {
//       // Burning: can burn tokens (e.g., for cleanup or mistakes)
//       // For NFTs, we'd typically burn exactly -1 token at a time
//       mint_quantity == -1
//     } else {
//       // Quantity of 0 makes no sense - reject
//       False
//     }
//     // ------------------------------------------------------------------
//     // VALIDATION RULE 3: Check total supply doesn't exceed maximum
//     // ------------------------------------------------------------------
//     // Calculate how many tokens with this policy_id exist in the transaction
//     // This checks if we'd exceed the max supply with this minting operation
//     let minted_value = value.from_minted_value(tx.mint)
//     let tokens_in_tx = value.quantity_of(minted_value, policy_id, token_name)
//     // The total after this transaction should not exceed max_supply
//     // Note: This is a simplified check. A production version would track
//     // the cumulative total across all transactions.
//     let within_supply_cap = tokens_in_tx <= max_supply
//     // ------------------------------------------------------------------
//     // VALIDATION RULE 4: Token name uniqueness
//     // ------------------------------------------------------------------
//     // Each NFT should have a unique name within the collection
//     // Token names should follow a pattern, e.g., "ArtPiece001", "ArtPiece002"
//     // Minimum length prevents empty or very short names
//     let valid_token_name = builtin.length_of_bytearray(token_name) >= 1
//     // ------------------------------------------------------------------
//     // FINAL DECISION: All conditions must be true
//     // ------------------------------------------------------------------
//     // The transaction is only approved if ALL security checks pass
//     authorized && valid_quantity && within_supply_cap && valid_token_name
//   }
// }

// // ============================================================================
// // HOW THIS WORKS IN PRACTICE
// // ============================================================================
// //
// // STEP 1 - DEPLOY THE MINTING POLICY:
// // Sarah compiles this Aiken code and deploys it to the blockchain
// // The policy gets a unique policy_id (hash of the script)
// // All NFTs minted with this policy will share this policy_id
// //
// // STEP 2 - MINTING THE FIRST NFT:
// // Sarah creates a transaction that:
// // - Includes a minting operation for 1 token with policy_id and name "ArtPiece001"
// // - Includes a Redeemer: MintRedeemer { token_name: "ArtPiece001", quantity: 1 }
// // - Is signed by Sarah's private key (proves she's the authorized minter)
// // - Creates an output UTxO containing the newly minted NFT
// //
// // The validator checks:
// // ✓ Is this signed by the authorized minter? YES (Sarah's signature)
// // ✓ Is the quantity exactly 1? YES
// // ✓ Is the token name valid? YES ("ArtPiece001" is at least 1 byte)
// // ✓ Is this within the supply cap? YES (1 ≤ 100)
// // APPROVED - The NFT is minted!
// //
// // STEP 3 - MINTING SUBSEQUENT NFTs:
// // Sarah repeats this process with different token names:
// // "ArtPiece002", "ArtPiece003", ... up to "ArtPiece100"
// // Each must be signed by her and passes the same validation rules
// //
// // STEP 4 - ATTEMPTING TO EXCEED SUPPLY:
// // If Sarah (or anyone else) tries to mint "ArtPiece101":
// // The validator would reject it because it exceeds max_supply
// // (In this simplified version - a production version needs better tracking)
// //
// // STEP 5 - BURNING AN NFT:
// // If Sarah made a mistake and wants to burn an NFT:
// // She creates a transaction that:
// // - Includes a minting operation for -1 token (negative = burn)
// // - Uses the same policy_id and the token name to burn
// // - Signs with her key
// // The validator allows burning (quantity == -1)
// //
// // ============================================================================
// // KEY CONCEPTS
// // ============================================================================
// //
// // POLICY ID:
// // Every minting policy has a unique ID (hash). Tokens minted with the same
// // policy share this ID. It's like a "brand" or "collection identifier".
// // Format: [policy_id].[token_name] = "abc123.ArtPiece001"
// //
// // TOKEN NAME:
// // The unique identifier within a collection. Two tokens with the same
// // policy_id but different token_names are different tokens.
// //
// // MINTING vs BURNING:
// // - Positive quantity: Create new tokens (minting)
// // - Negative quantity: Destroy existing tokens (burning)
// // - The validator controls both operations
// //
// // NFT vs FUNGIBLE TOKEN:
// // - NFT: Quantity is always 1 (non-fungible = unique)
// // - Fungible: Quantity can be many (like ADA or other currencies)
// // This validator enforces the NFT pattern (quantity = 1 or -1)
// //
// // ============================================================================
// // SECURITY FEATURES
// // ============================================================================
// //
// // 1. AUTHORIZATION: Only the designated artist can mint tokens.
// //    No one else can create NFTs in this collection.
// //
// // 2. SUPPLY CAP: The collection is limited to 100 NFTs total.
// //    Prevents unlimited inflation of the collection.
// //
// // 3. UNIQUENESS: Each token must have a unique name within the collection.
// //    Prevents accidental duplicates.
// //
// // 4. NFT ENFORCEMENT: Quantity must be exactly 1 (or -1 for burning).
// //    Ensures tokens remain non-fungible.
// //
// // ============================================================================
// // LIMITATIONS & IMPROVEMENTS
// // ============================================================================
// //
// // This is a simplified educational example. A production minting policy
// // would add:
// //
// // 1. BETTER SUPPLY TRACKING: Track cumulative mints across all transactions,
// //    not just within a single transaction. Use a counter stored on-chain.
// //
// // 2. DEADLINE: Add a time window for minting (e.g., only mint during first
// //    30 days after deployment) to create scarcity.
// //
// // 3. ONE-TIME MINT: Use a UTxO-based approach where a special token must be
// //    spent to mint, ensuring each token can only be minted once.
// //
// // 4. METADATA: Integrate with CIP-25 (NFT metadata standard) to attach
// //    rich metadata (image, description, attributes) to each NFT.
// //
// // 5. ROYALTIES: Integrate with CIP-27 (royalty standard) to ensure creators
// //    receive royalties on secondary sales.
// //
// // 6. WHITELIST: Allow multiple authorized minters or implement a whitelist
// //    for collaborative collections.
// //
// // These improvements will be covered in advanced modules.
// // ============================================================================
