import { describe, expect, it } from "vitest";
import { signSandboxWebhook } from "../../contracts/payments.js";
import {
  buildSandboxPaidEvent,
  initiateSandboxPayment,
  parseAndVerifySandboxWebhook,
} from "./sandbox-adapter.js";

describe("sandbox payment adapter", () => {
  it("initiates pending sandbox redirects labelled as sandbox", () => {
    const result = initiateSandboxPayment(
      {
        orderId: "22222222-2222-4222-8222-222222222001",
        orderReference: "IPS-20261019-ABCD",
        amount: { amount: 12000, currency: "RWF" },
        idempotencyKey: "11111111-1111-4111-8111-111111111201",
        returnUrl: "http://localhost:3000/order/IPS-20261019-ABCD",
      },
      { appBaseUrl: "http://localhost:3000" },
    );
    expect(result.mode).toBe("sandbox");
    expect(result.status).toBe("pending");
    expect(result.provider).toBe("sandbox");
  });

  it("rejects invalid webhook signatures", () => {
    const event = buildSandboxPaidEvent(
      "22222222-2222-4222-8222-222222222001",
      12000,
    );
    const body = JSON.stringify(event);
    expect(() => parseAndVerifySandboxWebhook(body, "bad", "secret")).toThrow(
      /signature/i,
    );
  });

  it("accepts signed webhooks", () => {
    const event = buildSandboxPaidEvent(
      "22222222-2222-4222-8222-222222222001",
      12000,
    );
    const body = JSON.stringify(event);
    const sig = signSandboxWebhook(body, "secret");
    const parsed = parseAndVerifySandboxWebhook(body, sig, "secret");
    expect(parsed.type).toBe("payment.paid");
  });
});
