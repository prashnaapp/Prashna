/**
 * Prashna Cloud Functions entrypoint.
 *
 * Phase 5.11–5.16: entitlements, Play Billing, RTDN, void reconciliation.
 * Phase 5.20: server-authoritative test attempts (startTestAttempt / submitTestAttempt).
 * Do not deploy without secrets + Play Console / Pub/Sub configured.
 */
import { setGlobalOptions } from 'firebase-functions/v2';

import {
  adminExtendEntitlement,
  adminGetEntitlement,
  adminGetTransaction,
  adminGrantEntitlement,
  adminProcessVerifiedPayment,
  adminRevokeEntitlement,
  setSyllabusCompletion,
  startTestAttempt,
  submitTestAttempt,
  verifyPlayPurchase,
} from './src/callables.js';
import { ensureAdminApp } from './src/firebase.js';
import { onPlayRtdn, PLAY_RTDN_TOPIC } from './src/rtdn_pubsub.js';
import {
  reconcileVoidedPurchases,
  RECONCILE_VOIDED_SCHEDULE,
  RECONCILE_VOIDED_TIME_ZONE,
} from './src/reconcile_voided_schedule.js';

setGlobalOptions({
  region: 'asia-south1',
  maxInstances: 10,
});

ensureAdminApp();

export {
  adminGrantEntitlement,
  adminRevokeEntitlement,
  adminExtendEntitlement,
  adminGetEntitlement,
  adminProcessVerifiedPayment,
  adminGetTransaction,
  verifyPlayPurchase,
  startTestAttempt,
  submitTestAttempt,
  setSyllabusCompletion,
  onPlayRtdn,
  PLAY_RTDN_TOPIC,
  reconcileVoidedPurchases,
  RECONCILE_VOIDED_SCHEDULE,
  RECONCILE_VOIDED_TIME_ZONE,
};

// Service factories for unit tests / future webhook modules.
export { createEntitlementService, resolveEffectiveStatus } from './src/entitlement_service.js';
export { createTransactionService } from './src/transaction_service.js';
export { createPaymentProcessingService } from './src/payment_processing_service.js';
export { createPlayPurchaseService } from './src/play_purchase_service.js';
export { createRtdnService } from './src/rtdn_service.js';
export {
  createVoidedPurchaseService,
  assertSafeReconcileLogPayload,
} from './src/voided_purchase_service.js';
export { runReconcileVoidedPurchasesJob } from './src/reconcile_voided_schedule.js';
export { createPaymentOpsReviewStore } from './src/payment_ops_review.js';
export {
  resolveVoidedLookbackDays,
  GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS,
} from './src/voided_lookback.js';
export {
  createTestAttemptService,
  AUTHORITY_SERVER_VERIFIED,
  AUTHORITY_LEGACY_CLIENT,
  resolveAuthority,
} from './src/test_attempt_service.js';
export { calculateScoreV1, SCORING_VERSION_V1 } from './src/test_scoring.js';
export {
  createProgressRevisionService,
  deriveWrongQuestionIds,
  AUTHORITY_SERVER_VERIFIED as PROGRESS_AUTHORITY_SERVER_VERIFIED,
} from './src/progress_revision_service.js';
export {
  createSyllabusCompletionService,
  SyllabusCompletionStatus,
  resolveValidatedCompletionScope,
} from './src/syllabus_completion_service.js';
export {
  findCanonicalSyllabusUnit,
  isKnownCanonicalSyllabusUnit,
  CANONICAL_SYLLABUS_UNITS,
} from './src/canonical_syllabus_catalog.js';
export {
  parseRtdnPubSubMessage,
  ONE_TIME_PRODUCT_PURCHASED,
  ONE_TIME_PRODUCT_CANCELED,
  VOIDED_PRODUCT_TYPE_ONE_TIME,
  VOIDED_PRODUCT_TYPE_SUBSCRIPTION,
} from './src/rtdn_parser.js';
export { createGooglePlayVerifier, mapPurchaseState } from './src/google_play_verifier.js';
export {
  PLAY_PACKAGE_NAME,
  PLAY_PRODUCT_CATALOG,
  resolvePlayProduct,
  computeExpiresAt,
} from './src/play_product_catalog.js';
export {
  VOIDED_REASON,
  VOIDED_SOURCE,
  decideVoidEntitlementAction,
  voidedReasonName,
} from './src/void_reasons.js';
export { stableTransactionId } from './src/ids.js';
export { assertAdmin, assertAuthenticated } from './src/callables.js';
