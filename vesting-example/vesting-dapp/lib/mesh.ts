import fs from "node:fs";

import {
  BlockfrostProvider,
  MeshTxBuilder,
  MeshWallet,
  serializePlutusScript,
} from "@meshsdk/core";

import { getEnv } from "./env";

const env = getEnv();
const blueprint = JSON.parse(fs.readFileSync(env.blueprintPath, "utf8"));

const scriptCbor = blueprint.validators?.[0]?.compiledCode;

if (!scriptCbor) {
  throw new Error(
    `Blueprint at ${env.blueprintPath} does not include any validators.`,
  );
}

const blockfrostProvider = new BlockfrostProvider(env.blockfrostApiKey);

const ownerWallet = new MeshWallet({
  networkId: env.networkId,
  fetcher: blockfrostProvider,
  submitter: blockfrostProvider,
  key: {
    type: "root",
    bech32: env.ownerRootKey,
  },
});

const beneficiaryWallet = new MeshWallet({
  networkId: env.networkId,
  fetcher: blockfrostProvider,
  submitter: blockfrostProvider,
  key: {
    type: "root",
    bech32: env.beneficiaryRootKey,
  },
});

const scriptAddress = serializePlutusScript(
  { code: scriptCbor, version: "V3" },
  undefined,
  env.networkId,
).address;

export function getTxBuilder(verbose = false) {
  return new MeshTxBuilder({
    fetcher: blockfrostProvider,
    submitter: blockfrostProvider,
    verbose,
  });
}

export function getOwnerWallet() {
  return ownerWallet;
}

export function getBeneficiaryWallet() {
  return beneficiaryWallet;
}

export function getScriptCbor() {
  return scriptCbor;
}

export function getScriptAddress() {
  return scriptAddress;
}

export function getBlueprint() {
  return blueprint;
}

