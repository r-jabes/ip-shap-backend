import { z } from "zod";

/** Integer Rwandan Francs. Never use floating point for money. */
export const moneyRwfSchema = z.object({
  amount: z.number().int().nonnegative(),
  currency: z.literal("RWF"),
});

export type MoneyRwf = z.infer<typeof moneyRwfSchema>;

export const CONTRACT_VERSION = "0.2.0" as const;
