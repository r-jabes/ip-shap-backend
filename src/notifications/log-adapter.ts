import type {
  NotificationRequest,
  NotificationResult,
} from "../../contracts/notifications.js";
import { notificationRequestSchema } from "../../contracts/notifications.js";

const sentKeys = new Set<string>();

/**
 * Default notification adapter: structured log only.
 * No third-party credentials; safe for local/dev. Failed send never mutates orders.
 */
export function sendNotification(
  input: NotificationRequest,
): NotificationResult {
  const parsed = notificationRequestSchema.parse(input);
  if (sentKeys.has(parsed.idempotencyKey)) {
    return {
      ok: true,
      channel: parsed.channel,
      skippedDuplicate: true,
    };
  }
  // Intentionally no PII dump beyond template + reference.
  console.info(
    JSON.stringify({
      type: "notification",
      channel: parsed.channel,
      templateId: parsed.templateId,
      orderReference: parsed.orderReference,
      idempotencyKey: parsed.idempotencyKey,
    }),
  );
  sentKeys.add(parsed.idempotencyKey);
  return {
    ok: true,
    channel: parsed.channel,
    providerMessageId: `log_${parsed.idempotencyKey}`,
  };
}

export function resetNotificationIdempotencyForTests() {
  sentKeys.clear();
}
