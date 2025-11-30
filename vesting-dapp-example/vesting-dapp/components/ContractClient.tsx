"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { formatAda, formatRelative, formatTimestamp } from "@/lib/format";
import type { ContractState } from "@/lib/types";

import DepositForm from "./DepositForm";
import UnlockForm from "./UnlockForm";
import UtxoTable from "./UtxoTable";

interface ContractClientProps {
  initialState: ContractState;
}

export default function ContractClient({ initialState }: ContractClientProps) {
  const [state, setState] = useState(initialState);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refreshState = useCallback(async () => {
    setRefreshing(true);
    setError(null);
    try {
      const response = await fetch("/api/vesting/state", {
        cache: "no-store",
      });
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error ?? "Failed to refresh contract state");
      }
      setState(payload as ContractState);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unexpected error");
    } finally {
      setRefreshing(false);
    }
  }, []);

  const stats = useMemo(
    () => [
      {
        label: "Script balance",
        value: formatAda(state.scriptBalance),
      },
      {
        label: "Active vestings",
        value: state.totalVestingOutputs.toString(),
      },
      {
        label: "Next unlock",
        value: formatTimestamp(state.nextUnlock),
        footnote: formatRelative(state.nextUnlock),
      },
    ],
    [state],
  );

  useEffect(() => {
    setState(initialState);
  }, [initialState]);

  return (
    <section className="space-y-6">
      <div className="rounded-3xl border border-white/10 bg-white/5 p-6 shadow-2xl shadow-emerald-500/10 backdrop-blur">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-sm uppercase tracking-wide text-white/60">
              Network
            </p>
            <p className="text-2xl font-semibold text-white">
              {state.network.toUpperCase()}
            </p>
            <p className="text-sm text-white/60">
              Blueprint hash {state.blueprintHash.slice(0, 12)}…
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <RefreshButton loading={refreshing} onClick={refreshState} />
            {error ? (
              <span className="text-sm text-red-300">{error}</span>
            ) : (
              <span className="text-sm text-white/60">
                Updated {formatRelative(Date.parse(state.fetchedAt))}
              </span>
            )}
          </div>
        </div>

        <div className="mt-8 grid gap-4 sm:grid-cols-3">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className="rounded-2xl border border-white/10 bg-white/5 p-4"
            >
              <p className="text-xs uppercase tracking-widest text-white/60">
                {stat.label}
              </p>
              <p className="mt-2 text-2xl font-semibold text-white">
                {stat.value}
              </p>
              {stat.footnote ? (
                <p className="text-xs text-white/60">{stat.footnote}</p>
              ) : null}
            </div>
          ))}
        </div>

        <div className="mt-8 grid gap-4 lg:grid-cols-2">
          <AddressCard
            label="Owner wallet"
            address={state.ownerAddress}
            description="Deposits funds into the vesting script."
          />
          <AddressCard
            label="Beneficiary wallet"
            address={state.beneficiaryAddress}
            description="Unlocks funds after the cliff."
          />
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <DepositForm
          scriptAddress={state.scriptAddress}
          onSuccess={refreshState}
        />
        <UnlockForm availableUtxos={state.utxos} onSuccess={refreshState} />
      </div>

      <UtxoTable
        utxos={state.utxos}
        scriptAddress={state.scriptAddress}
        onRefresh={refreshState}
        refreshing={refreshing}
        referenceTime={Date.parse(state.fetchedAt)}
      />
    </section>
  );
}

function RefreshButton({
  loading,
  onClick,
}: {
  loading: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={loading}
      className="inline-flex items-center justify-center rounded-full border border-emerald-400/70 px-4 py-2 text-sm font-medium text-emerald-100 transition hover:bg-emerald-400/10 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {loading ? "Refreshing..." : "Refresh state"}
    </button>
  );
}

function AddressCard({
  label,
  address,
  description,
}: {
  label: string;
  address?: string | null;
  description: string;
}) {
  const hasAddress = Boolean(address);
  const displayText = hasAddress
    ? `${address!.slice(0, 24)}…`
    : "Set wallet keys in .env.local";
  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
      <p className="text-xs uppercase tracking-widest text-white/60">{label}</p>
      <div className="mt-2 flex items-center gap-2">
        <code className="truncate text-sm text-white/90">{displayText}</code>
        <CopyButton value={hasAddress ? address! : undefined} />
      </div>
      <p className="mt-2 text-sm text-white/60">{description}</p>
    </div>
  );
}

function CopyButton({ value }: { value?: string }) {
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    if (!value) return;
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (error) {
      console.error("Clipboard error", error);
    }
  };

  return (
    <button
      type="button"
      onClick={copy}
      disabled={!value}
      className="rounded-full border border-white/20 px-3 py-1 text-xs font-medium text-white/80 hover:bg-white/10 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {copied ? "Copied" : value ? "Copy" : "No key"}
    </button>
  );
}

