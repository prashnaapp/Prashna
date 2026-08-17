import assert from 'node:assert/strict';
import test from 'node:test';

import { createEntitlementService } from '../src/entitlement_service.js';
import {
  AUTHORITY_LEGACY_CLIENT,
  AUTHORITY_SERVER_VERIFIED,
  createTestAttemptService,
  resolveAuthority,
} from '../src/test_attempt_service.js';
import { calculateScoreV1, SCORING_VERSION_V1 } from '../src/test_scoring.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-10T12:00:00.000Z');
const UID = 'student-1';
const COURSE = 'group-ii';
const TEST_ID = 'test-group-ii-1';

function seedQuestion(db, id, {
  correctOption = 'A',
  courseId = COURSE,
  isActive = true,
  question = null,
  paperId = null,
  partId = null,
  syllabusUnitId = null,
  topicId = null,
} = {}) {
  return db.collection('questions').doc(id).set({
    id,
    courseId,
    isActive,
    question: question || `Question ${id}`,
    correctOption,
    options: [
      { label: 'A', text: 'one' },
      { label: 'B', text: 'two' },
      { label: 'C', text: 'three' },
      { label: 'D', text: 'four' },
    ],
    explanation: `Explanation for ${id}`,
    questionType: 'practice',
    difficulty: 'medium',
    marks: 1,
    ...(paperId ? { paperId } : {}),
    ...(partId ? { partId } : {}),
    ...(syllabusUnitId ? { syllabusUnitId } : {}),
    ...(topicId ? { topicId } : {}),
  });
}

async function seedPublishedTest(db, {
  testId = TEST_ID,
  questionIds = ['q1', 'q2', 'q3', 'q4'],
  totalMarks = 4,
  negativeMarks = 0.25,
  durationMinutes = 10,
  status = 'published',
  isPublished = true,
  questionCount = null,
} = {}) {
  for (const [index, id] of questionIds.entries()) {
    await seedQuestion(db, id, {
      correctOption: ['A', 'B', 'C', 'D'][index % 4],
    });
  }
  await db.collection('tests').doc(testId).set({
    id: testId,
    courseId: COURSE,
    title: 'Group II Sample',
    category: 'mockTests',
    questionCount: questionCount ?? questionIds.length,
    totalMarks,
    durationMinutes,
    negativeMarks,
    questionIds,
    status,
    isPublished,
  });
}

async function seedAccess(db, { free = false } = {}) {
  await db.collection('courses').doc(COURSE).set({
    id: COURSE,
    name: 'Group II',
    isFree: free,
    isPublished: true,
  });
  if (!free) {
    await createEntitlementService(db).grant({
      uid: UID,
      courseId: COURSE,
      source: 'purchase',
      expiresAt: new Date(NOW.getTime() + 365 * 24 * 60 * 60 * 1000),
    });
  }
}

function createService(db, overrides = {}) {
  return createTestAttemptService({
    db,
    now: () => NOW,
    generateAttemptId: () => 'attempt-fixed-1',
    ...overrides,
  });
}

test('scoring v1 mirrors client calculateScore semantics', () => {
  const result = calculateScoreV1({
    totalQuestions: 4,
    totalMarks: 4,
    negativeMarks: 0.25,
    answers: [
      { questionId: 'q1', selectedOption: 'A' },
      { questionId: 'q2', selectedOption: 'A' },
      { questionId: 'q3', selectedOption: null },
    ],
    correctByQuestionId: {
      q1: 'A',
      q2: 'B',
      q3: 'C',
      q4: 'D',
    },
  });
  assert.equal(result.correct, 1);
  assert.equal(result.wrong, 1);
  assert.equal(result.attempted, 2);
  assert.equal(result.skipped, 2);
  assert.equal(result.score, 0.75);
  assert.equal(result.scoringVersion, SCORING_VERSION_V1);
  assert.equal(result.passed, false);
});

test('1/2: auth required and uid from auth path', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createService(db);
  await assert.rejects(
    () => service.startAttempt({ uid: '', testId: TEST_ID , startRequestId: 'req-test_attempt_auth.test'}),
    /Authentication required/,
  );
});

test('3/4/5/6/7/8: published + access + server creates attempt without client course/questions', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createService(db);
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_auth.test-1' });
  assert.equal(started.attemptId, 'attempt-fixed-1');
  assert.equal(started.courseId, COURSE);
  assert.deepEqual(started.questionIds, ['q1', 'q2', 'q3', 'q4']);
  assert.equal(started.status, 'in_progress');
  assert.equal(started.authority, AUTHORITY_SERVER_VERIFIED);

  const snap = await db.collection('test_attempts').doc(started.attemptId).get();
  assert.equal(snap.data().uid, UID);
  assert.equal(snap.data().score, undefined);
});

test('draft test rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db, { status: 'draft', isPublished: false });
  await assert.rejects(
    () => createService(db).startAttempt({ uid: UID, testId: TEST_ID , startRequestId: 'req-test_attempt_auth.test'}),
    /Draft/,
  );
});

test('archived test rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db, { status: 'archived', isPublished: false });
  await assert.rejects(
    () => createService(db).startAttempt({ uid: UID, testId: TEST_ID , startRequestId: 'req-test_attempt_auth.test'}),
    /Archived/,
  );
});

test('course access required', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await db.collection('courses').doc(COURSE).set({
    id: COURSE,
    isFree: false,
    isPublished: true,
  });
  await seedPublishedTest(db);
  await assert.rejects(
    () => createService(db).startAttempt({ uid: UID, testId: TEST_ID , startRequestId: 'req-test_attempt_auth.test'}),
    /Course access denied/,
  );
});

test('9/10/11/12/13/14/15/16/17/18/19: authoritative scoring path', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createService(db);
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_auth.test-2' });

  await assert.rejects(
    () => service.submitAttempt({
      uid: UID,
      attemptId: started.attemptId,
      selectedAnswers: [
        { questionId: 'q1', selectedOption: 'A', correctOption: 'A' },
      ],
    }),
    /must not submit correctOption/,
  );

  await assert.rejects(
    () => service.submitAttempt({
      uid: UID,
      attemptId: started.attemptId,
      selectedAnswers: [{ questionId: 'unknown', selectedOption: 'A' }],
    }),
    /outside attempt/,
  );

  await assert.rejects(
    () => service.submitAttempt({
      uid: UID,
      attemptId: started.attemptId,
      selectedAnswers: [{ questionId: 'q1', selectedOption: 'Z' }],
    }),
    /Invalid option/,
  );

  const submitted = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'q1', selectedOption: 'A' }, // correct
      { questionId: 'q2', selectedOption: 'A' }, // wrong (B)
      // q3/q4 skipped
    ],
  });

  assert.equal(submitted.correct, 1);
  assert.equal(submitted.wrong, 1);
  assert.equal(submitted.skipped, 2);
  assert.equal(submitted.attempted, 2);
  assert.equal(submitted.score, 0.75);
  assert.equal(submitted.authority, AUTHORITY_SERVER_VERIFIED);
  assert.equal(submitted.scoringVersion, SCORING_VERSION_V1);
  assert.equal(submitted.passed, false);

  const snap = await db.collection('test_attempts').doc(started.attemptId).get();
  assert.equal(snap.data().status, 'submitted');
  assert.equal(snap.data().authority, AUTHORITY_SERVER_VERIFIED);
  assert.ok(snap.data().submittedAt);
});

test('20/21: clearly late submission is rejected', async () => {
  let current = NOW;
  const db = new FakeFirestore({ now: () => current });
  await seedAccess(db);
  await seedPublishedTest(db, { durationMinutes: 1 });
  const service = createService(db, { now: () => current });
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_auth.test-3' });
  current = new Date(NOW.getTime() + 10 * 60 * 1000);
  await assert.rejects(
    () => service.submitAttempt({
      uid: UID,
      attemptId: started.attemptId,
      selectedAnswers: [{ questionId: 'q1', selectedOption: 'A' }],
    }),
    /expired/,
  );
  const snap = await db.collection('test_attempts').doc(started.attemptId).get();
  assert.equal(snap.data().status, 'in_progress');
});

test('24: cross-user submission rejected', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createService(db);
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_auth.test-4' });
  await assert.rejects(
    () => service.submitAttempt({
      uid: 'other-user',
      attemptId: started.attemptId,
      selectedAnswers: [{ questionId: 'q1', selectedOption: 'A' }],
    }),
    /Cross-user/,
  );
});

test('25/26/27/28/29: duplicate submission is idempotent and side effects once', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createService(db);
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_auth.test-5' });
  const first = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q1', selectedOption: 'A' }],
  });
  const second = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'q1', selectedOption: 'A' },
      { questionId: 'q2', selectedOption: 'B' },
      { questionId: 'q3', selectedOption: 'C' },
      { questionId: 'q4', selectedOption: 'D' },
    ],
  });
  assert.equal(first.duplicate, false);
  assert.equal(second.duplicate, true);
  assert.equal(second.score, first.score);
  assert.equal(second.correct, first.correct);

  const event = await db.collection('test_attempt_events').doc(started.attemptId).get();
  assert.equal(event.data().progressApplied, true);
  assert.equal(event.data().revisionApplied, true);

  // Still only one attempt document.
  assert.equal(db._store.has(`test_attempts/${started.attemptId}`), true);
  const attemptDocs = [...db._store.keys()].filter((k) =>
    k.startsWith('test_attempts/'),
  );
  assert.equal(attemptDocs.length, 1);
});

test('30/31/32: legacy vs verified authority', () => {
  assert.equal(resolveAuthority({}), AUTHORITY_LEGACY_CLIENT);
  assert.equal(
    resolveAuthority({ authority: AUTHORITY_SERVER_VERIFIED }),
    AUTHORITY_SERVER_VERIFIED,
  );
});

test('dynamic question set resolved on server', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedQuestion(db, 'd1', { correctOption: 'A' });
  await seedQuestion(db, 'd2', { correctOption: 'B' });
  await seedQuestion(db, 'd3', { correctOption: 'C' });
  await db.collection('tests').doc('dynamic-1').set({
    id: 'dynamic-1',
    courseId: COURSE,
    title: 'Dynamic',
    category: 'mockTests',
    questionCount: 2,
    totalMarks: 2,
    durationMinutes: 5,
    negativeMarks: 0,
    questionIds: [],
    status: 'published',
    isPublished: true,
  });

  let call = 0;
  const service = createService(db, {
    generateAttemptId: () => 'attempt-dynamic-1',
    listActiveQuestionIds: async () => {
      call += 1;
      return ['d1', 'd2', 'd3'];
    },
    random: () => 0,
  });
  const started = await service.startAttempt({ uid: UID, testId: 'dynamic-1', startRequestId: 'req-test_attempt_auth.test-6' });
  assert.equal(call, 1);
  assert.equal(started.questionIds.length, 2);
  assert.ok(!started.questionIds.includes('client-injected'));
});

test('client cannot choose uid/course/question set via start payload semantics', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createService(db, {
    generateAttemptId: () => 'attempt-owned',
  });
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-test_attempt_auth.test-7' });
  const snap = await db.collection('test_attempts').doc(started.attemptId).get();
  assert.equal(snap.data().uid, UID);
  assert.equal(snap.data().courseId, COURSE);
  assert.deepEqual(snap.data().questionIds, ['q1', 'q2', 'q3', 'q4']);
});
