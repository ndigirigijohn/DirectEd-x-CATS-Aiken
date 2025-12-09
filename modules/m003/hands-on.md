# Module M003 Hands-on

Follow these exercises sequentially; each builds on the previous one so you end up with a validator that enforces multiple rules.

## 1. Redeemer branches

1. Copy your Module M001 validator into a new file (e.g., `validators/m003_access.ak`).
2. Define a redeemer type with at least three constructors (`Unlock`, `Cancel`, `Extend`).
3. Implement `when redeemer is { ... }` logic where each branch either returns `True` or a Boolean expression.
4. Write a success test for each allowed branch and a failure test for any forbidden action.

## 2. Datum extraction

1. Add a custom datum type that stores the owner, minimum amount, and optional deadline.
2. Use `expect Some(cfg) = datum` to enforce datum presence.
3. Destructure the datum and use its fields in your redeemer logic (e.g., `cfg.owner` must sign, `cfg.minimum_amount` must match an output).
4. Update tests to include datums: `validator.spend(Some(my_datum), ...)`.

## 3. Signature checks

1. Create helper functions, e.g., `fn signed_by(hash: ByteArray, tx: Transaction) -> Bool`.
2. Modify your redeemer branches so owner/admin actions require different keys in `tx.extra_signatories`.
3. Tests should add signers via `mock_tx() |> add_signatory(...)` (use Vodka helpers).

## 4. Time constraints

1. Import `vodka/time.{is_before, is_after}`.
2. Add a rule that certain redeemers only work before/after `cfg.deadline`.
3. Mock validity ranges with helper builders and prove both success and failure cases.

## 5. Parameterise the validator

1. Wrap the validator with compile-time parameters, e.g., `validator gated(params: Params)`.
2. Supply different `Params` instances in tests to show how script addresses would differ per deployment.
3. Keep datum/redeemer logic intact; parameters simply set default owners/admins.

## 6. Reference input requirement

1. Add a mock reference input that carries oracle/config data.
2. Use helper functions (`ref_input_at`, custom search) to locate the reference input and validate a field (e.g., current price).
3. Include failure tests for “missing” or “invalid” reference inputs.

## 7. Final integration test

- Compose all checks (datum, redeemer, signatures, time, reference input) in one validator.
- Write a comprehensive test that sets up the full transaction context with Vodka builders and demonstrates the happy path.
- Add individual regression tests for each failure mode to quickly pinpoint regressions later.

Take notes as you go—challenges in the next module will lean on these helper patterns instead of re-explaining them.
