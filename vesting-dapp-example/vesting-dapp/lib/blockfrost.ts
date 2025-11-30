import { getEnv } from "./env";
import type { AssetAmount, MeshUTxO } from "./types";

export interface RawBlockfrostUTxO {
  tx_hash: string;
  output_index: number;
  amount: AssetAmount[];
  inline_datum?: string | null;
  data_hash?: string | null;
  address: string;
}

async function blockfrostFetch<T>(
  path: string,
  init?: RequestInit,
  treat404AsEmpty = false,
): Promise<T> {
  const env = getEnv();
  const response = await fetch(`${env.blockfrostBaseUrl}${path}`, {
    ...init,
    cache: "no-store",
    headers: {
      project_id: env.blockfrostApiKey,
      ...(init?.headers ?? {}),
    },
  });

  if (response.status === 404 && treat404AsEmpty) {
    return [] as unknown as T;
  }

  if (!response.ok) {
    const message = await response.text();
    throw new Error(
      `Blockfrost request failed (${response.status}): ${message}`,
    );
  }

  return response.json();
}

export function normalizeUtxo(raw: RawBlockfrostUTxO): MeshUTxO {
  return {
    input: {
      txHash: raw.tx_hash,
      outputIndex: raw.output_index,
    },
    output: {
      address: raw.address,
      amount: raw.amount,
      plutusData: raw.inline_datum ?? raw.data_hash ?? null,
    },
  };
}

export async function fetchAddressUtxos(address: string): Promise<MeshUTxO[]> {
  const payload = await blockfrostFetch<RawBlockfrostUTxO[]>(
    `/addresses/${address}/utxos`,
    undefined,
    true,
  );
  return payload.map(normalizeUtxo);
}

interface RawTxOutput {
  output_index: number;
  amount: AssetAmount[];
  inline_datum?: string | null;
  data_hash?: string | null;
  address: string;
}

export async function fetchTxOutputs(txHash: string) {
  const payload = await blockfrostFetch<{ outputs: RawTxOutput[] }>(
    `/txs/${txHash}/utxos`,
  );
  return payload.outputs.map((output) => ({
    input: {
      txHash,
      outputIndex: output.output_index,
    },
    output: {
      address: output.address,
      amount: output.amount,
      plutusData: output.inline_datum ?? output.data_hash ?? null,
    },
  }));
}

