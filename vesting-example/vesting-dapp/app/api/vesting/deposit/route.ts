import { NextResponse } from "next/server";
import { z } from "zod";

import { depositFunds } from "@/lib/vesting";

export const runtime = "nodejs";

const depositSchema = z.object({
  amountAda: z.coerce.number().positive(),
  lockDurationMinutes: z.coerce.number().int().min(1).max(60 * 24 * 30),
});

export async function POST(request: Request) {
  try {
    const payload = await request.json();
    const data = depositSchema.parse(payload);
    const result = await depositFunds(data);
    return NextResponse.json(result);
  } catch (error) {
    console.error("Deposit failed", error);
    const message =
      error instanceof z.ZodError
        ? error.errors.map((e) => e.message).join(", ")
        : error instanceof Error
          ? error.message
          : "Unknown error";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}

