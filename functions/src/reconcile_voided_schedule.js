/**
 * Scheduled reconciliation for Google Play voided purchases.
 *
 * Function export name: reconcileVoidedPurchases
 * Region: asia-south1
 * Schedule: daily (Asia/Kolkata 03:30)
 *
 * DO NOT deploy until Play API secrets + ops approval are ready.
 * Clients cannot invoke this Function.
 */
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { getDb } from './firebase.js';
import { createVoidedPurchaseService } from './voided_purchase_service.js';
import { createSafeLogger } from './safe_log.js';
import { PLAY_PACKAGE_NAME } from './play_product_catalog.js';

/** Cloud Scheduler cron: daily at 03:30 Asia/Kolkata */
export const RECONCILE_VOIDED_SCHEDULE = '30 3 * * *';
export const RECONCILE_VOIDED_TIME_ZONE = 'Asia/Kolkata';

/**
 * Core job body — unit-testable without Scheduler infrastructure.
 */
export async function runReconcileVoidedPurchasesJob({
  db = getDb(),
  googlePlayVerifier,
  now = () => new Date(),
  logger = createSafeLogger(),
  lookbackDays = null,
  runId = null,
} = {}) {
  const service = createVoidedPurchaseService({
    db,
    googlePlayVerifier,
    now,
    logger,
    lookbackDays,
  });
  return service.reconcileVoidedPurchases({
    packageName: PLAY_PACKAGE_NAME,
    runId,
  });
}

export const reconcileVoidedPurchases = onSchedule(
  {
    schedule: RECONCILE_VOIDED_SCHEDULE,
    timeZone: RECONCILE_VOIDED_TIME_ZONE,
    region: 'asia-south1',
    retryCount: 3,
  },
  async () => {
    const summary = await runReconcileVoidedPurchasesJob();
    // Transient Google list failures throw inside the service so Scheduler retries.
    if (summary?.status === 'error_retryable') {
      throw new Error(summary.message || 'Voided reconcile retryable failure');
    }
    return summary;
  },
);
