import { describe, expect, it } from "vitest";
import { moneyRwfSchema } from "./money.js";

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
