# Module M000 Challenge

Set up a reproducible development environment and prove it works by shipping a small suite of Aiken tests.

## Objectives

1. **Environment readiness**
   - Install Aiken via `aikup`, configure PATH, and verify `aiken --version`.
   - Install the VS Code extension and confirm syntax highlighting works for `.ak`.

2. **Starter project**
   - Create a project named `m000-lab` (or similar) with `aiken new`.
   - Add at least two validator files containing a total of five passing tests that cover:
     - Boolean logic
     - Integer math
     - String comparisons
     - Trace usage

3. **Failure recovery**
   - Intentionally break one test, observe the failure output, and fix it.
   - Capture the troubleshooting steps (PATH change, npm prefix tweak, etc.) you needed along the way.

4. **Evidence**
   - Run `aiken check` and keep the terminal output handy.
   - Document the difference between UTxO and EUTxO plus one insight about native assets or CIPs in your notes.

## Completion checklist

- [ ] `aiken --version` reports the expected release.
- [ ] VS Code recognises `.ak` files.
- [ ] Five tests pass (with at least one using `trace`).
- [ ] A failure was introduced and resolved.
- [ ] Personal notes summarise the conceptual takeaways.
