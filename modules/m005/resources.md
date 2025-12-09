# Module M005 Resources

## Docs & references
- Outputs & datums: https://aiken-lang.github.io/stdlib/cardano/transaction.html#type-output
- Vodka single output helpers: https://github.com/sidan-lab/vodka
- State machine background (Plutus Pioneer Program): https://www.youtube.com/watch?v=6gQFzbCLqL4
- Cardano design patterns (state machines): https://developers.cardano.org/docs/smart-contracts/state-machines

## Handy snippets
```text
// Fetch continuing output
expect Some(output) =
  single_script_output(self.inputs, self.outputs, own_ref)

// Extract inline datum
expect InlineDatum(next_data) = output.datum
expect next_state: StateDatum = next_data

// Compare states
fn is_valid_transition(current: StateDatum, next: StateDatum, action: Action) -> Bool

// Ensure closing action removes continuing output
let continues = outputs_at(self.outputs, validator_address)
list.is_empty(continues)
```

## Troubleshooting
- **Multiple continuing outputs** – check equality comparisons: addresses must include both payment and stake credentials; mismatches cause filters to miss outputs.
- **Datum decoding errors** – ensure `StateDatum` derives from `Data` or add manual conversion; inline datums must be read before pattern matching.
- **Lifecycle tests hard to manage** – build helper builders that accept the previous state and emit the next transaction to keep fixtures small.

## Repo pointers
- `modules/m005/` – lesson, exercises, challenge.
- `workshop-examples/validators/m005/` – examples of counters, voting machines, and vesting flows.
- `vesting-dapp-example/` – real project that uses similar patterns for Module M007.
