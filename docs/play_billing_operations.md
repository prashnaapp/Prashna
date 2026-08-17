# Google Play Billing — Operations Runbook

Backend-only payment ops for Prashna Group II (`group2_12m` → `group-ii`).

**Never put service-account JSON, private keys, or live purchase tokens in
tickets, chat, or this repo.**

---

## 1. Failed payment verification

**Symptoms**
- Client `verifyPlayPurchase` returns `error` / `pending`
- User paid in Play but has no active `UserCourse`

**Inspect (Admin SDK / Firebase console, backend-only)**
1. `payment_transactions` for hashed id from
   `stableTransactionId(google_play, purchaseToken)`
2. Callable logs for `verifyPlayPurchase` (no secrets)
3. Play Console order / purchase token status

**Common causes**
- Wrong package (`com.prashna.app` required)
- Unknown product id (must be `group2_12m`)
- Google purchase still `PENDING`
- Obfuscated account mismatch
- Play API credential / permission failure

**Safe action**
- Do **not** manually invent a success transaction from the client.
- Prefer re-running verification after Play state is `PURCHASED`, or
  admin grant only after confirming the Play order.

---

## 2. Missed RTDN

**Symptoms**
- Purchase or void happened in Play, but no matching `rtdn_events/{messageId}`
- Entitlement out of sync with Play

**Inspect**
1. Pub/Sub topic `play-rtdn` delivery / dead letter
2. Function `onPlayRtdn` logs in `asia-south1`
3. Daily job `reconcileVoidedPurchases` metrics (voids only)

**Note**
RTDN purchased/canceled gaps are primarily healed by client
`verifyPlayPurchase` and/or CANCELED RTDN retry. Void gaps are healed by
scheduled void reconciliation.

---

## 3. How reconciliation works

Function: `reconcileVoidedPurchases` (scheduled, not client-callable)

1. Reads `VOIDED_PURCHASE_LOOKBACK_DAYS` (default 30, capped at Google’s
   Voided Purchases API max of **30 days**)
2. Calls `purchases.voidedpurchases.list` for `com.prashna.app` (`type=0`)
3. Matches `purchaseToken` → `payment_transactions`
4. Resolves product only via `PLAY_PRODUCT_CATALOG`
5. Applies existing `revoke()` when void reason policy says so
6. Writes idempotent `voided_purchase_events` + optional `payment_ops_reviews`

Structured log fields: `runId`, counts (scanned/matched/revoked/…),
timestamps. Purchase tokens are fingerprinted, never logged raw.

---

## 4. Inspect a voided purchase

1. Find `payment_transactions` by purchase token (backend)
2. Check `metadata.voided`, `voidedReasonName`, `status` (`cancelled`)
3. Check `voided_purchase_events/{stableId}`
4. Check `user_courses/{uid}/courses/group-ii` → expect `revoked` if applied
5. Optionally confirm in Play Voided Purchases API / Play Console order

---

## 5. Manual review (`manual_review`)

Created when `voidedReason` is unknown/future (not in codes 0–8).

Collection: `payment_ops_reviews/{reviewId}`

Fields include: `purchaseToken`, `productId`, `packageName`, `voidReason`,
`voidedSource`, `detectedAt`, `status`, `reason`/`details`, `uid`,
`courseId`, `transactionId`.

**Do not auto-revoke.** Ops must confirm Play state, then either:
- call trusted admin revoke, or
- mark review `resolved` after confirming no action needed

Statuses: `pending` | `manual_review` | `resolved` | `failed`

---

## 6. `awaiting_account_link`

Means a void (or RTDN) could not safely map to a Firebase uid.

**Resolution**
1. Confirm whether `payment_transactions` exists and has `uid`
2. If the user later completes `verifyPlayPurchase`, account link is written
3. Re-run reconciliation (or process the void again after uid exists)
4. Never pick “likely” users from email/device guesses

Ops review status for this case: `pending`

---

## 7. Safely revoke entitlement

Use backend only:
- Admin callable `adminRevokeEntitlement`, or
- Existing `createEntitlementService(db).revoke(uid, courseId)`

Effects:
- Sets `UserCourse.status = revoked`
- Does **not** delete the document
- Does **not** delete `payment_transactions`

---

## 8. Duplicate transaction investigation

Identity: `paymentProvider + providerTransactionId` (`purchaseToken`)

1. Compute `stableTransactionId`
2. Confirm a single `payment_transactions` doc
3. Duplicate grants should show `duplicate: true` / no expiry extension
4. Duplicate voids show `voided_purchase_events` already `processed`

Do not create a second transaction “to fix” a duplicate.

---

## 9. What NOT to change manually

- Do not set `UserCourse.status = active` from the client console without
  a verified Play purchase / admin policy decision
- Do not delete historical `payment_transactions`
- Do not paste service account keys into Firestore
- Do not trust RTDN notification type alone
- Do not issue Play refunds from Prashna (Play Console / Play APIs only,
  as a separate ops action)

---

## 10. Controlled test purchase

1. License tester Google account in Play Console
2. Internal/closed testing track build with Billing
3. Buy `group2_12m`
4. Confirm `verifyPlayPurchase` → active `group-ii` entitlement
5. Confirm `payment_transactions` success + account link row

No real-money production cutover from this runbook alone.

---

## 11. Controlled refund / void test

1. Use a test purchase (license tester)
2. Refund/void from Play Console
3. Expect RTDN `voidedPurchaseNotification` and/or next daily reconcile
4. Confirm entitlement `revoked`, transaction preserved as `cancelled`
5. Confirm duplicate reconcile is a no-op

---

## 12. Production deployment checks

Before first deploy of payment Functions:

- [ ] `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret configured (not in git)
- [ ] Play Android Developer API enabled; SA permitted for products + voided list
- [ ] Product `group2_12m` active
- [ ] Pub/Sub topic `play-rtdn` + Play RTDN wired (including voided)
- [ ] Functions region `asia-south1`
- [ ] `onPlayRtdn`, `verifyPlayPurchase`, `reconcileVoidedPurchases` exported
- [ ] `VOIDED_PURCHASE_LOOKBACK_DAYS` set intentionally (≤ 30)
- [ ] Scheduler created only via Functions deploy (no ad-hoc prod edits)
- [ ] Test with license testers only first
- [ ] Ops know how to read `payment_ops_reviews` + reconcile logs

**This phase does not deploy.** Create infrastructure only after explicit approval.
