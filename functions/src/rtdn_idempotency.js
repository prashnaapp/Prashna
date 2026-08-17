/**
 * Minimal RTDN lifecycle idempotency store.
 *
 * Collection: rtdn_events/{messageId}
 * This is NOT a payment transaction and NOT an entitlement.
 */
import { FieldValue } from 'firebase-admin/firestore';

export function rtdnEventDoc(db, messageId) {
  return db.collection('rtdn_events').doc(messageId);
}

export function createRtdnIdempotencyStore(db) {
  return {
    async get(messageId) {
      const snap = await rtdnEventDoc(db, messageId).get();
      if (!snap.exists) return null;
      return snap.data();
    },

    /**
     * Claim a message for processing. Returns { claimed: true } when this
     * caller should process, or { claimed: false, existing } when already done.
     *
     * In-progress claims older than [staleAfterMs] may be retried (Pub/Sub retry).
     */
    async tryClaim(messageId, envelope, { now = () => new Date(), staleAfterMs = 15 * 60 * 1000 } = {}) {
      const ref = rtdnEventDoc(db, messageId);
      return db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (snap.exists) {
          const existing = snap.data() || {};
          if (existing.status === 'processed' || existing.status === 'skipped') {
            return { claimed: false, existing };
          }
          if (existing.status === 'processing') {
            const startedAt = existing.processingStartedAt?.toDate?.()
              || (existing.processingStartedAt
                ? new Date(existing.processingStartedAt)
                : null);
            if (
              startedAt
              && now().getTime() - startedAt.getTime() < staleAfterMs
            ) {
              return { claimed: false, existing, inProgress: true };
            }
          }
        }

        tx.set(
          ref,
          {
            messageId,
            status: 'processing',
            packageName: envelope.packageName || null,
            notificationType:
              envelope.oneTime?.notificationTypeName
              || (envelope.voided ? 'VOIDED_PURCHASE' : null),
            purchaseToken:
              envelope.oneTime?.purchaseToken
              || envelope.voided?.purchaseToken
              || null,
            sku: envelope.oneTime?.sku || null,
            processingStartedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            createdAt: snap.exists
              ? snap.data()?.createdAt || FieldValue.serverTimestamp()
              : FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        return { claimed: true, existing: null };
      });
    },

    async markProcessed(messageId, result) {
      await rtdnEventDoc(db, messageId).set(
        {
          status: 'processed',
          resultStatus: result.status || null,
          action: result.action || null,
          transactionId: result.transactionId || null,
          courseId: result.courseId || null,
          uid: result.uid || null,
          googlePurchaseState: result.googlePurchaseState || null,
          processedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          error: null,
        },
        { merge: true },
      );
    },

    async markSkipped(messageId, reason, extra = {}) {
      await rtdnEventDoc(db, messageId).set(
        {
          status: 'skipped',
          resultStatus: 'skipped',
          skipReason: reason,
          ...extra,
          processedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    },

    async markFailed(messageId, errorMessage) {
      await rtdnEventDoc(db, messageId).set(
        {
          status: 'failed',
          error: String(errorMessage || 'unknown'),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    },
  };
}
