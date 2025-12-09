# Module M004 Challenge

Secure a token-sale validator against double-satisfaction and underpayment attacks.

## Scenario

- Datum specifies:
  - `seller: ByteArray`
  - `price_lovelace: Int`
  - `token_policy: PolicyId`
  - `token_name: AssetName`
  - `token_amount: Int`

## Requirements

1. **Single script input guard**
   - Must use either `single_script_input` or an equivalent check to ensure exactly one validator UTxO is spent.
2. **Input datum validation**
   - Extract the inline datum and confirm the validator’s own input actually carries the advertised token amount.
3. **Payment verification**
   - Sum outputs sent to the seller’s address and ensure they meet/exceed `price_lovelace`.
   - Ensure each validator input maps to a distinct payment (no reusing the same ADA across multiple inputs).
4. **Token confirmation**
   - Enforce that the validator’s input contains at least `token_amount` of the specified policy/name.
5. **Tests**
   - Happy path: correct payment, single script input, sufficient tokens.
   - Double-satisfaction attempt: two script inputs but only one payment (should fail).
   - Underpayment attempt: single script input but insufficient ADA (fail).
   - Wrong token attempt: missing or incorrect token quantity (fail).

## Completion checklist

- [ ] Helper functions (`ensure_single_input`, `ensure_price_paid`, `ensure_tokens_present`) keep the validator readable.
- [ ] Tests clearly describe why each failure occurs.
- [ ] Challenge code reuses transaction builders from Module M002 for realism.
