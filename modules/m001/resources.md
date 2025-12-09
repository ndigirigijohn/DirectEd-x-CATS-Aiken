# Module M001 Resources

## Docs & references
- Validators overview: https://aiken-lang.org/language-tour/validators
- Testing guide: https://aiken-lang.org/language-tour/tests
- Transaction module: https://aiken-lang.github.io/stdlib/cardano/transaction.html
- Assets & PolicyId docs: https://aiken-lang.github.io/stdlib/cardano/assets.html
- CIP-30 (wallet bridge): https://cips.cardano.org/cips/cip30/

## Handy commands
```bash
# Run module-specific tests in workshop examples
cd workshop-examples
aiken check -m m001

# Create a practice project
cd ~/cardano-dev && aiken new m001-practice

# Compile and inspect validators
aiken build
aiken blueprint address -v m001_practice.my_validator.spend
aiken blueprint policy -v m001_practice.my_mint.mint

# Search blueprint entries
cat plutus.json | grep -n \"title\"
```

## Troubleshooting cues
- **Validator not found**: use the exact `title` string from `plutus.json` when running `aiken blueprint ...`.
- **Type mismatch**: ensure redeemer placeholders use `Void`, datums use `None`/`Some`, and mock references come from `mock_utxo_ref`.
- **Unused parameter warnings**: prefix with `_datum`, `_redeemer`, etc., until the variable participates in logic later.
- **Blueprint confusion**: remember that script addresses derive from validator hashes, while policy IDs identify minting rules—both live inside `plutus.json`.

## Repo pointers
- `modules/m001/` – lesson outline, hands-on flow, challenge brief.
- `workshop-examples/validators/m001/` – canonical sample validators + tests.
- `nft-workshop/` – revisit after Module M006; includes minting patterns that build on this module’s foundation.
