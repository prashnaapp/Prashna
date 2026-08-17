import assert from 'node:assert/strict';
import test from 'node:test';

import { createEntitlementService } from '../src/entitlement_service.js';
import {
  AUTHORITY_SERVER_VERIFIED,
  createTestAttemptService,
} from '../src/test_attempt_service.js';
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
    generateAttemptId: () => 'attempt-concurrent-1',
    ...overrides,
  });
}

const ANSWERS_PARTIAL = [
  { questionId: 'q1', selectedOption: 'A' }, // correct
  { questionId: 'q2', selectedOption: 'A' }, // wrong
];

const ANSWERS_ALL_CORRECT = [
  { questionId: 'q1', selectedOption: 'A' },
  { questionId: 'q2', selectedOption: 'B' },
  { questionId: 'q3', selectedOption: 'C' },
  { questionId: 'q4', selectedOption: 'D' },
];

test('concurrent identical submits: one result, one progress, one revision', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createAttemptService(db);
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-concurrent_submit.test-1' });

  const results = await Promise.all([
    service.submitAttempt({
      uid: UID,
      attemptId: started.attemptId,
      selectedAnswers: ANSWERS_PARTIAL,
    }),
    service.submitAttempt({
      uid: UID,
      attemptId: started.attemptId,
      selectedAnswers: ANSWERS_PARTIAL,
    }),
    service.submitAttempt({
      uid: UID,
      attemptId: started.attemptId,
      selectedAnswers: ANSWERS_PARTIAL,
    }),
  ]);

  assert.equal(results.length, 3);
  const scores = new Set(results.map((r) => r.score));
  const corrects = new Set(results.map((r) => r.correct));
  assert.equal(scores.size, 1, 'all concurrent responses share one score');
  assert.equal(corrects.size, 1);
  assert.equal(results[0].score, 0.75);
  assert.equal(results[0].correct, 1);
  assert.equal(results[0].wrong, 1);
  assert.equal(results[0].skipped, 2);

  const winners = results.filter((r) => r.duplicate === false);
  const duplicates = results.filter((r) => r.duplicate === true);
  assert.equal(winners.length, 1, 'exactly one first successful transition');
  assert.equal(duplicates.length, 2, 'other concurrent calls are duplicates');

  const attemptSnap = await db
    .collection('test_attempts')
    .doc(started.attemptId)
    .get();
  assert.equal(attemptSnap.data().status, 'submitted');
  assert.equal(attemptSnap.data().score, 0.75);
  assert.equal(attemptSnap.data().authority, AUTHORITY_SERVER_VERIFIED);

  const attemptDocs = [...db._store.keys()].filter((k) =>
    k.startsWith('test_attempts/'),
  );
  assert.equal(attemptDocs.length, 1);

  const eventSnap = await db
    .collection('test_attempt_events')
    .doc(started.attemptId)
    .get();
  assert.equal(eventSnap.exists, true);
  assert.equal(eventSnap.data().progressApplied, true);
  assert.equal(eventSnap.data().revisionApplied, true);
  const eventDocs = [...db._store.keys()].filter((k) =>
    k.startsWith('test_attempt_events/'),
  );
  assert.equal(eventDocs.length, 1);

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

test('concurrent different payloads: first successful transition wins permanently', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedPublishedTest(db);
  const service = createAttemptService(db, {
    generateAttemptId: () => 'attempt-race-payload',
  });
  const started = await service.startAttempt({ uid: UID, testId: TEST_ID, startRequestId: 'req-concurrent_submit.test-2' });

  // Launch many races so either payload may win the first transition, but the
  // loser must never overwrite the winner.
  const launches = [];
  for (let i = 0; i < 6; i += 1) {
    const answers = i % 2 === 0 ? ANSWERS_PARTIAL : ANSWERS_ALL_CORRECT;
    launches.push(
      service.submitAttempt({
        uid: UID,
        attemptId: started.attemptId,
        selectedAnswers: answers,
      }),
    );
  }
  const results = await Promise.all(launches);

  const winners = results.filter((r) => r.duplicate === false);
  assert.equal(winners.length, 1, 'exactly one authoritative transition');

  const authoritative = winners[0];
  for (const result of results) {
    assert.equal(result.score, authoritative.score);
    assert.equal(result.correct, authoritative.correct);
    assert.equal(result.wrong, authoritative.wrong);
    assert.equal(result.skipped, authoritative.skipped);
    assert.equal(result.percentage, authoritative.percentage);
  }

  const attemptSnap = await db
    .collection('test_attempts')
    .doc(started.attemptId)
    .get();
  assert.equal(attemptSnap.data().status, 'submitted');
  assert.equal(attemptSnap.data().score, authoritative.score);
  assert.equal(attemptSnap.data().correct, authoritative.correct);

  // Authoritative payload is either partial (0.75 / 1 correct) or all-correct
  // (4 / 4 correct) — never a hybrid overwrite.
  const valid =
    (authoritative.correct === 1 && authoritative.score === 0.75) ||
    (authoritative.correct === 4 && authoritative.score === 4);
  assert.equal(valid, true);

  const progress = await db
    .collection('user_progress')
    .doc(UID)
    .collection('courses')
    .doc(COURSE)
    .get();
  assert.equal(
    progress.data().overall.questionsCorrect,
    authoritative.correct,
  );
  assert.equal(progress.data().overall.questionsAttempted, 4);

  const revision = await db.collection('user_revision').doc(UID).get();
  if (authoritative.correct === 1) {
    assert.deepEqual(revision.data().wrongQuestions, ['q2']);
    assert.equal(revision.data().mistakeCounts.q2, 1);
  } else {
    assert.deepEqual(revision.data().wrongQuestions, []);
  }

  const eventDocs = [...db._store.keys()].filter((k) =>
    k.startsWith('test_attempt_events/'),
  );
  assert.equal(eventDocs.length, 1);
});
