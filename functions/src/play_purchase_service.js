/**
 * Orchestrates Google Play purchase verification → entitlement grant → ack.
 *
 * Reuses processVerifiedPayment() — no second entitlement path.
 */
import { createHash } from 'node:crypto';

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
import { stableTransactionId } from './ids.js';
import { createPlayAccountLinkStore } from './play_account_links.js';

function sha256Hex(value) {
  return createHash('sha256').update(String(value)).digest('hex');
}

function obfuscatedAccountIdForUid(uid) {
  const hex = sha256Hex(uid.trim());
  return hex.length <= 64 ? hex : hex.substring(0, 64);
}

export function createPlayPurchaseService({
  db,
  googlePlayVerifier,
  now = () => new Date(),
}) {
  const verifier = googlePlayVerifier || createGooglePlayVerifier();
  const payments = createPaymentProcessingService(db);
  const transactions = createTransactionService(db);
  const accountLinks = createPlayAccountLinkStore(db);

  return {
    /**
     * @param {object} input
     * @param {string} input.uid authenticated Firebase UID (from request.auth)
     * @param {string} input.productId
     * @param {string} input.purchaseToken
     * @param {string} [input.packageName]
     */
    async verifyAndGrant(input) {
      const uid = String(input.uid || '').trim();
      const productId = String(input.productId || '').trim();
      const purchaseToken = String(input.purchaseToken || '').trim();
      const packageName = String(
        input.packageName || PLAY_PACKAGE_NAME,
      ).trim();

      if (!uid) {
        return { status: 'error', message: 'Authenticated uid is required.' };
      }
      if (!productId || !purchaseToken) {
        return {
          status: 'error',
          message: 'productId and purchaseToken are required.',
        };
      }
      if (packageName !== PLAY_PACKAGE_NAME) {
        return {
          status: 'error',
          message: `Wrong package name. Expected ${PLAY_PACKAGE_NAME}.`,
        };
      }

      const product = resolvePlayProduct(productId);
      if (!product) {
        return {
          status: 'error',
          message: `Unknown or unmapped productId: ${productId}`,
        };
      }

      let googlePurchase;
      try {
        googlePurchase = await verifier.getProductPurchase({
          packageName,
          productId,
          purchaseToken,
        });
      } catch (error) {
        return {
          status: 'error',
          message: error.message || 'Google Play verification failed.',
        };
      }

      const purchaseState = mapPurchaseState(googlePurchase.purchaseState);
      if (purchaseState === 'PENDING') {
        return {
          status: 'pending',
          message: 'Purchase is pending. Entitlement is not granted.',
          courseId: product.courseId,
          productId,
        };
      }
      if (purchaseState === 'CANCELED') {
        return {
          status: 'error',
          message: 'Purchase was canceled.',
          courseId: product.courseId,
          productId,
        };
      }
      if (purchaseState !== 'PURCHASED') {
        return {
          status: 'error',
          message: `Unsupported purchase state: ${purchaseState}`,
          courseId: product.courseId,
          productId,
        };
      }

      // Optional ownership hint — reject clear mismatches when Google returns it.
      const expectedObfuscated = obfuscatedAccountIdForUid(uid);
      const googleObfuscated = googlePurchase.obfuscatedExternalAccountId;
      if (
        typeof googleObfuscated === 'string'
        && googleObfuscated.length > 0
        && googleObfuscated !== expectedObfuscated
      ) {
        return {
          status: 'error',
          message: 'Purchase is not associated with this Firebase account.',
        };
      }

      const expiresAt = computeExpiresAt(product.accessDurationDays, {
        from: now(),
      });

      // purchaseToken is the provider identity (not orderId).
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
          productId,
          packageName,
          orderId: googlePurchase.orderId ?? null,
          purchaseState,
          acknowledgementState: googlePurchase.acknowledgementState ?? null,
          purchaseTimeMillis: googlePurchase.purchaseTimeMillis ?? null,
          regionCode: googlePurchase.regionCode ?? null,
          rtdnReady: true,
        },
      });

      await accountLinks.upsert(uid);

      const transactionId =
        grant.transactionId
        || stableTransactionId({
          paymentProvider: PLAY_PROVIDER,
          providerTransactionId: purchaseToken,
        });

      // Acknowledge only after successful verification + entitlement grant.
      let acknowledgement = {
        attempted: false,
        success: false,
        alreadyAcknowledged: Number(googlePurchase.acknowledgementState) === 1,
      };

      if (Number(googlePurchase.acknowledgementState) !== 1) {
        acknowledgement.attempted = true;
        try {
          await verifier.acknowledgeProductPurchase({
            packageName,
            productId,
            purchaseToken,
          });
          acknowledgement.success = true;
          await transactions.markStatus(transactionId, 'success', {
            verifiedAt: now(),
          });
          // Best-effort metadata update for ack — entitlement already granted.
          const existing = await transactions.get(transactionId);
          if (existing) {
            // markStatus only updates status; ack flag lives in metadata via merge set
          }
        } catch (error) {
          acknowledgement.success = false;
          acknowledgement.error = error.message || String(error);
          // Do NOT revoke or re-grant. Retry ack is idempotent on next verify.
        }
      } else {
        acknowledgement.alreadyAcknowledged = true;
        acknowledgement.success = true;
      }

      return {
        status: grant.duplicate ? 'already_owned' : 'success',
        duplicate: grant.duplicate === true,
        transactionId,
        courseId: product.courseId,
        productId,
        entitlementStatus: grant.entitlementStatus,
        acknowledgement,
        message: grant.duplicate
          ? 'Purchase already verified for this account.'
          : 'Purchase verified and entitlement granted.',
      };
    },
  };
}
