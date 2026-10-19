import { randomUUID } from "node:crypto";
import {
  initiatePaymentRequestSchema,
  type InitiatePaymentRequest,
  type InitiatePaymentResult,
  type SandboxWebhookEvent,
  sandboxWebhookEventSchema,
  statusFromSandboxEvent,
  verifySandboxWebhookSignature,
} from "../../contracts/payments.js";

/**
 * Test-only payment adapter. Never present as a live Rwanda provider in UI.
 */
export function initiateSandboxPayment(
  input: InitiatePaymentRequest,
  options: { appBaseUrl: string },
): InitiatePaymentResult {
  const parsed = initiatePaymentRequestSchema.parse(input);
  const attemptId = `sandbox_${parsed.idempotencyKey}`;
  return {
    provider: "sandbox",
    attemptId,
    status: "pending",
    mode: "sandbox",
    redirectUrl: `${options.appBaseUrl.replace(/\/$/, "")}/order/${encodeURIComponent(parsed.orderReference)}?payment=sandbox_pending`,
  };
}

export function parseAndVerifySandboxWebhook(
  rawBody: string,
  signature: string | null | undefined,
  secret: string,
): SandboxWebhookEvent {
  if (!verifySandboxWebhookSignature(rawBody, signature, secret)) {
    throw new Error("Invalid webhook signature");
  }
  return sandboxWebhookEventSchema.parse(JSON.parse(rawBody));
}

export function sandboxEventToPaymentStatus(event: SandboxWebhookEvent) {
  return statusFromSandboxEvent(event.type);
}

/** Helper for tests: build a signed paid event body. */
export function buildSandboxPaidEvent(orderId: string, amountRwf: number) {
  const event: SandboxWebhookEvent = {
    id: `evt_${randomUUID()}`,
    type: "payment.paid",
    orderId,
    attemptId: `sandbox_${randomUUID()}`,
    amountRwf,
    occurredAt: new Date().toISOString(),
  };
  return event;
}
