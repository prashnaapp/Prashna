import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { describe, it, before, after, beforeEach } from 'mocha';

import {
  STUDENT_A,
  STUDENT_B,
  PAID_COURSE_ID,
  clearFirestore,
  deleteDoc,
  doc,
  enrollmentPath,
  futureTimestamp,
  getDoc,
  seed,
  seedEnrollment,
  setDoc,
  setupRulesTestEnvironment,
  studentA,
  studentB,
  teardownRulesTestEnvironment,
  updateDoc,
} from './helpers.mjs';

describe('Firestore rules — user_courses enrollment lockdown', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  it('1/10: studentA can read their own enrollment', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      });
    });

    const db = studentA().firestore();
    await assertSucceeds(
      getDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID))),
    );
  });

  it('2/10: studentA CANNOT read studentB enrollment', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_B, PAID_COURSE_ID, {
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      });
    });

    const db = studentA().firestore();
    await assertFails(
      getDoc(doc(db, enrollmentPath(STUDENT_B, PAID_COURSE_ID))),
    );
  });

  it('3/10: studentA CANNOT create active purchase enrollment', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID)), {
        uid: STUDENT_A,
        courseId: PAID_COURSE_ID,
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      }),
    );
  });

  it('4/10: studentA CANNOT create inactive enrollment either', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID)), {
        uid: STUDENT_A,
        courseId: PAID_COURSE_ID,
        status: 'inactive',
        source: 'free',
        expiresAt: null,
      }),
    );
  });

  it('5/10: studentA CANNOT update inactive → active', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'inactive',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID)), {
        status: 'active',
      }),
    );
  });

  it('6/10: studentA CANNOT extend expiresAt', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(7),
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID)), {
        expiresAt: futureTimestamp(365),
      }),
    );
  });

  it('7/10: studentA CANNOT clear expiresAt', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(7),
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID)), {
        expiresAt: null,
      }),
    );
  });

  it('8/10: studentA CANNOT change source to purchase', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'active',
        source: 'free',
        expiresAt: futureTimestamp(30),
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID)), {
        source: 'purchase',
      }),
    );
  });

  it('9/10: studentA CANNOT delete their enrollment', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      });
    });

    const db = studentA().firestore();
    await assertFails(
      deleteDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID))),
    );
  });

  it('10/10: existing active enrollment remains readable', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID, {
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      });
    });

    const db = studentA().firestore();
    const snap = await assertSucceeds(
      getDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID))),
    );
    if (!snap.exists()) {
      throw new Error('Expected seeded enrollment to exist');
    }
    if (snap.data().status !== 'active') {
      throw new Error('Expected status active');
    }
  });

  it('cross-user: studentA CANNOT create enrollment under studentB path', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, enrollmentPath(STUDENT_B, PAID_COURSE_ID)), {
        uid: STUDENT_A,
        courseId: PAID_COURSE_ID,
        status: 'active',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      }),
    );
  });

  it('cross-user: studentA CANNOT update studentB enrollment', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_B, PAID_COURSE_ID, {
        status: 'inactive',
        source: 'purchase',
        expiresAt: futureTimestamp(30),
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, enrollmentPath(STUDENT_B, PAID_COURSE_ID)), {
        status: 'active',
      }),
    );
  });

  it('cross-user: studentB still cannot read studentA enrollment', async () => {
    await seed(async (db) => {
      await seedEnrollment(db, STUDENT_A, PAID_COURSE_ID);
    });

    const db = studentB().firestore();
    await assertFails(
      getDoc(doc(db, enrollmentPath(STUDENT_A, PAID_COURSE_ID))),
    );
  });
});
