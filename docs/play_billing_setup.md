# Google Play Billing + RTDN — Manual Setup

Do **not** deploy Functions or publish the app until explicitly approved.

## Play Console — product

1. Open the Android app with application ID `com.prashna.app`.
2. Create a **one-time** in-app product with ID exactly:
   - `group2_12m`
3. Title/description can say Group II 12-Month Access.
4. Set the commercial price in Play Console (UI shows Play’s localized price).
5. Activate the product.
6. Add **license tester** Google accounts for test purchases (no real money).

## Google Play Developer API (backend verification)

1. In Google Cloud project linked to the Firebase/Play app, enable
   **Google Play Android Developer API**.
2. Create a service account (or reuse a locked-down ops SA).
3. In Play Console → Users and permissions, invite that service account with
   permission to view financial data / manage orders as required for
   `purchases.products.get`, `purchases.products.acknowledge`, and
   `purchases.voidedpurchases.list`.
4. For Cloud Functions, store credentials as a secret, e.g.:
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` = full JSON key string
   - **Never** commit the JSON key to Git, Flutter, or Android source.

## Firebase Functions — client verify

Callable (region `asia-south1`):

- `verifyPlayPurchase` — authenticated users only; UID from `request.auth`

## Pub/Sub RTDN (Phase 5.14+)

Function: `onPlayRtdn`  
Topic (default): `play-rtdn` (override with env `PLAY_RTDN_TOPIC`)  
Region: `asia-south1`

### Manual wiring

1. Create Pub/Sub topic `play-rtdn` in the same GCP project as Firebase.
2. Grant `google-play-developer-notifications@system.gserviceaccount.com`
   the **Pub/Sub Publisher** role on that topic.
3. Play Console → Monetization setup → Real-time developer notifications:
   - Topic name: `projects/<PROJECT_ID>/topics/play-rtdn`
   - Notification content: **Subscriptions, voided purchases, and all one-time products**
4. Send a Play Console test notification and confirm `onPlayRtdn` receives it
   (after Functions deploy).
5. Deploy Functions only after secrets + topic + Play product are ready.

### Handled notification types

- `ONE_TIME_PRODUCT_PURCHASED` (notificationType=1)
- `ONE_TIME_PRODUCT_CANCELED` (notificationType=2)
- `voidedPurchaseNotification` (refund / chargeback / revoke)

One-time purchased/canceled events re-query `purchases.products.get`.  
Voided events re-query `purchases.voidedpurchases.list` and match by
`purchaseToken` before calling existing `revoke()`.

Notification payloads alone never grant or revoke access.

### Voided Purchases API (Phase 5.15)

Endpoint:

`GET .../androidpublisher/v3/applications/{packageName}/purchases/voidedpurchases`

- Scoped to `com.prashna.app`
- `type=0` (in-app / one-time products only for V1)
- Lookback limited to Google’s ~30-day window
- Primary identity: `purchaseToken` (not `orderId`)

#### voidedReason (auto-revoke when known)

| Code | Name | Action |
|------|------|--------|
| 0 | OTHER | revoke |
| 1 | REMORSE (refund) | revoke |
| 2 | NOT_RECEIVED | revoke |
| 3 | DEFECTIVE | revoke |
| 4 | ACCIDENTAL_PURCHASE | revoke |
| 5 | FRAUD | revoke |
| 6 | FRIENDLY_FRAUD | revoke |
| 7 | CHARGEBACK | revoke |
| 8 | UNACKNOWLEDGED_PURCHASE | revoke |
| other | UNKNOWN | manual_review (no auto-revoke) |

#### voidedSource (diagnostic)

| Code | Name |
|------|------|
| 0 | USER |
| 1 | DEVELOPER |
| 2 | GOOGLE |

Prashna does **not** issue refunds from the backend. This phase only detects
voids and revokes entitlement when justified.

### Reconciliation (Phase 5.16 — code present, do not deploy yet)

Scheduled Function: `reconcileVoidedPurchases`  
Schedule: `30 3 * * *` (`Asia/Kolkata`)  
Region: `asia-south1`

Env: `VOIDED_PURCHASE_LOOKBACK_DAYS` (default 30, capped at Google’s 30-day
Voided Purchases API maximum).

Ops runbook: `docs/play_billing_operations.md`  
Ops review collection: `payment_ops_reviews` (Admin SDK only)

### Deferred / later

- `pendingRefundReviewNotification`
- Subscription notifications (V1 is one-time only)
- Production Scheduler activation after explicit deploy approval

## Client / server product config

Client: `lib/features/payments/config/play_billing_config.dart`  
Server: `functions/src/play_product_catalog.js` (`PLAY_PACKAGE_NAME`)

- `packageName = com.prashna.app`
- `group2_12m` → `group-ii` + `accessDurationDays: 365`
