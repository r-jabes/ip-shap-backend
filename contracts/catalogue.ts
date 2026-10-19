import { z } from "zod";
import { moneyRwfSchema } from "./money.js";

export const productStatusSchema = z.enum([
  "draft",
  "demo",
  "published",
  "archived",
]);

export const productImageRoleSchema = z.enum([
  "catalogue_primary",
  "catalogue_secondary",
  "editorial",
  "thumbnail",
  "zoom",
]);

export const imageProcessingStatusSchema = z.enum([
  "source_received",
  "needs_review",
  "approved_for_catalogue",
  "rejected",
  "archived",
]);

export const productImageSchema = z.object({
  id: z.string().min(1),
  role: productImageRoleSchema,
  /** Public derivative path/URL. */
  src: z.string().min(1),
  /** Higher-res derivative loaded only for zoom/lightbox. */
  zoomSrc: z.string().min(1).optional(),
  alt: z.string().min(1),
  width: z.number().int().positive(),
  height: z.number().int().positive(),
  sortOrder: z.number().int().nonnegative(),
  processingStatus: imageProcessingStatusSchema,
  isSharedMultiProductPhoto: z.boolean().optional(),
  /** Operator reference only — never product identity. */
  sourceFilename: z.string().optional(),
  /** Private/original storage key; not public by default. */
  originalRef: z.string().optional(),
  cropInstructions: z.string().optional(),
  rightsNote: z.string().optional(),
  needsClientConfirmation: z.boolean().optional(),
});

export const productSchema = z.object({
  id: z.string().uuid(),
  slug: z.string().min(1),
  name: z.string().min(1),
  description: z.string(),
  price: moneyRwfSchema,
  categorySlug: z.string().optional(),
  status: productStatusSchema,
  images: z.array(productImageSchema),
  isProvisional: z.boolean(),
  internalNotes: z.array(z.string()).optional(),
});

export const catalogueListQuerySchema = z.object({
  categorySlug: z.string().optional(),
  q: z.string().optional(),
  sort: z.enum(["price_asc", "price_desc", "name_asc"]).optional(),
  cursor: z.string().optional(),
  limit: z.number().int().min(1).max(100).default(24),
});

export type Product = z.infer<typeof productSchema>;
export type ProductImage = z.infer<typeof productImageSchema>;
export type CatalogueListQuery = z.infer<typeof catalogueListQuerySchema>;
