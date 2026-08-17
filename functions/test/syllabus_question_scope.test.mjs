import assert from 'node:assert/strict';
import test from 'node:test';

import { createEntitlementService } from '../src/entitlement_service.js';
import { createTestAttemptService } from '../src/test_attempt_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-15T10:00:00.000Z');
const UID = 'student-1';

function createService(db, overrides = {}) {
  return createTestAttemptService({
    db,
    now: () => NOW,
    generateAttemptId: () => 'attempt-scope-1',
    random: () => 0,
    ...overrides,
  });
}

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

async function seedQuestion(db, {
  id,
  courseId,
  paperId,
  partId,
  syllabusUnitId,
  topicId,
  majorStudyAreaId,
}) {
  await db.collection('questions').doc(id).set({
    id,
    courseId,
    paperId,
    partId: partId || null,
    syllabusUnitId: syllabusUnitId || null,
    topicId: topicId || '',
    majorStudyAreaId: majorStudyAreaId || null,
    isActive: true,
    question: `Question ${id}`,
    explanation: `Explanation for ${id}`,
    correctOption: 'A',
    options: [
      { label: 'A', text: 'one' },
      { label: 'B', text: 'two' },
      { label: 'C', text: 'three' },
      { label: 'D', text: 'four' },
    ],
  });
}

async function seedDynamicTest(db, {
  testId,
  courseId,
  questionCount,
  paperId,
  partId,
  syllabusUnitId,
}) {
  await db.collection('tests').doc(testId).set({
    id: testId,
    courseId,
    title: testId,
    category: 'chapterTests',
    questionCount,
    totalMarks: questionCount,
    durationMinutes: 10,
    negativeMarks: 0,
    questionIds: [],
    paperId,
    partId,
    syllabusUnitId,
    status: 'published',
    isPublished: true,
  });
}

test('A/E/F: Group-II exact unit with enough questions succeeds in-scope', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const unit = 'group-ii-paper-ii-part-01-topic-04';
  await seedQuestion(db, {
    id: 'gii-u1-a',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    topicId: unit,
  });
  await seedQuestion(db, {
    id: 'gii-u1-b',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    topicId: unit,
  });
  await seedQuestion(db, {
    id: 'gii-other-unit',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    topicId: 'group-ii-paper-ii-part-01-topic-05',
  });
  await seedDynamicTest(db, {
    testId: 'gii-unit-test',
    courseId: 'group-ii',
    questionCount: 2,
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    syllabusUnitId: unit,
  });

  const started = await createService(db).startAttempt({ uid: UID,
    testId: 'gii-unit-test', startRequestId: 'req-syllabus_question_scope.test-1' });
  assert.deepEqual(started.questionIds.sort(), ['gii-u1-a', 'gii-u1-b']);
  assert.ok(!started.questionIds.includes('gii-other-unit'));
});

test('B/C/D: Group-II undersized unit fails and does not fall back', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  await seedQuestion(db, {
    id: 'gii-u1-a',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    topicId: 'group-ii-paper-ii-part-01-topic-04',
  });
  await seedQuestion(db, {
    id: 'gii-other-unit',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    topicId: 'group-ii-paper-ii-part-01-topic-05',
  });
  await seedQuestion(db, {
    id: 'gii-other-part',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-02',
    topicId: 'group-ii-paper-ii-part-02-topic-01',
  });
  await seedDynamicTest(db, {
    testId: 'gii-thin-unit',
    courseId: 'group-ii',
    questionCount: 2,
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
  });

  await assert.rejects(
    () => createService(db).startAttempt({ uid: UID, testId: 'gii-thin-unit' , startRequestId: 'req-syllabus_question_scope.test'}),
    (error) => {
      assert.equal(error.code, 'failed-precondition');
      assert.match(error.message, /selected syllabus scope/);
      return true;
    },
  );
  const attempts = [...db._store.keys()].filter((k) =>
    k.startsWith('test_attempts/'),
  );
  assert.equal(attempts.length, 0);
});

test('G: Group-III exact unit succeeds; other units are excluded', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  const unit = 'group-iii-paper-ii-part-i-unit-02';
  await seedQuestion(db, {
    id: 'giii-u1-a',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
  });
  await seedQuestion(db, {
    id: 'giii-u1-b',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
  });
  await seedQuestion(db, {
    id: 'giii-other-unit',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: 'group-iii-paper-ii-part-i-unit-01',
  });
  await seedDynamicTest(db, {
    testId: 'giii-unit-test',
    courseId: 'group-iii',
    questionCount: 2,
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
  });

  const started = await createService(db, {
    generateAttemptId: () => 'attempt-giii-1',
  }).startAttempt({ uid: UID, testId: 'giii-unit-test', startRequestId: 'req-syllabus_question_scope.test-2' });
  assert.deepEqual(started.questionIds.sort(), ['giii-u1-a', 'giii-u1-b']);
  assert.ok(!started.questionIds.includes('giii-other-unit'));
});

test('explicit questionIds are unchanged', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  await seedQuestion(db, {
    id: 'fixed-a',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
    majorStudyAreaId: 'group-ii-paper-i-area-01',
  });
  await seedQuestion(db, {
    id: 'fixed-b',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
    majorStudyAreaId: 'group-ii-paper-i-area-01',
  });
  await db.collection('tests').doc('fixed-1').set({
    id: 'fixed-1',
    courseId: 'group-ii',
    title: 'Fixed',
    category: 'chapterTests',
    questionCount: 2,
    totalMarks: 2,
    durationMinutes: 10,
    negativeMarks: 0,
    questionIds: ['fixed-b', 'fixed-a'],
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
    status: 'published',
    isPublished: true,
  });
  const started = await createService(db, {
    generateAttemptId: () => 'attempt-fixed',
  }).startAttempt({ uid: UID, testId: 'fixed-1', startRequestId: 'req-syllabus_question_scope.test-3' });
  assert.deepEqual(started.questionIds, ['fixed-b', 'fixed-a']);
});
