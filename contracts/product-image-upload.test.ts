import { describe, expect, it } from "vitest";
import {
  matchesDeclaredImageSignature,
  validateProductImageUpload,
} from "./product-image-upload.js";

const validMeta = {
  productId: "22222222-2222-4222-8222-222222222001",
  role: "catalogue_primary" as const,
  alt: "Bottle on warm surface",
  originalFilename: "sku-001.jpg",
  declaredMimeType: "image/jpeg" as const,
  byteLength: 3,
  width: 810,
  height: 1080,
};

describe("matchesDeclaredImageSignature", () => {
  it("accepts JPEG SOI", () => {
    expect(
      matchesDeclaredImageSignature(
        new Uint8Array([0xff, 0xd8, 0xff, 0xe0]),
        "image/jpeg",
      ),
    ).toBe(true);
  });

  it("rejects PNG bytes claimed as JPEG", () => {
    expect(
      matchesDeclaredImageSignature(
        new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        "image/jpeg",
      ),
    ).toBe(false);
  });
});

describe("validateProductImageUpload", () => {
  it("accepts matching JPEG meta + bytes", () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff]);
    expect(
      validateProductImageUpload({
        meta: { ...validMeta, byteLength: bytes.byteLength },
        bytes,
      }).role,
    ).toBe("catalogue_primary");
  });

  it("rejects oversized declared dimensions", () => {
    expect(() =>
      validateProductImageUpload({
        meta: { ...validMeta, width: 9000, byteLength: 3 },
        bytes: new Uint8Array([0xff, 0xd8, 0xff]),
      }),
    ).toThrow();
  });

  it("rejects MIME/signature mismatch", () => {
    expect(() =>
      validateProductImageUpload({
        meta: validMeta,
        bytes: new Uint8Array([0x00, 0x00, 0x00]),
      }),
    ).toThrow(/signature/i);
  });
});
