# Module M001 Hands-on

Work through these steps to gain confidence creating, testing, and compiling both spending and minting validators.

## 1. Explore the reference validators

```bash
cd workshop-examples
aiken check -m m001
```

- Open the files under `validators/m001/` to study the `always_succeed` and minting examples.
- Note how `mock_utxo_ref`, `placeholder`, and `Void` keep tests concise.

## 2. Scaffold your own project

```bash
cd ~/cardano-dev
aiken new m001-practice
cd m001-practice
code .
```

- Add `validators/first_spend.ak` and copy the “always succeed” spend pattern.
- Write a success test that calls `.spend(None, Void, mock_utxo_ref(...), placeholder)`.
- Run `aiken check` and confirm the test passes.

## 3. Generate a script address

```bash
aiken build
aiken blueprint address -v m001_practice.first_spend.spend
```

- If the CLI can’t find the validator, read `plutus.json` and copy the exact `title` string.

## 4. Add a minting validator

1. Create `validators/first_mint.ak` with the “always succeed” mint signature.
2. Write a test: `first_mint.mint(Void, #"", placeholder)`.
3. Run `aiken check` again, then compile and fetch the policy ID:

```bash
aiken build
aiken blueprint policy -v m001_practice.first_mint.mint
```

## 5. Trace and failure coverage

- Add `trace @"..."` lines inside both validators and tests to see call order.
- Write a failure test using the `else` path:

```text
test wrong_purpose() fail {
  let context =
    ScriptContext {
      transaction: placeholder,
      redeemer: Void,
      info: Minting(#""),
    }
  !first_spend.else(context)
}
```

Run targeted suites:

```bash
aiken check -m wrong_purpose
aiken check -m first_mint
```

## 6. Inspect the blueprint

- Open `plutus.json` in VS Code.
- Locate each validator entry, confirm hashes, and understand how the `title` maps to module names.
- Compare the hash to the generated address/policy outputs for a sanity check.

Repeat any step that feels shaky. You should feel comfortable iterating on validators and seeing immediate feedback before continuing.
