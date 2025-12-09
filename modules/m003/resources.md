# Module M003 Resources

## Docs & reading
- Validators & pattern matching: https://aiken-lang.org/language-tour/validators
- Custom data types / pattern matching: https://aiken-lang.org/language-tour/types
- Transaction module: https://aiken-lang.github.io/stdlib/cardano/transaction.html
- Vodka helpers (time, address, reference inputs): https://github.com/sidan-lab/vodka
- CIP-30 + signature flow refresher: https://cips.cardano.org/cips/cip30/
- `modules/m003/notes/real_world_validator_examples.md` – narrative walkthrough of the real-world samples that used to live beside the .ak files.

## Useful snippets
```text
// Redeemer pattern match
when redeemer is {
  OwnerWithdraw { amount } -> amount <= datum.amount
  _ -> False
}

// Datum extraction
expect Some(config) = datum
let MyDatum { owner, unlock_after, .. } = config

// Signature check
fn signed_by(hash: ByteArray, tx: Transaction) -> Bool {
  list.has(tx.extra_signatories, hash)
}

// Time guard
let time_ok = is_after(tx.validity_range, unlock_after)
```

## Troubleshooting
- **`expect Some(...)` fails** – ensure your mock transactions attach a datum (inline or hashed) when creating the script UTxO.
- **Reference input missing** – double-check you added it to `tx.reference_inputs` and the lookup function matches the same address/hash as the validator expects.
- **Signatures not detected** – confirm tests add the signer via helper functions before passing the transaction to the validator.
- **Unreadable validator** – break logic into helper functions; Aiken encourages pure functions for each rule so error messages stay targeted.

## Repo pointers
- `modules/m003/` – lesson, exercises, challenge, plus note files.
- `workshop-examples/validators/m003/` – reference implementations for redeemer, datum, parameterised, reference-input, and time-lock validators.
- `workshop-examples/lib/` – supporting helper modules (time utilities, mock builders) used throughout this module.
