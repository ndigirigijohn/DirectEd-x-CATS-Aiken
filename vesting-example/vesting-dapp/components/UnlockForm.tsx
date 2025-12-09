"use client";

import { useEffect, useMemo, useState } from "react";

import { formatAda, formatRelative, formatTimestamp } from "@/lib/format";
import type { VestingUtxo } from "@/lib/types";

interface UnlockFormProps {
  availableUtxos: VestingUtxo[];
  onSuccess?: () => void | Promise<void>;
}

export default function UnlockForm({
  availableUtxos,
  onSuccess,
}: UnlockFormProps) {
  const options = useMemo(
    () =>
      availableUtxos.map((utxo) => ({
        key: `${utxo.input.txHash}#${utxo.input.outputIndex}`,
        label: `${utxo.input.txHash.slice(0, 10)}…#${
          utxo.input.outputIndex
        } • ${formatAda(utxo.lovelace)} • unlocks ${formatRelative(
          utxo.datum?.lockUntil,
        )}`,
        txHash: utxo.input.txHash,
        outputIndex: utxo.input.outputIndex,
        lockUntil: utxo.datum?.lockUntil,
      })),
    [availableUtxos],
  );

  const [selected, setSelected] = useState(options[0]);
  const [txHash, setTxHash] = useState(selected?.txHash ?? "");
  const [outputIndex, setOutputIndex] = useState(
    selected?.outputIndex?.toString() ?? "",
  );
  const [status, setStatus] = useState<{
    type: "idle" | "pending" | "success" | "error";
    message?: string;
  }>({ type: "idle" });

  useEffect(() => {
    setSelected(options[0]);
    setTxHash(options[0]?.txHash ?? "");
    setOutputIndex(
      typeof options[0]?.outputIndex === "number"
        ? options[0]?.outputIndex.toString()
        : "",
    );
  }, [options]);

  const disabled = status.type === "pending" || !txHash;

  const submit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!txHash) return;
    setStatus({ type: "pending" });
    try {
      const body = {
        txHash,
        outputIndex: outputIndex === "" ? undefined : Number(outputIndex),
      };
      const response = await fetch("/api/vesting/unlock", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error ?? "Failed to unlock funds");
      }
      setStatus({
        type: "success",
        message: `Unlock submitted (${payload.txHash.slice(
          0,
          10,
        )}…). Funds become spendable after slot ${payload.invalidBefore}.`,
      });
      await onSuccess?.();
    } catch (error) {
      setStatus({
        type: "error",
        message:
          error instanceof Error ? error.message : "Unexpected error occured",
      });
    }
  };

  return (
    <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur">
      <h2 className="text-xl font-semibold text-white">Unlock funds</h2>
      <p className="mt-2 text-sm text-white/70">
        Select a vested output and submit a transaction with the beneficiary
        wallet.
      </p>

      <form className="mt-6 space-y-4" onSubmit={submit}>
        <label className="block text-sm text-white/80">
          Script UTxO
          <select
            className="mt-1 w-full rounded-2xl border border-white/10 bg-black/40 px-4 py-2 text-white focus:border-emerald-400/70 focus:outline-none"
            value={selected?.key ?? ""}
            onChange={(event) => {
              const option = options.find((opt) => opt.key === event.target.value);
              setSelected(option);
              setTxHash(option?.txHash ?? "");
              setOutputIndex(
                typeof option?.outputIndex === "number"
                  ? option.outputIndex.toString()
                  : "",
              );
            }}
            disabled={!options.length}
          >
            {options.length === 0 ? (
              <option value="">No locked outputs detected</option>
            ) : (
              options.map((option) => (
                <option key={option.key} value={option.key}>
                  {option.label}
                </option>
              ))
            )}
          </select>
        </label>

        <div className="grid gap-4 sm:grid-cols-2">
          <label className="block text-sm text-white/80">
            txHash
            <input
              type="text"
              value={txHash}
              onChange={(event) => setTxHash(event.target.value)}
              className="mt-1 w-full rounded-2xl border border-white/10 bg-black/40 px-4 py-2 text-white focus:border-emerald-400/70 focus:outline-none"
              placeholder="64-char hex"
              required
            />
          </label>
          <label className="block text-sm text-white/80">
            Output index
            <input
              type="number"
              min="0"
              step="1"
              value={outputIndex}
              onChange={(event) => setOutputIndex(event.target.value)}
              className="mt-1 w-full rounded-2xl border border-white/10 bg-black/40 px-4 py-2 text-white focus:border-emerald-400/70 focus:outline-none"
              required
            />
          </label>
        </div>

        <button
          type="submit"
          disabled={disabled}
          className="w-full rounded-full border border-white/20 py-3 text-center text-sm font-semibold uppercase tracking-wide text-white transition hover:bg-white/10 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {status.type === "pending" ? "Submitting…" : "Unlock to beneficiary"}
        </button>
      </form>

      {selected?.lockUntil ? (
        <p className="mt-2 text-xs text-white/60">
          Unlock after {formatTimestamp(selected.lockUntil)} (
          {formatRelative(selected.lockUntil)})
        </p>
      ) : null}

      {status.type !== "idle" ? (
        <p
          className={`mt-3 text-sm ${
            status.type === "success" ? "text-emerald-200" : "text-red-300"
          }`}
        >
          {status.message}
        </p>
      ) : null}
    </div>
  );
}

