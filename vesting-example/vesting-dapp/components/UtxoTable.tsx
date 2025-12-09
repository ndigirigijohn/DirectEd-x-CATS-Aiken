import { formatAda, formatRelative, formatTimestamp } from "@/lib/format";
import type { VestingUtxo } from "@/lib/types";

interface Props {
  utxos: VestingUtxo[];
  scriptAddress: string;
  onRefresh: () => void;
  refreshing: boolean;
  referenceTime: number;
}

export default function UtxoTable({
  utxos,
  scriptAddress,
  onRefresh,
  refreshing,
  referenceTime,
}: Props) {
  return (
    <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-semibold text-white">
            Script UTxOs ({utxos.length})
          </h2>
          <p className="text-sm text-white/70">
            {scriptAddress.slice(0, 24)}…
          </p>
        </div>
        <button
          type="button"
          onClick={onRefresh}
          disabled={refreshing}
          className="rounded-full border border-white/20 px-4 py-2 text-sm text-white/80 hover:bg-white/10 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {refreshing ? "Updating…" : "Refresh"}
        </button>
      </div>

      {utxos.length === 0 ? (
        <p className="mt-6 text-sm text-white/70">
          No funds are currently locked in the contract.
        </p>
      ) : (
        <div className="mt-6 overflow-x-auto">
          <table className="min-w-full text-left text-sm text-white/80">
            <thead className="text-xs uppercase tracking-wide text-white/60">
              <tr>
                <th className="pb-3 pr-6">txHash#index</th>
                <th className="pb-3 pr-6">Amount</th>
                <th className="pb-3 pr-6">Unlocks</th>
                <th className="pb-3">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/10">
              {utxos.map((utxo) => {
                const isUnlockable =
                  (utxo.datum?.lockUntil ?? 0) <= referenceTime;
                return (
                  <tr key={`${utxo.input.txHash}-${utxo.input.outputIndex}`}>
                    <td className="py-3 pr-6 font-mono text-xs text-white/80">
                      {utxo.input.txHash.slice(0, 10)}…#{utxo.input.outputIndex}
                    </td>
                    <td className="py-3 pr-6 text-white">
                      {formatAda(utxo.lovelace)}
                    </td>
                    <td className="py-3 pr-6 text-white/80">
                      {formatTimestamp(utxo.datum?.lockUntil)}
                      <span className="block text-xs text-white/50">
                        {formatRelative(utxo.datum?.lockUntil)}
                      </span>
                    </td>
                    <td className="py-3">
                      <span
                        className={`rounded-full px-3 py-1 text-xs font-semibold ${
                          isUnlockable
                            ? "bg-emerald-400/20 text-emerald-200"
                            : "bg-white/10 text-white/70"
                        }`}
                      >
                        {isUnlockable ? "Unlockable" : "Locked"}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

