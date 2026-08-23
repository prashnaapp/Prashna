import assert from 'node:assert/strict';
import test from 'node:test';

import {
  rejectUnverifiedAdminPayment,
  assertAdmin,
} from '../src/callables.js';

const adminRequest = {
  auth: { uid: 'admin-1', token: { admin: true } },
  data: {
    paymentProvider: 'google_play',
    providerTransactionId: 'spoof-token',
    uid: 'student-1',
    courseId: 'group-ii',
    planId: 'group2_12m',
    amount: 699,
    currency: 'INR',
    expiresAt: '2027-08-10T00:00:00.000Z',
    source: 'purchase',
  },
};

test('adminProcessVerifiedPayment rejects admin-supplied unverified payment facts', () => {
  assert.throws(
    () => rejectUnverifiedAdminPayment(adminRequest),
    (err) =>
      err.code === 'failed-precondition'
      && /Google Play verification/.test(err.message),
  );
});

test('adminProcessVerifiedPayment still requires the admin claim', () => {
  assert.throws(
    () => rejectUnverifiedAdminPayment({ auth: { uid: 'u1', token: {} }, data: {} }),
    (err) => err.code === 'permission-denied',
  );
  assert.throws(
    () => rejectUnverifiedAdminPayment({ auth: null, data: {} }),
    (err) => err.code === 'unauthenticated',
  );
  assert.doesNotThrow(() => assertAdmin(adminRequest));
});
