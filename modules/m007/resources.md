# Module M007 Resources

## Docs & tooling
- Aiken blueprint format: https://aiken-lang.org/language-tour/blueprint
- Mesh SDK datum/redeemer encoding: https://meshjs.dev/apis/transaction
- Lucid Evolution parameter application: https://anastasia-labs.github.io/lucid-evolution/docs/advanced/parameterized-scripts
- Cardano serialization lib (CSL) docs: https://lucid.spacebudz.io/docs/advanced/csl
- `modules/m007/notes/advanced_dapp_architecture.md` – deep dive on the multi-validator architecture that used to live next to the examples.

## Commands
```bash
# Build and inspect blueprint
aiken build
aiken blueprint address -v path.to.validator.spend
aiken blueprint policy -v path.to.policy.mint

# Grep constructor indexes quickly
rg --json \"index\" plutus.json
```

## Off-chain snippets
```ts
// Mesh-style redeemer
const redeemer = {
  data: {
    alternative: 1,
    fields: [{ int: 42 }],
  },
};

// Parameter application (pseudo-code)
const scriptCbor = applyParamsToScript(
  validator.compiledCode,
  [ownerPkh, feePercentage],
);
```

## Planning templates
- **Parameter table**: columns for `Validator`, `Parameter`, `Type`, `Where it comes from`, `Who controls it`.
- **Transaction spec**: `Action`, `Inputs`, `Outputs`, `Reference Inputs`, `Validators involved`, `Datums`, `Redeemers`.
- **Initialization checklist**: `Select UTxO`, `Compile policy`, `Mint oracle token`, `Lock oracle`, `Deploy collection policy`, `Fund script addresses`.

## Repo pointers
- `modules/m007/` – blueprint + architecture guidance plus extra note files.
- `vesting-example/` – practical reference for integrating Aiken contracts with a Next.js frontend.
- `nft-workshop/` – CLI-centric walkthrough that can be paired with the blueprint to test off-chain flows.
