# Module M005 Hands-on

Use these exercises to build confidence in output validation and state-machine style validators.

## 1. Enforce a single continuing output

1. Add `validators/m005_state.ak` to your project.
2. Start with the Module M003 validator and import `vodka/single.{single_script_output}`.
3. Inside `spend`, call:
   ```text
   expect Some(next_output) =
     single_script_output(self.inputs, self.outputs, own_ref)
   ```
4. Write a test that passes when exactly one continuing output exists and fails when:
   - No outputs return to the script.
   - Two outputs return (simulate via Module M002 transaction builders).

## 2. Extract and compare datums

1. Define a `StateDatum` record (e.g., `{ owner, count, status }`).
2. Extract the input datum (`expect Some(current) = datum`) and output datum:
   ```text
   expect InlineDatum(next_data) = next_output.datum
   expect next: StateDatum = next_data
   ```
3. Ensure invariants such as `current.owner == next.owner`.

## 3. Implement state transitions

1. Define redeemers/actions (e.g., `Init`, `Increment`, `Close`).
2. Write a helper `fn is_valid_transition(current, next, action) -> Bool`.
3. For each action:
   - `Init`: only allowed when no datum exists yet (use a separate validator or redeemer branch).
   - `Increment`: ensures `next.count == current.count + 1`.
   - `Close`: requires no continuing output (guard with pattern matching).
4. Create tests for each action, covering both success and failure.

## 4. Validate output values

1. Enforce minimum lovelace in the continuing output to avoid dust UTxOs.
2. If your state carries tokens, verify the output includes the expected quantity.
3. Tests should mutate output value to ensure the guard fires.

## 5. Build lifecycle tests

1. Initialise the contract: create a transaction that locks the first datum at the script address.
2. Simulate multiple updates: each test should consume the previous output and produce a new one with an incremented state.
3. Close the contract: final action spends the UTxO without recreating another script output, sending funds to a beneficiary instead.

## 6. Document helper modules

1. Split transition logic into small pure functions; export them from `lib/` if you plan to reuse them.
2. Keep tests close to the validator—they double as documentation for future contributors.

Reference `workshop-examples/validators/m005/` whenever you need inspiration for transaction builders or transition helpers.
