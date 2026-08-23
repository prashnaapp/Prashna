import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { describe, it, before, after, beforeEach } from 'mocha';

import {
  PAID_COURSE_ID,
  adminContext,
  clearFirestore,
  deleteDoc,
  doc,
  getDoc,
  seed,
  seedCourse,
  seedQuestion,
  seedTest,
  setDoc,
  setupRulesTestEnvironment,
  studentA,
  teardownRulesTestEnvironment,
  updateDoc,
} from './helpers.mjs';

describe('Firestore rules — admin claim isolation', () => {
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
    });
  });

  it('1/3: admin can read a question but cannot write it directly', async () => {
    await seed(async (db) => {
      await seedQuestion(db, 'q-admin-1', PAID_COURSE_ID, { isActive: false });
    });
    const db = adminContext().firestore();
    await assertSucceeds(getDoc(doc(db, 'questions', 'q-admin-1')));
    await assertFails(
      setDoc(doc(db, 'questions', 'q-admin-2'), {
        questionId: 'q-admin-2',
        courseId: PAID_COURSE_ID,
        isActive: false,
        stem: 'Admin must use callable',
        questionType: 'mcq',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'questions', 'q-admin-1'), {
        stem: 'Admin must use callable',
      }),
    );
    await assertFails(deleteDoc(doc(db, 'questions', 'q-admin-1')));
  });

  it('2/3: admin can read a test but cannot write it directly', async () => {
    await seed(async (db) => {
      await seedTest(db, 't-admin-1', PAID_COURSE_ID, { isPublished: false });
    });
    const db = adminContext().firestore();
    await assertSucceeds(getDoc(doc(db, 'tests', 't-admin-1')));
    await assertFails(
      setDoc(doc(db, 'tests', 't-admin-2'), {
        testId: 't-admin-2',
        courseId: PAID_COURSE_ID,
        isPublished: false,
        title: 'Admin must use callable',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'tests', 't-admin-1'), {
        title: 'Admin must use callable',
      }),
    );
    await assertFails(deleteDoc(doc(db, 'tests', 't-admin-1')));
  });

  it('3/3: student cannot perform the same admin operations', async () => {
    await seed(async (db) => {
      await seedQuestion(db, 'q-existing', PAID_COURSE_ID, { isActive: false });
      await seedTest(db, 't-existing', PAID_COURSE_ID, { isPublished: false });
    });

    const db = studentA().firestore();

    await assertFails(
      setDoc(doc(db, 'questions', 'q-student-create'), {
        questionId: 'q-student-create',
        courseId: PAID_COURSE_ID,
        isActive: true,
        stem: 'Student should not create',
        questionType: 'mcq',
      }),
    );

    await assertFails(
      updateDoc(doc(db, 'questions', 'q-existing'), {
        stem: 'Student should not update',
      }),
    );

    await assertFails(deleteDoc(doc(db, 'questions', 'q-existing')));

    await assertFails(
      setDoc(doc(db, 'tests', 't-student-create'), {
        testId: 't-student-create',
        courseId: PAID_COURSE_ID,
        isPublished: true,
        title: 'Student should not create',
      }),
    );

    await assertFails(
      updateDoc(doc(db, 'tests', 't-existing'), {
        title: 'Student should not update',
      }),
    );

    await assertFails(deleteDoc(doc(db, 'tests', 't-existing')));
  });
});
