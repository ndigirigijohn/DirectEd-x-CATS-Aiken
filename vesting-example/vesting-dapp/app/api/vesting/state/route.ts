import { NextResponse } from "next/server";

import { getContractState } from "@/lib/vesting";

export const runtime = "nodejs";

export async function GET() {
  try {
    const state = await getContractState();
    return NextResponse.json(state);
  } catch (error) {
    console.error("Failed to read contract state", error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Unknown error" },
      { status: 500 },
    );
  }
}

