import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { describe, it, before, after, beforeEach } from 'mocha';

import {
  STUDENT_A,
  STUDENT_B,
  PAID_COURSE_ID,
  clearFirestore,
  doc,
  getDoc,
  seed,
  setDoc,
  setupRulesTestEnvironment,
  studentA,
  studentB,
  teardownRulesTestEnvironment,
  updateDoc,
  Timestamp,
} from './helpers.mjs';

describe('Firestore rules — test_attempts server-authoritative lockdown', () => {
  before(async () => {
    await setupRulesTestEnvironment();
  });

  after(async () => {
    await teardownRulesTestEnvironment();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  it('33: client cannot create authoritative attempt', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, 'test_attempts', 'attempt-client-1'), {
        attemptId: 'attempt-client-1',
        uid: STUDENT_A,
        testId: 'test-1',
        courseId: PAID_COURSE_ID,
        status: 'submitted',
        score: 100,
        authority: 'server_verified',
      }),
    );
  });

  it('34/35/36: client cannot update score/status/answers', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'test_attempts', 'attempt-a-1'), {
        attemptId: 'attempt-a-1',
        uid: STUDENT_A,
        testId: 'test-1',
        courseId: PAID_COURSE_ID,
        status: 'submitted',
        score: 1,
        answers: [{ questionId: 'q1', selectedOption: 'A' }],
        authority: 'server_verified',
        submittedAt: Timestamp.now(),
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, 'test_attempts', 'attempt-a-1'), { score: 99 }),
    );
    await assertFails(
      updateDoc(doc(db, 'test_attempts', 'attempt-a-1'), {
        status: 'in_progress',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'test_attempts', 'attempt-a-1'), {
        answers: [{ questionId: 'q1', selectedOption: 'D' }],
      }),
    );
  });

  it('37/38/39: client cannot change uid/testId/configuration', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'test_attempts', 'attempt-a-2'), {
        attemptId: 'attempt-a-2',
        uid: STUDENT_A,
        testId: 'test-1',
        courseId: PAID_COURSE_ID,
        questionIds: ['q1'],
        totalMarks: 1,
        status: 'in_progress',
        authority: 'server_verified',
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, 'test_attempts', 'attempt-a-2'), { uid: STUDENT_B }),
    );
    await assertFails(
      updateDoc(doc(db, 'test_attempts', 'attempt-a-2'), {
        testId: 'hijacked',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'test_attempts', 'attempt-a-2'), {
        questionIds: ['q-fake'],
        totalMarks: 999,
      }),
    );
  });

  it('40: owner can read own attempt', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'test_attempts', 'attempt-a-3'), {
        attemptId: 'attempt-a-3',
        uid: STUDENT_A,
        testId: 'test-1',
        courseId: PAID_COURSE_ID,
        status: 'submitted',
        score: 1,
        authority: 'legacy_client',
      });
    });

    const db = studentA().firestore();
    await assertSucceeds(getDoc(doc(db, 'test_attempts', 'attempt-a-3')));
  });

  it('41: cross-user read denied', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'test_attempts', 'attempt-b-1'), {
        attemptId: 'attempt-b-1',
        uid: STUDENT_B,
        testId: 'test-1',
        courseId: PAID_COURSE_ID,
        status: 'submitted',
        score: 1,
      });
    });

    const db = studentA().firestore();
    await assertFails(getDoc(doc(db, 'test_attempts', 'attempt-b-1')));
  });

  it('42: cross-user update denied', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'test_attempts', 'attempt-b-2'), {
        attemptId: 'attempt-b-2',
        uid: STUDENT_B,
        testId: 'test-1',
        courseId: PAID_COURSE_ID,
        status: 'submitted',
        score: 1,
      });
    });

    const db = studentA().firestore();
    await assertFails(
      updateDoc(doc(db, 'test_attempts', 'attempt-b-2'), { score: 0 }),
    );
  });

  it('43: Admin SDK / privileged writes remain possible', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'test_attempts', 'attempt-admin-1'), {
        attemptId: 'attempt-admin-1',
        uid: STUDENT_A,
        testId: 'test-1',
        courseId: PAID_COURSE_ID,
        status: 'in_progress',
        authority: 'server_verified',
        questionIds: ['q1'],
        score: 0,
      });
      await setDoc(doc(db, 'test_attempt_events', 'attempt-admin-1'), {
        attemptId: 'attempt-admin-1',
        progressApplied: true,
        revisionApplied: true,
      });
    });

    await seed(async (db) => {
      const snap = await getDoc(doc(db, 'test_attempts', 'attempt-admin-1'));
      if (!snap.exists()) {
        throw new Error('Admin SDK write failed');
      }
    });
  });

  it('client cannot write test_attempt_events', async () => {
    const db = studentA().firestore();
    await assertFails(
      setDoc(doc(db, 'test_attempt_events', 'attempt-x'), {
        attemptId: 'attempt-x',
        progressApplied: true,
      }),
    );
  });

  it('9: student cannot read grading answer-key snapshots', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'test_attempt_grading_snapshots', 'attempt-key-1'), {
        attemptId: 'attempt-key-1',
        uid: STUDENT_A,
        questions: [{ questionId: 'q17', correctOption: 'B' }],
      });
    });

    const db = studentA().firestore();
    await assertFails(
      getDoc(doc(db, 'test_attempt_grading_snapshots', 'attempt-key-1')),
    );
    await assertFails(
      setDoc(doc(db, 'test_attempt_grading_snapshots', 'attempt-key-2'), {
        attemptId: 'attempt-key-2',
        questions: [{ correctOption: 'A' }],
      }),
    );
  });

  it('P1-2: client cannot read or write start idempotency keys', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'test_attempt_start_requests', 'student-a__sr-1'), {
        uid: STUDENT_A,
        startRequestId: 'sr-1',
        attemptId: 'attempt-1',
        testId: 'test-1',
      });
    });

    const db = studentA().firestore();
    await assertFails(
      getDoc(doc(db, 'test_attempt_start_requests', 'student-a__sr-1')),
    );
    await assertFails(
      setDoc(doc(db, 'test_attempt_start_requests', 'student-a__sr-2'), {
        uid: STUDENT_A,
        startRequestId: 'sr-2',
        attemptId: 'attempt-2',
      }),
    );
  });
});
