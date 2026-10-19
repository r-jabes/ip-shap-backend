import { createHmac, timingSafeEqual } from "node:crypto";
import { z } from "zod";
import { moneyRwfSchema } from "./money.js";

export const paymentProviderIdSchema = z.enum(["sandbox", "unselected"]);

export const paymentAttemptStatusSchema = z.enum([
  "unpaid",
  "pending",
  "paid",
  "failed",
  "cancelled",
  "refunded",
]);

export const initiatePaymentRequestSchema = z.object({
  orderId: z.string().uuid(),
  orderReference: z.string().min(1),
  amount: moneyRwfSchema,
  /** Client-generated UUID for provider idempotency. */
  idempotencyKey: z.string().uuid(),
  returnUrl: z.string().url(),
});

export const initiatePaymentResultSchema = z.object({
  provider: paymentProviderIdSchema,
  attemptId: z.string().min(1),
  status: paymentAttemptStatusSchema,
  /** Hosted/redirect URL when applicable. */
  redirectUrl: z.string().url().optional(),
  /** Explicit label — sandbox must never be presented as live. */
  mode: z.enum(["sandbox", "live"]),
});

export const sandboxWebhookEventSchema = z.object({
  id: z.string().min(1),
  type: z.enum([
    "payment.pending",
    "payment.paid",
    "payment.failed",
    "payment.cancelled",
    "payment.refunded",
  ]),
  orderId: z.string().uuid(),
  attemptId: z.string().min(1),
  amountRwf: z.number().int().nonnegative(),
  occurredAt: z.string().datetime(),
});

export type InitiatePaymentRequest = z.infer<
  typeof initiatePaymentRequestSchema
>;
export type InitiatePaymentResult = z.infer<typeof initiatePaymentResultSchema>;
export type SandboxWebhookEvent = z.infer<typeof sandboxWebhookEventSchema>;
export type PaymentAttemptStatus = z.infer<typeof paymentAttemptStatusSchema>;

export function signSandboxWebhook(rawBody: string, secret: string): string {
  return createHmac("sha256", secret).update(rawBody).digest("hex");
}

export function verifySandboxWebhookSignature(
  rawBody: string,
  signatureHeader: string | null | undefined,
  secret: string,
): boolean {
  if (!signatureHeader || !secret) return false;
  const expected = signSandboxWebhook(rawBody, secret);
  const a = Buffer.from(signatureHeader);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

/** Map sandbox event type → attempt status. */
export function statusFromSandboxEvent(
  type: SandboxWebhookEvent["type"],
): PaymentAttemptStatus {
  switch (type) {
    case "payment.pending":
      return "pending";
    case "payment.paid":
      return "paid";
    case "payment.failed":
      return "failed";
    case "payment.cancelled":
      return "cancelled";
    case "payment.refunded":
      return "refunded";
    default:
      return "failed";
  }
}
