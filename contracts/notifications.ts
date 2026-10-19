import { z } from "zod";

export const notificationChannelSchema = z.enum([
  "log",
  "email",
  "sms",
  "whatsapp_provider",
]);

export const notificationTemplateIdSchema = z.enum([
  "order_awaiting_confirmation",
  "order_confirmed",
  "payment_received",
  "order_cancelled",
  "fulfilment_update",
]);

export const notificationRequestSchema = z.object({
  channel: notificationChannelSchema,
  templateId: notificationTemplateIdSchema,
  to: z.string().min(1).max(200),
  orderReference: z.string().min(1),
  /** Idempotency key for retries — same key must not double-send. */
  idempotencyKey: z.string().min(1).max(200),
  variables: z.record(z.string(), z.string()).default({}),
});

export const notificationResultSchema = z.object({
  ok: z.boolean(),
  channel: notificationChannelSchema,
  providerMessageId: z.string().optional(),
  skippedDuplicate: z.boolean().optional(),
  error: z.string().optional(),
});

export type NotificationRequest = z.infer<typeof notificationRequestSchema>;
export type NotificationResult = z.infer<typeof notificationResultSchema>;
