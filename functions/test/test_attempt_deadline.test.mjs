import assert from 'node:assert/strict';
import test from 'node:test';

import { createEntitlementService } from '../src/entitlement_service.js';
import {
  SUBMISSION_GRACE_SECONDS,
  createTestAttemptService,
  resolveAttemptDeadlineMs,
} from '../src/test_attempt_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-10T12:00:00.000Z');
const UID = 'student-1';
const COURSE = 'group-ii';
const TEST_ID = 'test-group-ii-deadline';

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

async function seedPublishedTest(db, { durationMinutes = 1 } = {}) {
  for (const [index, id] of ['q1', 'q2'].entries()) {
    await seedQuestion(db, id, {
      correctOption: ['A', 'B'][index],
    });
  }
  await db.collection('tests').doc(TEST_ID).set({
    id: TEST_ID,
    courseId: COURSE,
    title: 'Deadline sample',
    category: 'chapter',
    questionCount: 2,
    totalMarks: 2,
    durationMinutes,
    negativeMarks: 0,
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

test('deadline helper is inclusive of duration + grace', () => {
  const startedAt = NOW;
  const durationSeconds = 60;
  const deadline = resolveAttemptDeadlineMs({
    startedAt,
    durationSeconds,
    graceSeconds: SUBMISSION_GRACE_SECONDS,
  });
  assert.equal(
    deadline,
    NOW.getTime() + (durationSeconds + SUBMISSION_GRACE_SECONDS) * 1000,
  );
});

test('E: submission before deadline is accepted', async () => {
  let current = NOW;
  const db = new FakeFirestore({ now: () => current });
  await seedAccess(db);
  await seedPublishedTest(db, { durationMinutes: 10 });
  const service = createTestAttemptService({
    db,
    now: () => current,
    generateAttemptId: () => 'attempt-timely',
  });
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_deadline.test-1' });
  current = new Date(NOW.getTime() + 30 * 1000);
  const submitted = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q1', selectedOption: 'A' }],
  });
  assert.equal(submitted.status, 'submitted');
  assert.equal(submitted.duplicate, false);
});

test('boundary: submission at duration + grace is accepted', async () => {
  let current = NOW;
  const db = new FakeFirestore({ now: () => current });
  await seedAccess(db);
  await seedPublishedTest(db, { durationMinutes: 1 });
  const service = createTestAttemptService({
    db,
    now: () => current,
    generateAttemptId: () => 'attempt-boundary',
  });
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_deadline.test-2' });
  current = new Date(
    NOW.getTime() + (60 + SUBMISSION_GRACE_SECONDS) * 1000,
  );
  const submitted = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q1', selectedOption: 'A' }],
  });
  assert.equal(submitted.status, 'submitted');
});

test('D: submission clearly after deadline is rejected', async () => {
  let current = NOW;
  const db = new FakeFirestore({ now: () => current });
  await seedAccess(db);
  await seedPublishedTest(db, { durationMinutes: 1 });
  const service = createTestAttemptService({
    db,
    now: () => current,
    generateAttemptId: () => 'attempt-late',
  });
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_deadline.test-3' });
  current = new Date(
    NOW.getTime() + (60 + SUBMISSION_GRACE_SECONDS) * 1000 + 1,
  );
  await assert.rejects(
    () => service.submitAttempt({
      uid: UID,
      attemptId: started.attemptId,
      selectedAnswers: [{ questionId: 'q1', selectedOption: 'A' }],
    }),
    /expired/,
  );
});

test('F: duplicate already-finalized attempt remains idempotent after deadline', async () => {
  let current = NOW;
  const db = new FakeFirestore({ now: () => current });
  await seedAccess(db);
  await seedPublishedTest(db, { durationMinutes: 1 });
  const service = createTestAttemptService({
    db,
    now: () => current,
    generateAttemptId: () => 'attempt-dup',
  });
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_deadline.test-4' });
  const first = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q1', selectedOption: 'A' }],
  });
  current = new Date(NOW.getTime() + 30 * 60 * 1000);
  const second = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'q1', selectedOption: 'B' },
      { questionId: 'q2', selectedOption: 'B' },
    ],
  });
  assert.equal(first.duplicate, false);
  assert.equal(second.duplicate, true);
  assert.equal(second.score, first.score);
  assert.equal(second.correct, first.correct);
});

test('client cannot extend the deadline via submit payload or local timer', async () => {
  let current = NOW;
  const db = new FakeFirestore({ now: () => current });
  await seedAccess(db);
  await seedPublishedTest(db, { durationMinutes: 1 });
  const service = createTestAttemptService({
    db,
    now: () => current,
    generateAttemptId: () => 'attempt-no-extend',
  });
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_deadline.test-5' });
  assert.equal(started.durationSeconds, 60);
  current = new Date(NOW.getTime() + 10 * 60 * 1000);
  await assert.rejects(
    () => service.submitAttempt({
      uid: UID,
      attemptId: started.attemptId,
      selectedAnswers: [{ questionId: 'q1', selectedOption: 'A' }],
    }),
    /expired/,
  );
});
