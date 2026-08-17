# Prashna Cloud Functions (local)

Trusted entitlement + Google Play purchase verification + RTDN + void
protection + scheduled reconciliation.

## Scope

- Grant / revoke / extend / get entitlements on `user_courses/{uid}/courses/{courseId}`
- Idempotent verified-payment processing → `payment_transactions` + entitlement
- Admin-only callables (`request.auth.token.admin === true`)
- Authenticated `verifyPlayPurchase` callable (Google Play Developer API)
- Pub/Sub `onPlayRtdn` for Google Play Real-time Developer Notifications
- Voided purchase protection via Voided Purchases API
- Scheduled `reconcileVoidedPurchases` (daily, asia-south1) — **do not deploy yet**
- Backend `payment_ops_reviews` for manual_review / awaiting_account_link

## Out of scope (until explicit ops approval)

- Production deploy
- Production data writes
- Razorpay / Stripe
- Issuing refunds from Prashna
- Admin Ops UI
- `pendingRefundReviewNotification` handling

## Commands

```bash
cd functions
npm install
npm test
npm run lint
```

Do **not** run `firebase deploy --only functions` unless explicitly approved.
Secrets: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (never commit).
Topic: `play-rtdn`  
Lookback: `VOIDED_PURCHASE_LOOKBACK_DAYS` (≤ 30)  
Ops: `docs/play_billing_operations.md`
