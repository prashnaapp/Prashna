import assert from 'node:assert/strict';
import test from 'node:test';

import { createPlayPurchaseService } from '../src/play_purchase_service.js';
import {
  PLAY_PACKAGE_NAME,
  PLAY_PRODUCT_CATALOG,
  computeExpiresAt,
  resolvePlayProduct,
} from '../src/play_product_catalog.js';
import { mapPurchaseState } from '../src/google_play_verifier.js';
import { assertAuthenticated } from '../src/callables.js';
import { FakeFirestore } from './fake_firestore.mjs';
import { createEntitlementService } from '../src/entitlement_service.js';
import { createTransactionService } from '../src/transaction_service.js';
import { stableTransactionId } from '../src/ids.js';

const NOW = new Date('2026-08-10T12:00:00.000Z');
const TOKEN = 'play-token-abc-very-long-value';

function mockVerifier(overrides = {}) {
  const state = {
    purchaseState: 0,
    acknowledgementState: 0,
    orderId: 'GPA.1234',
    purchaseTimeMillis: String(NOW.getTime()),
    obfuscatedExternalAccountId: null,
    ...overrides.purchase,
  };
  let ackCalls = 0;
  return {
    state,
    get ackCalls() {
      return ackCalls;
    },
    async getProductPurchase() {
      if (overrides.getError) throw overrides.getError;
      return { ...state };
    },
    async acknowledgeProductPurchase() {
      ackCalls += 1;
      if (overrides.ackError) throw overrides.ackError;
      state.acknowledgementState = 1;
      return {};
    },
  };
}

test('product configuration maps group2_12m to group-ii with 365 days', () => {
  const product = resolvePlayProduct('group2_12m');
  assert.ok(product);
  assert.equal(product.courseId, 'group-ii');
  assert.equal(product.accessDurationDays, 365);
  assert.equal(PLAY_PACKAGE_NAME, 'com.prashna.app');
  assert.ok(PLAY_PRODUCT_CATALOG.group2_12m);
});

test('computeExpiresAt uses approved duration, not Play-granted months claim', () => {
  const expires = computeExpiresAt(365, { from: NOW });
  assert.equal(expires.toISOString(), '2027-08-10T12:00:00.000Z');
});

test('mapPurchaseState covers PENDING/PURCHASED/CANCELED', () => {
  assert.equal(mapPurchaseState(0), 'PURCHASED');
  assert.equal(mapPurchaseState(1), 'CANCELED');
  assert.equal(mapPurchaseState(2), 'PENDING');
  assert.equal(mapPurchaseState(99), 'UNKNOWN');
});

test('pending purchase does not unlock', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const verifier = mockVerifier({ purchase: { purchaseState: 2 } });
  const service = createPlayPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const result = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(result.status, 'pending');
  const ent = await createEntitlementService(db).get('user-1', 'group-ii');
  assert.equal(ent, null);
  assert.equal(verifier.ackCalls, 0);
});

test('canceled purchase does not unlock', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const verifier = mockVerifier({ purchase: { purchaseState: 1 } });
  const service = createPlayPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const result = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(result.status, 'error');
  assert.match(result.message, /canceled/i);
  assert.equal(await createEntitlementService(db).get('user-1', 'group-ii'), null);
});

test('invalid / API failure token rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const verifier = mockVerifier({
    getError: Object.assign(new Error('Google Play API 404: not found'), {
      status: 404,
    }),
  });
  const service = createPlayPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const result = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: 'bad-token',
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(result.status, 'error');
});

test('wrong product ID rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createPlayPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  });
  const result = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group3_evil',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(result.status, 'error');
  assert.match(result.message, /unmapped productId/i);
});

test('wrong package ID rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createPlayPurchaseService({
    db,
    googlePlayVerifier: mockVerifier(),
    now: () => NOW,
  });
  const result = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: 'com.evil.app',
  });
  assert.equal(result.status, 'error');
  assert.match(result.message, /package name/i);
});

test('successful purchase creates entitlement + transaction and acknowledges', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const verifier = mockVerifier();
  const service = createPlayPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const result = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(result.status, 'success');
  assert.equal(result.courseId, 'group-ii');
  assert.equal(verifier.ackCalls, 1);

  const ent = await createEntitlementService(db).get('user-1', 'group-ii');
  assert.equal(ent.status, 'active');
  assert.equal(ent.source, 'purchase');
  assert.equal(
    ent.expiresAt.toDate().toISOString(),
    '2027-08-10T12:00:00.000Z',
  );

  const txn = await createTransactionService(db).get(result.transactionId);
  assert.equal(txn.status, 'success');
  assert.equal(txn.providerTransactionId, TOKEN);
  assert.equal(txn.courseId, 'group-ii');
});

test('duplicate purchase token is idempotent and does not double-extend', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const verifier = mockVerifier();
  const service = createPlayPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const first = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });
  const firstExpiry = (
    await createEntitlementService(db).get('user-1', 'group-ii')
  ).expiresAt.toMillis();

  // Second call with already-acknowledged Google state.
  verifier.state.acknowledgementState = 1;
  const second = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(second.status, 'already_owned');
  assert.equal(second.duplicate, true);
  const secondExpiry = (
    await createEntitlementService(db).get('user-1', 'group-ii')
  ).expiresAt.toMillis();
  assert.equal(secondExpiry, firstExpiry);
  assert.equal(first.transactionId, second.transactionId);
});

test('acknowledgement failure does not duplicate entitlement', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const verifier = mockVerifier({
    ackError: new Error('ack failed'),
  });
  const service = createPlayPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const first = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(first.status, 'success');
  assert.equal(first.acknowledgement.success, false);

  verifier.state.acknowledgementState = 0;
  const second = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(second.duplicate, true);
  assert.equal(
    (await createEntitlementService(db).get('user-1', 'group-ii')).status,
    'active',
  );
});

test('obfuscated account mismatch rejects grant', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const verifier = mockVerifier({
    purchase: { obfuscatedExternalAccountId: 'someone-else' },
  });
  const service = createPlayPurchaseService({
    db,
    googlePlayVerifier: verifier,
    now: () => NOW,
  });
  const result = await service.verifyAndGrant({
    uid: 'user-1',
    productId: 'group2_12m',
    purchaseToken: TOKEN,
    packageName: PLAY_PACKAGE_NAME,
  });
  assert.equal(result.status, 'error');
  assert.match(result.message, /not associated/i);
});

test('unauthenticated callable helper rejects', () => {
  assert.throws(
    () => assertAuthenticated({ auth: null }),
    (err) => err.code === 'unauthenticated',
  );
});

test('long purchase token still yields stable transaction id', () => {
  const longToken = 'x'.repeat(900);
  const id = stableTransactionId({
    paymentProvider: 'google_play',
    providerTransactionId: longToken,
  });
  assert.ok(id.startsWith('google_play_'));
  assert.ok(id.length < 100);
  assert.equal(
    id,
    stableTransactionId({
      paymentProvider: 'google_play',
      providerTransactionId: longToken,
    }),
  );
});

test('historical UserCourse remains readable after play grant path', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const entitlements = createEntitlementService(db);
  await entitlements.grant({
    uid: 'legacy-user',
    courseId: 'group-ii',
    source: 'admin',
    expiresAt: new Date('2026-12-01T00:00:00.000Z'),
  });
  const got = await entitlements.get('legacy-user', 'group-ii');
  assert.equal(got.status, 'active');
  assert.equal(got.source, 'admin');
});
