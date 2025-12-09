# Module M002 Hands-on

Build transaction contexts step by step so every validator test mimics on-chain behaviour.

## 1. Inspect the transaction skeletons

```bash
cd workshop-examples
aiken check -m m002
```

- Open `validators/m002/` to review the spending, minting, locking, and unlocking examples.
- Focus on how `Transaction { ..placeholder, ... }` alters only the needed fields.

## 2. Recreate a balanced spending transaction

1. In your practice project (e.g., `m002-practice`), add `validators/mock_spend.ak`.
2. Define an `Input` and `Output` manually, making sure `inputs = outputs + fee`.
3. Write a test that asserts the values and addresses match expectations.

## 3. Use the Mocktail builder

```text
mocktail_tx()
  |> tx_in(True, mock_tx_hash(0), 0, from_lovelace(10_000_000), mock_pub_key_address(0, None))
  |> tx_out(True, mock_pub_key_address(1, None), from_lovelace(9_000_000))
  |> set_fee(True, 1_000_000)
  |> complete()
```

- Compare the builder output to your manual struct using a test such as `mock_spend_manual() == mock_spend_builder()`.

## 4. Model minting transactions

1. Create `mock_minting_tx()` with `from_asset(mock_policy_id(0), "DemoToken", 1)`.
2. Extend it by adding multiple assets via `add` or by piping multiple `mint` calls.
3. Write tests that assert token quantities for each asset.

## 5. Lock funds at a script address

- Use `mock_script_address` or construct an `Address` with `PaymentCredential.Script`.
- Build an output that uses `InlineDatum(...)` so the datum travels with the UTxO.
- Assemble a transaction that sends ADA + optional tokens to that script output.
- Document the datum structure; you’ll need it when unlocking.

## 6. Unlock with redeemers

1. Build a new transaction that:
   - Includes the locked script output as an input (`Input { output_reference, output: locked_output }`).
   - Adds the redeemer to `tx.redeemers`.
   - Supplies the datum hash/value inside `tx.datums` if you used `DatumHash`.
2. Point your validator test at this transaction and ensure it succeeds with the correct redeemer and fails with an incorrect one.

## 7. Combine flows

- Write one test that locks funds and another that spends them, sharing helper functions so the inputs/outputs stay consistent.
- Add a minting step to the same transaction to simulate NFT issuance while locking funds at a script.
- Verify the balance equation and minted assets each time.

Repeat any section until you can assemble transactions quickly. The goal is to make complex validator tests feel routine long before we add heavy validation logic.
