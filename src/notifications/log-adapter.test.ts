import { beforeEach, describe, expect, it } from "vitest";
import {
  resetNotificationIdempotencyForTests,
  sendNotification,
} from "./log-adapter.js";

describe("log notification adapter", () => {
  beforeEach(() => {
    resetNotificationIdempotencyForTests();
  });

  it("is idempotent on retry keys", () => {
    const payload = {
      channel: "log" as const,
      templateId: "order_awaiting_confirmation" as const,
      to: "log:ops",
      orderReference: "IPS-TEST",
      idempotencyKey: "notif-1",
      variables: { status: "awaiting_confirmation" },
    };
    expect(sendNotification(payload).skippedDuplicate).toBeUndefined();
    expect(sendNotification(payload).skippedDuplicate).toBe(true);
  });
});
