# Phase 5.17 — Controlled Google Play E2E Validation Checklist

**Status: BLOCKED until prerequisites below are green.**

This document is the operator runbook for a **license-tester** end-to-end
validation. It does **not** authorize real-money purchases, production student
testing, or commit/push.

---

## Hard prerequisites (STOP if any fail)

| # | Check | Expected | Status |
|---|--------|----------|--------|
| 1 | Firebase project | `prashna-67689` (explicitly approved for this dry-run) | CLI current = `prashna-67689` |
| 2 | Billing plan | **Blaze** (required for Functions + Secret Manager) | **FAIL — Spark / upgrade required** |
| 3 | Android package | `com.prashna.app` | Code + `google-services.json` OK |
| 4 | Play product | one-time `group2_12m` active | **Unverified in Play Console from agent** |
| 5 | Functions region | `asia-south1` | Code OK |
| 6 | Test Firebase UID | dedicated license-tester user, **not** a production student | **Unverified — provide UID** |
| 7 | Play license tester | Google account added in Play Console license testing | **Unverified — provide email** |
| 8 | SA secret in Git | none | OK (no `.env` / SA JSON tracked) |
| 9 | Catalog | `group2_12m` → `group-ii` → 365 days | Code OK |
| 10 | Client writes denied | `user_courses`, `payment_transactions` | Rules OK |
| 11 | Real money | license tester / test track only | **Unverified until Play Console confirmed** |
| 12 | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | configured as Functions secret (never printed) | **Blocked — Secret Manager needs Blaze** |
| 13 | Pub/Sub topic | `play-rtdn` + Play RTDN wired | **Not created / unverified** |

**Do not deploy Functions until rows 2, 4, 6, 7, 11, 12, 13 are confirmed.**

---

## Pre-deploy record (fill at deploy time)

- Firebase project:
- Functions to deploy (only):
  - `verifyPlayPurchase`
  - `onPlayRtdn`
  - `reconcileVoidedPurchases`
  - (optional admin callables if already required for ops revoke)
- Region: `asia-south1`
- Secrets present (names only): `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- Env: `PLAY_RTDN_TOPIC=play-rtdn`, `VOIDED_PURCHASE_LOOKBACK_DAYS=30`
- RTDN topic: `projects/prashna-67689/topics/play-rtdn`
- Deploy operator:
- Deploy timestamp:

Suggested command **after** Blaze + secrets (do not run until approved):

```bash
firebase deploy --only \
  functions:verifyPlayPurchase,functions:onPlayRtdn,functions:reconcileVoidedPurchases \
  --project prashna-67689
```

---

## Test matrix (operator)

### TEST 1 — Product discovery
Install internal/closed test build → login with license-tester Firebase account →
confirm Group II card, Play title, **Play-localized price**, Buy enabled.

### TEST 2 — Purchase
License-tester purchase of `group2_12m`. Record account (email), product ID,
time, app version. **Do not paste purchaseToken into git.** Confirm Flutter
`PURCHASED` and `verifyPlayPurchase` call.

### TEST 3 — Backend verification
Auth uid from `request.auth` only; package/product verified; course from catalog;
`payment_transactions` success; purchase acknowledged; no duplicate txn.

### TEST 4 — Access
`user_courses/{uid}/courses/group-ii` → `status=active`, `expiresAt ≈ now+365d`.
Restart app; access via `SubscriptionAccessService` only.

### TEST 5 — RTDN
Confirm `onPlayRtdn` log (messageId fingerprint only). Duplicate delivery harmless.

### TEST 6 — Void/refund (license-test only)
Play Console refund/void of the **test** order. Confirm revoke; UserCourse kept;
transaction preserved as `cancelled`.

### TEST 7 — Reconciliation
Manual invoke / Scheduler run once, then again. Second run idempotent.
Capture metrics: scanned, matched, revoked, alreadyProcessed,
awaitingAccountLink, manualReview, failed, skipped.

### TEST 8 — Access after revoke
Reload CourseContext; Group II denied; free content still works.

### TEST 9 — Security
Unauthenticated verify rejected; client cannot write entitlements/transactions;
client cannot call reconcile; spoofed courseId ignored (catalog only).

### TEST 10 — Failure cases
Prefer unit mocks (already in `functions/test`). Do not invent live Play failures
unnecessarily.

---

## Rollback (no production infra deletion)

1. **Purchase UI:** hide Group II buy CTA / feature flag / ship build without
   Play product query.
2. **RTDN:** remove Play Console RTDN topic binding (or pause Pub/Sub push).
3. **Reconciliation:** delete/disable Cloud Scheduler job for
   `reconcileVoidedPurchases` (or undeploy that function only).
4. **Test entitlement:** `adminRevokeEntitlement` for the **test UID only**.
5. **Play product:** deactivate `group2_12m` in Play Console if needed.

---

## Test data / cleanup

Document every Firestore path created for the tester UID:

- `user_courses/{TEST_UID}/courses/group-ii`
- `payment_transactions/{stableId}`
- `play_account_links/{obfuscated}`
- `rtdn_events/{messageId}`
- `voided_purchase_events/{eventId}`
- `payment_ops_reviews/{reviewId}` (if any)

Delete **only** those tester paths after explicit operator approval.
Never run broad collection deletes.

---

## Local validation (always safe)

```bash
flutter test test/features
cd functions && npm test && npm run lint
flutter analyze
git diff --check
```
