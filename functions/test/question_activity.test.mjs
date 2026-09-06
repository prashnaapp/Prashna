import assert from 'node:assert/strict';
import test from 'node:test';

import {
  createProgressRevisionService,
  deriveWrongQuestionIds,
  mergeTrustedWrongQuestionsIntoRevision,
  FREQUENT_WRONG_MIN,
  AUTHORITY_SERVER_VERIFIED,
} from '../src/progress_revision_service.js';
import { createQuestionActivityService } from '../src/question_activity_service.js';
import {
  createTestAttemptService,
} from '../src/test_attempt_service.js';
import { createEntitlementService } from '../src/entitlement_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-09-06T12:00:00.000Z');
const UID = 'student-qa-1';
const COURSE = 'group-ii';
const TEST_ID = 'test-group-ii-qa';

function seedQuestion(db, id, { correctOption = 'A', courseId = COURSE } = {}) {
  return db.collection('questions').doc(id).set({
    id,
    courseId,
    isActive: true,
    question: `Question ${id}`,
    explanation: `Explanation for ${id}`,
    correctOption,
    options: [
      { label: 'A', text: 'one' },
      { label: 'B', text: 'two' },
      { label: 'C', text: 'three' },
      { label: 'D', text: 'four' },
    ],
  });
}

async function seedPublishedTest(db) {
  await seedQuestion(db, 'q1', { correctOption: 'A' });
  await seedQuestion(db, 'q2', { correctOption: 'B' });
  await db.collection('tests').doc(TEST_ID).set({
    id: TEST_ID,
    courseId: COURSE,
    title: 'Group II Sample',
    category: 'mockTests',
    questionCount: 2,
    totalMarks: 2,
    durationMinutes: 10,
    negativeMarks: 0.25,
    questionIds: ['q1', 'q2'],
    status: 'published',
    isPublished: true,
  });
}

async function seedAccess(db) {
  await db.collection('courses').doc(COURSE).set({
    id: COURSE,
    name: 'Group II',
    isFree: false,
    isPublished: true,
  });
  await createEntitlementService(db).grant({
    uid: UID,
    courseId: COURSE,
    source: 'purchase',
    expiresAt: new Date(NOW.getTime() + 365 * 24 * 60 * 60 * 1000),
  });
}

test('mergeTrustedWrongQuestionsIntoRevision increments counts and frequent threshold', () => {
  assert.equal(FREQUENT_WRONG_MIN, 2);
  const first = mergeTrustedWrongQuestionsIntoRevision({
    priorRevision: {},
    trustedWrongIds: ['q1'],
    courseId: COURSE,
    uid: UID,
  });
  assert.deepEqual(first.wrongQuestions, ['q1']);
  assert.equal(first.mistakeCounts.q1, 1);
  assert.deepEqual(first.frequentlyWrongQuestions, []);
  assert.equal(first.authority, AUTHORITY_SERVER_VERIFIED);

  const second = mergeTrustedWrongQuestionsIntoRevision({
    priorRevision: first,
    trustedWrongIds: ['q1'],
    courseId: COURSE,
    uid: UID,
  });
  assert.deepEqual(second.wrongQuestions, ['q1']);
  assert.equal(second.mistakeCounts.q1, 2);
  assert.deepEqual(second.frequentlyWrongQuestions, ['q1']);
});

test('question activity: correct answer does not enter wrongQuestions', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedQuestion(db, 'q1', { correctOption: 'A' });
  const service = createQuestionActivityService({ db, now: () => NOW });
  const result = await service.reportQuestionActivity({
    uid: UID,
    activityEventId: 'qa_sess1_q1',
    questionId: 'q1',
    selectedOption: 'A',
    sourceModule: 'practice',
    sourceType: 'topicPractice',
  });
  assert.equal(result.isWrong, false);
  assert.equal(result.revisionApplied, false);
  const revision = await db.collection('user_revision').doc(UID).get();
  assert.equal(revision.exists, false);
});

test('question activity: wrong answer reaches user_revision once', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedQuestion(db, 'q1', { correctOption: 'A' });
  const service = createQuestionActivityService({ db, now: () => NOW });
  const first = await service.reportQuestionActivity({
    uid: UID,
    activityEventId: 'qa_sess1_q1',
    questionId: 'q1',
    selectedOption: 'B',
    sourceModule: 'practice',
    sourceType: 'topicPractice',
    encounterId: 'sess1',
    context: { testId: 'practice-topic-1' },
  });
  assert.equal(first.isWrong, true);
  assert.equal(first.revisionApplied, true);
  assert.equal(first.duplicate, false);

  const revision = await db.collection('user_revision').doc(UID).get();
  assert.equal(revision.exists, true);
  assert.deepEqual(revision.data().wrongQuestions, ['q1']);
  assert.equal(revision.data().mistakeCounts.q1, 1);
  assert.deepEqual(revision.data().frequentlyWrongQuestions, []);

  const retry = await service.reportQuestionActivity({
    uid: UID,
    activityEventId: 'qa_sess1_q1',
    questionId: 'q1',
    selectedOption: 'B',
    sourceModule: 'practice',
  });
  assert.equal(retry.duplicate, true);
  const afterRetry = await db.collection('user_revision').doc(UID).get();
  assert.equal(afterRetry.data().mistakeCounts.q1, 1);

  const secondEncounter = await service.reportQuestionActivity({
    uid: UID,
    activityEventId: 'qa_sess2_q1',
    questionId: 'q1',
    selectedOption: 'C',
    sourceModule: 'practice',
  });
  assert.equal(secondEncounter.duplicate, false);
  const afterSecond = await db.collection('user_revision').doc(UID).get();
  assert.deepEqual(afterSecond.data().wrongQuestions, ['q1']);
  assert.equal(afterSecond.data().mistakeCounts.q1, 2);
  assert.deepEqual(afterSecond.data().frequentlyWrongQuestions, ['q1']);
});

test('question activity: missing question does not create revision', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createQuestionActivityService({ db, now: () => NOW });
  await assert.rejects(
    () =>
      service.reportQuestionActivity({
        uid: UID,
        activityEventId: 'qa_missing_q9',
        questionId: 'missing-q',
        selectedOption: 'A',
        sourceModule: 'practice',
      }),
    (error) => error.code === 'not-found',
  );
  const revision = await db.collection('user_revision').doc(UID).get();
  assert.equal(revision.exists, false);
});

test('question activity rejects client authority fields at service boundary via selected-only trust', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedQuestion(db, 'q1', { correctOption: 'A' });
  const service = createQuestionActivityService({ db, now: () => NOW });
  // Even if a caller claimed wrongness incorrectly, selectedOption A is correct.
  const result = await service.reportQuestionActivity({
    uid: UID,
    activityEventId: 'qa_trust_q1',
    questionId: 'q1',
    selectedOption: 'A',
    sourceModule: 'practice',
  });
  assert.equal(result.isWrong, false);
});

test('catalog submit still applies revision via shared merge (regression)', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const attempts = createTestAttemptService({
    db,
    now: () => NOW,
    generateAttemptId: () => 'attempt-qa-catalog-1',
  });
  const started = await attempts.startAttempt({
    uid: UID,
    testId: TEST_ID,
    startRequestId: 'req-qa-catalog-1',
  });
  await attempts.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'q1', selectedOption: 'A' },
      { questionId: 'q2', selectedOption: 'A' },
    ],
  });
  const revision = await db.collection('user_revision').doc(UID).get();
  assert.equal(revision.exists, true);
  assert.deepEqual(revision.data().wrongQuestions, ['q2']);
  assert.equal(revision.data().mistakeCounts.q2, 1);

  // Re-apply side effects must not double-count (attempt event idempotency).
  const progressRevision = createProgressRevisionService({ db, now: () => NOW });
  await progressRevision.applyVerifiedTestAttemptSideEffects({
    attemptId: started.attemptId,
  });
  const after = await db.collection('user_revision').doc(UID).get();
  assert.equal(after.data().mistakeCounts.q2, 1);
});

test('deriveWrongQuestionIds still works', () => {
  assert.deepEqual(
    deriveWrongQuestionIds(
      [
        { questionId: 'q1', selectedOption: 'A' },
        { questionId: 'q2', selectedOption: 'A' },
      ],
      { q1: 'A', q2: 'B' },
    ),
    ['q2'],
  );
});
