# Module M006 – Minting Policies & NFT Systems

Spending validators guard UTxOs; minting policies control token supply. This module teaches you how to write minting policies, guarantee one-time NFT issuance, implement oracle/reference-token patterns, and coordinate policies with spending validators to run a complete NFT collection.

## Core concepts

- **Minting policy signature** – Minting validators receive only `(redeemer, policy_id, tx)` and inspect `tx.mint` to see what quantities are being created (`> 0`) or burned (`< 0`).
- **Token identity** – Each asset is uniquely identified by `PolicyId + AssetName`, so policies define collections and asset names differentiate tokens.
- **One-shot minting** – Parameterise policies with an `OutputReference`; require that UTxO in the transaction inputs so the policy can only succeed once (perfect for oracle NFTs).
- **Oracle/reference pattern** – Mint a unique oracle NFT, lock it in a spending validator whose datum tracks collection state (count, pricing, admin). Collection policies read that datum via reference inputs to decide whether a mint is valid.
- **Mint + burn logic** – Positive quantities create tokens, negative quantities burn them. Policies should enforce who can burn and under what conditions.

## Learning checkpoints

1. Write a basic minting policy that checks signer authorization and inspects `tx.mint`.
2. Upgrade it to a one-shot policy using an `OutputReference`.
3. Build the oracle NFT + oracle validator pair and confirm the NFT must remain locked for collection mints to succeed.
4. Implement a collection minting policy that:
   - Reads the oracle datum via reference input.
   - Generates dynamic token names (e.g., `CollectionName-<counter>`).
   - Updates the oracle state after each mint (handled in the spending validator).
5. Add burn logic that requires the oracle NFT or admin signature.

## When to move on

- You can explain why minting policies lack datums and how they rely on transaction inputs/reference inputs for context.
- Tests prove one-shot behaviour, reference input requirements, and mint/burn authorization.
- You can sketch the full architecture: oracle NFT policy → oracle validator → collection policy → optional burn policy.

Proceed to `hands-on.md` for the guided build, then complete the `challenge.md` brief to demonstrate a full NFT system.
