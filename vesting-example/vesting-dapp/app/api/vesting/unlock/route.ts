import { NextResponse } from "next/server";
import { z } from "zod";

import { unlockFunds } from "@/lib/vesting";

export const runtime = "nodejs";

const unlockSchema = z.object({
  txHash: z
    .string()
    .regex(/^[0-9a-f]+$/i, "txHash must be hex encoded")
    .length(64, "txHash must be 64 hex characters"),
  outputIndex: z.coerce.number().int().min(0).optional(),
});

export async function POST(request: Request) {
  try {
    const payload = await request.json();
    const data = unlockSchema.parse(payload);
    const result = await unlockFunds(data);
    return NextResponse.json(result);
  } catch (error) {
    console.error("Unlock failed", error);
    const message =
      error instanceof z.ZodError
        ? error.errors.map((e) => e.message).join(", ")
        : error instanceof Error
          ? error.message
          : "Unknown error";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}

