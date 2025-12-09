# Module M004 Resources

## Docs & guides
- Transaction inputs: https://aiken-lang.github.io/stdlib/cardano/transaction.html#type-input
- Assets & value helpers: https://aiken-lang.github.io/stdlib/cardano/assets.html
- Vodka utilities (`inputs_at`, `single_script_input`): https://github.com/sidan-lab/vodka
- Double-satisfaction background: https://developers.cardano.org/docs/smart-contracts/security-considerations/#double-satisfaction

## Snippets
```text
// Locate own input
expect Some(own_input) = find_input(tx.inputs, own_ref)

// Ensure only one script input
expect Some(_) = single_script_input(tx.inputs, own_ref)

// Minimum lovelace check
lovelace_of(own_input.output.value) >= min_required

// Token quantity
quantity_of(
  own_input.output.value,
  datum.token_policy,
  datum.token_name,
) >= datum.token_amount
```

## Troubleshooting tips
- **Multiple script inputs slip through** – print/log the result of `inputs_at` to confirm addresses actually match; mismatched staking credentials can cause equality checks to fail.
- **Token quantity returns 0** – verify the policy ID and token name literal match exactly (case-sensitive, byte arrays vs string).
- **Datum missing** – make sure your mock transaction uses `InlineDatum(...)`; otherwise `own_input.output.datum` may be `NoDatum`.
- **Balance equation errors** – re-use Module M002 helpers to guarantee `inputs = outputs + fee`; failing that, simplfy tests to a single wallet input plus the script input.

## Repo references
- `modules/m004/` – current lesson + exercises.
- `workshop-examples/validators/m004/` – reference implementations for address filtering, single-script-input utilities, value validation, and datum checks.
