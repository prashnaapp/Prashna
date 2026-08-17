import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { Timestamp } from 'firebase-admin/firestore';

import {
  createEntitlementService,
  resolveEffectiveStatus,
} from '../src/entitlement_service.js';
import { createPaymentProcessingService } from '../src/payment_processing_service.js';
import { createTransactionService } from '../src/transaction_service.js';
import { stableTransactionId } from '../src/ids.js';
import { assertAdmin } from '../src/callables.js';
import { FakeFirestore } from './fake_firestore.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../..');
const RULES = readFileSync(resolve(REPO_ROOT, 'firestore.rules'), 'utf8');

const NOW = new Date('2026-08-10T12:00:00.000Z');

function services(now = NOW) {
  const db = new FakeFirestore({ now: () => now });
  return {
    db,
    entitlements: createEntitlementService(db),
    transactions: createTransactionService(db),
    payments: createPaymentProcessingService(db),
  };
}

test('1: grant entitlement', async () => {
  const { entitlements } = services();
  const expiresAt = new Date('2026-11-10T12:00:00.000Z');
  const result = await entitlements.grant({
    uid: 'user-1',
    courseId: 'group-ii',
    source: 'purchase',
    expiresAt,
  });
  assert.equal(result.status, 'active');
  assert.equal(result.source, 'purchase');
  assert.equal(result.courseId, 'group-ii');
  assert.ok(result.expiresAt.toDate().getTime() === expiresAt.getTime());
});

test('2: revoke entitlement', async () => {
  const { entitlements } = services();
  await entitlements.grant({
    uid: 'user-1',
    courseId: 'group-ii',
    source: 'admin',
    expiresAt: null,
  });
  const revoked = await entitlements.revoke('user-1', 'group-ii');
  assert.equal(revoked.status, 'revoked');
  assert.equal(revoked.courseId, 'group-ii');
});

test('3: extend entitlement uses explicit expiresAt', async () => {
  const { entitlements } = services();
  await entitlements.grant({
    uid: 'user-1',
    courseId: 'group-ii',
    source: 'purchase',
    expiresAt: new Date('2026-09-01T00:00:00.000Z'),
  });
  const next = new Date('2027-01-01T00:00:00.000Z');
  const extended = await entitlements.extend('user-1', 'group-ii', next);
  assert.equal(extended.status, 'active');
  assert.equal(extended.expiresAt.toDate().getTime(), next.getTime());
});

test('4: expired entitlement effective status', async () => {
  const past = Timestamp.fromDate(new Date('2026-01-01T00:00:00.000Z'));
  const effective = resolveEffectiveStatus(
    { status: 'active', expiresAt: past },
    { now: () => NOW },
  );
  assert.equal(effective, 'expired');
});

test('5: active entitlement effective status', async () => {
  const future = Timestamp.fromDate(new Date('2026-12-01T00:00:00.000Z'));
  const effective = resolveEffectiveStatus(
    { status: 'active', expiresAt: future },
    { now: () => NOW },
  );
  assert.equal(effective, 'active');
});

test('6: different course isolation', async () => {
  const { entitlements } = services();
  await entitlements.grant({
    uid: 'user-1',
    courseId: 'group-ii',
    source: 'purchase',
  });
  assert.equal((await entitlements.get('user-1', 'group-iii')), null);
  assert.equal((await entitlements.get('user-1', 'group-ii'))?.status, 'active');
});

test('7: payment transaction creation', async () => {
  const { transactions } = services();
  const id = stableTransactionId({
    paymentProvider: 'test',
    providerTransactionId: 'evt_1',
  });
  const created = await transactions.createIfAbsent({
    transactionId: id,
    paymentProvider: 'test',
    uid: 'user-1',
    courseId: 'group-ii',
    planId: 'plan-90',
    amount: 299,
    currency: 'INR',
    status: 'pending',
    providerTransactionId: 'evt_1',
    expiresAt: null,
    metadata: {},
  });
  assert.equal(created.created, true);
  assert.equal(created.transaction.status, 'pending');
  assert.equal(created.transaction.amount, 299);
});

test('8: duplicate transaction createIfAbsent is idempotent', async () => {
  const { transactions } = services();
  const id = stableTransactionId({
    paymentProvider: 'test',
    providerTransactionId: 'evt_dup',
  });
  const first = await transactions.createIfAbsent({
    transactionId: id,
    paymentProvider: 'test',
    uid: 'user-1',
    courseId: 'group-ii',
    planId: 'plan-90',
    amount: 299,
    currency: 'INR',
    status: 'pending',
    providerTransactionId: 'evt_dup',
  });
  const second = await transactions.createIfAbsent({
    transactionId: id,
    paymentProvider: 'test',
    uid: 'user-1',
    courseId: 'group-ii',
    planId: 'plan-90',
    amount: 999,
    currency: 'INR',
    status: 'success',
    providerTransactionId: 'evt_dup',
  });
  assert.equal(first.created, true);
  assert.equal(second.created, false);
  assert.equal(second.transaction.status, 'pending');
  assert.equal(second.transaction.amount, 299);
});

test('9: duplicate verified payment processing does not re-extend', async () => {
  const { payments, entitlements, transactions } = services();
  const event = {
    paymentProvider: 'test',
    providerTransactionId: 'pay_abc',
    uid: 'user-1',
    courseId: 'group-ii',
    planId: 'plan-90',
    amount: 299,
    currency: 'INR',
    expiresAt: new Date('2026-11-10T00:00:00.000Z'),
    source: 'purchase',
  };
  const first = await payments.processVerifiedPayment(event);
  assert.equal(first.duplicate, false);
  assert.equal(first.entitlementStatus, 'active');

  // Change requested expiry — must NOT apply on duplicate.
  const second = await payments.processVerifiedPayment({
    ...event,
    expiresAt: new Date('2028-01-01T00:00:00.000Z'),
  });
  assert.equal(second.duplicate, true);

  const ent = await entitlements.get('user-1', 'group-ii');
  assert.equal(
    ent.expiresAt.toDate().toISOString(),
    '2026-11-10T00:00:00.000Z',
  );

  const txn = await transactions.get(first.transactionId);
  assert.equal(txn.status, 'success');
  assert.ok(txn.verifiedAt);
});

test('10: transaction + entitlement consistency', async () => {
  const { payments, entitlements, transactions } = services();
  const result = await payments.processVerifiedPayment({
    paymentProvider: 'test',
    providerTransactionId: 'pay_consistent',
    uid: 'user-2',
    courseId: 'group-iii',
    planId: 'plan-30',
    amount: 149,
    expiresAt: new Date('2026-09-10T00:00:00.000Z'),
  });
  const txn = await transactions.get(result.transactionId);
  const ent = await entitlements.get('user-2', 'group-iii');
  assert.equal(txn.status, 'success');
  assert.equal(ent.status, 'active');
  assert.equal(txn.uid, 'user-2');
  assert.equal(ent.courseId, 'group-iii');
  assert.equal(txn.metadata.entitlementGranted, true);
});

test('11/12: Firestore rules still deny client entitlement and payment writes', () => {
  const userCoursesBlock = RULES.slice(
    RULES.indexOf('match /user_courses/{userId}'),
    RULES.indexOf('match /payment_plans/{planId}'),
  );
  const paymentTxnBlock = RULES.slice(
    RULES.indexOf('match /payment_transactions/{transactionId}'),
    RULES.indexOf('match /questions/{questionId}'),
  );
  assert.match(userCoursesBlock, /allow create, update, delete: if false/);
  assert.match(paymentTxnBlock, /allow create, update, delete: if false/);
  assert.doesNotMatch(userCoursesBlock, /allow create: if request\.auth/);
  assert.doesNotMatch(paymentTxnBlock, /allow create: if request\.auth/);
});

test('13: admin-only callable access rejects non-admin', () => {
  assert.throws(
    () => assertAdmin({ auth: null }),
    (err) => err.code === 'unauthenticated',
  );
  assert.throws(
    () => assertAdmin({ auth: { uid: 'u1', token: {} } }),
    (err) => err.code === 'permission-denied',
  );
  assert.throws(
    () =>
      assertAdmin({
        auth: { uid: 'u1', token: { isAdmin: true } },
      }),
    (err) => err.code === 'permission-denied',
  );
  assert.doesNotThrow(() =>
    assertAdmin({ auth: { uid: 'admin-1', token: { admin: true } } }),
  );
});

test('14: existing UserCourse inactive compatibility', async () => {
  const { db, entitlements } = services();
  // Legacy inactive document remains readable and maps to revoked effective.
  const path = 'user_courses/user-legacy/courses/group-ii';
  db._store.set(path, {
    uid: 'user-legacy',
    courseId: 'group-ii',
    status: 'inactive',
    source: 'purchase',
    enrolledAt: Timestamp.fromDate(new Date('2026-01-01')),
    expiresAt: null,
    updatedAt: Timestamp.fromDate(new Date('2026-01-01')),
  });
  const got = await entitlements.get('user-legacy', 'group-ii');
  assert.equal(got.status, 'inactive');
  assert.equal(resolveEffectiveStatus(got, { now: () => NOW }), 'revoked');
});

test('15: grant preserves enrolledAt on update (SubscriptionAccessService shape)', async () => {
  const { entitlements } = services();
  const first = await entitlements.grant({
    uid: 'user-1',
    courseId: 'group-ii',
    source: 'purchase',
    expiresAt: new Date('2026-10-01T00:00:00.000Z'),
  });
  const enrolledAt = first.enrolledAt;
  const second = await entitlements.grant({
    uid: 'user-1',
    courseId: 'group-ii',
    source: 'purchase',
    expiresAt: new Date('2026-12-01T00:00:00.000Z'),
  });
  assert.equal(second.enrolledAt.toMillis(), enrolledAt.toMillis());
  assert.equal(second.status, 'active');
});

test('extend refuses revoked entitlement', async () => {
  const { entitlements } = services();
  await entitlements.grant({
    uid: 'user-1',
    courseId: 'group-ii',
    source: 'admin',
  });
  await entitlements.revoke('user-1', 'group-ii');
  await assert.rejects(
    () =>
      entitlements.extend(
        'user-1',
        'group-ii',
        new Date('2027-01-01T00:00:00.000Z'),
      ),
    /revoked/,
  );
});
