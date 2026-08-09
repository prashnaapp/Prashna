import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { describe, it, before, after, beforeEach } from 'mocha';

import {
  FREE_COURSE_ID,
  PAID_COURSE_ID,
  STUDENT_A,
  clearFirestore,
  doc,
  futureTimestamp,
  getDoc,
  pastTimestamp,
  seed,
  seedCourse,
  seedEnrollment,
  seedQuestion,
  seedTest,
  setDoc,
  setupRulesTestEnvironment,
  studentA,
  teardownRulesTestEnvironment,
} from './helpers.mjs';

describe('Firestore rules — course access via questions/tests', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  it('1/5: free course content readable when courses.isFree == true (no enrollment)', async () => {
    await seed(async (db) => {
      await seedCourse(db, FREE_COURSE_ID, { isFree: true });
      await seedQuestion(db, 'q-free-1', FREE_COURSE_ID, { isActive: true });
      await seedTest(db, 't-free-1', FREE_COURSE_ID, { isPublished: true });
    });

    const db = studentA().firestore();
    await assertSucceeds(getDoc(doc(db, 'questions', 'q-free-1')));
    await assertSucceeds(getDoc(doc(db, 'tests', 't-free-1')));
  });

  it('2/5: paid course without entitlement is denied', async () => {
    await seed(async (db) => {
      await seedCourse(db, PAID_COURSE_ID, { isFree: false });
      await seedQuestion(db, 'q-paid-1', PAID_COURSE_ID, { isActive: true });
      await seedTest(db, 't-paid-1', PAID_COURSE_ID, { isPublished: true });
    });

    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, 'questions', 'q-paid-1')));
    await assertFails(getDoc(doc(db, 'tests', 't-paid-1')));
  });

  it('3/5: paid course with valid active entitlement is allowed', async () => {
    await seed(async (db) => {
      await seedCourse(db, PAID_COURSE_ID, { isFree: false });
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      });
      await seedQuestion(db, 'q-paid-2', PAID_COURSE_ID, { isActive: true });
      await seedTest(db, 't-paid-2', PAID_COURSE_ID, { isPublished: true });
    });

    const db = studentA().firestore();
    await assertSucceeds(getDoc(doc(db, 'questions', 'q-paid-2')));
    await assertSucceeds(getDoc(doc(db, 'tests', 't-paid-2')));
  });

  it('4/5: expired entitlement is denied', async () => {
    await seed(async (db) => {
      await seedCourse(db, PAID_COURSE_ID, { isFree: false });
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'active',
        source: 'purchase',
        expiresAt: pastTimestamp(1),
      });
      await seedQuestion(db, 'q-paid-3', PAID_COURSE_ID, { isActive: true });
      await seedTest(db, 't-paid-3', PAID_COURSE_ID, { isPublished: true });
    });

    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, 'questions', 'q-paid-3')));
    await assertFails(getDoc(doc(db, 'tests', 't-paid-3')));
  });

  it('5/5: inactive entitlement is denied', async () => {
    await seed(async (db) => {
      await seedCourse(db, PAID_COURSE_ID, { isFree: false });
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'inactive',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      });
      await seedQuestion(db, 'q-paid-4', PAID_COURSE_ID, { isActive: true });
      await seedTest(db, 't-paid-4', PAID_COURSE_ID, { isPublished: true });
    });

    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, 'questions', 'q-paid-4')));
    await assertFails(getDoc(doc(db, 'tests', 't-paid-4')));
  });

  it('student cannot manufacture entitlement then read paid content', async () => {
    await seed(async (db) => {
      await seedCourse(db, PAID_COURSE_ID, { isFree: false });
      await seedQuestion(db, 'q-paid-5', PAID_COURSE_ID, { isActive: true });
    });

    // Create attempt is denied by enrollment rules; paid question remains denied.
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, `user_courses/${STUDENT_A}/courses/${PAID_COURSE_ID}`), {
        uid: STUDENT_A,
        courseId: PAID_COURSE_ID,
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      }),
    );
    await assertFails(getDoc(doc(db, 'questions', 'q-paid-5')));
  });
});
