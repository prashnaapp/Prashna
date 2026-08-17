import assert from 'node:assert/strict';
import test from 'node:test';

import { createEntitlementService } from '../src/entitlement_service.js';
import {
  createSyllabusCompletionService,
  resolveValidatedCompletionScope,
  SyllabusCompletionStatus,
  syllabusCompletionRef,
} from '../src/syllabus_completion_service.js';
import { createTestAttemptService } from '../src/test_attempt_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-15T15:00:00.000Z');
const UID = 'student-completion-1';

async function seedAccess(db, courseId) {
  await db.collection('courses').doc(courseId).set({
    id: courseId,
    name: courseId,
    isFree: false,
    isPublished: true,
  });
  await createEntitlementService(db).grant({
    uid: UID,
    courseId,
    source: 'purchase',
    expiresAt: new Date(NOW.getTime() + 365 * 24 * 60 * 60 * 1000),
  });
}

function createService(db) {
  return createSyllabusCompletionService(db, { now: () => NOW });
}

test('7: Group-II Paper-I scopeKey + in_progress write', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const service = createService(db);

  const result = await service.setCompletionStatus({
    uid: UID,
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
    status: SyllabusCompletionStatus.inProgress,
  });

  assert.equal(
    result.scopeKey,
    'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
  );
  assert.equal(result.status, 'in_progress');
  assert.equal(result.completion.status, 'in_progress');
  assert.equal(result.completion.completedAt, null);

  const snap = await syllabusCompletionRef(db, UID, result.scopeKey).get();
  assert.equal(snap.exists, true);
  assert.equal(snap.data().uid, UID);
});

test('8: Group-II Part/Unit completed', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const service = createService(db);

  const result = await service.setCompletionStatus({
    uid: UID,
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
    status: SyllabusCompletionStatus.completed,
  });

  assert.equal(
    result.scopeKey,
    'v1|group-ii|group-ii-paper-ii|group-ii-paper-ii-part-01|group-ii-paper-ii-part-01-topic-04',
  );
  assert.equal(result.status, 'completed');
  assert.ok(result.completion.completedAt);
});

test('9/10: Group-III Paper-I and Part/Unit', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  const service = createService(db);

  const paperI = await service.setCompletionStatus({
    uid: UID,
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: 'group-iii-paper-i-unit-01',
    status: SyllabusCompletionStatus.inProgress,
  });
  assert.equal(
    paperI.scopeKey,
    'v1|group-iii|group-iii-paper-i||group-iii-paper-i-unit-01',
  );

  const partUnit = await service.setCompletionStatus({
    uid: UID,
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: 'group-iii-paper-ii-part-i-unit-02',
    status: SyllabusCompletionStatus.completed,
  });
  assert.equal(
    partUnit.scopeKey,
    'v1|group-iii|group-iii-paper-ii|group-iii-paper-ii-part-i|group-iii-paper-ii-part-i-unit-02',
  );
});

test('2/3/4/5: Completed → In Progress → Reset', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const service = createService(db);
  const args = {
    uid: UID,
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
  };

  await service.setCompletionStatus({
    ...args,
    status: SyllabusCompletionStatus.completed,
  });
  const back = await service.setCompletionStatus({
    ...args,
    status: SyllabusCompletionStatus.inProgress,
  });
  assert.equal(back.status, 'in_progress');
  assert.equal(back.completion.completedAt, null);

  const reset = await service.setCompletionStatus({
    ...args,
    status: SyllabusCompletionStatus.notStarted,
  });
  assert.equal(reset.status, 'not_started');
  assert.equal(reset.completion, null);

  const snap = await syllabusCompletionRef(db, UID, reset.scopeKey).get();
  assert.equal(snap.exists, false);
});

test('11: invalid scope rejected', () => {
  assert.throws(
    () =>
      resolveValidatedCompletionScope({
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        partId: 'should-not-exist',
        syllabusUnitId: 'group-ii-paper-i-area-01',
      }),
    (error) => error.code === 'not-found',
  );
});

test('12: unknown syllabus unit rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const service = createService(db);

  await assert.rejects(
    () =>
      service.setCompletionStatus({
        uid: UID,
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'not-a-real-unit',
        status: SyllabusCompletionStatus.inProgress,
      }),
    (error) => error.code === 'not-found',
  );
});

test('11: spoofed scopeKey rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const service = createService(db);

  await assert.rejects(
    () =>
      service.setCompletionStatus({
        uid: UID,
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
        status: SyllabusCompletionStatus.inProgress,
        scopeKey: 'v1|group-ii|forged||group-ii-paper-i-area-01',
      }),
    (error) => error.code === 'invalid-argument',
  );
});

test('16: service uses provided auth uid, not client body course alone without access', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  // No entitlement seeded.
  const service = createService(db);

  await assert.rejects(
    () =>
      service.setCompletionStatus({
        uid: UID,
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
        status: SyllabusCompletionStatus.inProgress,
      }),
    (error) => error.code === 'permission-denied',
  );
});

test('19/20: test submission does not write syllabus_completion', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');

  await db.collection('questions').doc('q1').set({
    id: 'q1',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: 'group-iii-paper-ii-part-i-unit-02',
    isActive: true,
    question: 'Q',
    explanation: 'E',
    correctOption: 'A',
    options: [
      { label: 'A', text: 'A' },
      { label: 'B', text: 'B' },
      { label: 'C', text: 'C' },
      { label: 'D', text: 'D' },
    ],
  });
  await db.collection('tests').doc('test-1').set({
    id: 'test-1',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: 'group-iii-paper-ii-part-i-unit-02',
    title: 'test-1',
    category: 'chapter',
    status: 'published',
    isPublished: true,
    questionIds: ['q1'],
    questionCount: 1,
    totalMarks: 1,
    durationMinutes: 10,
    negativeMarks: 0,
  });

  const attempts = createTestAttemptService({
    db,
    now: () => NOW,
    generateAttemptId: () => 'attempt-1',
  });
  const started = await attempts.startAttempt({ uid: UID, testId: 'test-1', startRequestId: 'req-syllabus_completion.test-1' });
  await attempts.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q1', selectedOption: 'A' }],
  });

  const scopeKey =
    'v1|group-iii|group-iii-paper-ii|group-iii-paper-ii-part-i|group-iii-paper-ii-part-i-unit-02';
  const completionSnap = await syllabusCompletionRef(db, UID, scopeKey).get();
  assert.equal(completionSnap.exists, false);

  const unitPerf = await db
    .collection('user_progress')
    .doc(UID)
    .collection('unit_performance')
    .doc(scopeKey)
    .get();
  assert.equal(unitPerf.exists, true);
});

test('24: duplicate completed mutation is safe', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const service = createService(db);
  const args = {
    uid: UID,
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
    status: SyllabusCompletionStatus.completed,
  };
  const first = await service.setCompletionStatus(args);
  const second = await service.setCompletionStatus(args);
  assert.equal(first.status, 'completed');
  assert.equal(second.status, 'completed');
  const snap = await syllabusCompletionRef(db, UID, first.scopeKey).get();
  assert.equal(snap.data().status, 'completed');
});

test('contentTopicId is not accepted as unit identity for Paper-I', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const service = createService(db);

  await assert.rejects(
    () =>
      service.setCompletionStatus({
        uid: UID,
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01-topic-01',
        status: SyllabusCompletionStatus.inProgress,
      }),
    (error) => error.code === 'not-found',
  );
});
