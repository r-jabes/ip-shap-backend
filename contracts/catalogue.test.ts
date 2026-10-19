import { describe, expect, it } from "vitest";
import {
  catalogueListQuerySchema,
  catalogueListResultSchema,
  productSchema,
} from "./catalogue.js";

const sampleProduct = {
  id: "22222222-2222-4222-8222-222222222001",
  slug: "sample-sku",
  name: "Sample",
  description: "Desc",
  price: { amount: 12000, currency: "RWF" as const },
  status: "published" as const,
  availability: "unknown" as const,
  images: [],
  isProvisional: false,
};

describe("catalogueListQuerySchema", () => {
  it("defaults page and pageSize", () => {
    expect(catalogueListQuerySchema.parse({})).toMatchObject({
      page: 1,
      pageSize: 24,
    });
  });

  it("rejects unbounded pageSize", () => {
    expect(() => catalogueListQuerySchema.parse({ pageSize: 200 })).toThrow();
  });

  it("caps search query length", () => {
    expect(() =>
      catalogueListQuerySchema.parse({ q: "x".repeat(121) }),
    ).toThrow();
  });
});

describe("productSchema", () => {
  it("requires integer RWF and availability", () => {
    expect(productSchema.parse(sampleProduct).availability).toBe("unknown");
  });

  it("rejects floating money", () => {
    expect(() =>
      productSchema.parse({
        ...sampleProduct,
        price: { amount: 12.5, currency: "RWF" },
      }),
    ).toThrow();
  });
});

describe("catalogueListResultSchema", () => {
  it("accepts paginated envelopes", () => {
    const result = catalogueListResultSchema.parse({
      items: [sampleProduct],
      page: 1,
      pageSize: 24,
      total: 1,
      totalPages: 1,
    });
    expect(result.items).toHaveLength(1);
  });
});
