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

export const productImageSchema = z.object({
  id: z.string().min(1),
  role: productImageRoleSchema,
  src: z.string().min(1),
  alt: z.string().min(1),
  width: z.number().int().positive(),
  height: z.number().int().positive(),
  sortOrder: z.number().int().nonnegative(),
  isSharedMultiProductPhoto: z.boolean().optional(),
  sourceFilename: z.string().optional(),
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
export type CatalogueListQuery = z.infer<typeof catalogueListQuerySchema>;
