import fs from "node:fs";
import path from "node:path";

type NetworkName = "preview" | "preprod" | "mainnet";

interface EnvConfig {
  blockfrostApiKey: string;
  blockfrostBaseUrl: string;
  networkName: NetworkName;
  networkId: number;
  ownerRootKey: string;
  beneficiaryRootKey: string;
  blueprintPath: string;
}

const DEFAULT_BLUEPRINT_PATH = "../vesting-sc/plutus.json";
const blockfrostBaseUrls: Record<NetworkName, string> = {
  preview: "https://cardano-preview.blockfrost.io/api/v0",
  preprod: "https://cardano-preprod.blockfrost.io/api/v0",
  mainnet: "https://cardano-mainnet.blockfrost.io/api/v0",
};

let cachedEnv: EnvConfig | null = null;

function requireEnvVar(name: string): string {
  const value = process.env[name];
  if (!value || !value.trim()) {
    throw new Error(`Missing ${name}. Make sure it is defined in .env.local.`);
  }
  return value.trim();
}

function normalizeKeyMaterial(value: string): string {
  return value.replace(/\\n/g, "\n").trim();
}

export function getEnv(): EnvConfig {
  if (cachedEnv) return cachedEnv;

  const networkName =
    ((process.env.CARDANO_NETWORK ?? "preview") as NetworkName);

  if (!["preview", "preprod", "mainnet"].includes(networkName)) {
    throw new Error(
      `Unsupported CARDANO_NETWORK "${networkName}". Use preview, preprod, or mainnet.`,
    );
  }

  const blockfrostApiKey = requireEnvVar("BLOCKFROST_API_KEY");
  if (!blockfrostApiKey) {
    throw new Error("Missing BLOCKFROST_API_KEY. Create one at blockfrost.io.");
  }

  const blockfrostBaseUrl =
    process.env.BLOCKFROST_BASE_URL?.trim() ?? blockfrostBaseUrls[networkName];

  const blueprintPathRaw =
    process.env.BLUEPRINT_PATH?.trim() ?? DEFAULT_BLUEPRINT_PATH;
  const blueprintPath = path.isAbsolute(blueprintPathRaw)
    ? blueprintPathRaw
    : path.resolve(process.cwd(), blueprintPathRaw);

  if (!fs.existsSync(blueprintPath)) {
    throw new Error(
      `Could not find blueprint at ${blueprintPath}. Did you run "aiken build" inside vesting-sc?`,
    );
  }

  cachedEnv = {
    blockfrostApiKey,
    blockfrostBaseUrl,
    networkName,
    networkId: networkName === "mainnet" ? 1 : 0,
    ownerRootKey: normalizeKeyMaterial(requireEnvVar("OWNER_ROOT_KEY")),
    beneficiaryRootKey: normalizeKeyMaterial(
      requireEnvVar("BENEFICIARY_ROOT_KEY"),
    ),
    blueprintPath,
  };

  return cachedEnv;
}

