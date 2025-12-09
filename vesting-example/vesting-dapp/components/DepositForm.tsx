"use client";

import { useState } from "react";

interface DepositFormProps {
  scriptAddress: string;
  onSuccess?: () => void | Promise<void>;
}

export default function DepositForm({
  scriptAddress,
  onSuccess,
}: DepositFormProps) {
  const [amount, setAmount] = useState("3");
  const [lockMinutes, setLockMinutes] = useState("15");
  const [status, setStatus] = useState<{
    type: "idle" | "pending" | "success" | "error";
    message?: string;
  }>({ type: "idle" });

  const disabled = status.type === "pending";

  const submit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setStatus({ type: "pending" });
    try {
      const response = await fetch("/api/vesting/deposit", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          amountAda: amount,
          lockDurationMinutes: lockMinutes,
        }),
      });
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error ?? "Failed to deposit funds");
      }
      setStatus({
        type: "success",
        message: `Deposited ${payload.amountLabel} until ${new Date(
          payload.lockUntil,
        ).toLocaleString()}`,
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
      <h2 className="text-xl font-semibold text-white">Lock funds</h2>
      <p className="mt-2 text-sm text-white/70">
        Send ADA from the owner wallet into the vesting script at
        <br />
        <code className="text-xs text-white/90">{scriptAddress.slice(0, 32)}…</code>
      </p>
      <form className="mt-6 space-y-4" onSubmit={submit}>
        <label className="block text-sm text-white/80">
          Amount (ADA)
          <input
            type="number"
            min="1"
            step="0.5"
            value={amount}
            onChange={(event) => setAmount(event.target.value)}
            className="mt-1 w-full rounded-2xl border border-white/10 bg-black/40 px-4 py-2 text-white focus:border-emerald-400/70 focus:outline-none"
            required
          />
        </label>
        <label className="block text-sm text-white/80">
          Cliff (minutes)
          <input
            type="number"
            min="1"
            step="1"
            value={lockMinutes}
            onChange={(event) => setLockMinutes(event.target.value)}
            className="mt-1 w-full rounded-2xl border border-white/10 bg-black/40 px-4 py-2 text-white focus:border-emerald-400/70 focus:outline-none"
            required
          />
        </label>
        <button
          type="submit"
          disabled={disabled}
          className="w-full rounded-full bg-emerald-400/90 py-3 text-center text-sm font-semibold uppercase tracking-wide text-emerald-950 transition hover:bg-emerald-300 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {status.type === "pending" ? "Submitting…" : "Deposit to script"}
        </button>
      </form>
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

