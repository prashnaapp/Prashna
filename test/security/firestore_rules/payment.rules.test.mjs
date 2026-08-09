import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { describe, it, before, after, beforeEach } from 'mocha';

import {
  STUDENT_A,
  STUDENT_B,
  PAID_COURSE_ID,
  clearFirestore,
  deleteDoc,
  doc,
  futureTimestamp,
  getDoc,
  seed,
  seedPaymentTransaction,
  setDoc,
  setupRulesTestEnvironment,
  studentA,
  teardownRulesTestEnvironment,
  updateDoc,
} from './helpers.mjs';

describe('Firestore rules — payment_transactions lockdown', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  it('1/6: studentA can read their own payment transaction', async () => {
    await seed(async (db) => {
      await seedPaymentTransaction(db, 'txn-a-1', {
        uid: STUDENT_A,
        status: 'success',
      });
    });

    const db = studentA().firestore();
    await assertSucceeds(getDoc(doc(db, 'payment_transactions', 'txn-a-1')));
  });

  it('2/6: studentA CANNOT read studentB payment transaction', async () => {
    await seed(async (db) => {
      await seedPaymentTransaction(db, 'txn-b-1', {
        uid: STUDENT_B,
        status: 'success',
      });
    });

    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, 'payment_transactions', 'txn-b-1')));
  });

  it('3/6: studentA CANNOT create payment transaction with status success', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, 'payment_transactions', 'txn-spoof-success'), {
        transactionId: 'txn-spoof-success',
        uid: STUDENT_A,
        courseId: PAID_COURSE_ID,
        planId: 'plan-90',
        amount: 299,
        currency: 'INR',
        paymentProvider: 'debug',
        providerTransactionId: 'txn-spoof-success',
        status: 'success',
        purchasedAt: futureTimestamp(0),
        expiresAt: futureTimestamp(90),
        metadata: {},
      }),
    );
  });

  it('4/6: studentA CANNOT create pending payment transaction either', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, 'payment_transactions', 'txn-spoof-pending'), {
        transactionId: 'txn-spoof-pending',
        uid: STUDENT_A,
        courseId: PAID_COURSE_ID,
        planId: 'plan-90',
        amount: 299,
        currency: 'INR',
        paymentProvider: 'debug',
        providerTransactionId: 'txn-spoof-pending',
        status: 'pending',
        purchasedAt: null,
        expiresAt: null,
        metadata: {},
      }),
    );
  });

  it('5/6: studentA CANNOT update an existing transaction', async () => {
    await seed(async (db) => {
      await seedPaymentTransaction(db, 'txn-a-2', {
        uid: STUDENT_A,
        status: 'pending',
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, 'payment_transactions', 'txn-a-2'), {
        status: 'success',
      }),
    );
  });

  it('6/6: studentA CANNOT delete a transaction', async () => {
    await seed(async (db) => {
      await seedPaymentTransaction(db, 'txn-a-3', {
        uid: STUDENT_A,
        status: 'success',
      });
    });

    const db = studentA().firestore();
    await assertFails(deleteDoc(doc(db, 'payment_transactions', 'txn-a-3')));
  });

  it('cross-user: studentA cannot create txn under studentB uid field', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, 'payment_transactions', 'txn-field-spoof'), {
        transactionId: 'txn-field-spoof',
        uid: STUDENT_B,
        courseId: PAID_COURSE_ID,
        planId: 'plan-90',
        amount: 1,
        currency: 'INR',
        paymentProvider: 'debug',
        status: 'success',
        purchasedAt: futureTimestamp(0),
        expiresAt: futureTimestamp(90),
        metadata: {},
      }),
    );
  });
});
