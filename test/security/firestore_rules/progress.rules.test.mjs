/**
 * Firestore rules tests for per-course user progress:
 * user_progress/{userId}/courses/{courseId}
 *
 * Emulator-only. Never targets production.
 */
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { describe, it, before, after, beforeEach } from 'mocha';

import {
  STUDENT_A,
  STUDENT_B,
  clearFirestore,
  deleteDoc,
  doc,
  getDoc,
  seed,
  setDoc,
  setupRulesTestEnvironment,
  studentA,
  studentB,
  teardownRulesTestEnvironment,
  unauthenticated,
  updateDoc,
} from './helpers.mjs';

const COURSE_A = 'group-ii';
const COURSE_B = 'group-iii';

function courseProgressPath(uid, courseId) {
  return `user_progress/${uid}/courses/${courseId}`;
}

function courseProgressDoc(uid, courseId, overrides = {}) {
  return {
    uid,
    courseId,
    overall: {
      completion: 10,
      accuracy: 0.5,
      chaptersCompleted: 1,
      totalChapters: 5,
      questionsAttempted: 10,
      questionsCorrect: 5,
    },
    papers: {},
    chapters: {},
    appVersion: '1.0.0',
    schemaVersion: 1,
    ...overrides,
  };
}

describe('Firestore rules — user_progress per-course documents', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  it('1: student can create own course progress', async () => {
    const db = studentA().firestore();
    await assertSucceeds(
      setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      ),
    );
  });

  it('2: student can read own course progress', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      );
    });

    const db = studentA().firestore();
    await assertSucceeds(
      getDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A))),
    );
  });

  it('3: student can update own course progress', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      );
    });

    const db = studentA().firestore();
    await assertSucceeds(
      updateDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)), {
        overall: {
          completion: 55,
          accuracy: 0.7,
          chaptersCompleted: 2,
          totalChapters: 5,
          questionsAttempted: 20,
          questionsCorrect: 14,
        },
      }),
    );
  });

  it('4: student cannot delete own course progress', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      );
    });

    const db = studentA().firestore();
    await assertFails(
      deleteDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A))),
    );
  });

  it('5: student cannot create progress under another uid', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(
        doc(db, courseProgressPath(STUDENT_B, COURSE_A)),
        courseProgressDoc(STUDENT_B, COURSE_A),
      ),
    );
  });

  it('6: student cannot read another user progress', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_B, COURSE_A)),
        courseProgressDoc(STUDENT_B, COURSE_A),
      );
    });

    const db = studentA().firestore();
    await assertFails(
      getDoc(doc(db, courseProgressPath(STUDENT_B, COURSE_A))),
    );
  });

  it('7: student cannot update another user progress', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_B, COURSE_A)),
        courseProgressDoc(STUDENT_B, COURSE_A),
      );
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, courseProgressPath(STUDENT_B, COURSE_A)), {
        'overall.completion': 99,
      }),
    );
  });

  it('8: student cannot change uid field', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      );
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)), {
        uid: STUDENT_B,
      }),
    );
  });

  it('9: student cannot change courseId field', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      );
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)), {
        courseId: COURSE_B,
      }),
    );
  });

  it('10: different course documents remain independent', async () => {
    const db = studentA().firestore();
    await assertSucceeds(
      setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A, {
          overall: {
            completion: 11,
            accuracy: 0.5,
            chaptersCompleted: 1,
            totalChapters: 5,
            questionsAttempted: 10,
            questionsCorrect: 5,
          },
        }),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_B)),
        courseProgressDoc(STUDENT_A, COURSE_B, {
          overall: {
            completion: 22,
            accuracy: 0.5,
            chaptersCompleted: 1,
            totalChapters: 5,
            questionsAttempted: 10,
            questionsCorrect: 5,
          },
        }),
      ),
    );

    await assertSucceeds(
      updateDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)), {
        overall: {
          completion: 99,
          accuracy: 0.9,
          chaptersCompleted: 4,
          totalChapters: 5,
          questionsAttempted: 40,
          questionsCorrect: 36,
        },
      }),
    );

    const aSnap = await getDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)));
    const bSnap = await getDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_B)));
    if (aSnap.data().overall.completion !== 99) {
      throw new Error('course A was not updated');
    }
    if (bSnap.data().overall.completion !== 22) {
      throw new Error('course B was unexpectedly modified');
    }
  });

  it('11: unauthenticated access denied', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      );
    });

    const db = unauthenticated().firestore();
    await assertFails(
      getDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A))),
    );
    await assertFails(
      setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      ),
    );
  });

  it('12: create rejects body uid/courseId mismatch with path', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)), {
        ...courseProgressDoc(STUDENT_A, COURSE_A),
        uid: STUDENT_B,
      }),
    );
    await assertFails(
      setDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)), {
        ...courseProgressDoc(STUDENT_A, COURSE_A),
        courseId: COURSE_B,
      }),
    );
  });

  it('13: legacy parent user_progress/{uid} behavior unchanged', async () => {
    const db = studentA().firestore();
    await assertSucceeds(
      setDoc(doc(db, `user_progress/${STUDENT_A}`), {
        uid: STUDENT_A,
        courseId: COURSE_A,
        overall: { completion: 1 },
        papers: {},
        chapters: {},
        appVersion: '1.0.0',
      }),
    );
    await assertSucceeds(getDoc(doc(db, `user_progress/${STUDENT_A}`)));
    await assertFails(
      setDoc(doc(db, `user_progress/${STUDENT_B}`), {
        uid: STUDENT_B,
        courseId: COURSE_A,
        overall: { completion: 1 },
        papers: {},
        chapters: {},
        appVersion: '1.0.0',
      }),
    );
    await assertFails(deleteDoc(doc(db, `user_progress/${STUDENT_A}`)));
  });
});
