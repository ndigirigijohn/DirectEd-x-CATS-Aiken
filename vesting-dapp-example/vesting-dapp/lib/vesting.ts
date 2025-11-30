import {
  deserializeAddress,
  deserializeDatum,
  SLOT_CONFIG_NETWORK,
  unixTimeToEnclosingSlot,
} from "@meshsdk/core";
import { mConStr0 } from "@meshsdk/common";

import { fetchAddressUtxos, fetchTxOutputs } from "./blockfrost";
import { getEnv } from "./env";
import { formatAda } from "./format";
import {
  getBeneficiaryWallet,
  getBlueprint,
  getOwnerWallet,
  getScriptAddress,
  getScriptCbor,
  getTxBuilder,
} from "./mesh";
import type {
  ContractState,
  DepositRequest,
  MeshUTxO,
  UnlockRequest,
  VestingDatum,
  VestingUtxo,
} from "./types";

const env = getEnv();

const slotConfigMap = {
  preview: SLOT_CONFIG_NETWORK.preview,
  preprod: SLOT_CONFIG_NETWORK.preprod,
  mainnet: SLOT_CONFIG_NETWORK.mainnet,
};

function decodeDatum(plutusData?: string | null): VestingDatum | null {
  if (!plutusData) return null;
  const datum = deserializeDatum(plutusData);
  if (!datum || !Array.isArray(datum.fields) || datum.fields.length < 3) {
    return null;
  }

  const [lockUntil, owner, beneficiary] = datum.fields;
  return {
    lockUntil: Number(lockUntil?.int ?? 0),
    ownerPkh: owner?.bytes ?? "",
    beneficiaryPkh: beneficiary?.bytes ?? "",
  };
}

function enrichUtxo(utxo: MeshUTxO): VestingUtxo {
  const lovelace =
    utxo.output.amount.find((a) => a.unit === "lovelace")?.quantity ?? "0";
  const datum = decodeDatum(utxo.output.plutusData);
  return {
    ...utxo,
    lovelace,
    datum,
  };
}

export async function getContractState(): Promise<ContractState> {
  const ownerWallet = getOwnerWallet();
  const beneficiaryWallet = getBeneficiaryWallet();
  const scriptAddress = getScriptAddress();

  const utxosRaw = await fetchAddressUtxos(scriptAddress);
  const utxos: VestingUtxo[] = utxosRaw.map(enrichUtxo);

  const scriptBalance = utxos.reduce(
    (acc, curr) => acc + BigInt(curr.lovelace),
    BigInt(0),
  );

  const validLocks = utxos
    .map((u) => u.datum?.lockUntil)
    .filter((value): value is number => typeof value === "number" && value > 0)
    .sort((a, b) => a - b);

  const blueprint = getBlueprint();

  return {
    scriptAddress,
    ownerAddress: ownerWallet.addresses.baseAddressBech32,
    beneficiaryAddress: beneficiaryWallet.addresses.baseAddressBech32,
    network: env.networkName,
    blueprintHash: blueprint.validators?.[0]?.hash ?? "unknown",
    scriptBalance: scriptBalance.toString(),
    totalVestingOutputs: utxos.length,
    nextUnlock: validLocks[0] ?? null,
    utxos,
    fetchedAt: new Date().toISOString(),
  };
}

function assertPositive(value: number, label: string) {
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`${label} must be greater than zero.`);
  }
}

export async function depositFunds(request: DepositRequest) {
  assertPositive(request.amountAda, "Amount");
  assertPositive(request.lockDurationMinutes, "Lock duration");

  const ownerWallet = getOwnerWallet();
  const beneficiaryWallet = getBeneficiaryWallet();
  const scriptAddress = getScriptAddress();

  const ownerAddress = ownerWallet.addresses.baseAddressBech32;
  const ownerUtxos = await fetchAddressUtxos(ownerAddress);

  if (!ownerUtxos.length) {
    throw new Error(
      "Owner wallet is empty. Fund it before depositing into the contract.",
    );
  }

  const lovelaceAmount = BigInt(
    Math.round(request.amountAda * 1_000_000),
  ).toString();
  const lockUntil = Date.now() + request.lockDurationMinutes * 60_000;

  const { pubKeyHash: ownerPkh } = deserializeAddress(ownerAddress);
  const { pubKeyHash: beneficiaryPkh } = deserializeAddress(
    beneficiaryWallet.addresses.baseAddressBech32,
  );

  const txBuilder = getTxBuilder();
  await txBuilder
    .txOut(scriptAddress, [{ unit: "lovelace", quantity: lovelaceAmount }])
    .txOutInlineDatumValue(
      mConStr0([lockUntil, ownerPkh, beneficiaryPkh]),
    )
    .changeAddress(ownerAddress)
    .selectUtxosFrom(ownerUtxos)
    .complete();

  const signedTx = await ownerWallet.signTx(txBuilder.txHex);
  const txHash = await ownerWallet.submitTx(signedTx);

  return {
    txHash,
    lockUntil,
    amount: lovelaceAmount,
    amountLabel: formatAda(lovelaceAmount),
  };
}

async function findScriptUtxo(
  txHash: string,
  outputIndex?: number,
): Promise<VestingUtxo> {
  const outputs = await fetchTxOutputs(txHash);
  const scriptAddress = getScriptAddress();
  const target = outputs.find((output) =>
    typeof outputIndex === "number"
      ? output.input.outputIndex === outputIndex
      : output.output.address === scriptAddress,
  );

  if (!target) {
    throw new Error(
      `Could not find a script output for ${txHash}. Provide the exact output index if the transaction has multiple script outputs.`,
    );
  }

  if (!target.output.plutusData) {
    throw new Error("Selected output is missing an inline datum.");
  }

  return enrichUtxo(target);
}

export async function unlockFunds(request: UnlockRequest) {
  if (!request.txHash || request.txHash.length < 10) {
    throw new Error("A valid transaction hash is required.");
  }

  const target = await findScriptUtxo(request.txHash, request.outputIndex);

  const beneficiaryWallet = getBeneficiaryWallet();
  const beneficiaryAddress = beneficiaryWallet.addresses.baseAddressBech32;
  const beneficiaryUtxos = await fetchAddressUtxos(beneficiaryAddress);

  if (!beneficiaryUtxos.length) {
    throw new Error(
      "Beneficiary wallet has no ADA to pay fees. Fund it before unlocking.",
    );
  }

  const collateral = await beneficiaryWallet.getCollateral();
  if (!collateral || !collateral.length) {
    throw new Error(
      "Beneficiary wallet has no collateral set. Create a collateral UTxO (5 ADA) first.",
    );
  }

  const datum = target.datum;
  if (!datum?.lockUntil) {
    throw new Error("Unable to read vesting datum from the target output.");
  }

  const slotConfig = slotConfigMap[env.networkName];
  const invalidBefore =
    unixTimeToEnclosingSlot(
      Math.min(datum.lockUntil, Date.now() - 19_000),
      slotConfig,
    ) + 1;

  const { pubKeyHash: beneficiaryPkh } = deserializeAddress(beneficiaryAddress);
  const txBuilder = getTxBuilder();

  const collateralInput = collateral[0].input;
  const collateralOutput = collateral[0].output;

  await txBuilder
    .spendingPlutusScript("V3")
    .txIn(
      target.input.txHash,
      target.input.outputIndex,
      target.output.amount,
      getScriptAddress(),
    )
    .spendingReferenceTxInInlineDatumPresent()
    .spendingReferenceTxInRedeemerValue("")
    .txInScript(getScriptCbor())
    .txOut(beneficiaryAddress, [])
    .txInCollateral(
      collateralInput.txHash,
      collateralInput.outputIndex,
      collateralOutput.amount,
      collateralOutput.address,
    )
    .invalidBefore(invalidBefore)
    .requiredSignerHash(beneficiaryPkh)
    .changeAddress(beneficiaryAddress)
    .selectUtxosFrom(beneficiaryUtxos)
    .complete();

  const signedTx = await beneficiaryWallet.signTx(txBuilder.txHex);
  const txHash = await beneficiaryWallet.submitTx(signedTx);

  return {
    txHash,
    invalidBefore,
    lockUntil: datum.lockUntil,
  };
}

