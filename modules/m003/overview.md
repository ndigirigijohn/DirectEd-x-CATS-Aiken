# Module M003 – Validation Logic

Validators become useful only when they enforce rules. This module teaches you how to implement real decision making: redeemer pattern matching, datum inspection, signature/time checks, reference inputs, and parameterisation so one validator can power multiple deployments.

## Core concepts

- **Redeemer-driven behaviour** – Define algebraic data types (e.g., `Unlock | Cancel | Extend`) and use `when ... is { ... }` to allow or reject each action.
- **Datum-backed state** – Store configuration such as owners, deadlines, or amounts in datums; destructure them safely with `expect Some(d)` and `let MyDatum { ... } = d`.
- **Parameterized validators** – Accept compile-time parameters (e.g., owner/admin keys) so the same source file can generate multiple addresses.
- **Reference inputs and signatures** – Use helper utilities to read reference inputs (for oracle data) and enforce that particular verification key hashes appear in `tx.extra_signatories`.
- **Time and IO checks** – Leverage `validity_range`, `vodka/time` helpers, and list-processing functions to make sure transactions happen within allowed windows and include the right inputs/outputs.

## Learning checkpoints

1. Extend a Module M001 validator with redeemer constructors and tests that cover success + failure cases per action.
2. Introduce a custom datum type, extract its fields, and guard on signer presence or thresholds defined inside the datum.
3. Parameterise the validator (e.g., `validator access_control(params: ...)`) and instantiate it with different owners in tests.
4. Add reference-input, signature, and time constraints to the same validator, documenting why each rule exists.

## When to move on

- You can articulate which `Transaction` fields each rule depends on and access them without panicking or pattern-match errors.
- Tests target each rule individually (signature missing, wrong redeemer, time too early, etc.) and your failure messages point to the culprit.
- Validator modules stay readable because you extracted helper functions or `let` bindings for non-trivial checks.

Work through `hands-on.md` to layer these skills one at a time, then tackle `challenge.md` to combine them into a compact, production-style validator. The patterns you master here underpin Modules M004–M007.
