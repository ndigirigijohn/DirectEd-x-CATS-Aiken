export interface AssetAmount {
  unit: string;
  quantity: string;
}

export interface MeshUTxO {
  input: {
    txHash: string;
    outputIndex: number;
  };
  output: {
    address: string;
    amount: AssetAmount[];
    plutusData?: string | null;
  };
}

export interface VestingDatum {
  lockUntil: number;
  ownerPkh: string;
  beneficiaryPkh: string;
}

export interface VestingUtxo extends MeshUTxO {
  lovelace: string;
  datum?: VestingDatum | null;
}

export interface ContractState {
  scriptAddress: string;
  ownerAddress: string;
  beneficiaryAddress: string;
  network: "preview" | "preprod" | "mainnet";
  blueprintHash: string;
  scriptBalance: string;
  totalVestingOutputs: number;
  nextUnlock?: number | null;
  utxos: VestingUtxo[];
  fetchedAt: string;
}

export interface DepositRequest {
  amountAda: number;
  lockDurationMinutes: number;
}

export interface UnlockRequest {
  txHash: string;
  outputIndex?: number;
}

