import { describe, expect, it } from "vitest";
import { moneyRwfSchema, multiplyRwfAmount } from "./money.js";

describe("moneyRwfSchema", () => {
  it("accepts integer RWF", () => {
    expect(moneyRwfSchema.parse({ amount: 28000, currency: "RWF" })).toEqual({
      amount: 28000,
      currency: "RWF",
    });
  });

  it("rejects fractional amounts", () => {
    expect(() =>
      moneyRwfSchema.parse({ amount: 12.5, currency: "RWF" }),
    ).toThrow();
  });
});

describe("multiplyRwfAmount invariants", () => {
  it("matches unit × qty for random safe integers", () => {
    for (let i = 0; i < 40; i += 1) {
      const unit = Math.floor(Math.random() * 80_000);
      const qty = Math.floor(Math.random() * 24) + 1;
      expect(multiplyRwfAmount(unit, qty)).toBe(unit * qty);
    }
  });

  it("rejects overflow", () => {
    expect(() => multiplyRwfAmount(Number.MAX_SAFE_INTEGER, 2)).toThrow(
      /overflow/i,
    );
  });
});
