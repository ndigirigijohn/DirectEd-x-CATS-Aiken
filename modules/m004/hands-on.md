# Module M004 Hands-on

Use these exercises to harden validators against input-based attacks. Start simple and add one layer at a time.

## 1. Locate the validator’s own input

1. In your project, create `validators/m004_inputs.ak`.
2. Inside `spend(...)`, call `find_input(self.inputs, own_ref)` and assert it returns `Some`.
3. Expose helper functions:
   ```text
   fn own_input(tx: Transaction, ref: OutputReference) -> Input
   fn own_address(input: Input) -> Address
   ```
4. Add tests that fail when the input is missing to confirm your guards work.

## 2. Count script inputs

1. Implement both manual filtering (`list.filter`) and Vodka’s `inputs_at`.
2. Add a guard that rejects transactions when more than one script input shares the same address.
3. Use Module M002 builders to craft:
   - A valid transaction with one script input.
   - A malicious transaction with two script inputs from the same validator.

## 3. Enforce single-script-input via helper

1. Import `vodka/inputs.{single_script_input}`.
2. Replace manual counting with:
   ```text
   expect Some(own_input) = single_script_input(self.inputs, own_ref)
   ```
3. Keep both versions in tests so you understand how the helper behaves when the expectation fails.

## 4. Validate minimum lovelace and tokens

1. Use `lovelace_of(own_input.output.value)` to enforce a baseline ADA amount.
2. If your validator uses native tokens, call `quantity_of` for the expected policy/name pair and compare against the datum requirement.
3. Write tests for:
   - Exact threshold
   - Just below threshold (should fail)
   - Large surplus (still passes)

## 5. Read datums directly from inputs

1. Access `own_input.output.datum` and support inline datums via `expect InlineDatum(data) = own_input.output.datum`.
2. Decode the datum into a record (matching Module M003 patterns) and use its fields to drive the value checks.
3. Add negative tests for missing datums and mismatched data.

## 6. Combine checks into a reusable module

1. Wrap the guards into functions such as `ensure_single_script_input(tx, ref)` and `ensure_min_assets(input, datum)`.
2. Export these helpers so later modules (state machines, NFT contracts) can reuse them.
3. Write a “mega test” that tries to break the validator via:
   - Two script inputs
   - Insufficient ADA
   - Missing datum
   - Wrong token quantity
   Each sub-test should fail for the specific reason you expect.

Refer back to `workshop-examples/validators/m004/` whenever you need sample code or inspiration for new test cases.
