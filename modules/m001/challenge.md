# Module M001 Challenge

Design a pair of validators—a spending validator that guards a script address and a minting validator that defines a token policy—then prove they behave through tests and compiled artifacts.

## Requirements

1. **Custom spending validator**
   - Give it a meaningful name and at least one `trace` call.
   - Write two success tests (e.g., different redeemers or datums) and one failure test that hits the `else` branch or a guard condition.
2. **Custom minting validator**
   - Implement unique trace text so you know when minting logic runs.
   - Provide at least two success scenarios and one failure test (use `fail` or negation).
3. **Artifacts**
   - Run `aiken build` and confirm both validators appear in `plutus.json`.
   - Generate one script address and one policy ID using the CLI.
4. **Reflection**
   - Capture a short note (personal doc or README snippet) describing the differences between the four spending parameters and three minting parameters, plus how you resolved any compile/test failures.

## Completion checklist

- [ ] Both validators compile with no warnings (unused parameters prefixed with `_`).
- [ ] Minimum of six tests (three per validator) pass, including failure scenarios.
- [ ] Script address and policy ID recorded.
- [ ] Notes mention at least one troubleshooting insight.
