## Vesting dApp – Next.js + Mesh SDK

This Next.js (App Router) project demonstrates how to interact with the Aiken
vesting contract that lives in `../vesting-sc`. It reuses the same logic that
the console scripts inside `temp/vesting-Dapp` expose, but wraps everything into
a full-stack dashboard:

- Lock ADA with the owner wallet to the script, choosing the cliff duration.
- Display live script state, aggregated balances, and all inline datums.
- Unlock funds with the beneficiary wallet once the datum time has elapsed.
- Back-end API routes execute Mesh SDK transactions and submit them to Blockfrost.

![screenshot](./public/window.svg)

### Prerequisites

1. [Aiken](https://aiken-lang.org/) installed locally.
2. Cardano wallets for the owner and beneficiary (the repo already contains
   sample `.sk` files under `temp/vesting-Dapp/`).
3. A Blockfrost API key with access to the network you intend to use.
4. Node 18+ and `pnpm` (preferred package manager for this repo).

### Build the contract blueprint

```
cd ../vesting-sc
aiken build
```

This produces `plutus.json`, which the Next.js app loads to derive the script
address. Rebuild whenever you change the validator.

### Environment variables

Create `vesting-dapp/.env.local` (you can copy `env.example`) with:

```
BLOCKFROST_API_KEY=previewXXXXXXXXXXXX
CARDANO_NETWORK=preview # preview | preprod | mainnet
OWNER_ROOT_KEY=your_owner_bech32_root_key
BENEFICIARY_ROOT_KEY=your_beneficiary_bech32_root_key
BLUEPRINT_PATH=../vesting-sc/plutus.json
```

> 💡 Tip: copy the contents of `owner.sk` / `beneficiary.sk` and paste them
> directly into `.env.local`. Multi-line values with literal `\n` sequences are
> also supported (they will be converted to real newlines at runtime).

### Install & run

```
cd vesting-dapp
pnpm install
pnpm dev
```

Navigate to http://localhost:3000 and you will see:

1. **Overview cards** – network, balances, next unlock.
2. **Deposit form** – locks funds with the owner wallet via `/api/vesting/deposit`.
3. **Unlock form** – selects a script UTxO and spends it with the beneficiary via `/api/vesting/unlock`.
4. **Live table** – lists every inline datum and whether it is already claimable.

All state-changing actions hit API routes that execute server-side using Mesh
SDK (`@meshsdk/core`, `@meshsdk/common`, `@meshsdk/core-csl`). They deserialize
the datum, build transactions, sign them with the wallets derived from the
provided root keys, and submit them with the Blockfrost provider.

### Helpful tips

- Fund the owner wallet before trying to deposit. Fund the beneficiary wallet
  and set a collateral UTxO (5 ADA) before trying to unlock.
- The unlock form automatically lists UTxOs at the script address, but you can
  paste any tx hash/index pair manually if needed.
- If you make changes to the contract parameters in Aiken, rebuild the blueprint
  and restart the dev server so the script CBOR is refreshed.

### API reference

- `GET /api/vesting/state` – returns `ContractState`, including parsed datums.
- `POST /api/vesting/deposit` – `{ amountAda, lockDurationMinutes }`.
- `POST /api/vesting/unlock` – `{ txHash, outputIndex? }`.

Each route returns an error payload with a human-readable `message` when
something fails (missing UTxOs, collateral, invalid datum, etc.).
