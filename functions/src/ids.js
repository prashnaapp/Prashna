/**
 * Path helpers and stable IDs for entitlement / payment documents.
 */
import { createHash } from 'node:crypto';

export function entitlementPath(uid, courseId) {
  return `user_courses/${uid}/courses/${courseId}`;
}

export function entitlementDoc(db, uid, courseId) {
  return db
    .collection('user_courses')
    .doc(uid)
    .collection('courses')
    .doc(courseId);
}

export function transactionDoc(db, transactionId) {
  return db.collection('payment_transactions').doc(transactionId);
}

/**
 * Deterministic payment_transactions document ID from provider identifiers.
 *
 * Long provider refs (e.g. Google Play purchase tokens) are hashed so the
 * Firestore document ID stays within limits. The raw token is still stored on
 * the transaction document as providerTransactionId.
 */
export function stableTransactionId({
  paymentProvider,
  providerTransactionId,
}) {
  const provider = String(paymentProvider || '')
    .trim()
    .toLowerCase();
  const providerRef = String(providerTransactionId || '').trim();
  if (!provider || !providerRef) {
    throw new Error(
      'paymentProvider and providerTransactionId are required for stableTransactionId',
    );
  }
  const safe = `${provider}_${providerRef}`.replace(/[^A-Za-z0-9_-]/g, '_');
  if (safe.length <= 700) return safe;

  const hash = createHash('sha256')
    .update(`${provider}:${providerRef}`)
    .digest('hex');
  return `${provider}_${hash}`;
}

export const ENTITLEMENT_SOURCES = Object.freeze(['purchase', 'admin']);
export const TRANSACTION_STATUSES = Object.freeze([
  'pending',
  'success',
  'failed',
  'cancelled',
]);
