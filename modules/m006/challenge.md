# Module M006 Challenge

Ship a minimal NFT collection stack with three validators:

1. **Oracle NFT policy** – One-shot minting policy parameterised with an `OutputReference`. Mints exactly one oracle NFT (empty asset name) and allows burning only when signed by the admin.
2. **Oracle validator** – Holds the oracle NFT and a datum `{ admin, next_token, price, supply_cap }`. Every mint transaction must:
   - Spend this UTxO.
   - Recreate it with `next_token + 1`.
   - Enforce `next_token <= supply_cap`.
3. **Collection minting policy** – Requires:
   - Reference input pointing to the oracle UTxO.
   - Oracle NFT present in that input.
   - Mint quantity of exactly `1`.
   - Token name generated as `#{collection}-#{next_token}`.

## Deliverables

- Tests showing:
  - Oracle NFT can be minted once and then only burned by the admin.
  - Collection mint succeeds when referencing the oracle and fails when the reference is missing or the counter skips.
  - Supply cap prevents minting beyond the configured limit.
  - Burn operation reduces supply or flags the token as destroyed.
- Short README snippet (or comments) describing how the three validators interact.

Focus on correctness and clarity—this stack feeds directly into Module M007’s DApp integration.
