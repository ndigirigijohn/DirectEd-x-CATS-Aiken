# Complete Guide to Aiken Contract Deployment: From Compilation to Full-Stack DApp

This guide walks you through every step of deploying an Aiken smart contract on Cardano, from compilation through building a complete full-stack decentralized application.

---

## Table of Contents

1. [After Writing Your Contract](#1-after-writing-your-contract)
2. [Understanding the Blueprint (plutus.json)](#2-understanding-the-blueprint-plutusjson)
3. [Setting Up Your Off-Chain Environment](#3-setting-up-your-off-chain-environment)
4. [Getting Script Addresses and Policy IDs](#4-getting-script-addresses-and-policy-ids)
5. [Transaction Building Scenarios](#5-transaction-building-scenarios)
6. [Real-World Examples](#6-real-world-examples)
7. [Building a Full-Stack DApp](#7-building-a-full-stack-dapp)

---

## 1. After Writing Your Contract

### 1.1 Compiling Your Contract

Once you've written and tested your Aiken validator, compile it:

```bash
aiken build
```

This generates a **plutus.json** file (also called a "blueprint") at your project root. This file contains:
- Your compiled validator code (as CBOR hex)
- Validator hash (used for addresses and policy IDs)
- Datum and redeemer schemas
- Parameter definitions

**Example compiled validator structure:**
```json
{
  "validators": [
    {
      "title": "my_validator.spend",
      "datum": {
        "title": "datum",
        "schema": { "$ref": "#/definitions/my_validator/Datum" }
      },
      "redeemer": {
        "title": "redeemer",
        "schema": { "$ref": "#/definitions/my_validator/Redeemer" }
      },
      "compiledCode": "590a3f01000...",
      "hash": "69b9758387079fd00c05c7daa8fde367..."
    }
  ],
  "definitions": {
    "my_validator/Datum": {
      "title": "Datum",
      "anyOf": [
        {
          "title": "Initialize",
          "dataType": "constructor",
          "index": 0,
          "fields": []
        }
      ]
    }
  }
}
```

### 1.2 Understanding What You've Built

Your validator is now compiled to on-chain code, but it doesn't yet exist on the blockchain. To deploy it, you need to:
1. **Read the compiled code** from plutus.json
2. **Apply parameters** (if your validator has them)
3. **Generate addresses** (for spending validators) or **policy IDs** (for minting validators)
4. **Build transactions** that interact with these validators

---

## 2. Understanding the Blueprint (plutus.json)

### 2.1 What's in the Blueprint?

The blueprint is your interface between on-chain and off-chain code. Key components:

**Compiled Code:**
```json
"compiledCode": "590a3f01000032323232..."
```
This is your validator as CBOR-encoded Plutus script.

**Validator Hash:**
```json
"hash": "69b9758387079fd00c05c7daa8fde367acdb84dbd9c35dfd05b701ad"
```
This hash is used to:
- Generate script addresses (spending validators)
- Generate policy IDs (minting validators)

**Datum/Redeemer Schemas:**
```json
"datum": {
  "schema": {
    "$ref": "#/definitions/my_validator/Datum"
  }
}
```
These tell you how to structure your data off-chain.

### 2.2 Constructor Indexing

Redeemers and datums with multiple constructors use indexing:

```aiken
// On-chain Aiken code
pub type Redeemer {
  IncrementCount  // index: 0
  CloseState      // index: 1
}
```

```json
// In plutus.json
"anyOf": [
  {
    "title": "IncrementCount",
    "dataType": "constructor",
    "index": 0,
    "fields": []
  },
  {
    "title": "CloseState",
    "dataType": "constructor",
    "index": 1,
    "fields": []
  }
]
```

Off-chain, you reference these by index when building transactions.

---

## 3. Setting Up Your Off-Chain Environment

### 3.1 Install Dependencies

**Using JavaScript/TypeScript with Mesh:**

```bash
npm install @meshsdk/core @meshsdk/core-csl dotenv
```

**Or using Lucid Evolution:**

```bash
npm install @lucid-evolution/lucid dotenv
```

### 3.2 Get Testnet Access

**1. Get Blockfrost API Key:**
- Sign up at [blockfrost.io](https://blockfrost.io)
- Create a project for "Preview Testnet"
- Copy your API key

**2. Create Environment File:**

Create `.env` in your project root:
```env
BLOCKFROST_PROJECT_ID=previewYourApiKeyHere
```

**3. Generate Test Wallets:**

```bash
# Generate wallet keys
aiken address generate
```

This creates files like:
- `me.sk` - Your private key (Bech32 format)
- `me.addr` - Your address

**4. Get Test ADA:**
- Go to [Cardano Faucet](https://docs.cardano.org/cardano-testnet/tools/faucet)
- Select "Preview Testnet"
- Paste your address from `me.addr`
- Receive test ADA (usually 1000 tADA)

### 3.3 Create Common Utilities

Create `common.ts` (or `common.mjs` for Node.js):

```typescript
import fs from "node:fs";
import {
  BlockfrostProvider,
  MeshTxBuilder,
  MeshWallet,
  serializePlutusScript,
  UTxO,
} from "@meshsdk/core";
import { applyParamsToScript } from "@meshsdk/core-csl";
import blueprint from "./plutus.json";

// Setup Blockfrost provider
const blockchainProvider = new BlockfrostProvider(
  process.env.BLOCKFROST_PROJECT_ID
);

// Create wallet from your generated keys
export const wallet = new MeshWallet({
  networkId: 0, // 0 = testnet, 1 = mainnet
  fetcher: blockchainProvider,
  submitter: blockchainProvider,
  key: {
    type: "root",
    bech32: fs.readFileSync("me.sk").toString(),
  },
});

// Function to load and prepare your validator
export function getScript() {
  // Apply parameters (empty array if no params)
  const scriptCbor = applyParamsToScript(
    blueprint.validators[0].compiledCode,
    [] // Add parameters here if your validator needs them
  );

  // Generate script address (for spending validators)
  const scriptAddr = serializePlutusScript(
    { code: scriptCbor, version: "V3" },
  ).address;

  return { scriptCbor, scriptAddr };
}

// Create transaction builder
export function getTxBuilder() {
  return new MeshTxBuilder({
    fetcher: blockchainProvider,
    submitter: blockchainProvider,
  });
}

// Fetch UTxO by transaction hash
export async function getUtxoByTxHash(txHash: string): Promise<UTxO> {
  const utxos = await blockchainProvider.fetchUTxOs(txHash);
  if (utxos.length === 0) {
    throw new Error("UTxO not found");
  }
  return utxos[0];
}
```

---

## 4. Getting Script Addresses and Policy IDs

### 4.1 Script Address (Spending Validators)

A script address is where you send funds that will be locked by your validator.

**Using Mesh:**
```typescript
import { serializePlutusScript } from "@meshsdk/core";
import { applyParamsToScript } from "@meshsdk/core-csl";
import blueprint from "./plutus.json";

const scriptCbor = applyParamsToScript(
  blueprint.validators[0].compiledCode,
  [] // parameters
);

const scriptAddress = serializePlutusScript(
  { code: scriptCbor, version: "V3" },
).address;

console.log("Script Address:", scriptAddress);
// Output: addr_test1wqag3rt979nep9g2wtdwu8mr4gz6m4kjdpp37wx8pnh8dqq9pqw2h
```

### 4.2 Policy ID (Minting Validators)

The policy ID is the hash of your minting validator. It identifies tokens minted by that policy.

**Getting Policy ID:**
```typescript
import { serializePlutusScript } from "@meshsdk/core";
import { applyParamsToScript } from "@meshsdk/core-csl";
import blueprint from "./plutus.json";

const scriptCbor = applyParamsToScript(
  blueprint.validators[0].compiledCode,
  []
);

const policyId = serializePlutusScript(
  { code: scriptCbor, version: "V3" },
).hash;

console.log("Policy ID:", policyId);
// Output: 69b9758387079fd00c05c7daa8fde367acdb84dbd9c35dfd05b701ad
```

**Asset Identifier:**
Tokens are identified by: `{policyId}{assetName}`

```typescript
import { fromText } from "@meshsdk/core";

const assetName = fromText("MyToken"); // Convert to hex
const assetId = `${policyId}${assetName}`;
// Output: 69b9758387079fd00c05c7daa8fde367acdb84dbd9c35dfd05b701ad4d79546f6b656e
```

---

## 5. Transaction Building Scenarios

### 5.1 Scenario 1: Lock Funds at Script Address

**Purpose:** Send ADA (and tokens) to a script address, protected by a datum.

**Example: Lock 10 ADA**

Create `lock.ts`:

```typescript
import { Asset, deserializeAddress, mConStr0 } from "@meshsdk/core";
import { getScript, getTxBuilder, wallet } from "./common";

async function main() {
  // Assets to lock
  const assets: Asset[] = [
    {
      unit: "lovelace",
      quantity: "10000000", // 10 ADA
    },
  ];

  // Get wallet info
  const utxos = await wallet.getUtxos();
  const walletAddress = (await wallet.getUsedAddresses())[0];
  const { scriptAddr } = getScript();

  // Get wallet pubKeyHash for datum
  const signerHash = deserializeAddress(walletAddress).pubKeyHash;

  // Build transaction
  const txBuilder = getTxBuilder();
  await txBuilder
    .txOut(scriptAddr, assets) // Send to script
    .txOutInlineDatumValue(mConStr0([signerHash])) // Inline datum
    .changeAddress(walletAddress) // Change back to wallet
    .selectUtxosFrom(utxos)
    .complete();

  const unsignedTx = txBuilder.txHex;

  // Sign and submit
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  
  console.log(`Funds locked at Tx ID: ${txHash}`);
  console.log(`View on CardanoScan: https://preview.cardanoscan.io/transaction/${txHash}`);
}

main();
```

**Run it:**
```bash
npx tsx lock.ts
```

**Understanding the datum:**
- `mConStr0([signerHash])` creates a datum with constructor 0 and one field
- This matches an Aiken datum like:
  ```aiken
  pub type Datum {
    Datum { owner: Hash<Blake2b_224, VerificationKey> }
  }
  ```

### 5.2 Scenario 2: Unlock Funds from Script

**Purpose:** Spend a UTxO locked at a script address by providing a valid redeemer.

**Example: Unlock with "Hello, World!" redeemer**

Create `unlock.ts`:

```typescript
import {
  deserializeAddress,
  mConStr0,
  stringToHex,
} from "@meshsdk/core";
import { getScript, getTxBuilder, getUtxoByTxHash, wallet } from "./common";

async function main() {
  // Get wallet info
  const utxos = await wallet.getUtxos();
  const walletAddress = (await wallet.getUsedAddresses())[0];
  const collateral = (await wallet.getCollateral())[0];

  const { scriptCbor } = getScript();
  const signerHash = deserializeAddress(walletAddress).pubKeyHash;

  // The redeemer value
  const message = "Hello, World!";

  // Get the locked UTxO (from previous transaction)
  const txHashFromDeposit = process.argv[2]; // Pass as CLI argument
  const scriptUtxo = await getUtxoByTxHash(txHashFromDeposit);

  // Build unlock transaction
  const txBuilder = getTxBuilder();
  await txBuilder
    .spendingPlutusScript("V3")
    .txIn(
      scriptUtxo.input.txHash,
      scriptUtxo.input.outputIndex,
      scriptUtxo.output.amount,
      scriptUtxo.output.address
    )
    .txInScript(scriptCbor) // Provide validator script
    .txInRedeemerValue(mConStr0([stringToHex(message)])) // Redeemer
    .txInInlineDatumPresent() // We used inline datum
    .requiredSignerHash(signerHash) // Required signature
    .changeAddress(walletAddress)
    .txInCollateral(
      collateral.input.txHash,
      collateral.input.outputIndex,
      collateral.output.amount,
      collateral.output.address
    )
    .selectUtxosFrom(utxos)
    .complete();

  const unsignedTx = txBuilder.txHex;

  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);

  console.log(`Funds unlocked at Tx ID: ${txHash}`);
}

main();
```

**Run it:**
```bash
npx tsx unlock.ts <TX_HASH_FROM_LOCK>
```

**Key Points:**
- **Collateral:** Required for script transactions, returned if script succeeds
- **Redeemer:** Must match validator's expected type/value
- **Required Signers:** Must include any pubKeyHashes checked by validator

### 5.3 Scenario 3: Mint Tokens

**Purpose:** Create new tokens using a minting policy.

**Example: Mint an NFT**

Create `mint.ts`:

```typescript
import { 
  deserializeAddress, 
  fromText, 
  mConStr0 
} from "@meshsdk/core";
import { getScript, getTxBuilder, wallet } from "./common";
import { serializePlutusScript } from "@meshsdk/core";
import { applyParamsToScript } from "@meshsdk/core-csl";
import blueprint from "./plutus.json";

async function main() {
  const utxos = await wallet.getUtxos();
  const walletAddress = (await wallet.getUsedAddresses())[0];
  const collateral = (await wallet.getCollateral())[0];

  // Get minting policy
  const scriptCbor = applyParamsToScript(
    blueprint.validators[0].compiledCode,
    []
  );

  const policyId = serializePlutusScript(
    { code: scriptCbor, version: "V3" },
  ).hash;

  // Define token
  const tokenName = "MyNFT";
  const assetName = fromText(tokenName);
  const assetId = `${policyId}${assetName}`;

  // Build minting transaction
  const txBuilder = getTxBuilder();
  await txBuilder
    .mintPlutusScript("V3")
    .mint("1", policyId, assetName) // Mint 1 token
    .mintingScript(scriptCbor)
    .mintRedeemerValue(mConStr0([])) // Redeemer for minting
    .changeAddress(walletAddress)
    .txInCollateral(
      collateral.input.txHash,
      collateral.input.outputIndex,
      collateral.output.amount,
      collateral.output.address
    )
    .selectUtxosFrom(utxos)
    .complete();

  const unsignedTx = txBuilder.txHex;

  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);

  console.log(`Token minted at Tx ID: ${txHash}`);
  console.log(`Asset ID: ${assetId}`);
}

main();
```

### 5.4 Scenario 4: Burn Tokens

**Purpose:** Remove tokens from circulation.

**Example: Burn NFT**

```typescript
import { fromText, mConStr1 } from "@meshsdk/core";
import { getScript, getTxBuilder, wallet } from "./common";
import { serializePlutusScript } from "@meshsdk/core";
import { applyParamsToScript } from "@meshsdk/core-csl";
import blueprint from "./plutus.json";

async function main() {
  const utxos = await wallet.getUtxos();
  const walletAddress = (await wallet.getUsedAddresses())[0];
  const collateral = (await wallet.getCollateral())[0];

  const scriptCbor = applyParamsToScript(
    blueprint.validators[0].compiledCode,
    []
  );

  const policyId = serializePlutusScript(
    { code: scriptCbor, version: "V3" },
  ).hash;

  const tokenName = "MyNFT";
  const assetName = fromText(tokenName);
  const assetId = `${policyId}${assetName}`;

  // Redeemer for burning (using constructor index 1)
  const burnRedeemer = mConStr1([]);

  const txBuilder = getTxBuilder();
  await txBuilder
    .mintPlutusScript("V3")
    .mint("-1", policyId, assetName) // Negative quantity = burn
    .mintingScript(scriptCbor)
    .mintRedeemerValue(burnRedeemer)
    .changeAddress(walletAddress)
    .txInCollateral(
      collateral.input.txHash,
      collateral.input.outputIndex,
      collateral.output.amount,
      collateral.output.address
    )
    .selectUtxosFrom(utxos)
    .complete();

  const unsignedTx = txBuilder.txHex;

  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);

  console.log(`Token burned at Tx ID: ${txHash}`);
}

main();
```

---

## 6. Real-World Examples

### 6.1 Example 1: Vesting Contract

**Use Case:** Lock funds that can only be released after a specific time.

**Aiken Validator (simplified):**
```aiken
use aiken/transaction.{Transaction, ScriptContext}
use aiken/time.{PosixTime}

pub type Datum {
  lock_until: PosixTime,
  owner: Hash<Blake2b_224, VerificationKey>,
  beneficiary: Hash<Blake2b_224, VerificationKey>,
}

validator vesting {
  spend(
    datum_opt: Option<Datum>,
    _redeemer: Data,
    _output_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(datum) = datum_opt
    
    let is_owner = list.has(self.extra_signatories, datum.owner)
    let is_beneficiary = list.has(self.extra_signatories, datum.beneficiary)
    let after_deadline = self.validity_range.lower_bound >= datum.lock_until
    
    // Owner can always withdraw, beneficiary only after deadline
    is_owner || (is_beneficiary && after_deadline)
  }
}
```

**Off-Chain Lock Script:**

```typescript
import { mConStr0, deserializeAddress } from "@meshsdk/core";
import { getTxBuilder, wallet } from "./common";

async function lockVesting(
  amount: string,
  lockUntilTimestamp: number,
  beneficiaryAddress: string
) {
  const utxos = await wallet.getUtxos();
  const ownerAddress = (await wallet.getUsedAddresses())[0];
  const scriptAddr = "addr_test1..."; // Your vesting script address

  const ownerPubKeyHash = deserializeAddress(ownerAddress).pubKeyHash;
  const beneficiaryPubKeyHash = deserializeAddress(beneficiaryAddress).pubKeyHash;

  const datum = mConStr0([
    lockUntilTimestamp,
    ownerPubKeyHash,
    beneficiaryPubKeyHash
  ]);

  const txBuilder = getTxBuilder();
  await txBuilder
    .txOut(scriptAddr, [{ unit: "lovelace", quantity: amount }])
    .txOutInlineDatumValue(datum)
    .changeAddress(ownerAddress)
    .selectUtxosFrom(utxos)
    .complete();

  const unsignedTx = txBuilder.txHex;
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);

  console.log(`Vesting locked: ${txHash}`);
  return txHash;
}

// Lock 100 ADA for 1 hour from now
const oneHourFromNow = Date.now() + 3600000;
lockVesting("100000000", oneHourFromNow, "addr_test1...");
```

**Off-Chain Unlock Script:**

```typescript
import {
  deserializeAddress,
  unixTimeToEnclosingSlot,
  SLOT_CONFIG_NETWORK,
} from "@meshsdk/core";
import { getTxBuilder, wallet, getUtxoByTxHash } from "./common";

async function unlockVesting(vestingTxHash: string) {
  const utxos = await wallet.getUtxos();
  const beneficiaryAddress = (await wallet.getUsedAddresses())[0];
  const collateral = (await wallet.getCollateral())[0];

  const beneficiaryPubKeyHash = deserializeAddress(beneficiaryAddress).pubKeyHash;
  const scriptUtxo = await getUtxoByTxHash(vestingTxHash);

  // Extract lock_until from datum
  const lockUntil = scriptUtxo.output.plutusData.fields[0].int;

  // Set validity range (must be after lock time)
  const invalidBefore = unixTimeToEnclosingSlot(
    lockUntil,
    SLOT_CONFIG_NETWORK.preview
  ) + 1;

  const txBuilder = getTxBuilder();
  await txBuilder
    .spendingPlutusScript("V3")
    .txIn(
      scriptUtxo.input.txHash,
      scriptUtxo.input.outputIndex,
      scriptUtxo.output.amount,
      scriptUtxo.output.address
    )
    .txInScript("...scriptCbor...") // Your compiled script
    .txInInlineDatumPresent()
    .txInRedeemerValue("") // Empty redeemer
    .invalidBefore(invalidBefore) // Critical: sets lower bound
    .requiredSignerHash(beneficiaryPubKeyHash)
    .changeAddress(beneficiaryAddress)
    .txInCollateral(
      collateral.input.txHash,
      collateral.input.outputIndex,
      collateral.output.amount,
      collateral.output.address
    )
    .selectUtxosFrom(utxos)
    .complete();

  const unsignedTx = txBuilder.txHex;
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);

  console.log(`Vesting unlocked: ${txHash}`);
}
```

### 6.2 Example 2: NFT Gift Card

**Use Case:** Mint an NFT that acts as a gift card. Burn the NFT to unlock locked funds.

**Architecture:**
1. **Minting Policy:** Controls NFT creation (only 1 can be minted)
2. **Spending Validator:** Holds locked assets, released when NFT is burned

**Aiken Code (simplified):**

```aiken
// Minting Policy
validator gift_card(utxo_ref: OutputReference) {
  mint(redeemer: Action, _policy_id: PolicyId, self: Transaction) {
    when redeemer is {
      // Mint: Check that specific UTxO is spent
      Mint -> list.any(self.inputs, fn(i) { i.output_reference == utxo_ref })
      
      // Burn: Just verify presence of NFT in transaction
      Burn -> True
    }
  }
}

// Spending Validator
validator redeem(token_policy: PolicyId, token_name: AssetName) {
  spend(_datum, _redeemer, _ref, self: Transaction) {
    // Funds can only be unlocked if NFT is being burned
    let token_id = token_policy ++ token_name
    expect [(burned_policy, burned_name, amount)] = 
      self.mint |> assets.to_list()
    
    amount == -1 && burned_policy == token_policy && burned_name == token_name
  }
}
```

**Off-Chain: Create Gift Card**

```typescript
import { fromText, mConStr0 } from "@meshsdk/core";
import { getTxBuilder, wallet } from "./common";

async function createGiftCard(
  tokenName: string,
  lockedAmount: string
) {
  const utxos = await wallet.getUtxos();
  const walletAddress = (await wallet.getUsedAddresses())[0];
  const collateral = (await wallet.getCollateral())[0];

  // Use first UTxO as reference for one-time minting
  const utxoRef = utxos[0].input;

  // Apply parameters to minting policy
  const mintingScriptCbor = applyParamsToScript(
    mintingBlueprint.validators[0].compiledCode,
    [utxoRef.txHash, utxoRef.outputIndex]
  );

  const policyId = serializePlutusScript(
    { code: mintingScriptCbor, version: "V3" }
  ).hash;

  const assetName = fromText(tokenName);
  const assetId = `${policyId}${assetName}`;

  // Apply parameters to spending validator (policyId + token name)
  const spendingScriptCbor = applyParamsToScript(
    spendingBlueprint.validators[0].compiledCode,
    [policyId, assetName]
  );

  const scriptAddr = serializePlutusScript(
    { code: spendingScriptCbor, version: "V3" }
  ).address;

  // Build transaction: mint NFT AND lock funds
  const txBuilder = getTxBuilder();
  await txBuilder
    // Mint the NFT
    .mintPlutusScript("V3")
    .mint("1", policyId, assetName)
    .mintingScript(mintingScriptCbor)
    .mintRedeemerValue(mConStr0([])) // Mint redeemer
    // Lock the funds
    .txOut(scriptAddr, [{ unit: "lovelace", quantity: lockedAmount }])
    .txOutInlineDatumValue("") // Empty datum
    // Spend the reference UTxO
    .txIn(
      utxoRef.txHash,
      utxoRef.outputIndex,
      utxos[0].output.amount,
      utxos[0].output.address
    )
    .changeAddress(walletAddress)
    .txInCollateral(
      collateral.input.txHash,
      collateral.input.outputIndex,
      collateral.output.amount,
      collateral.output.address
    )
    .selectUtxosFrom(utxos)
    .complete();

  const unsignedTx = txBuilder.txHex;
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);

  console.log(`Gift card created: ${txHash}`);
  console.log(`NFT Asset ID: ${assetId}`);
  
  return { txHash, assetId, scriptAddr };
}
```

**Off-Chain: Redeem Gift Card**

```typescript
import { fromText, mConStr1 } from "@meshsdk/core";
import { getTxBuilder, wallet } from "./common";

async function redeemGiftCard(
  policyId: string,
  tokenName: string,
  scriptAddress: string,
  scriptCbor: string,
  mintingScriptCbor: string
) {
  const utxos = await wallet.getUtxos();
  const walletAddress = (await wallet.getUsedAddresses())[0];
  const collateral = (await wallet.getCollateral())[0];

  // Find UTxOs at script address
  const scriptUtxos = await blockchainProvider.fetchAddressUTxOs(scriptAddress);

  const assetName = fromText(tokenName);
  const assetId = `${policyId}${assetName}`;

  // Build transaction: burn NFT AND unlock funds
  const txBuilder = getTxBuilder();
  await txBuilder
    // Spend from script
    .spendingPlutusScript("V3")
    .txIn(
      scriptUtxos[0].input.txHash,
      scriptUtxos[0].input.outputIndex,
      scriptUtxos[0].output.amount,
      scriptAddress
    )
    .txInScript(scriptCbor)
    .txInInlineDatumPresent()
    .txInRedeemerValue("") // Empty redeemer
    // Burn the NFT
    .mintPlutusScript("V3")
    .mint("-1", policyId, assetName)
    .mintingScript(mintingScriptCbor)
    .mintRedeemerValue(mConStr1([])) // Burn redeemer (index 1)
    // Complete
    .changeAddress(walletAddress)
    .txInCollateral(
      collateral.input.txHash,
      collateral.input.outputIndex,
      collateral.output.amount,
      collateral.output.address
    )
    .selectUtxosFrom(utxos)
    .complete();

  const unsignedTx = txBuilder.txHex;
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);

  console.log(`Gift card redeemed: ${txHash}`);
}
```

---

## 7. Building a Full-Stack DApp

### 7.1 Architecture Overview

A complete DApp typically includes:

```
┌─────────────────────────────────────────┐
│         Frontend (React/Svelte)         │
│  - Wallet connection                    │
│  - UI for user interactions             │
│  - Transaction building                 │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│       Backend API (Optional)            │
│  - Business logic                       │
│  - Database for off-chain data          │
│  - Monitoring and indexing              │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│    Blockchain Node / API Provider       │
│  - Blockfrost, Koios, or own node       │
│  - Submit transactions                  │
│  - Query chain state                    │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│        Cardano Blockchain               │
│  - Your deployed smart contracts        │
│  - Distributed ledger                   │
└─────────────────────────────────────────┘
```

### 7.2 Frontend Setup (React + Mesh)

**1. Create React App:**

```bash
npx create-react-app my-dapp
cd my-dapp
npm install @meshsdk/core @meshsdk/react
```

**2. Setup Wallet Connection:**

```typescript
// src/App.tsx
import { useState } from 'react';
import { 
  BrowserWallet, 
  BlockfrostProvider,
  MeshTxBuilder 
} from '@meshsdk/core';
import { useWallet } from '@meshsdk/react';

function App() {
  const { wallet, connected, connect } = useWallet();
  const [txHash, setTxHash] = useState<string>("");

  const lockFunds = async () => {
    if (!connected) return;

    const provider = new BlockfrostProvider(
      process.env.REACT_APP_BLOCKFROST_KEY
    );

    const walletAddress = await wallet.getChangeAddress();
    const utxos = await wallet.getUtxos();

    const txBuilder = new MeshTxBuilder({
      fetcher: provider,
      submitter: provider,
    });

    await txBuilder
      .txOut("addr_test1...", [
        { unit: "lovelace", quantity: "5000000" }
      ])
      .txOutInlineDatumValue({ constructor: 0, fields: [] })
      .changeAddress(walletAddress)
      .selectUtxosFrom(utxos)
      .complete();

    const unsignedTx = txBuilder.txHex;
    const signedTx = await wallet.signTx(unsignedTx);
    const hash = await wallet.submitTx(signedTx);
    
    setTxHash(hash);
  };

  return (
    <div className="App">
      <h1>My DApp</h1>
      {!connected ? (
        <button onClick={() => connect('nami')}>
          Connect Wallet
        </button>
      ) : (
        <button onClick={lockFunds}>
          Lock 5 ADA
        </button>
      )}
      {txHash && (
        <p>Transaction: {txHash}</p>
      )}
    </div>
  );
}

export default App;
```

**3. Environment Variables:**

Create `.env` in your React app root:

```env
REACT_APP_BLOCKFROST_KEY=previewYourKeyHere
```

### 7.3 Frontend with SvelteKit (Alternative)

**1. Create SvelteKit App:**

```bash
npm create svelte@latest my-dapp
cd my-dapp
npm install
npm install @meshsdk/core lucid-cardano
```

**2. Create Wallet Store:**

```typescript
// src/lib/stores/wallet.ts
import { writable } from 'svelte/store';
import type { BrowserWallet } from '@meshsdk/core';

export const wallet = writable<BrowserWallet | null>(null);
export const connected = writable<boolean>(false);

export async function connectWallet(walletName: string) {
  const { BrowserWallet } = await import('@meshsdk/core');
  const w = await BrowserWallet.enable(walletName);
  wallet.set(w);
  connected.set(true);
}
```

**3. Create Transaction Page:**

```svelte
<!-- src/routes/+page.svelte -->
<script lang="ts">
  import { wallet, connected, connectWallet } from '$lib/stores/wallet';
  import { BlockfrostProvider, MeshTxBuilder } from '@meshsdk/core';
  
  let txHash = '';
  
  async function lockFunds() {
    if (!$wallet) return;
    
    const provider = new BlockfrostProvider(
      import.meta.env.VITE_BLOCKFROST_KEY
    );
    
    const address = await $wallet.getChangeAddress();
    const utxos = await $wallet.getUtxos();
    
    const txBuilder = new MeshTxBuilder({
      fetcher: provider,
      submitter: provider,
    });
    
    await txBuilder
      .txOut('addr_test1...', [{ unit: 'lovelace', quantity: '5000000' }])
      .txOutInlineDatumValue({ constructor: 0, fields: [] })
      .changeAddress(address)
      .selectUtxosFrom(utxos)
      .complete();
    
    const unsignedTx = txBuilder.txHex;
    const signedTx = await $wallet.signTx(unsignedTx);
    txHash = await $wallet.submitTx(signedTx);
  }
</script>

<main>
  <h1>My DApp</h1>
  
  {#if !$connected}
    <button on:click={() => connectWallet('nami')}>
      Connect Wallet
    </button>
  {:else}
    <button on:click={lockFunds}>
      Lock 5 ADA
    </button>
  {/if}
  
  {#if txHash}
    <p>Transaction: {txHash}</p>
    <a href="https://preview.cardanoscan.io/transaction/{txHash}" target="_blank">
      View on CardanoScan
    </a>
  {/if}
</main>
```

### 7.4 Backend API (Optional)

Many DApps don't need a backend, but if you do:

**Use Cases for Backend:**
- Store user preferences/data off-chain
- Index blockchain data for faster queries
- Handle complex business logic
- Send notifications
- Batch process transactions

**Example Express.js Backend:**

```typescript
// server.ts
import express from 'express';
import { BlockfrostProvider } from '@meshsdk/core';

const app = express();
app.use(express.json());

const provider = new BlockfrostProvider(process.env.BLOCKFROST_KEY);

// Endpoint to get script UTxOs
app.get('/api/script-utxos', async (req, res) => {
  const scriptAddress = req.query.address as string;
  const utxos = await provider.fetchAddressUTxOs(scriptAddress);
  res.json(utxos);
});

// Endpoint to monitor transaction
app.get('/api/tx-status/:txHash', async (req, res) => {
  try {
    const status = await provider.fetchTxInfo(req.params.txHash);
    res.json({ confirmed: true, ...status });
  } catch {
    res.json({ confirmed: false });
  }
});

app.listen(3001, () => {
  console.log('Backend running on port 3001');
});
```

### 7.5 Complete Project Structure

```
my-dapp/
├── aiken/                      # Aiken smart contracts
│   ├── validators/
│   │   └── my_validator.ak
│   ├── aiken.toml
│   └── plutus.json            # Generated blueprint
│
├── frontend/                   # React/Svelte app
│   ├── src/
│   │   ├── components/
│   │   │   ├── WalletConnect.tsx
│   │   │   └── TransactionForm.tsx
│   │   ├── hooks/
│   │   │   └── useContract.ts
│   │   ├── utils/
│   │   │   ├── contract.ts    # Load blueprint, get addresses
│   │   │   └── transactions.ts # Transaction builders
│   │   └── App.tsx
│   ├── public/
│   │   └── plutus.json        # Copy from aiken/
│   └── package.json
│
├── backend/ (optional)
│   ├── src/
│   │   ├── routes/
│   │   └── services/
│   └── package.json
│
└── scripts/                    # Deployment scripts
    ├── deploy.ts
    ├── test-lock.ts
    └── test-unlock.ts
```

### 7.6 Deployment Checklist

**Pre-Deployment:**
- [ ] All Aiken tests pass
- [ ] Off-chain tests complete
- [ ] Security audit (for production)
- [ ] Document all contract interactions
- [ ] Test on Preview Testnet
- [ ] Verify transaction fees are acceptable

**Mainnet Deployment:**
- [ ] Change `networkId` to `1`
- [ ] Update Blockfrost to mainnet API
- [ ] Test with small amounts first
- [ ] Monitor transactions closely
- [ ] Have rollback plan ready

**Post-Deployment:**
- [ ] Document all deployed addresses/policy IDs
- [ ] Set up monitoring/alerts
- [ ] Create user documentation
- [ ] Announce to users
- [ ] Continue monitoring

---

## Summary

You've now learned the complete flow from Aiken contract to production DApp:

1. **Write & Compile** → `aiken build` generates `plutus.json`
2. **Extract Info** → Get validator code, hashes, schemas from blueprint
3. **Generate Identifiers** → Create script addresses and policy IDs
4. **Build Transactions** → Lock, unlock, mint, burn using transaction builders
5. **Frontend Integration** → Connect wallets, build UIs, submit transactions
6. **Full-Stack** → Optionally add backend for enhanced features

### Key Takeaways

- **Blueprint is your interface** between on-chain and off-chain code
- **Script addresses** come from spending validators
- **Policy IDs** come from minting validators  
- **Datums** lock funds, **redeemers** unlock them
- **Constructor indexing** maps Aiken types to off-chain data structures
- **Test thoroughly** on Preview Testnet before mainnet

### Additional Resources

- [Aiken Documentation](https://aiken-lang.org/)
- [Mesh SDK Docs](https://meshjs.dev/)
- [Lucid Evolution](https://anastasia-labs.github.io/lucid-evolution/)
- [Cardano Docs](https://docs.cardano.org/)
- [CIPs (Cardano Improvement Proposals)](https://cips.cardano.org/)

---

**Happy Building! 🚀**
