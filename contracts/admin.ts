import { z } from "zod";
import {
  productAvailabilitySchema,
  productImageSchema,
  productStatusSchema,
} from "./catalogue.js";
import { moneyRwfSchema } from "./money.js";

export const adminRoleSchema = z.enum(["owner", "staff"]);

export const adminPermissionSchema = z.enum([
  "products:read",
  "products:write",
  "inventory:adjust",
  "import:run",
  "admins:manage",
  "audit:read",
]);

export const ROLE_PERMISSIONS: Record<
  z.infer<typeof adminRoleSchema>,
  Array<z.infer<typeof adminPermissionSchema>>
> = {
  owner: [
    "products:read",
    "products:write",
    "inventory:adjust",
    "import:run",
    "admins:manage",
    "audit:read",
  ],
  staff: [
    "products:read",
    "products:write",
    "inventory:adjust",
    "import:run",
    "audit:read",
  ],
};

export function roleHasPermission(
  role: z.infer<typeof adminRoleSchema>,
  permission: z.infer<typeof adminPermissionSchema>,
): boolean {
  return ROLE_PERMISSIONS[role].includes(permission);
}

export const adminProductWriteSchema = z.object({
  id: z.string().uuid().optional(),
  slug: z
    .string()
    .min(1)
    .max(160)
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Slug must be lowercase kebab-case"),
  name: z.string().min(1).max(200),
  description: z.string().max(5000).default(""),
  price: moneyRwfSchema,
  categorySlug: z.string().max(120).optional(),
  brandSlug: z.string().max(120).optional(),
  brandName: z.string().max(200).optional(),
  status: productStatusSchema,
  availability: productAvailabilitySchema,
  sku: z.string().max(80).optional(),
  barcode: z.string().max(80).optional(),
  isProvisional: z.boolean().default(false),
  images: z.array(productImageSchema).default([]),
  internalNotes: z.array(z.string().max(500)).optional(),
});

export const stockAdjustmentRequestSchema = z
  .object({
    productId: z.string().uuid(),
    newQuantity: z.number().int().nonnegative().nullable(),
    newAvailability: productAvailabilitySchema,
    reason: z.string().min(1).max(500),
    /** Client-observed previous quantity for stale-write detection. */
    expectedQuantity: z.number().int().nonnegative().nullable().optional(),
  })
  .superRefine((value, ctx) => {
    if (value.newAvailability === "unknown" && value.newQuantity !== null) {
      ctx.addIssue({
        code: "custom",
        message: "Unknown availability requires null quantity",
        path: ["newQuantity"],
      });
    }
    if (
      value.newAvailability !== "unknown" &&
      value.newAvailability !== "out_of_stock" &&
      value.newQuantity === null
    ) {
      ctx.addIssue({
        code: "custom",
        message:
          "Quantity required unless availability is unknown or out_of_stock",
        path: ["newQuantity"],
      });
    }
    if (
      value.newAvailability === "out_of_stock" &&
      value.newQuantity === null
    ) {
      // Allow treating out_of_stock as quantity 0 implicitly
    }
  });

export const auditEventSchema = z.object({
  id: z.string().uuid(),
  actorUserId: z.string().uuid().nullable(),
  action: z.string().min(1),
  entityType: z.string().min(1),
  entityId: z.string().optional(),
  metadata: z.record(z.string(), z.unknown()).default({}),
  createdAt: z.string().datetime(),
});

export type AdminRole = z.infer<typeof adminRoleSchema>;
export type AdminPermission = z.infer<typeof adminPermissionSchema>;
export type AdminProductWrite = z.infer<typeof adminProductWriteSchema>;
export type StockAdjustmentRequest = z.infer<
  typeof stockAdjustmentRequestSchema
>;
