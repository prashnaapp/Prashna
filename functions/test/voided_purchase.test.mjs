import assert from 'node:assert/strict';
import test from 'node:test';

import { createVoidedPurchaseService } from '../src/voided_purchase_service.js';
import { createRtdnService } from '../src/rtdn_service.js';
import { createPlayPurchaseService } from '../src/play_purchase_service.js';
import { createEntitlementService } from '../src/entitlement_service.js';
import { createTransactionService } from '../src/transaction_service.js';
import { createPaymentProcessingService } from '../src/payment_processing_service.js';
import {
  createPlayAccountLinkStore,
  obfuscatedAccountIdForUid,
} from '../src/play_account_links.js';
import {
  ONE_TIME_PRODUCT_PURCHASED,
  VOIDED_PRODUCT_TYPE_ONE_TIME,
  parseRtdnPubSubMessage,
} from '../src/rtdn_parser.js';
import {
  VOIDED_REASON,
  decideVoidEntitlementAction,
  voidedReasonName,
} from '../src/void_reasons.js';
import {
  PLAY_PACKAGE_NAME,
  PLAY_PROVIDER,
  computeExpiresAt,
} from '../src/play_product_catalog.js';
import { stableTransactionId } from '../src/ids.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-10T12:00:00.000Z');
const TOKEN = 'void-play-token-001';
const OTHER_COURSE = 'group-i';

function encodeNotification(notification) {
  return Buffer.from(JSON.stringify(notification), 'utf8').toString('base64');
}

function voidedMessage({
  messageId = 'void-msg-1',
  packageName = PLAY_PACKAGE_NAME,
  purchaseToken = TOKEN,
  orderId = 'GPA.VOID.1',
  productType = VOIDED_PRODUCT_TYPE_ONE_TIME,
  refundType = 1,
} = {}) {
  return {
    messageId,
    data: encodeNotification({
      version: '1.0',
      packageName,
      eventTimeMillis: String(NOW.getTime()),
      voidedPurchaseNotification: {
        purchaseToken,
        orderId,
        productType,
        refundType,
      },
    }),
  };
}

function oneTimePurchasedMessage({
  messageId = 'buy-msg-1',
  purchaseToken = TOKEN,
} = {}) {
  return {
    messageId,
    data: encodeNotification({
      version: '1.0',
      packageName: PLAY_PACKAGE_NAME,
      eventTimeMillis: String(NOW.getTime()),
      oneTimeProductNotification: {
        version: '1.0',
        notificationType: ONE_TIME_PRODUCT_PURCHASED,
        purchaseToken,
        sku: 'group2_12m',
      },
    }),
  };
}

function mockVerifier({
  purchase = {},
  voidedPurchases = [],
  listError = null,
  getError = null,
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
  return {
    state,
    get listCalls() {
      return listCalls;
    },
    async getProductPurchase() {
      if (getError) throw getError;
      return { ...state };
    },
    async acknowledgeProductPurchase() {
      state.acknowledgementState = 1;
      return {};
    },
    async listVoidedPurchases() {
      listCalls += 1;
      if (listError) throw listError;
      return { voidedPurchases: [...voidedPurchases] };
    },
  };
}

async function seedSuccessfulPurchase(db, {
  uid = 'user-void-1',
  purchaseToken = TOKEN,
  courseId = 'group-ii',
  productId = 'group2_12m',
} = {}) {
  const payments = createPaymentProcessingService(db);
  const expiresAt = computeExpiresAt(365, { from: NOW });
  const grant = await payments.processVerifiedPayment({
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: purchaseToken,
    uid,
    courseId,
    planId: productId,
    amount: 0,
    currency: 'INR',
    expiresAt,
    source: 'purchase',
    metadata: {
      productId,
      packageName: PLAY_PACKAGE_NAME,
      orderId: 'GPA.BUY.1',
    },
  });
  await createPlayAccountLinkStore(db).upsert(uid);
  return grant;
}

test('void reason policy: known reasons revoke; unknown requires review', () => {
  assert.equal(decideVoidEntitlementAction(VOIDED_REASON.REMORSE), 'revoke');
  assert.equal(decideVoidEntitlementAction(VOIDED_REASON.CHARGEBACK), 'revoke');
  assert.equal(
    decideVoidEntitlementAction(VOIDED_REASON.UNACKNOWLEDGED_PURCHASE),
    'revoke',
  );
  assert.equal(decideVoidEntitlementAction(99), 'manual_review');
  assert.equal(voidedReasonName(VOIDED_REASON.FRAUD), 'FRAUD');
  assert.equal(voidedReasonName(99), 'UNKNOWN_99');
});

test('1: valid voided Group II purchase revokes entitlement', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-void-1';
  await seedSuccessfulPurchase(db, { uid });

  const voided = {
    purchaseToken: TOKEN,
    orderId: 'GPA.VOID.1',
    voidedReason: VOIDED_REASON.REMORSE,
    voidedSource: 0,
    voidedTimeMillis: String(NOW.getTime()),
    purchaseTimeMillis: String(NOW.getTime() - 60_000),
  };
  const verifier = mockVerifier({ voidedPurchases: [voided] });
  const service = createVoidedPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });

  const result = await service.processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: voided,
  });
  assert.equal(result.status, 'revoked');
  assert.equal(result.courseId, 'group-ii');
  assert.equal(result.uid, uid);

  const ent = await createEntitlementService(db).get(uid, 'group-ii');
  assert.equal(ent.status, 'revoked');
});

test('2: refund reason (REMORSE) revokes', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedSuccessfulPurchase(db, { purchaseToken: 'tok-refund' });
  const voided = {
    purchaseToken: 'tok-refund',
    voidedReason: VOIDED_REASON.REMORSE,
    voidedSource: 0,
  };
  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier({ voidedPurchases: [voided] }),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: voided,
  });
  assert.equal(result.voidedReasonName, 'REMORSE');
  assert.equal(result.action, 'revoke');
});

test('3: chargeback reason revokes', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedSuccessfulPurchase(db, { purchaseToken: 'tok-cb' });
  const voided = {
    purchaseToken: 'tok-cb',
    voidedReason: VOIDED_REASON.CHARGEBACK,
    voidedSource: 2,
  };
  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: voided,
  });
  assert.equal(result.voidedReasonName, 'CHARGEBACK');
  assert.equal(result.status, 'revoked');
});

test('4: developer revocation source still revokes for known reason', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedSuccessfulPurchase(db, { purchaseToken: 'tok-dev' });
  const voided = {
    purchaseToken: 'tok-dev',
    voidedReason: VOIDED_REASON.OTHER,
    voidedSource: 1, // developer
  };
  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: voided,
  });
  assert.equal(result.voidedSourceName, 'DEVELOPER');
  assert.equal(result.status, 'revoked');
});

test('5: unknown void reason does not auto-revoke', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-unknown-reason';
  await seedSuccessfulPurchase(db, { uid, purchaseToken: 'tok-unk' });
  const voided = {
    purchaseToken: 'tok-unk',
    voidedReason: 42,
    voidedSource: 0,
  };
  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: voided,
  });
  assert.equal(result.status, 'manual_review');
  const ent = await createEntitlementService(db).get(uid, 'group-ii');
  assert.equal(ent.status, 'active');
});

test('6: unknown purchase token is a safe no-op', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: {
      purchaseToken: 'never-seen-token',
      voidedReason: VOIDED_REASON.REMORSE,
    },
  });
  assert.equal(result.action, 'noop_unknown_purchase_token');
  assert.equal(result.status, 'skipped');
});

test('7: unknown product on transaction is rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const token = 'tok-bad-product';
  const transactionId = stableTransactionId({
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: token,
  });
  await createTransactionService(db).createIfAbsent({
    transactionId,
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: token,
    uid: 'user-bad-product',
    courseId: 'group-ii',
    planId: 'not_a_real_sku',
    amount: 0,
    currency: 'INR',
    status: 'success',
    purchasedAt: NOW,
    verifiedAt: NOW,
    expiresAt: computeExpiresAt(365, { from: NOW }),
    metadata: { productId: 'not_a_real_sku' },
  });

  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: {
      purchaseToken: token,
      voidedReason: VOIDED_REASON.REMORSE,
    },
  });
  assert.equal(result.action, 'reject_product');
});

test('8: wrong package rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: 'com.evil.app',
    voidedPurchase: {
      purchaseToken: TOKEN,
      voidedReason: VOIDED_REASON.REMORSE,
    },
  });
  assert.equal(result.action, 'reject_package');
});

test('9: account link / transaction uid present → revoke that user', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-linked';
  await seedSuccessfulPurchase(db, { uid, purchaseToken: 'tok-linked' });
  assert.ok(await createPlayAccountLinkStore(db).resolveUid(
    obfuscatedAccountIdForUid(uid),
  ));

  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: {
      purchaseToken: 'tok-linked',
      voidedReason: VOIDED_REASON.FRAUD,
    },
  });
  assert.equal(result.uid, uid);
  assert.equal(result.status, 'revoked');
});

test('10: missing account / unknown token does not revoke arbitrary user', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  // Unrelated active entitlement for another user must remain untouched.
  await createEntitlementService(db).grant({
    uid: 'innocent-user',
    courseId: 'group-ii',
    source: 'purchase',
    expiresAt: computeExpiresAt(365, { from: NOW }),
  });

  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: {
      purchaseToken: 'orphan-void-token',
      voidedReason: VOIDED_REASON.CHARGEBACK,
    },
  });
  assert.equal(result.action, 'noop_unknown_purchase_token');
  const innocent = await createEntitlementService(db).get(
    'innocent-user',
    'group-ii',
  );
  assert.equal(innocent.status, 'active');
});

test('11: duplicate void processing is idempotent', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedSuccessfulPurchase(db, { purchaseToken: 'tok-dup-void' });
  const voided = {
    purchaseToken: 'tok-dup-void',
    voidedReason: VOIDED_REASON.REMORSE,
  };
  const service = createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  });
  const first = await service.processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: voided,
  });
  const second = await service.processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: voided,
  });
  assert.equal(first.status, 'revoked');
  assert.equal(second.status, 'duplicate_void');
  assert.equal(second.duplicate, true);
});

test('12: duplicate RTDN + void processing does not double-revoke harmfully', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-void';
  await seedSuccessfulPurchase(db, { uid, purchaseToken: 'tok-rtdn-void' });
  const voided = {
    purchaseToken: 'tok-rtdn-void',
    orderId: 'GPA.RTDN.VOID',
    voidedReason: VOIDED_REASON.CHARGEBACK,
    voidedSource: 2,
    voidedTimeMillis: String(NOW.getTime()),
  };
  const verifier = mockVerifier({ voidedPurchases: [voided] });
  const rtdn = createRtdnService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });

  const first = await rtdn.processPubSubMessage(
    voidedMessage({
      messageId: 'rtdn-void-1',
      purchaseToken: 'tok-rtdn-void',
    }),
  );
  assert.equal(first.status, 'revoked');

  const second = await rtdn.processPubSubMessage(
    voidedMessage({
      messageId: 'rtdn-void-1',
      purchaseToken: 'tok-rtdn-void',
    }),
  );
  assert.equal(second.status, 'duplicate_message');

  const third = await rtdn.processPubSubMessage(
    voidedMessage({
      messageId: 'rtdn-void-2',
      purchaseToken: 'tok-rtdn-void',
    }),
  );
  assert.equal(third.status, 'duplicate_void');

  const ent = await createEntitlementService(db).get(uid, 'group-ii');
  assert.equal(ent.status, 'revoked');
});

test('13/14: existing entitlement revoked; UserCourse document preserved', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-preserve';
  await seedSuccessfulPurchase(db, { uid, purchaseToken: 'tok-preserve' });
  const before = await createEntitlementService(db).get(uid, 'group-ii');
  assert.ok(before);
  assert.ok(before.enrolledAt);

  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: {
      purchaseToken: 'tok-preserve',
      voidedReason: VOIDED_REASON.ACCIDENTAL_PURCHASE,
    },
  });
  assert.equal(result.preservedDocument, true);
  const after = await createEntitlementService(db).get(uid, 'group-ii');
  assert.equal(after.status, 'revoked');
  assert.ok(after.enrolledAt);
});

test('15: historical payment transaction preserved (status cancelled + metadata)', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-txn';
  const token = 'tok-hist';
  await seedSuccessfulPurchase(db, { uid, purchaseToken: token });
  const transactionId = stableTransactionId({
    paymentProvider: PLAY_PROVIDER,
    providerTransactionId: token,
  });

  await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: {
      purchaseToken: token,
      voidedReason: VOIDED_REASON.DEFECTIVE,
      orderId: 'GPA.HIST',
    },
  });

  const txn = await createTransactionService(db).get(transactionId);
  assert.ok(txn);
  assert.equal(txn.status, 'cancelled');
  assert.equal(txn.uid, uid);
  assert.equal(txn.courseId, 'group-ii');
  assert.equal(txn.providerTransactionId, token);
  assert.equal(txn.metadata.voided, true);
  assert.equal(txn.metadata.voidedReasonName, 'DEFECTIVE');
});

test('16: other course entitlement unaffected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-multi';
  await seedSuccessfulPurchase(db, { uid, purchaseToken: 'tok-multi' });
  await createEntitlementService(db).grant({
    uid,
    courseId: OTHER_COURSE,
    source: 'admin',
    expiresAt: computeExpiresAt(30, { from: NOW }),
  });

  await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: {
      purchaseToken: 'tok-multi',
      voidedReason: VOIDED_REASON.REMORSE,
    },
  });

  const groupIi = await createEntitlementService(db).get(uid, 'group-ii');
  const other = await createEntitlementService(db).get(uid, OTHER_COURSE);
  assert.equal(groupIi.status, 'revoked');
  assert.equal(other.status, 'active');
});

test('17: existing purchase verification still works', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-verify-still';
  const obfuscated = obfuscatedAccountIdForUid(uid);
  const verifier = mockVerifier({
    purchase: { obfuscatedExternalAccountId: obfuscated, purchaseState: 0 },
  });
  const result = await createPlayPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  }).verifyAndGrant({
    uid,
    productId: 'group2_12m',
    purchaseToken: 'fresh-verify-token',
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.ok(result.status === 'success' || result.status === 'already_owned');
  const ent = await createEntitlementService(db).get(uid, 'group-ii');
  assert.equal(ent.status, 'active');
});

test('18: existing RTDN purchased flow still works', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-buy';
  const obfuscated = obfuscatedAccountIdForUid(uid);
  await createPlayAccountLinkStore(db).upsert(uid);
  const verifier = mockVerifier({
    purchase: {
      obfuscatedExternalAccountId: obfuscated,
      purchaseState: 0,
      acknowledgementState: 0,
    },
  });
  const result = await createRtdnService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  }).processPubSubMessage(
    oneTimePurchasedMessage({
      messageId: 'still-buy-1',
      purchaseToken: 'rtdn-buy-still',
    }),
  );
  assert.ok(result.status === 'success' || result.status === 'already_owned');
  assert.equal(result.courseId, 'group-ii');
});

test('parser decodes voidedPurchaseNotification', () => {
  const parsed = parseRtdnPubSubMessage(voidedMessage());
  assert.equal(parsed.hasVoidedPurchaseNotification, true);
  assert.equal(parsed.voided.purchaseToken, TOKEN);
  assert.equal(parsed.voided.productType, VOIDED_PRODUCT_TYPE_ONE_TIME);
  assert.equal(parsed.voided.refundType, 1);
});

test('reconcileVoidedPurchases processes list without deployable schedule', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedSuccessfulPurchase(db, { purchaseToken: 'tok-reconcile' });
  const voided = {
    purchaseToken: 'tok-reconcile',
    voidedReason: VOIDED_REASON.FRIENDLY_FRAUD,
    voidedSource: 2,
  };
  const service = createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier({ voidedPurchases: [voided] }),
    now: () => NOW,
  });
  const out = await service.reconcileVoidedPurchases({
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(out.status, 'ok');
  assert.equal(out.scannedCount, 1);
  assert.equal(out.revokedCount, 1);
  assert.equal(out.results[0].status, 'revoked');
});

test('RTDN void waits/retries when Voided Purchases API has no match yet', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedSuccessfulPurchase(db, { purchaseToken: 'tok-retry' });
  const verifier = mockVerifier({ voidedPurchases: [] });
  await assert.rejects(
    () => createRtdnService({
      db,
      googlePlayVerifier: verifier,
      now: () => NOW,
    }).processPubSubMessage(
      voidedMessage({ messageId: 'retry-1', purchaseToken: 'tok-retry' }),
    ),
    /not yet visible/,
  );
});

test('transaction without uid → awaiting_account_link (no arbitrary revoke)', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const token = 'tok-no-uid';
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

  const result = await createVoidedPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  }).processVerifiedVoidedPurchase({
    packageName: PLAY_PACKAGE_NAME,
    voidedPurchase: {
      purchaseToken: token,
      voidedReason: VOIDED_REASON.REMORSE,
    },
  });
  assert.equal(result.status, 'awaiting_account_link');
});
