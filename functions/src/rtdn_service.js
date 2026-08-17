/**
 * Google Play RTDN lifecycle processor.
 *
 * Always re-queries Google Play Developer API before grant/revoke.
 * Notification type alone is never sufficient proof.
 */
import {
  PLAY_PACKAGE_NAME,
  PLAY_PROVIDER,
  computeExpiresAt,
  resolvePlayProduct,
} from './play_product_catalog.js';
import {
  createGooglePlayVerifier,
  mapPurchaseState,
} from './google_play_verifier.js';
import { createPaymentProcessingService } from './payment_processing_service.js';
import { createTransactionService } from './transaction_service.js';
import { createEntitlementService } from './entitlement_service.js';
import { stableTransactionId } from './ids.js';
import { createRtdnIdempotencyStore } from './rtdn_idempotency.js';
import { createPlayAccountLinkStore } from './play_account_links.js';
import {
  ONE_TIME_PRODUCT_CANCELED,
  ONE_TIME_PRODUCT_PURCHASED,
  extractPubSubMessageFromCloudEvent,
  parseRtdnPubSubMessage,
} from './rtdn_parser.js';
import { createVoidedPurchaseService } from './voided_purchase_service.js';

export function createRtdnService({
  db,
  googlePlayVerifier,
  now = () => new Date(),
}) {
  const verifier = googlePlayVerifier || createGooglePlayVerifier();
  const payments = createPaymentProcessingService(db);
  const transactions = createTransactionService(db);
  const entitlements = createEntitlementService(db);
  const idempotency = createRtdnIdempotencyStore(db);
  const accountLinks = createPlayAccountLinkStore(db);
  const voidedPurchases = createVoidedPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now,
  });

  async function resolveUid({ purchaseToken, googlePurchase }) {
    const transactionId = stableTransactionId({
      paymentProvider: PLAY_PROVIDER,
      providerTransactionId: purchaseToken,
    });
    const existingTxn = await transactions.get(transactionId);
    if (existingTxn?.uid) return existingTxn.uid;

    const obfuscated = googlePurchase?.obfuscatedExternalAccountId;
    if (obfuscated) {
      const linked = await accountLinks.resolveUid(obfuscated);
      if (linked) return linked;
    }
    return null;
  }

  async function handlePurchasedCurrentState({
    uid,
    product,
    purchaseToken,
    packageName,
    googlePurchase,
    purchaseState,
  }) {
    const expiresAt = computeExpiresAt(product.accessDurationDays, {
      from: now(),
    });
    const grant = await payments.processVerifiedPayment({
      paymentProvider: PLAY_PROVIDER,
      providerTransactionId: purchaseToken,
      uid,
      courseId: product.courseId,
      planId: product.planId,
      amount: 0,
      currency: 'INR',
      expiresAt,
      source: 'purchase',
      metadata: {
        productId: product.productId,
        packageName,
        orderId: googlePurchase.orderId ?? null,
        purchaseState,
        acknowledgementState: googlePurchase.acknowledgementState ?? null,
        purchaseTimeMillis: googlePurchase.purchaseTimeMillis ?? null,
        regionCode: googlePurchase.regionCode ?? null,
        sourcePath: 'rtdn',
      },
    });

    await accountLinks.upsert(uid);

    const transactionId =
      grant.transactionId
      || stableTransactionId({
        paymentProvider: PLAY_PROVIDER,
        providerTransactionId: purchaseToken,
      });

    if (Number(googlePurchase.acknowledgementState) !== 1) {
      try {
        await verifier.acknowledgeProductPurchase({
          packageName,
          productId: product.productId,
          purchaseToken,
        });
      } catch {
        // Entitlement already granted; ack can retry on next event/verify.
      }
    }

    return {
      status: grant.duplicate ? 'already_owned' : 'success',
      action: grant.duplicate ? 'noop_duplicate_purchase' : 'grant',
      duplicate: grant.duplicate === true,
      transactionId,
      courseId: product.courseId,
      uid,
      googlePurchaseState: purchaseState,
      entitlementStatus: grant.entitlementStatus,
    };
  }

  async function handleCanceledCurrentState({
    uid,
    product,
    purchaseToken,
    purchaseState,
  }) {
    const transactionId = stableTransactionId({
      paymentProvider: PLAY_PROVIDER,
      providerTransactionId: purchaseToken,
    });
    const existingTxn = await transactions.get(transactionId);

    // Pending cancel with no prior success transaction: nothing to revoke.
    if (!existingTxn || existingTxn.status !== 'success') {
      return {
        status: 'skipped',
        action: 'noop_canceled_without_grant',
        transactionId: existingTxn?.transactionId || transactionId,
        courseId: product.courseId,
        uid,
        googlePurchaseState: purchaseState,
      };
    }

    const before = await entitlements.get(uid, product.courseId);
    const revoked = await entitlements.revoke(uid, product.courseId);
    return {
      status: 'revoked',
      action: 'revoke',
      transactionId,
      courseId: product.courseId,
      uid,
      googlePurchaseState: purchaseState,
      entitlementStatus: revoked?.status || null,
      preservedDocument: Boolean(before || revoked),
    };
  }

  async function processOneTimeNotification(envelope) {
    const packageName = envelope.packageName;
    if (packageName !== PLAY_PACKAGE_NAME) {
      return {
        status: 'error',
        action: 'reject_package',
        message: `Wrong package name. Expected ${PLAY_PACKAGE_NAME}.`,
      };
    }

    const oneTime = envelope.oneTime;
    if (!oneTime?.purchaseToken || !oneTime?.sku) {
      return {
        status: 'skipped',
        action: 'noop_incomplete_one_time',
        message: 'Missing purchaseToken or sku.',
      };
    }

    const product = resolvePlayProduct(oneTime.sku);
    if (!product) {
      return {
        status: 'error',
        action: 'reject_product',
        message: `Unknown or unmapped productId/sku: ${oneTime.sku}`,
      };
    }

    let googlePurchase;
    try {
      googlePurchase = await verifier.getProductPurchase({
        packageName,
        productId: product.productId,
        purchaseToken: oneTime.purchaseToken,
      });
    } catch (error) {
      const err = new Error(
        error.message || 'Google Play verification failed for RTDN.',
      );
      err.retryable = true;
      throw err;
    }

    const purchaseState = mapPurchaseState(googlePurchase.purchaseState);
    const uid = await resolveUid({
      purchaseToken: oneTime.purchaseToken,
      googlePurchase,
    });

    // Decision is based on CURRENT Google state, not notification type alone.
    if (purchaseState === 'PURCHASED') {
      if (!uid) {
        return {
          status: 'skipped',
          action: 'awaiting_account_link',
          message:
            'Purchase is PURCHASED but no Firebase uid mapping exists yet. '
            + 'Client verifyPlayPurchase will complete entitlement.',
          courseId: product.courseId,
          googlePurchaseState: purchaseState,
          notificationType: oneTime.notificationTypeName,
        };
      }
      return handlePurchasedCurrentState({
        uid,
        product,
        purchaseToken: oneTime.purchaseToken,
        packageName,
        googlePurchase,
        purchaseState,
      });
    }

    if (purchaseState === 'CANCELED') {
      if (!uid) {
        return {
          status: 'skipped',
          action: 'noop_canceled_unlinked',
          message: 'Canceled purchase with no linked Firebase uid.',
          courseId: product.courseId,
          googlePurchaseState: purchaseState,
          notificationType: oneTime.notificationTypeName,
        };
      }
      return handleCanceledCurrentState({
        uid,
        product,
        purchaseToken: oneTime.purchaseToken,
        purchaseState,
      });
    }

    if (purchaseState === 'PENDING') {
      return {
        status: 'skipped',
        action: 'noop_pending',
        message: 'Current Google state is PENDING — no entitlement change.',
        courseId: product.courseId,
        uid,
        googlePurchaseState: purchaseState,
        notificationType: oneTime.notificationTypeName,
      };
    }

    return {
      status: 'skipped',
      action: 'noop_unknown_state',
      message: `Unsupported current purchase state: ${purchaseState}`,
      courseId: product.courseId,
      uid,
      googlePurchaseState: purchaseState,
      notificationType: oneTime.notificationTypeName,
    };
  }

  return {
    /**
     * Process a decoded RTDN envelope (already parsed).
     */
    async processEnvelope(envelope) {
      const claim = await idempotency.tryClaim(envelope.messageId, envelope, {
        now,
      });
      if (!claim.claimed) {
        return {
          status: 'duplicate_message',
          action: 'noop_duplicate_message',
          messageId: envelope.messageId,
          duplicate: true,
          prior: claim.existing || null,
          inProgress: claim.inProgress === true,
        };
      }

      try {
        let result;
        if (envelope.isTest) {
          result = {
            status: 'skipped',
            action: 'noop_test_notification',
            message: 'Test notification acknowledged.',
          };
        } else if (envelope.oneTime) {
          // Record notification type for diagnostics, but decide from Google state.
          if (
            envelope.oneTime.notificationType !== ONE_TIME_PRODUCT_PURCHASED
            && envelope.oneTime.notificationType !== ONE_TIME_PRODUCT_CANCELED
          ) {
            result = {
              status: 'skipped',
              action: 'noop_unhandled_one_time_type',
              message: `Unhandled one-time notificationType=${envelope.oneTime.notificationType}`,
              notificationType: envelope.oneTime.notificationTypeName,
            };
          } else {
            result = await processOneTimeNotification(envelope);
          }
        } else if (envelope.voided || envelope.hasVoidedPurchaseNotification) {
          result = await voidedPurchases.processRtdnVoidedNotification({
            packageName: envelope.packageName,
            purchaseToken: envelope.voided?.purchaseToken,
            orderId: envelope.voided?.orderId,
            productType: envelope.voided?.productType,
            refundType: envelope.voided?.refundType,
            eventTimeMillis: envelope.eventTimeMillis,
          });
        } else if (envelope.hasSubscriptionNotification) {
          result = {
            status: 'skipped',
            action: 'noop_subscription_not_used',
            message: 'Subscription RTDN ignored (V1 is one-time products only).',
          };
        } else if (envelope.hasPendingRefundReviewNotification) {
          result = {
            status: 'skipped',
            action: 'noop_pending_refund_deferred',
            message: 'pendingRefundReviewNotification deferred.',
          };
        } else {
          result = {
            status: 'skipped',
            action: 'noop_empty_notification',
            message: 'No supported notification payload present.',
          };
        }

        if (result.status === 'error' && result.action?.startsWith('reject_')) {
          await idempotency.markSkipped(envelope.messageId, result.message, {
            action: result.action,
          });
          return { ...result, messageId: envelope.messageId };
        }

        if (result.status === 'skipped') {
          await idempotency.markSkipped(envelope.messageId, result.message, {
            action: result.action,
            courseId: result.courseId || null,
            uid: result.uid || null,
            googlePurchaseState: result.googlePurchaseState || null,
          });
        } else {
          await idempotency.markProcessed(envelope.messageId, result);
        }

        return { ...result, messageId: envelope.messageId };
      } catch (error) {
        await idempotency.markFailed(
          envelope.messageId,
          error.message || String(error),
        );
        throw error;
      }
    },

    /**
     * Entry point for Pub/Sub CloudEvent / message objects.
     */
    async processPubSubMessage(pubsubMessage) {
      const envelope = parseRtdnPubSubMessage(pubsubMessage);
      return this.processEnvelope(envelope);
    },

    async processCloudEvent(event) {
      const message = extractPubSubMessageFromCloudEvent(event);
      return this.processPubSubMessage(message);
    },
  };
}
