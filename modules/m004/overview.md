# Module M004 – Advanced Input Validation

Most Cardano exploits stem from sloppy input handling. This module focuses exclusively on the UTxOs being spent: finding the validator’s own input, filtering script addresses, preventing double-satisfaction attacks, checking balances, and reading datums straight from inputs.

## Core concepts

- **Understanding inputs** – Each `Input` bundles an `OutputReference` and the full `Output` data (address, value, datum, reference script). Validators must locate their own input using the provided `OutputReference`.
- **Address filtering utilities** – Use `find_input`, `inputs_at`, or Vodka helpers to count how many script inputs appear and ensure only one comes from your validator.
- **Double-satisfaction defense** – Enforce single script inputs using `single_script_input` or tag datums with the expected `OutputReference` so the same on-chain payment can’t satisfy multiple validator instances.
- **Value checks** – Inspect lovelace minimums and native token quantities via `lovelace_of` and `quantity_of`, combining them with datum data when required.
- **Input datums** – Extract inline datums, validate structure, and compare across multiple inputs before trusting their contents.

## Learning checkpoints

1. Rebuild the manual `find_input` + `inputs_at` helpers, then swap to Vodka utilities to see the difference.
2. Implement a guard that fails whenever more than one script input is present.
3. Validate minimum ADA/token requirements on the validator’s own input.
4. Extract datums directly from inputs and enforce business rules (e.g., `min_price`, `beneficiary`).

## When to move on

- You can explain why double-satisfaction attacks work and demonstrate the mitigation you chose.
- Your validator contains small helper functions for “find my input”, “count script inputs”, and “check min value” instead of inline walls of code.
- Tests include both balanced and malicious transactions (e.g., two script inputs, insufficient value, missing datum).

Proceed to `hands-on.md` for concrete workflows, then complete the `challenge.md` requirements to prove your validator resists the most common input-based attacks.
