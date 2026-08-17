import assert from 'node:assert/strict';
import test from 'node:test';

import {
  assertSafeReconcileLogPayload,
  createVoidedPurchaseService,
} from '../src/voided_purchase_service.js';
import { runReconcileVoidedPurchasesJob } from '../src/reconcile_voided_schedule.js';
import {
  RECONCILE_VOIDED_SCHEDULE,
  RECONCILE_VOIDED_TIME_ZONE,
} from '../src/reconcile_voided_schedule.js';
import { createRtdnService } from '../src/rtdn_service.js';
import { createPlayPurchaseService } from '../src/play_purchase_service.js';
import { createEntitlementService } from '../src/entitlement_service.js';
import { createTransactionService } from '../src/transaction_service.js';
import { createPaymentProcessingService } from '../src/payment_processing_service.js';
import { createPaymentOpsReviewStore } from '../src/payment_ops_review.js';
import {
  createPlayAccountLinkStore,
  obfuscatedAccountIdForUid,
} from '../src/play_account_links.js';
import {
  ONE_TIME_PRODUCT_PURCHASED,
  VOIDED_PRODUCT_TYPE_ONE_TIME,
} from '../src/rtdn_parser.js';
import {
  VOIDED_REASON,
} from '../src/void_reasons.js';
import {
  resolveVoidedLookbackDays,
  GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS,
} from '../src/voided_lookback.js';
import {
  PLAY_PACKAGE_NAME,
  PLAY_PROVIDER,
  computeExpiresAt,
} from '../src/play_product_catalog.js';
import { stableTransactionId } from '../src/ids.js';
import { fingerprintSecret } from '../src/safe_log.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-10T12:00:00.000Z');

function encodeNotification(notification) {
  return Buffer.from(JSON.stringify(notification), 'utf8').toString('base64');
}

function mockVerifier({
  purchase = {},
  voidedPurchases = [],
  listError = null,
} = {}) {
  const state = {
    purchaseState: 0,
    acknowledgementState: 1,
    orderId: 'GPA.BUY.1',
    purchaseTimeMillis: String(NOW.getTime() - 60_000),
    obfuscatedExternalAccountId: null,
    ...purchase,
  };
  let listCalls = 0;
  let lastListArgs = null;
  return {
    state,
    get listCalls() {
      return listCalls;
    },
    get lastListArgs() {
      return lastListArgs;
    },
    async getProductPurchase() {
      return { ...state };
    },
    async acknowledgeProductPurchase() {
      state.acknowledgementState = 1;
      return {};
    },
    async listVoidedPurchases(args = {}) {
      listCalls += 1;
      lastListArgs = args;
      if (listError) throw listError;
      return { voidedPurchases: [...voidedPurchases] };
    },
  };
}

function capturingLogger() {
  const lines = [];
  return {
    lines,
    info(event, payload) {
      lines.push({ level: 'info', event, ...payload });
    },
    warn(event, payload) {
      lines.push({ level: 'warn', event, ...payload });
    },
    error(event, payload) {
      lines.push({ level: 'error', event, ...payload });
    },
  };
}

async function seedPurchase(db, {
  uid = 'user-rec-1',
  purchaseToken = 'tok-rec-1',
  courseId = 'group-ii',
  productId = 'group2_12m',
} = {}) {
  await createPaymentProcessingService(db).processVerifiedPayment({
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: purchaseToken,
    uid,
    courseId,
    planId: productId,
    amount: 0,
    currency: 'INR',
    expiresAt: computeExpiresAt(365, { from: NOW }),
    source: 'purchase',
    metadata: {
      productId,
      packageName: PLAY_PACKAGE_NAME,
    },
  });
  await createPlayAccountLinkStore(db).upsert(uid);
}

test('18: lookback configuration respects env and Google 30-day cap', () => {
  assert.equal(GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS, 30);
  assert.equal(
    resolveVoidedLookbackDays({ env: {} }),
    30,
  );
  assert.equal(
    resolveVoidedLookbackDays({
      env: { VOIDED_PURCHASE_LOOKBACK_DAYS: '7' },
    }),
    7,
  );
  assert.equal(
    resolveVoidedLookbackDays({
      env: { VOIDED_PURCHASE_LOOKBACK_DAYS: '90' },
    }),
    30,
  );
  assert.equal(
    resolveVoidedLookbackDays({
      env: { VOIDED_PURCHASE_LOOKBACK_DAYS: '0' },
    }),
    30,
  );
});

test('schedule export is daily asia-south1 cron', () => {
  assert.equal(RECONCILE_VOIDED_SCHEDULE, '30 3 * * *');
  assert.equal(RECONCILE_VOIDED_TIME_ZONE, 'Asia/Kolkata');
});

test('1/2: scheduled reconciliation empty result', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const logger = capturingLogger();
  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({ voidedPurchases: [] }),
    now: () => NOW,
    logger,
    runId: 'run-empty',
  });
  assert.equal(summary.status, 'ok');
  assert.equal(summary.scannedCount, 0);
  assert.equal(summary.revokedCount, 0);
  assert.equal(summary.runId, 'run-empty');
  assert.ok(summary.startedAt);
  assert.ok(summary.completedAt);
});

test('3: one valid void via reconciliation', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedPurchase(db, { purchaseToken: 'tok-one' });
  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [{
        purchaseToken: 'tok-one',
        voidedReason: VOIDED_REASON.REMORSE,
        voidedSource: 0,
      }],
    }),
    now: () => NOW,
    runId: 'run-one',
  });
  assert.equal(summary.revokedCount, 1);
  assert.equal(summary.matchedCount, 1);
  const ent = await createEntitlementService(db).get('user-rec-1', 'group-ii');
  assert.equal(ent.status, 'revoked');
});

test('4: multiple voids in one run', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedPurchase(db, { uid: 'u1', purchaseToken: 'tok-a' });
  await seedPurchase(db, { uid: 'u2', purchaseToken: 'tok-b' });
  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [
        { purchaseToken: 'tok-a', voidedReason: VOIDED_REASON.CHARGEBACK },
        { purchaseToken: 'tok-b', voidedReason: VOIDED_REASON.FRAUD },
      ],
    }),
    now: () => NOW,
  });
  assert.equal(summary.scannedCount, 2);
  assert.equal(summary.revokedCount, 2);
});

test('5/20: duplicate execution is idempotent', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedPurchase(db, { purchaseToken: 'tok-dup-run' });
  const verifier = mockVerifier({
    voidedPurchases: [{
      purchaseToken: 'tok-dup-run',
      voidedReason: VOIDED_REASON.REMORSE,
    }],
  });
  const first = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const second = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  assert.equal(first.revokedCount, 1);
  assert.equal(second.revokedCount, 0);
  assert.equal(second.alreadyProcessedCount, 1);
});

test('6: duplicate purchase token within same list is safe', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedPurchase(db, { purchaseToken: 'tok-twice' });
  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [
        { purchaseToken: 'tok-twice', voidedReason: VOIDED_REASON.REMORSE },
        { purchaseToken: 'tok-twice', voidedReason: VOIDED_REASON.REMORSE },
      ],
    }),
    now: () => NOW,
  });
  assert.equal(summary.revokedCount, 1);
  assert.equal(summary.alreadyProcessedCount, 1);
});

test('7: already revoked entitlement stays revoked / preserved', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-already';
  await seedPurchase(db, { uid, purchaseToken: 'tok-already' });
  await createEntitlementService(db).revoke(uid, 'group-ii');
  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [{
        purchaseToken: 'tok-already',
        voidedReason: VOIDED_REASON.DEFECTIVE,
      }],
    }),
    now: () => NOW,
  });
  assert.equal(summary.revokedCount, 1);
  assert.equal(summary.results[0].action, 'noop_already_revoked');
  const ent = await createEntitlementService(db).get(uid, 'group-ii');
  assert.equal(ent.status, 'revoked');
  assert.ok(ent.enrolledAt);
});

test('8: missing account link / unknown token does not revoke others', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await createEntitlementService(db).grant({
    uid: 'innocent',
    courseId: 'group-ii',
    source: 'purchase',
    expiresAt: computeExpiresAt(365, { from: NOW }),
  });
  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [{
        purchaseToken: 'orphan-token',
        voidedReason: VOIDED_REASON.CHARGEBACK,
      }],
    }),
    now: () => NOW,
  });
  assert.equal(summary.skippedCount, 1);
  const innocent = await createEntitlementService(db).get('innocent', 'group-ii');
  assert.equal(innocent.status, 'active');
});

test('9: unknown product recorded as failed ops review', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const token = 'tok-bad-sku';
  const transactionId = stableTransactionId({
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: token,
  });
  await createTransactionService(db).createIfAbsent({
    transactionId,
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: token,
    uid: 'user-bad-sku',
    courseId: 'group-ii',
    planId: 'not_catalog',
    amount: 0,
    currency: 'INR',
    status: 'success',
    purchasedAt: NOW,
    verifiedAt: NOW,
    expiresAt: computeExpiresAt(365, { from: NOW }),
    metadata: { productId: 'not_catalog' },
  });

  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [{
        purchaseToken: token,
        voidedReason: VOIDED_REASON.REMORSE,
      }],
    }),
    now: () => NOW,
  });
  assert.equal(summary.failedCount, 1);
  const reviews = db._store;
  const reviewEntry = [...reviews.entries()].find(([path]) =>
    path.startsWith('payment_ops_reviews/'),
  );
  assert.ok(reviewEntry);
  assert.equal(reviewEntry[1].status, 'failed');
});

test('10/11: unknown void reason → manual_review record, no revoke', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-mr';
  await seedPurchase(db, { uid, purchaseToken: 'tok-mr' });
  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [{
        purchaseToken: 'tok-mr',
        voidedReason: 99,
        voidedSource: 2,
      }],
    }),
    now: () => NOW,
    runId: 'run-mr',
  });
  assert.equal(summary.manualReviewCount, 1);
  const ent = await createEntitlementService(db).get(uid, 'group-ii');
  assert.equal(ent.status, 'active');

  const review = [...db._store.entries()].find(([path]) =>
    path.startsWith('payment_ops_reviews/'),
  )?.[1];
  assert.ok(review);
  assert.equal(review.status, 'manual_review');
  assert.equal(review.purchaseToken, 'tok-mr');
  assert.equal(review.productId, 'group2_12m');
  assert.equal(review.packageName, PLAY_PACKAGE_NAME);
  assert.equal(review.voidReason, 99);
  assert.ok(review.detectedAt);
  assert.ok(review.reason || review.details);
});

test('12: Google API transient failure is retryable', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const err = new Error('Google Play API 503: unavailable');
  err.status = 503;
  await assert.rejects(
    () => runReconcileVoidedPurchasesJob({
      db,
      googlePlayVerifier: mockVerifier({ listError: err }),
      now: () => NOW,
    }),
    /503|unavailable|retryable/i,
  );
});

test('13: Google API permanent failure records diagnostics without throw', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const logger = capturingLogger();
  const err = new Error('Google Play API 403: forbidden');
  err.status = 403;
  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({ listError: err }),
    now: () => NOW,
    logger,
  });
  assert.equal(summary.status, 'error');
  assert.equal(summary.retryable, false);
  assert.match(summary.message, /403/);
  assert.ok(!JSON.stringify(logger.lines).includes('BEGIN PRIVATE KEY'));
});

test('14: historical transaction preserved after reconcile revoke', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const token = 'tok-hist-rec';
  await seedPurchase(db, { uid: 'user-hist', purchaseToken: token });
  await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [{
        purchaseToken: token,
        voidedReason: VOIDED_REASON.ACCIDENTAL_PURCHASE,
      }],
    }),
    now: () => NOW,
  });
  const txn = await createTransactionService(db).get(
    stableTransactionId({
      paymentProvider: PLAY_PROVIDER,
      providerTransactionId: token,
    }),
  );
  assert.equal(txn.status, 'cancelled');
  assert.equal(txn.providerTransactionId, token);
  assert.equal(txn.metadata.voided, true);
});

test('15: other course unaffected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-multi-rec';
  await seedPurchase(db, { uid, purchaseToken: 'tok-multi-rec' });
  await createEntitlementService(db).grant({
    uid,
    courseId: 'group-i',
    source: 'admin',
    expiresAt: computeExpiresAt(30, { from: NOW }),
  });
  await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [{
        purchaseToken: 'tok-multi-rec',
        voidedReason: VOIDED_REASON.REMORSE,
      }],
    }),
    now: () => NOW,
  });
  assert.equal(
    (await createEntitlementService(db).get(uid, 'group-ii')).status,
    'revoked',
  );
  assert.equal(
    (await createEntitlementService(db).get(uid, 'group-i')).status,
    'active',
  );
});

test('16: existing RTDN purchased path unaffected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-ok';
  const obfuscated = obfuscatedAccountIdForUid(uid);
  await createPlayAccountLinkStore(db).upsert(uid);
  const result = await createRtdnService({
    db,
    googlePlayVerifier: mockVerifier({
      purchase: {
        obfuscatedExternalAccountId: obfuscated,
        purchaseState: 0,
        acknowledgementState: 0,
      },
    }),
    now: () => NOW,
  }).processPubSubMessage({
    messageId: 'rtdn-still-1',
    data: encodeNotification({
      version: '1.0',
      packageName: PLAY_PACKAGE_NAME,
      eventTimeMillis: String(NOW.getTime()),
      oneTimeProductNotification: {
        version: '1.0',
        notificationType: ONE_TIME_PRODUCT_PURCHASED,
        purchaseToken: 'rtdn-still-token',
        sku: 'group2_12m',
      },
    }),
  });
  assert.ok(result.status === 'success' || result.status === 'already_owned');
});

test('17: existing verifyPlayPurchase unaffected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-verify-ok';
  const result = await createPlayPurchaseService({
    db,
    googlePlayVerifier: mockVerifier({
      purchase: {
        obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
        purchaseState: 0,
      },
    }),
    now: () => NOW,
  }).verifyAndGrant({
    uid,
    productId: 'group2_12m',
    purchaseToken: 'verify-still-token',
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.ok(result.status === 'success' || result.status === 'already_owned');
});

test('19: safe logging never includes purchase token plaintext', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const token = 'super-secret-purchase-token-xyz';
  await seedPurchase(db, { purchaseToken: token });
  const logger = capturingLogger();
  await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [{
        purchaseToken: token,
        voidedReason: VOIDED_REASON.REMORSE,
      }],
    }),
    now: () => NOW,
    logger,
    runId: 'run-safe-log',
  });
  for (const line of logger.lines) {
    assertSafeReconcileLogPayload(line, [token]);
  }
  assert.equal(fingerprintSecret(token).length, 16);
});

test('lookback days are passed into Voided Purchases list window', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const verifier = mockVerifier({ voidedPurchases: [] });
  await createVoidedPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
    lookbackDays: 7,
  }).reconcileVoidedPurchases();
  assert.equal(verifier.listCalls, 1);
  const windowMs = verifier.lastListArgs.endTime - verifier.lastListArgs.startTime;
  assert.equal(windowMs, 7 * 24 * 60 * 60 * 1000);
});

test('awaiting_account_link creates pending ops review', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const token = 'tok-pending-link';
  const transactionId = stableTransactionId({
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: token,
  });
  await createTransactionService(db).createIfAbsent({
    transactionId,
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: token,
    uid: '',
    courseId: 'group-ii',
    planId: 'group2_12m',
    amount: 0,
    currency: 'INR',
    status: 'success',
    purchasedAt: NOW,
    verifiedAt: NOW,
    expiresAt: computeExpiresAt(365, { from: NOW }),
    metadata: { productId: 'group2_12m' },
  });

  const summary = await runReconcileVoidedPurchasesJob({
    db,
    googlePlayVerifier: mockVerifier({
      voidedPurchases: [{
        purchaseToken: token,
        voidedReason: VOIDED_REASON.REMORSE,
      }],
    }),
    now: () => NOW,
  });
  assert.equal(summary.awaitingAccountLinkCount, 1);
  const review = [...db._store.entries()].find(([path]) =>
    path.startsWith('payment_ops_reviews/'),
  )?.[1];
  assert.equal(review.status, 'pending');
});

test('ops review markResolved is backend-only state transition', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const store = createPaymentOpsReviewStore(db);
  const created = await store.upsert({
    status: 'manual_review',
    purchaseToken: 'tok-resolve',
    productId: 'group2_12m',
    packageName: PLAY_PACKAGE_NAME,
    voidReason: 99,
    reason: 'unknown reason',
  });
  const resolved = await store.markResolved(created.reviewId, {
    details: 'confirmed no action',
  });
  assert.equal(resolved.status, 'resolved');
});

test('voided RTDN one-time product type constant still available', () => {
  assert.equal(VOIDED_PRODUCT_TYPE_ONE_TIME, 2);
});
