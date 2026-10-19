import { describe, expect, it } from "vitest";
import { createOrderRequestSchema, orderSummarySchema } from "./orders.js";

const baseRequest = {
  channel: "whatsapp_assisted" as const,
  items: [
    {
      productId: "22222222-2222-4222-8222-222222222001",
      quantity: 2,
    },
  ],
  customerName: "Test Customer",
  customerPhone: "+250788123456",
  idempotencyKey: "11111111-1111-4111-8111-111111111111",
};

describe("createOrderRequestSchema", () => {
  it("accepts WhatsApp-assisted create payload", () => {
    expect(createOrderRequestSchema.parse(baseRequest).channel).toBe(
      "whatsapp_assisted",
    );
  });

  it("strips client-supplied prices from line items", () => {
    const parsed = createOrderRequestSchema.parse({
      ...baseRequest,
      items: [
        {
          productId: baseRequest.items[0]!.productId,
          quantity: 1,
          unitPrice: 1,
        },
      ],
    });
    expect(parsed.items[0]).toEqual({
      productId: baseRequest.items[0]!.productId,
      quantity: 1,
    });
  });

  it("requires idempotency key", () => {
    const rest = { ...baseRequest } as Partial<typeof baseRequest>;
    delete rest.idempotencyKey;
    expect(() => createOrderRequestSchema.parse(rest)).toThrow();
  });
});

describe("orderSummarySchema", () => {
  it("requires integer money and lookup token", () => {
    const summary = orderSummarySchema.parse({
      id: "22222222-2222-4222-8222-222222222099",
      reference: "IPS-20261019-ABCD",
      lookupToken: "a".repeat(32),
      fulfilmentStatus: "awaiting_confirmation",
      paymentStatus: "not_applicable",
      channel: "whatsapp_assisted",
      currency: "RWF",
      subtotal: { amount: 24000, currency: "RWF" },
      deliveryFee: null,
      total: { amount: 24000, currency: "RWF" },
      items: [
        {
          productId: "22222222-2222-4222-8222-222222222001",
          productName: "Sample",
          productSlug: "sample",
          quantity: 2,
          unitPrice: { amount: 12000, currency: "RWF" },
          lineTotal: { amount: 24000, currency: "RWF" },
        },
      ],
      stockReserved: true,
      createdAt: new Date().toISOString(),
    });
    expect(summary.total.amount).toBe(24000);
  });
});
