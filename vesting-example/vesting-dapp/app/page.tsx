import ContractClient from "@/components/ContractClient";
import { getContractState } from "@/lib/vesting";

export default async function Home() {
  const initialState = await getContractState();

  return (
    <div className="min-h-screen bg-[#020617]">
      <div className="relative isolate overflow-hidden">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(16,185,129,0.15),_transparent_50%)]" />
        <div className="mx-auto max-w-6xl px-6 py-12 sm:py-16">
          <header className="space-y-4 text-white">
            <p className="text-sm uppercase tracking-[0.4em] text-emerald-200/80">
              Vesting • Aiken • MeshSDK
            </p>
            <h1 className="text-4xl font-semibold leading-tight sm:text-5xl">
              Next.js dashboard for the Aiken vesting contract
            </h1>
            <p className="max-w-3xl text-lg text-white/70">
              Lock ADA with the owner wallet, track live script UTxOs, and unlock
              funds with the beneficiary once the cliff expires. Powered by
              Blockfrost and Mesh SDK server-side actions.
            </p>
          </header>

          <div className="mt-8">
            <ContractClient initialState={initialState} />
          </div>
        </div>
      </div>
    </div>
  );
}
