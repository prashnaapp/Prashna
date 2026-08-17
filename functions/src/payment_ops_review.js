/**
 * Backend-only payment ops review records for future Admin Ops screens.
 *
 * Collection: payment_ops_reviews/{reviewId}
 * Clients cannot write (Firestore default deny). Admin SDK only.
 *
 * Status model (minimum):
 * - pending
 * - manual_review
 * - resolved
 * - failed
 */
import { FieldValue } from 'firebase-admin/firestore';

import { PLAY_PACKAGE_NAME, PLAY_PROVIDER } from './play_product_catalog.js';
import { stableTransactionId } from './ids.js';
import { fingerprintSecret } from './safe_log.js';
import { voidedReasonName, voidedSourceName } from './void_reasons.js';

export const OPS_REVIEW_STATUSES = Object.freeze([
  'pending',
  'manual_review',
  'resolved',
  'failed',
]);

export function paymentOpsReviewDoc(db, reviewId) {
  return db.collection('payment_ops_reviews').doc(reviewId);
}

export function reviewIdForPurchaseToken(purchaseToken) {
  return stableTransactionId({
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: `ops_${purchaseToken}`,
  });
}

export function createPaymentOpsReviewStore(db) {
  return {
    async upsert(input) {
      const purchaseToken = String(input.purchaseToken || '').trim();
      if (!purchaseToken) {
        throw new Error('purchaseToken is required for ops review');
      }
      const status = String(input.status || 'manual_review');
      if (!OPS_REVIEW_STATUSES.includes(status)) {
        throw new Error(
          `status must be one of: ${OPS_REVIEW_STATUSES.join(', ')}`,
        );
      }

      const reviewId =
        input.reviewId || reviewIdForPurchaseToken(purchaseToken);
      const ref = paymentOpsReviewDoc(db, reviewId);
      const snap = await ref.get();
      const existing = snap.exists ? snap.data() : null;

      // Do not reopen resolved reviews automatically.
      if (existing?.status === 'resolved' && status !== 'resolved') {
        return { reviewId, skipped: true, existing };
      }

      const payload = {
        reviewId,
        status,
        purchaseToken,
        purchaseTokenFingerprint: fingerprintSecret(purchaseToken),
        productId: input.productId ?? existing?.productId ?? null,
        packageName: input.packageName || PLAY_PACKAGE_NAME,
        voidReason:
          input.voidReason == null
            ? existing?.voidReason ?? null
            : Number(input.voidReason),
        voidReasonName:
          input.voidReasonName
          || voidedReasonName(input.voidReason)
          || existing?.voidReasonName
          || null,
        voidedSource:
          input.voidedSource == null
            ? existing?.voidedSource ?? null
            : Number(input.voidedSource),
        voidedSourceName:
          input.voidedSourceName
          || voidedSourceName(input.voidedSource)
          || existing?.voidedSourceName
          || null,
        transactionId: input.transactionId ?? existing?.transactionId ?? null,
        uid: input.uid ?? existing?.uid ?? null,
        courseId: input.courseId ?? existing?.courseId ?? null,
        detectedAt:
          existing?.detectedAt || FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        reason: input.reason || input.details || existing?.reason || null,
        details: input.details || input.reason || existing?.details || null,
        sourcePath: input.sourcePath || existing?.sourcePath || null,
        runId: input.runId || existing?.runId || null,
      };

      await ref.set(payload, { merge: true });
      return { reviewId, skipped: false, status };
    },

    async get(reviewId) {
      const snap = await paymentOpsReviewDoc(db, reviewId).get();
      if (!snap.exists) return null;
      return snap.data();
    },

    async markResolved(reviewId, { details = null } = {}) {
      await paymentOpsReviewDoc(db, reviewId).set(
        {
          status: 'resolved',
          details: details || null,
          resolvedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return this.get(reviewId);
    },
  };
}
