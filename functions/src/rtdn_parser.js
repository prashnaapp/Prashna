/**
 * Parse Google Play RTDN payloads delivered via Cloud Pub/Sub.
 *
 * DeveloperNotification shape:
 * https://developer.android.com/google/play/billing/rtdn-reference
 */
export const ONE_TIME_PRODUCT_PURCHASED = 1;
export const ONE_TIME_PRODUCT_CANCELED = 2;

/** VoidedPurchaseNotification.productType */
export const VOIDED_PRODUCT_TYPE_SUBSCRIPTION = 1;
export const VOIDED_PRODUCT_TYPE_ONE_TIME = 2;

/** VoidedPurchaseNotification.refundType */
export const VOIDED_REFUND_TYPE_FULL = 1;
export const VOIDED_REFUND_TYPE_QUANTITY_BASED = 2;

export function notificationTypeName(notificationType) {
  switch (Number(notificationType)) {
    case ONE_TIME_PRODUCT_PURCHASED:
      return 'ONE_TIME_PRODUCT_PURCHASED';
    case ONE_TIME_PRODUCT_CANCELED:
      return 'ONE_TIME_PRODUCT_CANCELED';
    default:
      return `UNKNOWN_${notificationType}`;
  }
}

/**
 * Decode a Pub/Sub message into a structured RTDN event.
 *
 * @param {object} pubsubMessage - CloudEvent data.message or { data, messageId }
 */
export function parseRtdnPubSubMessage(pubsubMessage) {
  if (!pubsubMessage) {
    throw new Error('Missing Pub/Sub message');
  }

  const messageId = String(
    pubsubMessage.messageId || pubsubMessage.message_id || '',
  ).trim();
  if (!messageId) {
    throw new Error('Pub/Sub messageId is required for RTDN idempotency');
  }

  const rawData = pubsubMessage.data;
  if (rawData == null || rawData === '') {
    throw new Error('Pub/Sub message data is empty');
  }

  const jsonText =
    typeof rawData === 'string'
      ? Buffer.from(rawData, 'base64').toString('utf8')
      : Buffer.from(rawData).toString('utf8');

  let developerNotification;
  try {
    developerNotification = JSON.parse(jsonText);
  } catch (error) {
    throw new Error(`Invalid RTDN JSON: ${error.message}`);
  }

  return {
    messageId,
    packageName: String(developerNotification.packageName || '').trim(),
    eventTimeMillis: developerNotification.eventTimeMillis ?? null,
    version: developerNotification.version ?? null,
    developerNotification,
    oneTime: developerNotification.oneTimeProductNotification
      ? {
          notificationType: Number(
            developerNotification.oneTimeProductNotification.notificationType,
          ),
          notificationTypeName: notificationTypeName(
            developerNotification.oneTimeProductNotification.notificationType,
          ),
          purchaseToken: String(
            developerNotification.oneTimeProductNotification.purchaseToken || '',
          ).trim(),
          sku: String(
            developerNotification.oneTimeProductNotification.sku || '',
          ).trim(),
          version: developerNotification.oneTimeProductNotification.version,
        }
      : null,
    isTest: Boolean(developerNotification.testNotification),
    hasSubscriptionNotification: Boolean(
      developerNotification.subscriptionNotification,
    ),
    voided: developerNotification.voidedPurchaseNotification
      ? {
          purchaseToken: String(
            developerNotification.voidedPurchaseNotification.purchaseToken
              || '',
          ).trim(),
          orderId: String(
            developerNotification.voidedPurchaseNotification.orderId || '',
          ).trim() || null,
          productType: Number(
            developerNotification.voidedPurchaseNotification.productType,
          ),
          refundType:
            developerNotification.voidedPurchaseNotification.refundType
              == null
              ? null
              : Number(
                developerNotification.voidedPurchaseNotification.refundType,
              ),
        }
      : null,
    hasVoidedPurchaseNotification: Boolean(
      developerNotification.voidedPurchaseNotification,
    ),
    hasPendingRefundReviewNotification: Boolean(
      developerNotification.pendingRefundReviewNotification,
    ),
  };
}

/**
 * Extract message fields from a Firebase Functions v2 Pub/Sub CloudEvent.
 */
export function extractPubSubMessageFromCloudEvent(event) {
  const message = event?.data?.message || event?.data || event;
  return {
    data: message?.data,
    messageId: message?.messageId || message?.message_id || event?.id,
    attributes: message?.attributes || {},
  };
}
