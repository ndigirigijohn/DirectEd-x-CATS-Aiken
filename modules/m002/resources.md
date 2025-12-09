# Module M002 Resources

## Docs & references
- Transaction type reference: https://aiken-lang.github.io/stdlib/cardano/transaction.html
- Mocktail/Vodka docs: https://github.com/sidan-lab/vodka
- Assets & Value helpers: https://aiken-lang.github.io/stdlib/cardano/assets.html
- Cardano ledger concepts: https://developers.cardano.org/docs/smart-contracts/overview/#transactions

## Commands & snippets
```bash
# Run module examples
cd workshop-examples
aiken check -m m002

# Start a practice project
cd ~/cardano-dev && aiken new m002-practice

# Inspect blueprint after adding new validators/tests
aiken build
```

```text
// Spread operator when customising placeholder
Transaction {
  ..placeholder,
  inputs: [input],
  outputs: [output],
  fee: 1_000_000,
}

// Mocktail builder skeleton
mocktail_tx()
  |> tx_in(True, mock_tx_hash(0), 0, from_lovelace(5_000_000), mock_pub_key_address(0, None))
  |> tx_out(True, mock_pub_key_address(1, None), from_lovelace(4_500_000))
  |> set_fee(True, 500_000)
  |> complete()
```

## Quick troubleshooting
- **Unbalanced transaction** – double-check lovelace sums: `sum(inputs) == sum(outputs) + fee`. Add assertions inside tests to avoid silent mismatches.
- **Missing datum in unlock** – include the datum hash/value in `tx.datums` or keep it inline when building the original output.
- **Redeemer not found** – ensure `tx.redeemers` contains an entry keyed by the correct `ScriptPurpose` (usually `Spending(mock_utxo_ref(...))` for these tests).
- **Mocktail conditional flags** – the first argument to `tx_in`/`tx_out`/`mint` toggles inclusion; unexpected `False` values mean entries never reach the transaction.

## Repo pointers
- `modules/m002/` – current write-up, exercises, and challenge.
- `workshop-examples/validators/m002/` – canonical mock transactions for spending, minting, locking, unlocking.
- `workshop-examples/lib/` – contains helper utilities (e.g., `mocktail`) used across modules.
