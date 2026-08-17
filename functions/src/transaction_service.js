/**
 * Trusted server-side payment transaction service.
 *
 * Writes ONLY to payment_transactions/{transactionId}.
 * Does NOT grant course access — entitlement is separate.
 */
import { FieldValue, Timestamp } from 'firebase-admin/firestore';

import { TRANSACTION_STATUSES, transactionDoc } from './ids.js';

function assertTransactionId(transactionId) {
  if (typeof transactionId !== 'string' || transactionId.trim().length === 0) {
    throw new Error('transactionId is required');
  }
}

function assertStatus(status) {
  if (!TRANSACTION_STATUSES.includes(status)) {
    throw new Error(
      `status must be one of: ${TRANSACTION_STATUSES.join(', ')}`,
    );
  }
}

function toTimestampOrNull(value) {
  if (value == null) return null;
  if (value instanceof Timestamp) return value;
  if (value instanceof Date) return Timestamp.fromDate(value);
  if (typeof value === 'string' || typeof value === 'number') {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw new Error('timestamp value is not a valid date');
    }
    return Timestamp.fromDate(date);
  }
  throw new Error('timestamp must be a Date, Timestamp, ISO string, or null');
}

function serializeTransaction(transactionId, data) {
  if (!data) return null;
  return {
    transactionId: data.transactionId ?? transactionId,
    paymentProvider: data.paymentProvider ?? '',
    uid: data.uid ?? '',
    courseId: data.courseId ?? '',
    planId: data.planId ?? '',
    amount: data.amount ?? 0,
    currency: data.currency ?? 'INR',
    status: data.status ?? null,
    purchasedAt: data.purchasedAt ?? null,
    providerTransactionId: data.providerTransactionId ?? null,
    expiresAt: data.expiresAt ?? null,
    verifiedAt: data.verifiedAt ?? null,
    metadata: data.metadata ?? {},
  };
}

export function createTransactionService(db) {
  return {
    async get(transactionId) {
      assertTransactionId(transactionId);
      const snap = await transactionDoc(db, transactionId).get();
      if (!snap.exists) return null;
      return serializeTransaction(transactionId, snap.data());
    },

    /**
     * Create-or-return existing transaction (idempotent by document ID).
     * If the document already exists, returns it without mutation.
     */
    async createIfAbsent(input) {
      assertTransactionId(input.transactionId);
      assertStatus(input.status);
      const ref = transactionDoc(db, input.transactionId);

      return db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (snap.exists) {
          return {
            created: false,
            transaction: serializeTransaction(input.transactionId, snap.data()),
          };
        }

        const payload = {
          transactionId: input.transactionId,
          paymentProvider: String(input.paymentProvider || ''),
          uid: String(input.uid || ''),
          courseId: String(input.courseId || ''),
          planId: String(input.planId || ''),
          amount: input.amount ?? 0,
          currency: String(input.currency || 'INR'),
          status: input.status,
          purchasedAt:
            toTimestampOrNull(input.purchasedAt) ?? FieldValue.serverTimestamp(),
          providerTransactionId: input.providerTransactionId ?? null,
          expiresAt: toTimestampOrNull(input.expiresAt),
          verifiedAt: toTimestampOrNull(input.verifiedAt),
          metadata: input.metadata ?? {},
        };
        tx.set(ref, payload);
        return {
          created: true,
          transaction: serializeTransaction(input.transactionId, {
            ...payload,
            purchasedAt: payload.purchasedAt,
            verifiedAt: payload.verifiedAt,
          }),
        };
      });
    },

    async markStatus(transactionId, status, { verifiedAt = null } = {}) {
      assertTransactionId(transactionId);
      assertStatus(status);
      const ref = transactionDoc(db, transactionId);
      await ref.set(
        {
          status,
          ...(verifiedAt != null
            ? { verifiedAt: toTimestampOrNull(verifiedAt) }
            : {}),
        },
        { merge: true },
      );
      return this.get(transactionId);
    },
  };
}
