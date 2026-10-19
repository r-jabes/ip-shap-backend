import { z } from "zod";
import { moneyRwfSchema } from "./money.js";

/** Fulfilment lifecycle (separate from payment). */
export const fulfilmentStatusSchema = z.enum([
  "awaiting_confirmation",
  "confirmed",
  "processing",
  "ready_for_dispatch",
  "out_for_delivery",
  "delivered",
  "cancelled",
]);

export const paymentStatusSchema = z.enum([
  "not_applicable",
  "unpaid",
  "pending",
  "paid",
  "failed",
  "cancelled",
  "refunded",
]);

export const checkoutChannelSchema = z.enum([
  "whatsapp_assisted",
  "online_payment",
]);

export const createOrderItemSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().positive().max(99),
});

const rwandaPhoneSchema = z
  .string()
  .min(9)
  .max(20)
  .regex(/^\+?[0-9\s()-]{9,20}$/, "Enter a valid phone number");

export const createOrderRequestSchema = z.object({
  channel: checkoutChannelSchema,
  items: z.array(createOrderItemSchema).min(1).max(50),
  customerName: z.string().min(1).max(200),
  customerPhone: rwandaPhoneSchema,
  customerNotes: z.string().max(2000).optional(),
  deliveryDistrict: z.string().max(120).optional(),
  deliverySector: z.string().max(120).optional(),
  deliveryCell: z.string().max(120).optional(),
  deliveryVillage: z.string().max(120).optional(),
  deliveryDirections: z.string().max(500).optional(),
  deliveryInstructions: z.string().max(500).optional(),
  deliveryZoneId: z.string().uuid().optional(),
  /** Client-generated UUID; duplicates return the original order. */
  idempotencyKey: z.string().uuid(),
});

export const orderItemSnapshotSchema = z.object({
  productId: z.string().uuid().nullable(),
  productName: z.string().min(1),
  productSlug: z.string().min(1),
  sku: z.string().optional(),
  quantity: z.number().int().positive(),
  unitPrice: moneyRwfSchema,
  lineTotal: moneyRwfSchema,
});

export const orderSummarySchema = z.object({
  id: z.string().uuid(),
  reference: z.string().min(1),
  lookupToken: z.string().min(20),
  fulfilmentStatus: fulfilmentStatusSchema,
  paymentStatus: paymentStatusSchema,
  channel: checkoutChannelSchema,
  currency: z.literal("RWF"),
  subtotal: moneyRwfSchema,
  deliveryFee: moneyRwfSchema.nullable(),
  total: moneyRwfSchema,
  items: z.array(orderItemSnapshotSchema),
  whatsappDeepLink: z.string().url().optional(),
  stockReserved: z.boolean(),
  reservationExpiresAt: z.string().datetime().nullable().optional(),
  createdAt: z.string().datetime(),
});

export const orderLookupRequestSchema = z.object({
  reference: z.string().min(1).max(40),
  lookupToken: z.string().min(20).max(200),
});

export type FulfilmentStatus = z.infer<typeof fulfilmentStatusSchema>;
export type PaymentStatus = z.infer<typeof paymentStatusSchema>;
export type CheckoutChannel = z.infer<typeof checkoutChannelSchema>;
export type CreateOrderRequest = z.infer<typeof createOrderRequestSchema>;
export type OrderSummary = z.infer<typeof orderSummarySchema>;
export type OrderLookupRequest = z.infer<typeof orderLookupRequestSchema>;
