/**
 * Idempotent verified-payment → transaction + entitlement grant.
 *
 * Provider SDKs are NOT integrated here. Callers pass a verified payment
 * event that a future Play/Razorpay webhook handler will construct after
 * server-side verification.
 *
 * Atomicity: a single Firestore transaction writes (or confirms) the
 * payment_transactions doc and upserts user_courses entitlement together.
 * Duplicate events with the same providerTransactionId are no-ops.
 */
import { FieldValue, Timestamp } from 'firebase-admin/firestore';

import { entitlementDoc, stableTransactionId, transactionDoc } from './ids.js';

function toTimestampOrNull(value) {
  if (value == null) return null;
  if (value instanceof Timestamp) return value;
  if (value instanceof Date) return Timestamp.fromDate(value);
  if (typeof value === 'string' || typeof value === 'number') {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw new Error('date value is invalid');
    }
    return Timestamp.fromDate(date);
  }
  throw new Error('invalid date value');
}

export function createPaymentProcessingService(db) {
  return {
    /**
     * @param {object} event
     * @param {string} event.paymentProvider
     * @param {string} event.providerTransactionId
     * @param {string} event.uid
     * @param {string} event.courseId
     * @param {string} event.planId
     * @param {number} event.amount
     * @param {string} [event.currency]
     * @param {Date|string|null} [event.expiresAt]
     * @param {object} [event.metadata]
     * @param {string} [event.source] entitlement source (default purchase)
     */
    async processVerifiedPayment(event) {
      const paymentProvider = String(event.paymentProvider || '').trim();
      const providerTransactionId = String(
        event.providerTransactionId || '',
      ).trim();
      const uid = String(event.uid || '').trim();
      const courseId = String(event.courseId || '').trim();
      const planId = String(event.planId || '').trim();
      const source = event.source || 'purchase';

      if (!paymentProvider || !providerTransactionId) {
        throw new Error(
          'paymentProvider and providerTransactionId are required',
        );
      }
      if (!uid || !courseId) {
        throw new Error('uid and courseId are required');
      }
      if (source !== 'purchase' && source !== 'admin') {
        throw new Error('source must be purchase or admin');
      }

      const transactionId = stableTransactionId({
        paymentProvider,
        providerTransactionId,
      });
      const txnRef = transactionDoc(db, transactionId);
      const entRef = entitlementDoc(db, uid, courseId);
      const expires = toTimestampOrNull(event.expiresAt ?? null);
      const nowTs = Timestamp.now();

      const result = await db.runTransaction(async (tx) => {
        const [txnSnap, entSnap] = await Promise.all([
          tx.get(txnRef),
          tx.get(entRef),
        ]);

        if (txnSnap.exists) {
          const existing = txnSnap.data() || {};
          // Idempotent success: do not re-extend entitlement.
          if (existing.status === 'success') {
            return {
              duplicate: true,
              transactionId,
              entitlementPath: entRef.path,
              transactionStatus: 'success',
              entitlementStatus: entSnap.exists
                ? entSnap.data()?.status ?? null
                : null,
            };
          }
        }

        const txnPayload = {
          transactionId,
          paymentProvider,
          uid,
          courseId,
          planId,
          amount: event.amount ?? 0,
          currency: String(event.currency || 'INR'),
          status: 'success',
          purchasedAt: FieldValue.serverTimestamp(),
          providerTransactionId,
          expiresAt: expires,
          verifiedAt: nowTs,
          metadata: {
            ...(event.metadata || {}),
            entitlementGranted: true,
            processedAt: nowTs.toDate().toISOString(),
          },
        };
        tx.set(txnRef, txnPayload, { merge: true });

        const existingEnt = entSnap.exists ? entSnap.data() : null;
        tx.set(
          entRef,
          {
            uid,
            courseId,
            status: 'active',
            source,
            expiresAt: expires,
            updatedAt: FieldValue.serverTimestamp(),
            enrolledAt:
              existingEnt?.enrolledAt != null
                ? existingEnt.enrolledAt
                : FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

        return {
          duplicate: false,
          transactionId,
          entitlementPath: entRef.path,
          transactionStatus: 'success',
          entitlementStatus: 'active',
        };
      });

      return result;
    },
  };
}
