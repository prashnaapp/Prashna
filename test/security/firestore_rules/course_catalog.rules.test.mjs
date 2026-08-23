import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { describe, it, before, after, beforeEach } from 'mocha';

import {
  PAID_COURSE_ID,
  adminContext,
  clearFirestore,
  doc,
  getDoc,
  seed,
  seedCourse,
  setupRulesTestEnvironment,
  studentA,
  teardownRulesTestEnvironment,
  unauthenticated,
} from './helpers.mjs';

describe('Firestore rules — courses catalog publication', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  it('student can read a published course', async () => {
    await seed(async (db) => {
      await seedCourse(db, PAID_COURSE_ID, { isFree: false, isPublished: true });
    });

    const db = studentA().firestore();
    await assertSucceeds(getDoc(doc(db, 'courses', PAID_COURSE_ID)));
  });

  it('student cannot read an unpublished course', async () => {
    await seed(async (db) => {
      await seedCourse(db, 'group-iii-draft', {
        isFree: false,
        isPublished: false,
      });
    });

    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, 'courses', 'group-iii-draft')));
  });

  it('admin can read an unpublished course', async () => {
    await seed(async (db) => {
      await seedCourse(db, 'group-iii-draft', {
        isFree: false,
        isPublished: false,
      });
    });

    const db = adminContext().firestore();
    await assertSucceeds(getDoc(doc(db, 'courses', 'group-iii-draft')));
  });

  it('unauthenticated users cannot read published courses', async () => {
    await seed(async (db) => {
      await seedCourse(db, PAID_COURSE_ID, { isFree: true, isPublished: true });
    });

    const db = unauthenticated().firestore();
    await assertFails(getDoc(doc(db, 'courses', PAID_COURSE_ID)));
  });
});
