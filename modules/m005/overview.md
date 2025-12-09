# Module M005 – Outputs & State Machines

After securing inputs, we flip the lens to outputs: continuing script UTxOs, output datums, and the input-output pattern that powers Cardano state machines. You’ll learn to validate where funds go, ensure updated state matches business rules, and structure contracts as initialise → update → close flows.

## Core concepts

- **Output filtering** – Use `outputs_at` or Vodka helpers to find outputs that return to your validator (continuing outputs) and enforce “exactly one” semantics.
- **Single script output utilities** – `single_script_output(self.inputs, self.outputs, own_ref)` or equivalent logic ensures you capture the exact UTxO that carries the next state.
- **Output datums** – Prefer inline datums for state machines; extract them, decode to custom types, and compare against the input datum to validate transitions.
- **State machine pattern** – Inputs carry the current state, outputs hold the next state. Redeemers describe the action, and the validator verifies `(current_state, action) -> next_state` is legal.
- **Lifecycle design** – Implement initialise (create the first state UTxO), update (iterate state via continuing outputs), and close (spend without recreating state) flows.

## Learning checkpoints

1. Enforce a single continuing output that keeps the validator alive.
2. Extract datums from both input and output, compare critical fields, and assert invariants like owner continuity or bounded increments.
3. Model actions (redeemers) that change state (increment counter, place bid, claim vesting) and ensure only legal transitions pass.
4. Add close paths where no continuing output exists and confirm tests cover both continuing and terminating scenarios.

## When to move on

- You can explain how state evolves through chained UTxOs and why validators must examine outputs to keep contracts safe.
- Test suites include complete lifecycles: initialise → multiple updates → close, covering both success and rejection cases.
- Your validator structure isolates transition logic in helper functions (`is_valid_transition`, `next_state_matches`) so adding new actions remains manageable.

Continue with the exercises in `hands-on.md`, then tackle the `challenge.md` state machine to prove you can manage output validation end to end.
