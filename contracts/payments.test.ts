import { describe, expect, it } from "vitest";
import {
  sandboxWebhookEventSchema,
  signSandboxWebhook,
  statusFromSandboxEvent,
  verifySandboxWebhookSignature,
} from "./payments.js";

describe("sandbox webhook signatures", () => {
  const secret = "test-webhook-secret";
  const body = JSON.stringify({
    id: "evt_1",
    type: "payment.paid",
    orderId: "22222222-2222-4222-8222-222222222001",
    attemptId: "att_1",
    amountRwf: 12000,
    occurredAt: "2026-10-19T12:00:00.000Z",
  });

  it("accepts a valid signature", () => {
    const sig = signSandboxWebhook(body, secret);
    expect(verifySandboxWebhookSignature(body, sig, secret)).toBe(true);
  });

  it("rejects forged signatures", () => {
    expect(verifySandboxWebhookSignature(body, "deadbeef", secret)).toBe(false);
    expect(verifySandboxWebhookSignature(body, null, secret)).toBe(false);
  });

  it("parses event payloads", () => {
    const event = sandboxWebhookEventSchema.parse(JSON.parse(body));
    expect(statusFromSandboxEvent(event.type)).toBe("paid");
  });
});
