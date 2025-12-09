# Module M002 Challenge

Create a full transaction lifecycle in tests: lock funds at a script address with a datum, mint a token in the same transaction, then unlock the funds with a redeemer in a later mock transaction.

## Requirements

1. **Locking transaction**
   - Uses at least two inputs and two outputs (one wallet change output, one script output).
   - Attaches an inline datum or datum hash to the script output.
   - Balances inputs, outputs, and fees.
2. **Minting component**
   - Adds at least one custom token to the `mint` field during the locking transaction.
   - Test asserts the token quantity and policy ID.
3. **Unlocking transaction**
   - Consumes the script output by including it in `tx.inputs`.
   - Supplies the correct redeemer via `tx.redeemers`.
   - Includes an incorrect redeemer test that fails.
4. **Helper functions**
   - Reuse shared builders (e.g., `mk_locked_output()`, `mk_unlock_tx(...)`) to keep data aligned between tests.

## Completion checklist

- [ ] Locking test confirms datum, address, and minted assets.
- [ ] Unlocking success test passes with the correct redeemer.
- [ ] Unlocking failure test proves the validator rejects bad redeemers or missing datums.
- [ ] All transactions explicitly demonstrate the balance equation.
