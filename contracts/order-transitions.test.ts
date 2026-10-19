import { describe, expect, it } from "vitest";
import {
  assertFulfilmentTransition,
  canTransitionFulfilment,
  canTransitionPayment,
} from "./order-transitions.js";

describe("fulfilment transitions", () => {
  it("allows awaiting_confirmation → confirmed / cancelled", () => {
    expect(canTransitionFulfilment("awaiting_confirmation", "confirmed")).toBe(
      true,
    );
    expect(canTransitionFulfilment("awaiting_confirmation", "cancelled")).toBe(
      true,
    );
    expect(canTransitionFulfilment("awaiting_confirmation", "delivered")).toBe(
      false,
    );
  });

  it("rejects transitions from terminal delivered", () => {
    expect(() => assertFulfilmentTransition("delivered", "cancelled")).toThrow(
      /Illegal fulfilment/,
    );
  });
});

describe("payment transitions", () => {
  it("keeps not_applicable terminal for WhatsApp channel", () => {
    expect(canTransitionPayment("not_applicable", "paid")).toBe(false);
  });

  it("allows unpaid → pending → paid → refunded", () => {
    expect(canTransitionPayment("unpaid", "pending")).toBe(true);
    expect(canTransitionPayment("pending", "paid")).toBe(true);
    expect(canTransitionPayment("paid", "refunded")).toBe(true);
  });
});
