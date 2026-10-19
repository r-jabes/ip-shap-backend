import { z } from "zod";

/** Integer Rwandan Francs. Never use floating point for money. */
export const moneyRwfSchema = z.object({
  amount: z.number().int().nonnegative(),
  currency: z.literal("RWF"),
});

export type MoneyRwf = z.infer<typeof moneyRwfSchema>;

export const CONTRACT_VERSION = "0.7.0" as const;

/** Safe integer multiply for line totals (unit RWF × quantity). */
export function multiplyRwfAmount(
  unitAmount: number,
  quantity: number,
): number {
  if (!Number.isInteger(unitAmount) || unitAmount < 0) {
    throw new Error("Unit amount must be a non-negative integer.");
  }
  if (!Number.isInteger(quantity) || quantity < 0) {
    throw new Error("Quantity must be a non-negative integer.");
  }
  if (
    quantity > 0 &&
    unitAmount > 0 &&
    quantity > Math.floor(Number.MAX_SAFE_INTEGER / unitAmount)
  ) {
    throw new Error("Money overflow.");
  }
  return unitAmount * quantity;
}
