# Module M006 Resources

## Docs & references
- Aiken minting policy docs: https://aiken-lang.org/language-tour/validators#minting-validators
- Assets/mint field reference: https://aiken-lang.github.io/stdlib/cardano/assets.html
- Oracle/reference pattern overview: https://developers.cardano.org/docs/smart-contracts/oracle-pattern
- CIP-25 (NFT metadata) for naming conventions: https://cips.cardano.org/cips/cip25

## Commands & helpers
```bash
# Run module examples
cd workshop-examples && aiken check -m m006

# Inspect minted tokens in a transaction
aiken eval "assets.tokens(tx.mint, policy_id)"
```

```text
// One-shot mint guard
let has_ref =
  list.any(tx.inputs, fn(input) { input.output_reference == utxo_ref })

// Reference input fetch
fn oracle_ref(tx: Transaction, addr: Address) -> Option<Input> {
  list.find(tx.reference_inputs, fn(input) { input.output.address == addr })
}

// Token name builder
fn token_name(collection: String, counter: Int) -> AssetName {
  string.concat(collection, "-", int.to_string(counter))
}
```

## Troubleshooting
- **Policy not found in blueprint** – remember that minting validators live under `.mint`; use `aiken blueprint policy -v path.to.validator.mint`.
- **Reference input missing** – ensure the oracle UTxO is included in `tx.reference_inputs`, not `tx.inputs`, when the minting policy only needs to read state.
- **Token names look garbled** – `AssetName` is a byte array; convert strings using `string.to_utf8`.
- **One-shot policy reused** – verify that the parameterised `OutputReference` actually exists on-chain; mock references must match the transaction inputs exactly.

## Repo pointers
- `modules/m006/` – lesson + exercise flow.
- `workshop-examples/validators/m006/` – oracle NFT, oracle validator, collection policy samples.
- `nft-workshop/` – CLI walkthrough referenced later for real-world minting.
