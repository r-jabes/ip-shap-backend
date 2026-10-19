import { describe, expect, it } from "vitest";
import {
  adminProductWriteSchema,
  roleHasPermission,
  stockAdjustmentRequestSchema,
} from "./admin.js";

describe("roleHasPermission", () => {
  it("allows staff product writes but not admin management", () => {
    expect(roleHasPermission("staff", "products:write")).toBe(true);
    expect(roleHasPermission("staff", "admins:manage")).toBe(false);
    expect(roleHasPermission("owner", "admins:manage")).toBe(true);
  });
});

describe("adminProductWriteSchema", () => {
  it("rejects fractional RWF", () => {
    expect(() =>
      adminProductWriteSchema.parse({
        slug: "test-sku",
        name: "Test",
        price: { amount: 12.5, currency: "RWF" },
        status: "draft",
        availability: "unknown",
      }),
    ).toThrow();
  });

  it("accepts integer draft product", () => {
    const parsed = adminProductWriteSchema.parse({
      slug: "test-sku",
      name: "Test",
      price: { amount: 12000, currency: "RWF" },
      status: "draft",
      availability: "unknown",
    });
    expect(parsed.price.amount).toBe(12000);
  });
});

describe("stockAdjustmentRequestSchema", () => {
  it("rejects negative stock", () => {
    expect(() =>
      stockAdjustmentRequestSchema.parse({
        productId: "22222222-2222-4222-8222-222222222001",
        newQuantity: -1,
        newAvailability: "in_stock",
        reason: "correction",
      }),
    ).toThrow();
  });

  it("requires null quantity for unknown availability", () => {
    expect(() =>
      stockAdjustmentRequestSchema.parse({
        productId: "22222222-2222-4222-8222-222222222001",
        newQuantity: 3,
        newAvailability: "unknown",
        reason: "reset",
      }),
    ).toThrow();
  });
});
