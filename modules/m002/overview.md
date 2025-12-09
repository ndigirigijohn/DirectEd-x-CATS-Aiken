# Module M002 – Mock Transactions

Validators only see the transaction they live inside, so good tests must recreate that context. This module teaches you how to model inputs, outputs, datums, redeemers, minting values, and signers using Mocktail/Vodka helpers so validators can be exercised realistically.

## Core concepts

- **Transaction anatomy** – Understand `Transaction` fields (inputs, outputs, fee, mint, validity range, extra signers, redeemers, datums) and the balance equation `inputs = outputs + fee`.
- **Placeholders & spread operator** – Start from `placeholder` and override only the fields you care about via `Transaction { ..placeholder, inputs: [...], outputs: [...] }`.
- **Mocktail builders** – Use `mocktail_tx |> tx_in |> tx_out |> set_fee |> complete` to build fluent scenarios without manual struct creation.
- **Mint field** – Represent token bundles with `Value` (`PolicyId` → `AssetName` → quantity) using helpers such as `from_asset`, `add`, and `zero`.
- **Locking & unlocking** – Create script outputs using `PaymentCredential.Script`, attach inline datums, and include redeemers/datums dictionaries when spending those outputs later.

## Learning checkpoints

1. Rebuild the basic spending transaction from `validators/m002/l1_mock_spending.ak`, ensuring inputs/outputs balance.
2. Construct minting transactions that mint multiple assets and understand how values accumulate per policy.
3. Create locking transactions that send funds to script addresses with inline datums.
4. Author unlocking transactions that reference the correct datum/redeemer pair, include the script UTxO as an input, and provide the unlocking redeemer within `tx.redeemers`.

## When to move on

- You can explain which transaction fields your validators rely on and show how to populate them in tests.
- Building mock transactions feels faster with the builder APIs than with manual structs.
- You’ve written tests that simulate locking funds, unlocking them, and minting tokens, all while keeping the balance equation intact.

Use `hands-on.md` to practice each flow in sequence, then complete the scenario inside `challenge.md` to prove you can construct full transaction lifecycles for future modules.
