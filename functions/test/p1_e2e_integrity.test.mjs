import assert from 'node:assert/strict';
import test from 'node:test';

import { createEntitlementService } from '../src/entitlement_service.js';
import {
  createTestAttemptService,
  questionMatchesExactCanonicalScope,
  reconstructWrongQuestionIds,
  startRequestDocId,
} from '../src/test_attempt_service.js';
import { GRADING_SNAPSHOT_COLLECTION } from '../src/attempt_snapshot.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-15T12:00:00.000Z');
const UID = 'student-p1';
const UID_B = 'student-p1-b';

function createService(db, overrides = {}) {
  return createTestAttemptService({
    db,
    now: () => NOW,
    generateAttemptId: () => 'attempt-p1-1',
    random: () => 0,
    ...overrides,
  });
}

async function seedAccess(db, courseId, uid = UID) {
  await db.collection('courses').doc(courseId).set({
    id: courseId,
    name: courseId,
    isFree: false,
    isPublished: true,
  });
  await createEntitlementService(db).grant({
    uid,
    courseId,
    source: 'purchase',
    expiresAt: new Date(NOW.getTime() + 365 * 24 * 60 * 60 * 1000),
  });
}

async function seedQuestion(db, fields) {
  await db.collection('questions').doc(fields.id).set({
    isActive: true,
    question: `Question ${fields.id}`,
    explanation: `Explanation ${fields.id}`,
    correctOption: fields.correctOption || 'A',
    options: [
      { label: 'A', text: 'one' },
      { label: 'B', text: 'two' },
      { label: 'C', text: 'three' },
      { label: 'D', text: 'four' },
    ],
    ...fields,
  });
}

async function seedConfiguredTest(db, {
  testId,
  courseId,
  paperId,
  partId = null,
  syllabusUnitId,
  questionIds,
}) {
  await db.collection('tests').doc(testId).set({
    id: testId,
    courseId,
    title: testId,
    category: 'chapterTests',
    questionCount: questionIds.length,
    totalMarks: questionIds.length,
    durationMinutes: 10,
    negativeMarks: 0,
    questionIds,
    paperId,
    partId,
    syllabusUnitId,
    status: 'published',
    isPublished: true,
  });
}

test('P1-1.1 exact canonical question scope accepted', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  const unit = 'group-iii-paper-ii-part-i-unit-02';
  await seedQuestion(db, {
    id: 'ok-q1',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
  });
  await seedConfiguredTest(db, {
    testId: 'exact-ok',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
    questionIds: ['ok-q1'],
  });
  const started = await createService(db).startAttempt({
    uid: UID,
    testId: 'exact-ok',
    startRequestId: 'sr-exact-ok',
  });
  assert.deepEqual(started.questionIds, ['ok-q1']);
});

test('P1-1.2/3/4/5 wrong unit/part/paper/course rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  await seedAccess(db, 'group-ii');
  const unit = 'group-iii-paper-ii-part-i-unit-02';
  await seedQuestion(db, {
    id: 'wrong-unit',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: 'group-iii-paper-ii-part-i-unit-01',
  });
  await seedQuestion(db, {
    id: 'wrong-part',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-ii',
    syllabusUnitId: unit,
  });
  await seedQuestion(db, {
    id: 'wrong-paper',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    partId: null,
    syllabusUnitId: unit,
  });
  await seedQuestion(db, {
    id: 'wrong-course',
    courseId: 'group-ii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
  });

  for (const [qid, label] of [
    ['wrong-unit', 'unit'],
    ['wrong-part', 'part'],
    ['wrong-paper', 'paper'],
    ['wrong-course', 'course'],
  ]) {
    await seedConfiguredTest(db, {
      testId: `reject-${label}`,
      courseId: 'group-iii',
      paperId: 'group-iii-paper-ii',
      partId: 'group-iii-paper-ii-part-i',
      syllabusUnitId: unit,
      questionIds: [qid],
    });
    await assert.rejects(
      () =>
        createService(db, {
          generateAttemptId: () => `attempt-${label}`,
        }).startAttempt({
          uid: UID,
          testId: `reject-${label}`,
          startRequestId: `sr-reject-${label}`,
        }),
      /exact canonical syllabus scope/,
    );
  }
});

test('P1-1.6 duplicate questionIds rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  const unit = 'group-iii-paper-ii-part-i-unit-02';
  await seedQuestion(db, {
    id: 'dup-q',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
  });
  await seedConfiguredTest(db, {
    testId: 'dup-test',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
    questionIds: ['dup-q', 'dup-q'],
  });
  // questionCount intentionally matches array length including duplicate
  await db.collection('tests').doc('dup-test').set(
    { questionCount: 2 },
    { merge: true },
  );
  await assert.rejects(
    () =>
      createService(db).startAttempt({
        uid: UID,
        testId: 'dup-test',
        startRequestId: 'sr-dup',
      }),
    /duplicate questionId/,
  );
});

test('P1-1.7 Paper-I direct-unit scope accepted', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const unit = 'group-ii-paper-i-area-01';
  await seedQuestion(db, {
    id: 'paper-i-q',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    partId: null,
    syllabusUnitId: unit,
    majorStudyAreaId: unit,
  });
  await seedConfiguredTest(db, {
    testId: 'paper-i-test',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    partId: null,
    syllabusUnitId: unit,
    questionIds: ['paper-i-q'],
  });
  const started = await createService(db).startAttempt({
    uid: UID,
    testId: 'paper-i-test',
    startRequestId: 'sr-paper-i',
  });
  assert.deepEqual(started.questionIds, ['paper-i-q']);
  assert.equal(
    questionMatchesExactCanonicalScope(
      {
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        partId: null,
        syllabusUnitId: unit,
      },
      {
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        partId: null,
        syllabusUnitId: unit,
      },
    ),
    true,
  );
});

test('P1-1.8 legacy test without canonical metadata still works', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  await seedQuestion(db, {
    id: 'legacy-q1',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
  });
  await seedQuestion(db, {
    id: 'legacy-q2',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
  });
  await db.collection('tests').doc('legacy-test').set({
    id: 'legacy-test',
    courseId: 'group-ii',
    title: 'Legacy',
    category: 'chapterTests',
    questionCount: 2,
    totalMarks: 2,
    durationMinutes: 10,
    negativeMarks: 0,
    questionIds: ['legacy-q1', 'legacy-q2'],
    status: 'published',
    isPublished: true,
  });
  const started = await createService(db).startAttempt({
    uid: UID,
    testId: 'legacy-test',
    startRequestId: 'sr-legacy',
  });
  assert.deepEqual(started.questionIds, ['legacy-q1', 'legacy-q2']);
});

test('P1-2 start idempotency', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  await seedAccess(db, 'group-iii', UID_B);
  const unit = 'group-iii-paper-i-unit-01';
  await seedQuestion(db, {
    id: 'idem-q',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: unit,
  });
  await seedConfiguredTest(db, {
    testId: 'idem-test',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: unit,
    questionIds: ['idem-q'],
  });

  let attemptCounter = 0;
  const service = createService(db, {
    generateAttemptId: () => `attempt-idem-${++attemptCounter}`,
  });

  const first = await service.startAttempt({
    uid: UID,
    testId: 'idem-test',
    startRequestId: 'stable-key-1',
  });
  const retry = await service.startAttempt({
    uid: UID,
    testId: 'idem-test',
    startRequestId: 'stable-key-1',
  });
  assert.equal(first.attemptId, retry.attemptId);
  assert.equal(retry.duplicate, true);
  assert.equal(attemptCounter, 1);

  const second = await service.startAttempt({
    uid: UID,
    testId: 'idem-test',
    startRequestId: 'stable-key-2',
  });
  assert.notEqual(second.attemptId, first.attemptId);
  assert.equal(second.duplicate, false);

  await assert.rejects(
    () =>
      service.startAttempt({
        uid: UID_B,
        testId: 'idem-test',
        startRequestId: 'stable-key-1',
      }),
    /another user|Cross-user/,
  );

  // Different users cannot reuse the same startRequestId.
  assert.equal(
    startRequestDocId(UID, 'stable-key-1'),
    startRequestDocId(UID_B, 'stable-key-1'),
  );
});

test('P1-3 side-effect recovery reconstructs wrongQuestionIds from snapshot', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  const unit = 'group-iii-paper-i-unit-01';
  await seedQuestion(db, {
    id: 'rec-q1',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: unit,
    correctOption: 'A',
  });
  await seedQuestion(db, {
    id: 'rec-q2',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: unit,
    correctOption: 'B',
  });
  await seedConfiguredTest(db, {
    testId: 'rec-test',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: unit,
    questionIds: ['rec-q1', 'rec-q2'],
  });

  const service = createService(db, {
    generateAttemptId: () => 'attempt-rec-1',
  });
  const started = await service.startAttempt({
    uid: UID,
    testId: 'rec-test',
    startRequestId: 'sr-rec-1',
  });

  // Mutate live questions — recovery must ignore them.
  await db.collection('questions').doc('rec-q1').set(
    { correctOption: 'D', explanation: 'changed' },
    { merge: true },
  );

  const submitted = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'rec-q1', selectedOption: 'B' },
      { questionId: 'rec-q2', selectedOption: 'B' },
    ],
  });
  assert.equal(submitted.wrong, 1);
  assert.equal(submitted.correct, 1);

  // Simulate partial failure: wipe wrongQuestionIds + side-effect markers.
  const attemptRef = db.collection('test_attempts').doc(started.attemptId);
  const attempt = (await attemptRef.get()).data();
  await attemptRef.set(
    {
      ...attempt,
      wrongQuestionIds: null,
      progressEventApplied: false,
      revisionEventApplied: false,
    },
    { merge: false },
  );
  await db.collection('test_attempt_events').doc(started.attemptId).delete();
  await db
    .collection('user_progress')
    .doc(UID)
    .collection('courses')
    .doc('group-iii')
    .delete();
  await db.collection('user_revision').doc(UID).delete();

  const reconstructed = reconstructWrongQuestionIds({
    answers: attempt.answers,
    questionSnapshots: attempt.questionSnapshots,
  });
  assert.deepEqual(reconstructed, ['rec-q1']);

  const healed = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'rec-q1', selectedOption: 'B' },
      { questionId: 'rec-q2', selectedOption: 'B' },
    ],
  });
  assert.equal(healed.duplicate, true);

  const revision = await db.collection('user_revision').doc(UID).get();
  assert.deepEqual(revision.data().wrongQuestions, ['rec-q1']);

  const progress = await db
    .collection('user_progress')
    .doc(UID)
    .collection('courses')
    .doc('group-iii')
    .get();
  assert.equal(progress.data().overall.questionsCorrect, 1);

  // Second heal must not double-count.
  await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'rec-q1', selectedOption: 'B' },
      { questionId: 'rec-q2', selectedOption: 'B' },
    ],
  });
  const progress2 = await db
    .collection('user_progress')
    .doc(UID)
    .collection('courses')
    .doc('group-iii')
    .get();
  assert.equal(progress2.data().overall.questionsCorrect, 1);
  assert.equal(progress2.data().overall.questionsAttempted, 2);

  // Grading snapshot remains the authority even after live mutation.
  const grading = await db
    .collection(GRADING_SNAPSHOT_COLLECTION)
    .doc(started.attemptId)
    .get();
  assert.equal(grading.data().questions[0].correctOption, 'A');
});
