import { z } from "zod";

/**
 * Upload boundary rules for product imagery (Phase 02).
 * No live upload endpoint yet — these schemas gate a future Edge/Route handler.
 */

export const ALLOWED_IMAGE_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/avif",
] as const;

/** Soft ceilings for operator uploads before re-encode. */
export const MAX_UPLOAD_BYTES = 12 * 1024 * 1024; // 12 MiB
export const MAX_UPLOAD_DIMENSION_PX = 6000;
export const MIN_UPLOAD_DIMENSION_PX = 400;

export const productImageUploadMetaSchema = z.object({
  productId: z.string().uuid(),
  role: z.enum([
    "catalogue_primary",
    "catalogue_secondary",
    "editorial",
    "thumbnail",
    "zoom",
  ]),
  alt: z.string().min(1).max(240),
  originalFilename: z.string().min(1).max(255),
  declaredMimeType: z.enum(ALLOWED_IMAGE_MIME_TYPES),
  byteLength: z.number().int().positive().max(MAX_UPLOAD_BYTES),
  width: z
    .number()
    .int()
    .min(MIN_UPLOAD_DIMENSION_PX)
    .max(MAX_UPLOAD_DIMENSION_PX),
  height: z
    .number()
    .int()
    .min(MIN_UPLOAD_DIMENSION_PX)
    .max(MAX_UPLOAD_DIMENSION_PX),
  cropInstructions: z.string().max(1000).optional(),
  rightsNote: z.string().max(1000).optional(),
});

export type ProductImageUploadMeta = z.infer<
  typeof productImageUploadMetaSchema
>;

const JPEG_SOI = [0xff, 0xd8, 0xff] as const;
const PNG_SIG = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a] as const;
const WEBP_RIFF = [0x52, 0x49, 0x46, 0x46] as const; // RIFF....WEBP
const AVIF_FTYP = [0x66, 0x74, 0x79, 0x70] as const; // ....ftyp at offset 4

function startsWith(bytes: Uint8Array, signature: readonly number[]): boolean {
  if (bytes.length < signature.length) return false;
  return signature.every((value, index) => bytes[index] === value);
}

/**
 * Lightweight magic-byte check. Rejects mismatched MIME vs payload.
 * Full re-encode remains mandatory before public serve.
 */
export function matchesDeclaredImageSignature(
  bytes: Uint8Array,
  mime: (typeof ALLOWED_IMAGE_MIME_TYPES)[number],
): boolean {
  switch (mime) {
    case "image/jpeg":
      return startsWith(bytes, JPEG_SOI);
    case "image/png":
      return startsWith(bytes, PNG_SIG);
    case "image/webp":
      return (
        startsWith(bytes, WEBP_RIFF) &&
        bytes.length >= 12 &&
        bytes[8] === 0x57 &&
        bytes[9] === 0x45 &&
        bytes[10] === 0x42 &&
        bytes[11] === 0x50
      );
    case "image/avif":
      return (
        bytes.length >= 12 &&
        bytes[4] === AVIF_FTYP[0] &&
        bytes[5] === AVIF_FTYP[1] &&
        bytes[6] === AVIF_FTYP[2] &&
        bytes[7] === AVIF_FTYP[3]
      );
    default:
      return false;
  }
}

export function validateProductImageUpload(input: {
  meta: unknown;
  bytes: Uint8Array;
}): ProductImageUploadMeta {
  const meta = productImageUploadMetaSchema.parse(input.meta);
  if (input.bytes.byteLength !== meta.byteLength) {
    throw new Error("Upload byte length does not match declared length");
  }
  if (!matchesDeclaredImageSignature(input.bytes, meta.declaredMimeType)) {
    throw new Error("Upload signature does not match declared MIME type");
  }
  return meta;
}
