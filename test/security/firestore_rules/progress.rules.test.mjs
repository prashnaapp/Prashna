/**
 * Firestore rules tests for per-course user progress (Phase 5.21 lockdown):
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

describe('Firestore rules — user_progress server-authoritative lockdown', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  it('1: client cannot create authoritative course progress', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      ),
    );
  });

  it('2: owner can read own course progress', async () => {
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

  it('3: client cannot update score aggregates / fake completion', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A),
      );
    });

    const db = studentA().firestore();
    await assertFails(
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

  it('8/9: client cannot change uid or courseId', async () => {
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
    await assertFails(
      updateDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)), {
        courseId: COURSE_B,
      }),
    );
  });

  it('10: course documents remain independent under Admin SDK seed', async () => {
    await seed(async (db) => {
      await setDoc(
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
      );
      await setDoc(
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
      );
      await setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A, {
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
    });

    const db = studentA().firestore();
    const aSnap = await getDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)));
    const bSnap = await getDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_B)));
    if (aSnap.data().overall.completion !== 99) {
      throw new Error('course A was not updated by Admin SDK');
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

  it('12: client create still denied even with matching body fields', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)), {
        ...courseProgressDoc(STUDENT_A, COURSE_A),
        uid: STUDENT_A,
        courseId: COURSE_A,
      }),
    );
  });

  it('13: legacy parent user_progress/{uid} client writes denied; Admin SDK ok', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, `user_progress/${STUDENT_A}`), {
        uid: STUDENT_A,
        courseId: COURSE_A,
        overall: { completion: 1 },
        papers: {},
        chapters: {},
        appVersion: '1.0.0',
      }),
    );

    await seed(async (adminDb) => {
      await setDoc(doc(adminDb, `user_progress/${STUDENT_A}`), {
        uid: STUDENT_A,
        courseId: COURSE_A,
        overall: { completion: 1 },
        papers: {},
        chapters: {},
        appVersion: '1.0.0',
      });
    });

    await assertSucceeds(getDoc(doc(db, `user_progress/${STUDENT_A}`)));
    await assertFails(deleteDoc(doc(db, `user_progress/${STUDENT_A}`)));
  });

  it('Admin SDK / backend writes remain possible', async () => {
    await seed(async (db) => {
      await setDoc(
        doc(db, courseProgressPath(STUDENT_A, COURSE_A)),
        courseProgressDoc(STUDENT_A, COURSE_A, {
          authority: 'server_verified',
        }),
      );
    });
    const db = studentA().firestore();
    const snap = await getDoc(doc(db, courseProgressPath(STUDENT_A, COURSE_A)));
    if (!snap.exists()) throw new Error('Admin SDK write failed');
  });
});

describe('Firestore rules — user_revision server-authoritative lockdown', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  it('client cannot create verified revision records', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, `user_revision/${STUDENT_A}`), {
        uid: STUDENT_A,
        wrongQuestions: ['q-fake'],
        frequentlyWrongQuestions: ['q-fake'],
        weakQuestions: [],
      }),
    );
  });

  it('client cannot update revision wrong lists', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, `user_revision/${STUDENT_A}`), {
        uid: STUDENT_A,
        wrongQuestions: ['q1'],
        frequentlyWrongQuestions: [],
        weakQuestions: [],
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, `user_revision/${STUDENT_A}`), {
        wrongQuestions: ['q1', 'q-forged'],
      }),
    );
  });

  it('owner can read own revision', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, `user_revision/${STUDENT_A}`), {
        uid: STUDENT_A,
        wrongQuestions: ['q1'],
        frequentlyWrongQuestions: [],
        weakQuestions: [],
      });
    });
    const db = studentA().firestore();
    await assertSucceeds(getDoc(doc(db, `user_revision/${STUDENT_A}`)));
  });

  it('cross-user revision read denied', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, `user_revision/${STUDENT_B}`), {
        uid: STUDENT_B,
        wrongQuestions: ['q1'],
        frequentlyWrongQuestions: [],
        weakQuestions: [],
      });
    });
    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, `user_revision/${STUDENT_B}`)));
  });

  it('Admin SDK revision writes remain possible', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, `user_revision/${STUDENT_A}`), {
        uid: STUDENT_A,
        wrongQuestions: ['q1'],
        frequentlyWrongQuestions: ['q1'],
        weakQuestions: [],
        authority: 'server_verified',
      });
    });
    const db = studentA().firestore();
    const snap = await getDoc(doc(db, `user_revision/${STUDENT_A}`));
    if (!snap.exists()) throw new Error('Admin SDK revision write failed');
  });
});

describe('Firestore rules — unit_performance lockdown', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  const scopeKey =
    'v1|group-iii|group-iii-paper-ii|group-iii-paper-ii-part-i|unit-02';

  function unitPath(uid) {
    return `user_progress/${uid}/unit_performance/${scopeKey}`;
  }

  it('15: student can read own unit performance', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, unitPath(STUDENT_A)), {
        uid: STUDENT_A,
        scopeKey,
        courseId: 'group-iii',
        paperId: 'group-iii-paper-ii',
        syllabusUnitId: 'unit-02',
        correct: 1,
        authority: 'server_verified',
      });
    });
    const db = studentA().firestore();
    await assertSucceeds(getDoc(doc(db, unitPath(STUDENT_A))));
  });

  it('15: student cannot write authoritative unit performance', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, unitPath(STUDENT_A)), {
        uid: STUDENT_A,
        scopeKey,
        correct: 999,
        marksObtained: 999,
        authority: 'server_verified',
      }),
    );
  });

  it('15: student cannot read another user unit performance', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, unitPath(STUDENT_B)), {
        uid: STUDENT_B,
        scopeKey,
        correct: 1,
      });
    });
    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, unitPath(STUDENT_B))));
  });
});

describe('Firestore rules — syllabus_completion lockdown', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  const scopeKey =
    'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01';

  function completionPath(uid) {
    return `user_progress/${uid}/syllabus_completion/${scopeKey}`;
  }

  it('13: student cannot directly write completion document', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, completionPath(STUDENT_A)), {
        uid: STUDENT_A,
        scopeKey,
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
        status: 'completed',
      }),
    );
  });

  it('14: student can read own completion', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, completionPath(STUDENT_A)), {
        uid: STUDENT_A,
        scopeKey,
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
        status: 'in_progress',
      });
    });
    const db = studentA().firestore();
    await assertSucceeds(getDoc(doc(db, completionPath(STUDENT_A))));
  });

  it('15: student cannot read another user completion', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, completionPath(STUDENT_B)), {
        uid: STUDENT_B,
        scopeKey,
        status: 'completed',
      });
    });
    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, completionPath(STUDENT_B))));
  });

  it('student cannot update or delete own completion', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, completionPath(STUDENT_A)), {
        uid: STUDENT_A,
        scopeKey,
        status: 'in_progress',
      });
    });
    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, completionPath(STUDENT_A)), {
        status: 'completed',
      }),
    );
    await assertFails(deleteDoc(doc(db, completionPath(STUDENT_A))));
  });

  it('Admin SDK / backend completion writes remain possible', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, completionPath(STUDENT_A)), {
        uid: STUDENT_A,
        scopeKey,
        status: 'completed',
      });
    });
    const db = studentA().firestore();
    const snap = await getDoc(doc(db, completionPath(STUDENT_A)));
    if (!snap.exists()) throw new Error('Admin SDK completion write failed');
  });
});
