import type { FulfilmentStatus, PaymentStatus } from "./orders.js";

const FULFILMENT_TRANSITIONS: Record<FulfilmentStatus, FulfilmentStatus[]> = {
  awaiting_confirmation: ["confirmed", "cancelled"],
  confirmed: ["processing", "cancelled"],
  processing: ["ready_for_dispatch", "cancelled"],
  ready_for_dispatch: ["out_for_delivery", "cancelled"],
  out_for_delivery: ["delivered", "cancelled"],
  delivered: [],
  cancelled: [],
};

const PAYMENT_TRANSITIONS: Record<PaymentStatus, PaymentStatus[]> = {
  not_applicable: [],
  unpaid: ["pending", "paid", "failed", "cancelled"],
  pending: ["paid", "failed", "unpaid", "cancelled"],
  paid: ["refunded"],
  failed: ["pending", "unpaid"],
  cancelled: [],
  refunded: [],
};

export function canTransitionFulfilment(
  from: FulfilmentStatus,
  to: FulfilmentStatus,
): boolean {
  if (from === to) return true;
  return FULFILMENT_TRANSITIONS[from].includes(to);
}

export function canTransitionPayment(
  from: PaymentStatus,
  to: PaymentStatus,
): boolean {
  if (from === to) return true;
  return PAYMENT_TRANSITIONS[from].includes(to);
}

export function assertFulfilmentTransition(
  from: FulfilmentStatus,
  to: FulfilmentStatus,
): void {
  if (!canTransitionFulfilment(from, to)) {
    throw new Error(`Illegal fulfilment transition: ${from} → ${to}`);
  }
}

export function assertPaymentTransition(
  from: PaymentStatus,
  to: PaymentStatus,
): void {
  if (!canTransitionPayment(from, to)) {
    throw new Error(`Illegal payment transition: ${from} → ${to}`);
  }
}
