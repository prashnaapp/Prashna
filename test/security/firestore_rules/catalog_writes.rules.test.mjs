import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { describe, it, before, after, beforeEach } from 'mocha';

import {
  PAID_COURSE_ID,
  STUDENT_A,
  adminContext,
  clearFirestore,
  deleteDoc,
  doc,
  futureTimestamp,
  getDoc,
  seed,
  seedCourse,
  seedEnrollment,
  seedQuestion,
  seedTest,
  setDoc,
  setupRulesTestEnvironment,
  studentA,
  teardownRulesTestEnvironment,
  updateDoc,
} from './helpers.mjs';

describe('Firestore rules — catalog writes are server-only', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
    await seed(async (db) => {
      await seedCourse(db, PAID_COURSE_ID, { isFree: false });
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'active',
        expiresAt: futureTimestamp(30),
      });
      await seedQuestion(db, 'q-pub', PAID_COURSE_ID, { isActive: true });
      await seedQuestion(db, 'q-inactive', PAID_COURSE_ID, { isActive: false });
      await seedTest(db, 't-pub', PAID_COURSE_ID, { isPublished: true });
      await seedTest(db, 't-draft', PAID_COURSE_ID, { isPublished: false });
    });
  });

  it('student published reads still work', async () => {
    const db = studentA().firestore();
    await assertSucceeds(getDoc(doc(db, 'questions', 'q-pub')));
    await assertSucceeds(getDoc(doc(db, 'tests', 't-pub')));
  });

  it('student unpublished / inactive reads are denied', async () => {
    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, 'questions', 'q-inactive')));
    await assertFails(getDoc(doc(db, 'tests', 't-draft')));
  });

  it('direct student writes are denied', async () => {
    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, 'questions', 'q-pub'), { stem: 'nope' }),
    );
    await assertFails(deleteDoc(doc(db, 'tests', 't-pub')));
  });

  it('direct admin client writes are denied', async () => {
    const db = adminContext().firestore();
    await assertFails(
      setDoc(doc(db, 'questions', 'q-direct'), {
        courseId: PAID_COURSE_ID,
        isActive: true,
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'tests', 't-pub'), { title: 'direct write' }),
    );
    await assertFails(deleteDoc(doc(db, 'questions', 'q-pub')));
  });
});
