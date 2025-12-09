# Module M003 Challenge

Implement a validator that protects a time-locked treasury with owner/admin roles, reference-input oracle data, and redeemer-specific behaviour.

## Scenario

- Funds sit at a script address with a datum containing:
  - `owner` key hash
  - `admin` key hash
  - `unlock_after` (POSIX time)
  - `min_payout` amount
- Redeemers:
  - `OwnerWithdraw { amount }`
  - `AdminCancel`
  - `ExtendLock { new_deadline }`

## Requirements

1. **OwnerWithdraw**
   - Requires owner signature and current time ≥ `unlock_after`.
   - Ensures at least one output sends `amount` (≥ `min_payout`) back to the owner address.
2. **AdminCancel**
   - Requires admin signature.
   - Only valid before `unlock_after`.
3. **ExtendLock**
   - Requires admin signature plus a reference input that carries oracle approval (e.g., datum field `approved: Bool`).
   - Updates the datum in the output (simulate by checking redeemer value or writes to logs—tests should assert the redeemer is rejected without the reference input).
4. **General**
   - Validator is parameterised so you can swap default owner/admin at compile time.
   - Each branch has corresponding success and failure tests, with assertions documenting why it failed.

## Completion checklist

- [ ] Datum parsing covers all fields and fails cleanly when absent.
- [ ] Signature, time, and reference-input checks each have at least one targeted failure test.
- [ ] Helper functions keep the validator readable (e.g., `fn signed_by_owner(...)`).
- [ ] All tests pass using mock transactions from Module M002.
