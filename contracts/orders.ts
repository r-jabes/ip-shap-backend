import { z } from "zod";
import { moneyRwfSchema } from "./money.js";

export const orderStatusSchema = z.enum([
  "draft",
  "pending_payment",
  "awaiting_manual_confirmation",
  "paid",
  "cancelled",
  "fulfilled",
  "refunded",
]);

export const checkoutChannelSchema = z.enum([
  "online_payment",
  "whatsapp_assisted",
]);

export const createOrderItemSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().positive(),
});

/**
 * Client may propose a channel and contact details.
 * Server recomputes line prices and totals from authoritative catalogue data.
 */
export const createOrderRequestSchema = z.object({
  channel: checkoutChannelSchema,
  items: z.array(createOrderItemSchema).min(1),
  customerName: z.string().min(1).max(200),
  customerPhone: z.string().min(5).max(40),
  customerNotes: z.string().max(2000).optional(),
  deliveryZoneId: z.string().uuid().optional(),
});

export const orderSummarySchema = z.object({
  id: z.string().uuid(),
  status: orderStatusSchema,
  channel: checkoutChannelSchema,
  currency: z.literal("RWF"),
  subtotal: moneyRwfSchema,
  deliveryFee: moneyRwfSchema.nullable(),
  total: moneyRwfSchema,
  whatsappDeepLink: z.string().url().optional(),
});

export type CreateOrderRequest = z.infer<typeof createOrderRequestSchema>;
export type OrderSummary = z.infer<typeof orderSummarySchema>;
