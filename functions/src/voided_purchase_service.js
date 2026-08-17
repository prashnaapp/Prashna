/**
 * Google Play voided purchase / refund protection + reconciliation.
 *
 * Authoritative source: purchases.voidedpurchases.list
 * Entitlement action: existing entitlements.revoke() only.
 * Does NOT issue refunds. Does NOT delete UserCourse or payment_transactions.
 */
import { createHash, randomUUID } from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

import {
  PLAY_PACKAGE_NAME,
  PLAY_PROVIDER,
  resolvePlayProduct,
} from './play_product_catalog.js';
import { createGooglePlayVerifier } from './google_play_verifier.js';
import { createTransactionService } from './transaction_service.js';
import { createEntitlementService } from './entitlement_service.js';
import { stableTransactionId, transactionDoc } from './ids.js';
import {
  decideVoidEntitlementAction,
  voidedReasonName,
  voidedSourceName,
} from './void_reasons.js';
import {
  GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS,
  MS_PER_DAY,
  resolveVoidedLookbackDays,
} from './voided_lookback.js';
import { createPaymentOpsReviewStore } from './payment_ops_review.js';
import {
  createSafeLogger,
  fingerprintSecret,
  sanitizeErrorMessage,
} from './safe_log.js';

export function voidedPurchaseEventDoc(db, eventId) {
  return db.collection('voided_purchase_events').doc(eventId);
}

function voidEventIdForToken(purchaseToken) {
  return stableTransactionId({
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: purchaseToken,
  });
}

function normalizeVoidedPurchase(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const purchaseToken = String(raw.purchaseToken || '').trim();
  if (!purchaseToken) return null;
  return {
    purchaseToken,
    orderId: raw.orderId != null ? String(raw.orderId) : null,
    purchaseTimeMillis: raw.purchaseTimeMillis ?? null,
    voidedTimeMillis: raw.voidedTimeMillis ?? null,
    voidedReason:
      raw.voidedReason == null ? null : Number(raw.voidedReason),
    voidedSource:
      raw.voidedSource == null ? null : Number(raw.voidedSource),
    voidedQuantity:
      raw.voidedQuantity == null ? null : Number(raw.voidedQuantity),
    kind: raw.kind ?? null,
  };
}

function emptyMetrics() {
  return {
    scannedCount: 0,
    matchedCount: 0,
    revokedCount: 0,
    alreadyProcessedCount: 0,
    awaitingAccountLinkCount: 0,
    manualReviewCount: 0,
    failedCount: 0,
    skippedCount: 0,
  };
}

function classifyListError(error) {
  const status = Number(error?.status || error?.code || 0);
  if (status === 429 || status >= 500 || status === 0) {
    return 'transient';
  }
  if (status >= 400 && status < 500) {
    return 'permanent';
  }
  // Default: treat unknown as transient so Scheduler can retry.
  return error?.retryable === false ? 'permanent' : 'transient';
}

export function createVoidedPurchaseService({
  db,
  googlePlayVerifier,
  now = () => new Date(),
  logger = createSafeLogger(),
  lookbackDays = null,
}) {
  const verifier = googlePlayVerifier || createGooglePlayVerifier();
  const transactions = createTransactionService(db);
  const entitlements = createEntitlementService(db);
  const opsReviews = createPaymentOpsReviewStore(db);

  function configuredLookbackDays() {
    if (lookbackDays != null) {
      return resolveVoidedLookbackDays({
        env: { VOIDED_PURCHASE_LOOKBACK_DAYS: String(lookbackDays) },
      });
    }
    return resolveVoidedLookbackDays();
  }

  async function tryClaimVoidEvent(purchaseToken, voidedPurchase) {
    const eventId = voidEventIdForToken(purchaseToken);
    const ref = voidedPurchaseEventDoc(db, eventId);
    return db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) {
        const existing = snap.data() || {};
        if (
          existing.status === 'processed'
          || existing.status === 'skipped'
          || existing.status === 'manual_review'
          || existing.status === 'awaiting_account_link'
        ) {
          return { claimed: false, existing, eventId };
        }
      }
      tx.set(
        ref,
        {
          eventId,
          purchaseToken,
          purchaseTokenFingerprint: fingerprintSecret(purchaseToken),
          status: 'processing',
          voidedReason: voidedPurchase?.voidedReason ?? null,
          voidedReasonName: voidedReasonName(voidedPurchase?.voidedReason),
          voidedSource: voidedPurchase?.voidedSource ?? null,
          orderId: voidedPurchase?.orderId ?? null,
          processingStartedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          createdAt: snap.exists
            ? snap.data()?.createdAt || FieldValue.serverTimestamp()
            : FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return { claimed: true, existing: null, eventId };
    });
  }

  async function finishVoidEvent(eventId, result) {
    const terminalStatus =
      result.status === 'revoked'
      || result.status === 'duplicate_void'
        ? 'processed'
        : result.status === 'manual_review'
          ? 'manual_review'
          : result.status === 'awaiting_account_link'
            ? 'awaiting_account_link'
            : result.status === 'error'
              ? 'skipped'
              : result.status === 'skipped'
                ? 'skipped'
                : 'processed';

    await voidedPurchaseEventDoc(db, eventId).set(
      {
        status: terminalStatus,
        resultStatus: result.status,
        action: result.action || null,
        uid: result.uid || null,
        courseId: result.courseId || null,
        transactionId: result.transactionId || null,
        message: result.message || null,
        voidedReason: result.voidedReason ?? null,
        voidedReasonName: result.voidedReasonName || null,
        processedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        error: null,
      },
      { merge: true },
    );
  }

  async function recordOpsReview(result, {
    voidedPurchase,
    productId = null,
    packageName = PLAY_PACKAGE_NAME,
    sourcePath = null,
    runId = null,
  }) {
    const status =
      result.status === 'manual_review'
        ? 'manual_review'
        : result.status === 'awaiting_account_link'
          ? 'pending'
          : result.status === 'error'
            ? 'failed'
            : null;
    if (!status) return null;

    return opsReviews.upsert({
      status,
      purchaseToken: voidedPurchase.purchaseToken,
      productId,
      packageName,
      voidReason: voidedPurchase.voidedReason,
      voidedSource: voidedPurchase.voidedSource,
      transactionId: result.transactionId || null,
      uid: result.uid || null,
      courseId: result.courseId || null,
      reason: result.message || result.action,
      details: result.message || result.action,
      sourcePath,
      runId,
    });
  }

  async function markTransactionVoided(transactionId, voidedPurchase, extra = {}) {
    const ref = transactionDoc(db, transactionId);
    return db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return null;
      const data = snap.data() || {};
      const metadata = {
        ...(data.metadata || {}),
        voided: true,
        voidedReason: voidedPurchase.voidedReason,
        voidedReasonName: voidedReasonName(voidedPurchase.voidedReason),
        voidedSource: voidedPurchase.voidedSource,
        voidedSourceName: voidedSourceName(voidedPurchase.voidedSource),
        voidedTimeMillis: voidedPurchase.voidedTimeMillis,
        voidOrderId: voidedPurchase.orderId,
        voidSourcePath: extra.sourcePath || null,
        ...extra.metadata,
      };
      tx.set(
        ref,
        {
          status: 'cancelled',
          metadata,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return {
        transactionId,
        status: 'cancelled',
        uid: data.uid,
        courseId: data.courseId,
        providerTransactionId: data.providerTransactionId,
        metadata,
        previouslyCancelled: data.status === 'cancelled',
      };
    });
  }

  async function findVoidedPurchaseByToken({
    packageName,
    purchaseToken,
    eventTimeMillis = null,
  }) {
    const days = configuredLookbackDays();
    const endMs = now().getTime();
    const eventMs = eventTimeMillis != null
      ? Number(eventTimeMillis)
      : endMs;
    const startMs = Math.max(
      endMs - days * MS_PER_DAY,
      Number.isFinite(eventMs) ? eventMs - MS_PER_DAY : endMs - days * MS_PER_DAY,
    );

    let pageToken = null;
    do {
      const page = await verifier.listVoidedPurchases({
        packageName,
        startTime: startMs,
        endTime: endMs,
        maxResults: 1000,
        token: pageToken,
        type: 0,
      });
      const items = Array.isArray(page?.voidedPurchases)
        ? page.voidedPurchases
        : [];
      for (const item of items) {
        const normalized = normalizeVoidedPurchase(item);
        if (normalized?.purchaseToken === purchaseToken) {
          return normalized;
        }
      }
      pageToken = page?.tokenPagination?.nextPageToken || null;
    } while (pageToken);

    return null;
  }

  async function processVerifiedVoidedPurchase({
    packageName,
    voidedPurchase: rawVoided,
    productIdHint = null,
    sourcePath = 'voided_purchases_api',
    runId = null,
  }) {
    if (packageName !== PLAY_PACKAGE_NAME) {
      return {
        status: 'error',
        action: 'reject_package',
        message: `Wrong package name. Expected ${PLAY_PACKAGE_NAME}.`,
      };
    }

    const voidedPurchase = normalizeVoidedPurchase(rawVoided);
    if (!voidedPurchase) {
      return {
        status: 'error',
        action: 'reject_void_payload',
        message: 'voidedPurchase.purchaseToken is required.',
      };
    }

    const claim = await tryClaimVoidEvent(
      voidedPurchase.purchaseToken,
      voidedPurchase,
    );
    if (!claim.claimed) {
      return {
        status: 'duplicate_void',
        action: 'noop_duplicate_void',
        duplicate: true,
        purchaseTokenFingerprint: fingerprintSecret(voidedPurchase.purchaseToken),
        prior: claim.existing
          ? {
              status: claim.existing.status,
              resultStatus: claim.existing.resultStatus || null,
              action: claim.existing.action || null,
            }
          : null,
        eventId: claim.eventId,
      };
    }

    try {
      const transactionId = stableTransactionId({
        paymentProvider: PLAY_PROVIDER,
        providerTransactionId: voidedPurchase.purchaseToken,
      });
      const existingTxn = await transactions.get(transactionId);

      if (!existingTxn) {
        const result = {
          status: 'skipped',
          action: 'noop_unknown_purchase_token',
          message:
            'No payment_transactions row for this purchaseToken; '
            + 'nothing to revoke.',
          transactionId,
          purchaseTokenFingerprint: fingerprintSecret(
            voidedPurchase.purchaseToken,
          ),
          voidedReason: voidedPurchase.voidedReason,
          voidedReasonName: voidedReasonName(voidedPurchase.voidedReason),
        };
        await finishVoidEvent(claim.eventId, result);
        return result;
      }

      const productId =
        productIdHint
        || existingTxn.metadata?.productId
        || existingTxn.planId
        || null;
      const product = resolvePlayProduct(productId);
      if (!product) {
        const result = {
          status: 'error',
          action: 'reject_product',
          message: `Unknown or unmapped productId: ${productId}`,
          transactionId,
          uid: existingTxn.uid || null,
          productId,
          voidedReason: voidedPurchase.voidedReason,
          voidedReasonName: voidedReasonName(voidedPurchase.voidedReason),
        };
        await finishVoidEvent(claim.eventId, {
          ...result,
          status: 'skipped',
        });
        await recordOpsReview(result, {
          voidedPurchase,
          productId,
          packageName,
          sourcePath,
          runId,
        });
        return result;
      }

      if (
        existingTxn.courseId
        && existingTxn.courseId !== product.courseId
      ) {
        const result = {
          status: 'error',
          action: 'reject_course_mismatch',
          message: 'Transaction courseId does not match catalog mapping.',
          transactionId,
          uid: existingTxn.uid || null,
          courseId: existingTxn.courseId,
          productId: product.productId,
        };
        await finishVoidEvent(claim.eventId, {
          ...result,
          status: 'skipped',
        });
        await recordOpsReview(result, {
          voidedPurchase,
          productId: product.productId,
          packageName,
          sourcePath,
          runId,
        });
        return result;
      }

      const uid = String(existingTxn.uid || '').trim();
      if (!uid) {
        const result = {
          status: 'awaiting_account_link',
          action: 'awaiting_account_link',
          message:
            'Voided purchase has a transaction without uid; '
            + 'refusing to revoke an arbitrary user.',
          transactionId,
          courseId: product.courseId,
          productId: product.productId,
          voidedReason: voidedPurchase.voidedReason,
          voidedReasonName: voidedReasonName(voidedPurchase.voidedReason),
        };
        await finishVoidEvent(claim.eventId, result);
        await recordOpsReview(result, {
          voidedPurchase,
          productId: product.productId,
          packageName,
          sourcePath,
          runId,
        });
        return result;
      }

      const decision = decideVoidEntitlementAction(voidedPurchase.voidedReason);
      if (decision === 'manual_review') {
        const result = {
          status: 'manual_review',
          action: 'manual_review_unknown_void_reason',
          message:
            `Unknown voidedReason=${voidedPurchase.voidedReason}; `
            + 'entitlement not auto-revoked.',
          transactionId,
          uid,
          courseId: product.courseId,
          productId: product.productId,
          voidedReason: voidedPurchase.voidedReason,
          voidedReasonName: voidedReasonName(voidedPurchase.voidedReason),
          voidedSource: voidedPurchase.voidedSource,
        };
        await finishVoidEvent(claim.eventId, result);
        await recordOpsReview(result, {
          voidedPurchase,
          productId: product.productId,
          packageName,
          sourcePath,
          runId,
        });
        return result;
      }

      const before = await entitlements.get(uid, product.courseId);
      const alreadyRevoked =
        before?.status === 'revoked' || before?.status === 'inactive';
      const revoked = await entitlements.revoke(uid, product.courseId);
      await markTransactionVoided(transactionId, voidedPurchase, {
        sourcePath,
        metadata: {
          productId: product.productId,
        },
      });

      const result = {
        status: 'revoked',
        action: alreadyRevoked ? 'noop_already_revoked' : 'revoke',
        transactionId,
        uid,
        courseId: product.courseId,
        productId: product.productId,
        purchaseTokenFingerprint: fingerprintSecret(
          voidedPurchase.purchaseToken,
        ),
        voidedReason: voidedPurchase.voidedReason,
        voidedReasonName: voidedReasonName(voidedPurchase.voidedReason),
        voidedSource: voidedPurchase.voidedSource,
        voidedSourceName: voidedSourceName(voidedPurchase.voidedSource),
        entitlementStatus: revoked?.status || null,
        preservedDocument: Boolean(before || revoked),
        alreadyRevoked,
        googlePurchaseState: 'VOIDED',
      };
      await finishVoidEvent(claim.eventId, result);
      return result;
    } catch (error) {
      await voidedPurchaseEventDoc(db, claim.eventId).set(
        {
          status: 'failed',
          error: sanitizeErrorMessage(error),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      throw error;
    }
  }

  function accumulateMetrics(metrics, result, { matched = false } = {}) {
    if (matched) metrics.matchedCount += 1;
    switch (result?.status) {
      case 'revoked':
        metrics.revokedCount += 1;
        break;
      case 'duplicate_void':
        metrics.alreadyProcessedCount += 1;
        break;
      case 'awaiting_account_link':
        metrics.awaitingAccountLinkCount += 1;
        break;
      case 'manual_review':
        metrics.manualReviewCount += 1;
        break;
      case 'error':
        metrics.failedCount += 1;
        break;
      case 'skipped':
        metrics.skippedCount += 1;
        break;
      default:
        if (result?.status) metrics.skippedCount += 1;
        break;
    }
  }

  return {
    findVoidedPurchaseByToken,
    processVerifiedVoidedPurchase,
    configuredLookbackDays,

    async processRtdnVoidedNotification({
      packageName,
      purchaseToken,
      orderId = null,
      productType = null,
      refundType = null,
      eventTimeMillis = null,
    }) {
      if (packageName !== PLAY_PACKAGE_NAME) {
        return {
          status: 'error',
          action: 'reject_package',
          message: `Wrong package name. Expected ${PLAY_PACKAGE_NAME}.`,
        };
      }

      const token = String(purchaseToken || '').trim();
      if (!token) {
        return {
          status: 'skipped',
          action: 'noop_incomplete_voided',
          message: 'Missing purchaseToken on voidedPurchaseNotification.',
        };
      }

      if (productType != null && Number(productType) === 1) {
        return {
          status: 'skipped',
          action: 'noop_subscription_voided',
          message: 'Subscription void ignored (V1 is one-time products only).',
        };
      }

      let voidedPurchase;
      try {
        voidedPurchase = await findVoidedPurchaseByToken({
          packageName,
          purchaseToken: token,
          eventTimeMillis,
        });
      } catch (error) {
        const err = new Error(
          sanitizeErrorMessage(error) || 'Voided Purchases API failed.',
        );
        err.retryable = classifyListError(error) === 'transient';
        err.status = error?.status;
        throw err;
      }

      if (!voidedPurchase) {
        const err = new Error(
          'Voided purchase not yet visible in Voided Purchases API; retry.',
        );
        err.retryable = true;
        throw err;
      }

      if (!voidedPurchase.orderId && orderId) {
        voidedPurchase = { ...voidedPurchase, orderId: String(orderId) };
      }

      return processVerifiedVoidedPurchase({
        packageName,
        voidedPurchase,
        sourcePath: 'rtdn_voided',
        productIdHint: null,
      }).then((result) => ({
        ...result,
        refundType: refundType == null ? null : Number(refundType),
        rtdnOrderId: orderId || null,
      }));
    },

    /**
     * Daily reconciliation safety net.
     * Idempotent. Never trusts Google for courseId — catalog only.
     */
    async reconcileVoidedPurchases({
      packageName = PLAY_PACKAGE_NAME,
      startTime = null,
      endTime = null,
      runId = null,
    } = {}) {
      const startedAt = now().toISOString();
      const id = runId || randomUUID();
      const days = configuredLookbackDays();
      const metrics = emptyMetrics();

      if (packageName !== PLAY_PACKAGE_NAME) {
        const summary = {
          status: 'error',
          action: 'reject_package',
          runId: id,
          startedAt,
          completedAt: now().toISOString(),
          lookbackDays: days,
          googleApiMaxLookbackDays: GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS,
          message: `Wrong package name. Expected ${PLAY_PACKAGE_NAME}.`,
          ...metrics,
          results: [],
        };
        logger.error('voided_reconcile_rejected_package', {
          runId: id,
          packageName,
        });
        return summary;
      }

      const endMs = endTime != null ? Number(endTime) : now().getTime();
      const startMs =
        startTime != null
          ? Number(startTime)
          : endMs - days * MS_PER_DAY;

      logger.info('voided_reconcile_started', {
        runId: id,
        startedAt,
        lookbackDays: days,
        googleApiMaxLookbackDays: GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS,
        startTime: startMs,
        endTime: endMs,
        packageName,
      });

      const results = [];
      let pageToken = null;

      try {
        do {
          let page;
          try {
            // eslint-disable-next-line no-await-in-loop
            page = await verifier.listVoidedPurchases({
              packageName,
              startTime: startMs,
              endTime: endMs,
              maxResults: 1000,
              token: pageToken,
              type: 0,
            });
          } catch (error) {
            const kind = classifyListError(error);
            const summary = {
              status: kind === 'transient' ? 'error_retryable' : 'error',
              action: 'voided_list_failed',
              runId: id,
              startedAt,
              completedAt: now().toISOString(),
              lookbackDays: days,
              googleApiMaxLookbackDays: GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS,
              message: sanitizeErrorMessage(error),
              retryable: kind === 'transient',
              ...metrics,
              results,
            };
            logger.error('voided_reconcile_list_failed', {
              runId: id,
              retryable: kind === 'transient',
              message: sanitizeErrorMessage(error),
              ...metrics,
            });
            if (kind === 'transient') {
              const err = new Error(summary.message);
              err.retryable = true;
              err.summary = summary;
              throw err;
            }
            return summary;
          }

          const items = Array.isArray(page?.voidedPurchases)
            ? page.voidedPurchases
            : [];

          for (const item of items) {
            const voidedPurchase = normalizeVoidedPurchase(item);
            if (!voidedPurchase) {
              metrics.failedCount += 1;
              continue;
            }
            metrics.scannedCount += 1;

            const transactionId = stableTransactionId({
              paymentProvider: PLAY_PROVIDER,
              providerTransactionId: voidedPurchase.purchaseToken,
            });
            // eslint-disable-next-line no-await-in-loop
            const existingTxn = await transactions.get(transactionId);
            const productId =
              existingTxn?.metadata?.productId
              || existingTxn?.planId
              || null;
            const product = resolvePlayProduct(productId);

            // Product filtering: only catalog products. Unknown/unmatched skip.
            if (!existingTxn) {
              // eslint-disable-next-line no-await-in-loop
              const result = await processVerifiedVoidedPurchase({
                packageName,
                voidedPurchase,
                sourcePath: 'reconcile_voided_purchases',
                runId: id,
              });
              results.push({
                status: result.status,
                action: result.action,
                purchaseTokenFingerprint: fingerprintSecret(
                  voidedPurchase.purchaseToken,
                ),
              });
              accumulateMetrics(metrics, result, { matched: false });
              continue;
            }

            if (!product) {
              // eslint-disable-next-line no-await-in-loop
              const result = await processVerifiedVoidedPurchase({
                packageName,
                voidedPurchase,
                productIdHint: productId,
                sourcePath: 'reconcile_voided_purchases',
                runId: id,
              });
              results.push({
                status: result.status,
                action: result.action,
                purchaseTokenFingerprint: fingerprintSecret(
                  voidedPurchase.purchaseToken,
                ),
              });
              accumulateMetrics(metrics, result, { matched: true });
              continue;
            }

            // eslint-disable-next-line no-await-in-loop
            const result = await processVerifiedVoidedPurchase({
              packageName,
              voidedPurchase,
              productIdHint: product.productId,
              sourcePath: 'reconcile_voided_purchases',
              runId: id,
            });
            results.push({
              status: result.status,
              action: result.action,
              courseId: result.courseId || product.courseId,
              purchaseTokenFingerprint: fingerprintSecret(
                voidedPurchase.purchaseToken,
              ),
            });
            accumulateMetrics(metrics, result, { matched: true });
          }

          pageToken = page?.tokenPagination?.nextPageToken || null;
        } while (pageToken);
      } catch (error) {
        if (error?.summary) throw error;
        const err = new Error(sanitizeErrorMessage(error));
        err.retryable = true;
        throw err;
      }

      const completedAt = now().toISOString();
      const summary = {
        status: 'ok',
        action: 'reconcile_voided_purchases',
        runId: id,
        startedAt,
        completedAt,
        lookbackDays: days,
        googleApiMaxLookbackDays: GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS,
        ...metrics,
        results,
      };

      logger.info('voided_reconcile_completed', {
        runId: id,
        startedAt,
        completedAt,
        lookbackDays: days,
        scannedCount: metrics.scannedCount,
        matchedCount: metrics.matchedCount,
        revokedCount: metrics.revokedCount,
        alreadyProcessedCount: metrics.alreadyProcessedCount,
        awaitingAccountLinkCount: metrics.awaitingAccountLinkCount,
        manualReviewCount: metrics.manualReviewCount,
        failedCount: metrics.failedCount,
        skippedCount: metrics.skippedCount,
      });

      return summary;
    },
  };
}

/** Test helper: ensure reconcile logs never contain raw tokens. */
export function assertSafeReconcileLogPayload(payload, purchaseTokens = []) {
  const text = typeof payload === 'string' ? payload : JSON.stringify(payload);
  for (const token of purchaseTokens) {
    if (token && text.includes(token)) {
      throw new Error('Log payload leaked purchaseToken plaintext');
    }
  }
  if (/BEGIN PRIVATE KEY|private_key/i.test(text)) {
    throw new Error('Log payload leaked credential material');
  }
  return true;
}

export function sha256Fingerprint(value) {
  return createHash('sha256').update(String(value)).digest('hex');
}
