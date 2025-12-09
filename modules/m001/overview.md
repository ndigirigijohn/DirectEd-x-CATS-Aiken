# Module M001 – First Validator

This module turns the M000 environment into real output: you’ll write the simplest possible spending and minting validators, exercise them with tests, and produce the blueprint artifacts that wallets and dApps consume.

## Core concepts

- **Validator anatomy** – Aiken validators are pure functions that return `True` or `False`. Spending validators receive `(datum, redeemer, input, tx)` while minting validators take `(redeemer, policy_id, tx)`.
- **Spending vs minting** – Spending validators gate UTxOs at script addresses; minting validators control when tokens are created or burned via policy IDs.
- **Purpose clauses** – `validator ... { spend(...) { ... } else(_) { fail } }` ensures the validator only serves its intended role.
- **Blueprint outputs** – `aiken build` emits `plutus.json`, which lists validator hashes, compiled code, and gives inputs to address/policy generation.
- **Testing patterns** – Success tests call `validator.spend(...)`; failure tests lean on the `fail` keyword, `else` branch, or negated expectations.

## Learning checkpoints

1. Re-create the “always succeed” spending and minting validators from `workshop-examples/validators/m001` to see the type signatures in action.
2. Add simple traces plus success/failure tests that use `mock_utxo_ref`, `placeholder`, and `Void`.
3. Run `aiken build`, inspect `plutus.json`, and generate a script address (`aiken blueprint address`) plus policy ID (`aiken blueprint policy`).
4. Explore how title paths inside `plutus.json` map to validator modules so CLI commands can find them.

## When to move on

- You can describe every parameter in both validator types and explain why underscores silence unused-variable warnings.
- Your tests cover at least one success and one failure case and you’re comfortable reading the output of `aiken check`.
- You know how to fetch the address or policy for any compiled validator in the blueprint file.

Next, execute the step-by-step practice in `hands-on.md`, then complete the `challenge.md` brief to cement validator creation, testing, and artifact generation.
