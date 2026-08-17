/**
 * Google Play VoidedPurchase.voidedReason values.
 *
 * https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.voidedpurchases
 *
 * voidedSource (initiator): 0 User, 1 Developer, 2 Google
 */
export const VOIDED_REASON = Object.freeze({
  OTHER: 0,
  REMORSE: 1,
  NOT_RECEIVED: 2,
  DEFECTIVE: 3,
  ACCIDENTAL_PURCHASE: 4,
  FRAUD: 5,
  FRIENDLY_FRAUD: 6,
  CHARGEBACK: 7,
  UNACKNOWLEDGED_PURCHASE: 8,
});

export const VOIDED_SOURCE = Object.freeze({
  USER: 0,
  DEVELOPER: 1,
  GOOGLE: 2,
});

const REASON_NAMES = Object.freeze({
  [VOIDED_REASON.OTHER]: 'OTHER',
  [VOIDED_REASON.REMORSE]: 'REMORSE',
  [VOIDED_REASON.NOT_RECEIVED]: 'NOT_RECEIVED',
  [VOIDED_REASON.DEFECTIVE]: 'DEFECTIVE',
  [VOIDED_REASON.ACCIDENTAL_PURCHASE]: 'ACCIDENTAL_PURCHASE',
  [VOIDED_REASON.FRAUD]: 'FRAUD',
  [VOIDED_REASON.FRIENDLY_FRAUD]: 'FRIENDLY_FRAUD',
  [VOIDED_REASON.CHARGEBACK]: 'CHARGEBACK',
  [VOIDED_REASON.UNACKNOWLEDGED_PURCHASE]: 'UNACKNOWLEDGED_PURCHASE',
});

/**
 * Known void reasons that mean the purchase is no longer paid/valid.
 * Auto-revoke Group II entitlement for these.
 *
 * Unknown / future API values → manual_review (do not auto-revoke).
 */
const AUTO_REVOKE_REASONS = new Set([
  VOIDED_REASON.OTHER,
  VOIDED_REASON.REMORSE,
  VOIDED_REASON.NOT_RECEIVED,
  VOIDED_REASON.DEFECTIVE,
  VOIDED_REASON.ACCIDENTAL_PURCHASE,
  VOIDED_REASON.FRAUD,
  VOIDED_REASON.FRIENDLY_FRAUD,
  VOIDED_REASON.CHARGEBACK,
  VOIDED_REASON.UNACKNOWLEDGED_PURCHASE,
]);

export function voidedReasonName(voidedReason) {
  const code = Number(voidedReason);
  return REASON_NAMES[code] || `UNKNOWN_${voidedReason}`;
}

export function voidedSourceName(voidedSource) {
  switch (Number(voidedSource)) {
    case VOIDED_SOURCE.USER:
      return 'USER';
    case VOIDED_SOURCE.DEVELOPER:
      return 'DEVELOPER';
    case VOIDED_SOURCE.GOOGLE:
      return 'GOOGLE';
    default:
      return `UNKNOWN_${voidedSource}`;
  }
}

/**
 * @returns {'revoke' | 'manual_review'}
 */
export function decideVoidEntitlementAction(voidedReason) {
  const code = Number(voidedReason);
  if (!Number.isFinite(code)) return 'manual_review';
  if (AUTO_REVOKE_REASONS.has(code)) return 'revoke';
  return 'manual_review';
}
