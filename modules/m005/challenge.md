# Module M005 Challenge

Build a three-stage state machine for a vesting contract:

1. **Init** – Lock funds with a datum `{ beneficiary, total_amount, claimed_amount = 0, cliff_time, status = Active }`.
2. **Claim** – Beneficiary can withdraw portions after `cliff_time`, ensuring:
   - Transaction creates a continuing output with updated `claimed_amount`.
   - Remaining funds stay locked with the same datum structure.
   - Output value retains the same minimum ADA plus remaining tokens.
3. **Close** – Admin can close the contract once all funds are claimed or after an expiry time, removing the continuing output and sending leftovers to a treasury.

## Requirements

- Use `single_script_output` (or equivalent) to ensure only one continuing UTxO during Claim.
- Validate that `claimed_amount` never exceeds `total_amount`.
- Enforce signature requirements (beneficiary for Claim, admin for Close).
- Cover both inline datum extraction and output value checks.

## Tests to include

- Successful Init creates the first state UTxO.
- Multiple Claim transactions increment the claimed amount and keep the state consistent.
- Claim before `cliff_time` fails.
- Claim that would overshoot the total fails.
- Close succeeds only when conditions are met; otherwise it fails.

Document helper functions used to compare input/output datums and share them with later modules.
