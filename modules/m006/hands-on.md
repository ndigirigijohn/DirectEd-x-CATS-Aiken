# Module M006 Hands-on

Walk through these steps to assemble a complete NFT minting flow, from one-shot oracle tokens to collection policies and burns.

## 1. Authorised minting policy

1. Create `validators/m006_basic_mint.ak`.
2. Implement a minting policy that allows minting only when a specific signer hash is present in `tx.extra_signatories`.
3. Add tests for authorised minting, unauthorised attempts, and burning (negative mint value).

## 2. One-shot oracle NFT

1. Parameterise the policy with an `OutputReference`.
2. Require that the referenced UTxO appears in `tx.inputs`.
3. Enforce minting exactly one token with an empty asset name (`""`); burning requires the same policy.
4. Tests:
   - Success when the UTxO is consumed.
   - Failure when the UTxO is missing or when quantity ≠ 1.

## 3. Oracle validator

1. Write a spending validator that holds the oracle NFT plus a datum containing `{ admin, next_token, price }`.
2. Require admin signatures for state updates.
3. Ensure every successful spend recreates the oracle UTxO with an updated datum (unless closing).

## 4. Collection minting policy

1. Parameterise it with the oracle policy ID and the oracle validator address/hash.
2. Require a reference input pointing to the oracle UTxO; verify the oracle NFT sits inside that input.
3. Read the oracle datum to fetch the counter and derive token names such as `MyCollection-<counter>`.
4. Restrict mints to quantity `1` per transaction unless your design demands otherwise.

## 5. Update oracle state during mints

1. Extend the oracle validator so each mint transaction:
   - Spends the oracle UTxO.
   - Recreates it with `next_token + 1`.
   - Optionally adjusts pricing or other metadata.
2. Write an integration test that includes:
   - Oracle reference input (for the minting policy).
   - Oracle input/output (for the spending validator).
   - Collection mint output carrying the new NFT.

## 6. Burning logic

1. Allow burns by detecting negative quantities in `tx.mint`.
2. Decide who may burn (admin-only, token holder, etc.) and enforce via signatures or reference inputs.
3. Update oracle state accordingly (e.g., decrement counters or flag supply reductions).

## 7. Full workflow rehearsal

1. Mint the oracle NFT (one-shot policy).
2. Lock it in the oracle validator with an initial datum.
3. Execute multiple collection mint transactions, watching the counter increment and token names change.
4. Burn at least one token.
5. Close the oracle validator once the collection is complete or when an admin redeemer says so.

Use `workshop-examples/validators/m006/` for reference implementations of each step. Re-run `aiken check -m m006` frequently to confirm everything still compiles as you layer features.
