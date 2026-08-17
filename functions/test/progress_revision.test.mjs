import assert from 'node:assert/strict';
import test from 'node:test';

import {
  createProgressRevisionService,
  deriveWrongQuestionIds,
} from '../src/progress_revision_service.js';
import {
  AUTHORITY_SERVER_VERIFIED,
  createTestAttemptService,
} from '../src/test_attempt_service.js';
import { createEntitlementService } from '../src/entitlement_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-10T12:00:00.000Z');
const UID = 'student-1';
const COURSE = 'group-ii';
const TEST_ID = 'test-group-ii-1';

function seedQuestion(db, id, { correctOption = 'A' } = {}) {
  return db.collection('questions').doc(id).set({
    id,
    courseId: COURSE,
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
  await seedQuestion(db, 'q3', { correctOption: 'C' });
  await seedQuestion(db, 'q4', { correctOption: 'D' });
  await db.collection('tests').doc(TEST_ID).set({
    id: TEST_ID,
    courseId: COURSE,
    title: 'Group II Sample',
    category: 'mockTests',
    questionCount: 4,
    totalMarks: 4,
    durationMinutes: 10,
    negativeMarks: 0.25,
    questionIds: ['q1', 'q2', 'q3', 'q4'],
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

function createAttemptService(db, overrides = {}) {
  return createTestAttemptService({
    db,
    now: () => NOW,
    generateAttemptId: () => 'attempt-fixed-1',
    ...overrides,
  });
}

test('deriveWrongQuestionIds uses canonical correct options only', () => {
  const wrong = deriveWrongQuestionIds(
    [
      { questionId: 'q1', selectedOption: 'A' },
      { questionId: 'q2', selectedOption: 'A' },
      { questionId: 'q3', selectedOption: 'C' },
    ],
    { q1: 'A', q2: 'B', q3: 'C' },
  );
  assert.deepEqual(wrong, ['q2']);
});

test('1/2/5/6: submit once applies progress and revision once', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createAttemptService(db);
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-progress_revision.test-1' });

  await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'q1', selectedOption: 'A' },
      { questionId: 'q2', selectedOption: 'A' },
    ],
  });

  const progress = await db
    .collection('user_progress')
    .doc(UID)
    .collection('courses')
    .doc(COURSE)
    .get();
  assert.equal(progress.exists, true);
  assert.equal(progress.data().overall.questionsCorrect, 1);
  // correct(1)+wrong(1)+skipped(2) = 4
  assert.equal(progress.data().overall.questionsAttempted, 4);
  assert.equal(progress.data().authority, AUTHORITY_SERVER_VERIFIED);

  const revision = await db.collection('user_revision').doc(UID).get();
  assert.equal(revision.exists, true);
  assert.deepEqual(revision.data().wrongQuestions, ['q2']);
  assert.equal(revision.data().mistakeCounts.q2, 1);
  assert.deepEqual(revision.data().frequentlyWrongQuestions, []);

  const event = await db.collection('test_attempt_events').doc(started.attemptId).get();
  assert.equal(event.data().progressApplied, true);
  assert.equal(event.data().revisionApplied, true);
});

test('2/3/4/7: duplicate / retry submit does not inflate analytics', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createAttemptService(db);
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-progress_revision.test-2' });

  await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'q1', selectedOption: 'A' },
      { questionId: 'q2', selectedOption: 'A' },
    ],
  });
  await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'q1', selectedOption: 'A' },
      { questionId: 'q2', selectedOption: 'A' },
      { questionId: 'q3', selectedOption: 'A' },
      { questionId: 'q4', selectedOption: 'A' },
    ],
  });

  const progress = await db
    .collection('user_progress')
    .doc(UID)
    .collection('courses')
    .doc(COURSE)
    .get();
  assert.equal(progress.data().overall.questionsCorrect, 1);
  assert.equal(progress.data().overall.questionsAttempted, 4);

  const revision = await db.collection('user_revision').doc(UID).get();
  assert.deepEqual(revision.data().wrongQuestions, ['q2']);
  assert.equal(revision.data().mistakeCounts.q2, 1);
});

test('frequent wrong after two verified mistakes', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);

  const service1 = createAttemptService(db, {
    generateAttemptId: () => 'attempt-a',
  });
  const started1 = await service1.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-progress_revision.test-3' });
  await service1.submitAttempt({
    uid: UID,
    attemptId: started1.attemptId,
    selectedAnswers: [{ questionId: 'q2', selectedOption: 'A' }],
  });

  const service2 = createAttemptService(db, {
    generateAttemptId: () => 'attempt-b',
  });
  const started2 = await service2.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-progress_revision.test-4' });
  await service2.submitAttempt({
    uid: UID,
    attemptId: started2.attemptId,
    selectedAnswers: [{ questionId: 'q2', selectedOption: 'A' }],
  });

  const revision = await db.collection('user_revision').doc(UID).get();
  assert.equal(revision.data().mistakeCounts.q2, 2);
  assert.ok(revision.data().frequentlyWrongQuestions.includes('q2'));

  const progress = await db
    .collection('user_progress')
    .doc(UID)
    .collection('courses')
    .doc(COURSE)
    .get();
  // two attempts × 4 questions each in delta
  assert.equal(progress.data().overall.questionsAttempted, 8);
  assert.equal(progress.data().overall.questionsCorrect, 0);
});

test('8: fake / legacy attempt event rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createProgressRevisionService({ db, now: () => NOW });
  await db.collection('test_attempts').doc('legacy-1').set({
    attemptId: 'legacy-1',
    uid: UID,
    courseId: COURSE,
    testId: TEST_ID,
    status: 'submitted',
    correct: 99,
    wrong: 0,
    skipped: 0,
    // authority missing => legacy_client
  });

  await assert.rejects(
    () => service.applyVerifiedTestAttemptSideEffects({ attemptId: 'legacy-1' }),
    /server_verified/,
  );

  await assert.rejects(
    () => service.applyVerifiedTestAttemptSideEffects({ attemptId: 'missing' }),
    /not found/i,
  );
});

test('auth-ish: apply requires submitted server_verified attempt', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createProgressRevisionService({ db, now: () => NOW });
  await db.collection('test_attempts').doc('inprog').set({
    attemptId: 'inprog',
    uid: UID,
    courseId: COURSE,
    testId: TEST_ID,
    status: 'in_progress',
    authority: AUTHORITY_SERVER_VERIFIED,
    correct: 1,
    wrong: 0,
    skipped: 0,
  });
  await assert.rejects(
    () => service.applyVerifiedTestAttemptSideEffects({ attemptId: 'inprog' }),
    /submitted/,
  );
});

test('direct apply is idempotent on attemptId', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const service = createProgressRevisionService({ db, now: () => NOW });
  const attempt = {
    attemptId: 'attempt-direct',
    uid: UID,
    courseId: COURSE,
    testId: TEST_ID,
    status: 'submitted',
    authority: AUTHORITY_SERVER_VERIFIED,
    score: 1,
    correct: 1,
    wrong: 1,
    skipped: 2,
    attempted: 2,
  };
  await db.collection('test_attempts').doc('attempt-direct').set(attempt);

  const first = await service.applyVerifiedTestAttemptSideEffects({
    attemptId: 'attempt-direct',
    attempt,
    wrongQuestionIds: ['q2'],
  });
  const second = await service.applyVerifiedTestAttemptSideEffects({
    attemptId: 'attempt-direct',
    attempt,
    wrongQuestionIds: ['q2', 'q3'],
  });

  assert.equal(first.duplicate, false);
  assert.equal(second.duplicate, true);

  const progress = await db
    .collection('user_progress')
    .doc(UID)
    .collection('courses')
    .doc(COURSE)
    .get();
  assert.equal(progress.data().overall.questionsCorrect, 1);
  assert.equal(progress.data().overall.questionsAttempted, 4);

  const revision = await db.collection('user_revision').doc(UID).get();
  assert.deepEqual(revision.data().wrongQuestions, ['q2']);
});
