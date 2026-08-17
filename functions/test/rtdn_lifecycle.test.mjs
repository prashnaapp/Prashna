import assert from 'node:assert/strict';
import test from 'node:test';

import { createRtdnService } from '../src/rtdn_service.js';
import { createPlayPurchaseService } from '../src/play_purchase_service.js';
import { createEntitlementService } from '../src/entitlement_service.js';
import { createTransactionService } from '../src/transaction_service.js';
import { createPlayAccountLinkStore, obfuscatedAccountIdForUid } from '../src/play_account_links.js';
import { createRtdnIdempotencyStore } from '../src/rtdn_idempotency.js';
import {
  ONE_TIME_PRODUCT_CANCELED,
  ONE_TIME_PRODUCT_PURCHASED,
  parseRtdnPubSubMessage,
} from '../src/rtdn_parser.js';
import { PLAY_PACKAGE_NAME } from '../src/play_product_catalog.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-10T12:00:00.000Z');
const TOKEN = 'rtdn-play-token-001';

function encodeNotification(notification) {
  return Buffer.from(JSON.stringify(notification), 'utf8').toString('base64');
}

function oneTimeMessage({
  messageId = 'msg-1',
  notificationType = ONE_TIME_PRODUCT_PURCHASED,
  packageName = PLAY_PACKAGE_NAME,
  purchaseToken = TOKEN,
  sku = 'group2_12m',
} = {}) {
  return {
    messageId,
    data: encodeNotification({
      version: '1.0',
      packageName,
      eventTimeMillis: String(NOW.getTime()),
      oneTimeProductNotification: {
        version: '1.0',
        notificationType,
        purchaseToken,
        sku,
      },
    }),
  };
}

function mockVerifier(overrides = {}) {
  const state = {
    purchaseState: 0,
    acknowledgementState: 0,
    orderId: 'GPA.RTDN.1',
    purchaseTimeMillis: String(NOW.getTime()),
    obfuscatedExternalAccountId: null,
    ...overrides.purchase,
  };
  let getCalls = 0;
  return {
    state,
    get getCalls() {
      return getCalls;
    },
    async getProductPurchase() {
      getCalls += 1;
      if (overrides.getError) throw overrides.getError;
      return { ...state };
    },
    async acknowledgeProductPurchase() {
      state.acknowledgementState = 1;
      return {};
    },
  };
}

test('parser decodes one-time PURCHASED and CANCELED types', () => {
  const purchased = parseRtdnPubSubMessage(
    oneTimeMessage({ notificationType: ONE_TIME_PRODUCT_PURCHASED }),
  );
  assert.equal(purchased.oneTime.notificationTypeName, 'ONE_TIME_PRODUCT_PURCHASED');
  const canceled = parseRtdnPubSubMessage(
    oneTimeMessage({
      messageId: 'msg-c',
      notificationType: ONE_TIME_PRODUCT_CANCELED,
    }),
  );
  assert.equal(canceled.oneTime.notificationTypeName, 'ONE_TIME_PRODUCT_CANCELED');
});

test('1: valid PURCHASED RTDN grants via processVerifiedPayment', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-1';
  const obfuscated = obfuscatedAccountIdForUid(uid);
  await createPlayAccountLinkStore(db).upsert(uid);

  const verifier = mockVerifier({
    purchase: { obfuscatedExternalAccountId: obfuscated, purchaseState: 0 },
  });
  const service = createRtdnService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });

  const result = await service.processPubSubMessage(
    oneTimeMessage({ messageId: 'msg-purchased-1' }),
  );
  assert.equal(result.status, 'success');
  assert.equal(result.action, 'grant');
  assert.equal(result.courseId, 'group-ii');
  assert.equal(verifier.getCalls, 1);

  const ent = await createEntitlementService(db).get(uid, 'group-ii');
  assert.equal(ent.status, 'active');
  const txn = await createTransactionService(db).get(result.transactionId);
  assert.equal(txn.status, 'success');
  assert.equal(txn.providerTransactionId, TOKEN);
});

test('2: valid CANCELED RTDN revokes when prior grant exists', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-2';
  await createPlayAccountLinkStore(db).upsert(uid);

  // First grant through normal verify path.
  const grantVerifier = mockVerifier({
    purchase: {
      purchaseState: 0,
      obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
    },
  });
  await createPlayPurchaseService({
    db,
    googlePlayVerifier: grantVerifier,
    now: () => NOW,
  }).verifyAndGrant({
    uid,
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });

  const cancelVerifier = mockVerifier({
    purchase: {
      purchaseState: 1,
      obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
    },
  });
  const service = createRtdnService({
    db,
    googlePlayVerifier: cancelVerifier,
    now: () => NOW,
  });
  const result = await service.processPubSubMessage(
    oneTimeMessage({
      messageId: 'msg-canceled-1',
      notificationType: ONE_TIME_PRODUCT_CANCELED,
    }),
  );
  assert.equal(result.status, 'revoked');
  assert.equal(result.action, 'revoke');
  const ent = await createEntitlementService(db).get(uid, 'group-ii');
  assert.equal(ent.status, 'revoked');
  assert.ok(ent); // document preserved
});

test('3/15: duplicate message ID is idempotent', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-3';
  await createPlayAccountLinkStore(db).upsert(uid);
  const verifier = mockVerifier({
    purchase: {
      purchaseState: 0,
      obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
    },
  });
  const service = createRtdnService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const first = await service.processPubSubMessage(
    oneTimeMessage({ messageId: 'msg-dup' }),
  );
  const expiry = (
    await createEntitlementService(db).get(uid, 'group-ii')
  ).expiresAt.toMillis();
  const second = await service.processPubSubMessage(
    oneTimeMessage({ messageId: 'msg-dup' }),
  );
  assert.equal(second.status, 'duplicate_message');
  assert.equal(second.duplicate, true);
  assert.equal(
    (await createEntitlementService(db).get(uid, 'group-ii')).expiresAt.toMillis(),
    expiry,
  );
  assert.equal(first.transactionId, (
    await createRtdnIdempotencyStore(db).get('msg-dup')
  ).transactionId);
});

test('4/10/11: duplicate purchase token does not double-extend', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-4';
  await createPlayAccountLinkStore(db).upsert(uid);
  const verifier = mockVerifier({
    purchase: {
      purchaseState: 0,
      obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
    },
  });
  const service = createRtdnService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const first = await service.processPubSubMessage(
    oneTimeMessage({ messageId: 'msg-token-a', purchaseToken: 'same-token' }),
  );
  const expiry = (
    await createEntitlementService(db).get(uid, 'group-ii')
  ).expiresAt.toMillis();
  const second = await service.processPubSubMessage(
    oneTimeMessage({ messageId: 'msg-token-b', purchaseToken: 'same-token' }),
  );
  assert.equal(second.status, 'already_owned');
  assert.equal(second.duplicate, true);
  assert.equal(second.transactionId, first.transactionId);
  assert.equal(
    (await createEntitlementService(db).get(uid, 'group-ii')).expiresAt.toMillis(),
    expiry,
  );
});

test('5: wrong package rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createRtdnService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  });
  const result = await service.processPubSubMessage(
    oneTimeMessage({
      messageId: 'msg-pkg',
      packageName: 'com.evil.app',
    }),
  );
  assert.equal(result.status, 'error');
  assert.equal(result.action, 'reject_package');
});

test('6: unknown product rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createRtdnService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  });
  const result = await service.processPubSubMessage(
    oneTimeMessage({
      messageId: 'msg-sku',
      sku: 'unknown_sku',
    }),
  );
  assert.equal(result.status, 'error');
  assert.equal(result.action, 'reject_product');
});

test('7/8/14: invalid token / Google API failure is retryable', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createRtdnService({
    db,
    googlePlayVerifier: mockVerifier({
      getError: new Error('Google Play API 500'),
    }),
    now: () => NOW,
  });
  await assert.rejects(
    () =>
      service.processPubSubMessage(
        oneTimeMessage({ messageId: 'msg-fail' }),
      ),
    /Google Play API 500/,
  );
  const event = await createRtdnIdempotencyStore(db).get('msg-fail');
  assert.equal(event.status, 'failed');
});

test('9: PURCHASED event reuses processVerifiedPayment path', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-9';
  await createPlayAccountLinkStore(db).upsert(uid);
  const service = createRtdnService({
    db,
    googlePlayVerifier: mockVerifier({
      purchase: {
        purchaseState: 0,
        obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
      },
    }),
    now: () => NOW,
  });
  const result = await service.processPubSubMessage(
    oneTimeMessage({ messageId: 'msg-reuse' }),
  );
  assert.ok(['success', 'already_owned'].includes(result.status));
  const txn = await createTransactionService(db).get(result.transactionId);
  assert.equal(txn.paymentProvider, 'google_play');
  assert.equal(txn.metadata.sourcePath, 'rtdn');
});

test('12: revocation preserves UserCourse document', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-12';
  await createPlayAccountLinkStore(db).upsert(uid);
  await createPlayPurchaseService({
    db,
    googlePlayVerifier: mockVerifier({
      purchase: {
        purchaseState: 0,
        obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
      },
    }),
    now: () => NOW,
  }).verifyAndGrant({
    uid,
    productId: 'group2_12m',
    purchaseToken: 'revoke-token',
    packageName: PLAY_PACKAGE_NAME,
  });

  const service = createRtdnService({
    db,
    googlePlayVerifier: mockVerifier({
      purchase: {
        purchaseState: 1,
        obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
      },
    }),
    now: () => NOW,
  });
  await service.processPubSubMessage(
    oneTimeMessage({
      messageId: 'msg-rev-preserve',
      notificationType: ONE_TIME_PRODUCT_CANCELED,
      purchaseToken: 'revoke-token',
    }),
  );
  const ent = await createEntitlementService(db).get(uid, 'group-ii');
  assert.ok(ent);
  assert.equal(ent.status, 'revoked');
  assert.equal(ent.courseId, 'group-ii');
});

test('13: historical transactions remain readable after RTDN', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-rtdn-13';
  await createPlayAccountLinkStore(db).upsert(uid);
  const grant = await createPlayPurchaseService({
    db,
    googlePlayVerifier: mockVerifier({
      purchase: {
        purchaseState: 0,
        obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
      },
    }),
    now: () => NOW,
  }).verifyAndGrant({
    uid,
    productId: 'group2_12m',
    purchaseToken: 'hist-token',
    packageName: PLAY_PACKAGE_NAME,
  });
  const before = await createTransactionService(db).get(grant.transactionId);
  assert.equal(before.status, 'success');

  await createRtdnService({
    db,
    googlePlayVerifier: mockVerifier({
      purchase: {
        purchaseState: 0,
        obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
      },
    }),
    now: () => NOW,
  }).processPubSubMessage(
    oneTimeMessage({
      messageId: 'msg-hist',
      purchaseToken: 'hist-token',
    }),
  );
  const after = await createTransactionService(db).get(grant.transactionId);
  assert.equal(after.status, 'success');
  assert.equal(after.providerTransactionId, 'hist-token');
});

test('16: existing verifyPlayPurchase remains functional', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const result = await createPlayPurchaseService({
    db,
    googlePlayVerifier: mockVerifier({ purchase: { purchaseState: 0 } }),
    now: () => NOW,
  }).verifyAndGrant({
    uid: 'user-verify-still',
    productId: 'group2_12m',
    purchaseToken: 'client-token',
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(result.status, 'success');
  assert.equal(
    (await createEntitlementService(db).get('user-verify-still', 'group-ii'))
      .status,
    'active',
  );
});

test('RTDN without account link skips grant instead of inventing uid', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createRtdnService({
    db,
    googlePlayVerifier: mockVerifier({ purchase: { purchaseState: 0 } }),
    now: () => NOW,
  });
  const result = await service.processPubSubMessage(
    oneTimeMessage({ messageId: 'msg-nolink' }),
  );
  assert.equal(result.status, 'skipped');
  assert.equal(result.action, 'awaiting_account_link');
});

test('notification type PURCHASED is ignored when Google state is CANCELED', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const uid = 'user-stale-notif';
  await createPlayAccountLinkStore(db).upsert(uid);
  const service = createRtdnService({
    db,
    googlePlayVerifier: mockVerifier({
      purchase: {
        purchaseState: 1, // current state canceled
        obfuscatedExternalAccountId: obfuscatedAccountIdForUid(uid),
      },
    }),
    now: () => NOW,
  });
  const result = await service.processPubSubMessage(
    oneTimeMessage({
      messageId: 'msg-stale',
      notificationType: ONE_TIME_PRODUCT_PURCHASED,
    }),
  );
  // No prior grant → canceled without grant noop
  assert.equal(result.action, 'noop_canceled_without_grant');
  assert.equal(await createEntitlementService(db).get(uid, 'group-ii'), null);
});
