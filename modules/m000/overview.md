# Module M000 – Foundations & Setup

Cardano-building starts with two pillars: understanding the EUTxO model and running a healthy development environment. This module keeps both lightweight—enough background to reason about Cardano’s design, followed by practical setup so every later lesson can focus purely on validators.

## Why Cardano feels different

- **Accounting models** – Contrast account-based ledgers (balances mutate in place) with UTxO/EUTxO (explicit inputs and outputs). Cardano validators approve or reject spending specific UTxOs, never “modify an account”.
- **EUTxO upgrades** – Each UTxO can carry a datum (state), every spend supplies a redeemer (argument), and validators see the entire transaction context. You get Bitcoin-like determinism with smart-contract expressiveness.
- **Native assets** – Tokens live at the ledger level rather than inside contracts, so transfers stay cheap and secure. Ownership equals control over the UTxOs that hold the asset.
- **CIPs & community standards** – CIP-25, CIP-30, and friends serve as specs for metadata, wallet APIs, and future protocol changes. Expect to consult https://cips.cardano.org/ frequently.
- **Wallet and transaction roles** – Wallets select UTxOs, build transactions, collect signatures, and submit them. Your tests will simulate these flows; production dApps lean on wallet tooling.
- **Functional mindset** – Validators are pure functions: `(datum, redeemer, context) → Bool`. Immutability and explicit inputs mirror how UTxOs behave, which is why Aiken embraces functional programming.

## Environment objectives

1. Install prerequisites (Node.js, npm, Git, VS Code) and confirm versions meet the suggested minimums.
2. Use `aikup` to install Aiken, ensure `aiken --version` works, and add the binary to your shell `PATH` if needed.
3. Install the official VS Code Aiken extension for syntax highlighting, IntelliSense, and formatter support.
4. Create a sandbox project with `aiken new` to inspect `aiken.toml`, `lib/`, and `validators/`.
5. Run `aiken check` in both your sandbox project and `workshop-examples/validators/m000` to validate the toolchain.
6. Capture troubleshooting steps (PATH exports, npm prefix adjustments, etc.) so you can recreate the environment quickly.

## When to move on

- You can explain, in your own words, why Cardano chose the EUTxO model and how datums/redeemers/script context interact.
- VS Code recognises `.ak` files, the extension is active, and `aiken check` succeeds without PATH issues.
- You have a personal project folder plus a local clone of this repository for reference.

Next, follow the workflows in `hands-on.md` to harden your setup habits, then tackle the `challenge.md` checklist to confirm everything runs smoothly. Use `resources.md` for links and troubleshooting recipes you might revisit later.
