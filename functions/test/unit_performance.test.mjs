import assert from 'node:assert/strict';
import test from 'node:test';

import { createEntitlementService } from '../src/entitlement_service.js';
import {
  createProgressRevisionService,
} from '../src/progress_revision_service.js';
import { createTestAttemptService } from '../src/test_attempt_service.js';
import {
  buildUnitPerformanceDeltas,
  mergeUnitPerformance,
} from '../src/unit_performance_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-15T15:00:00.000Z');
const UID = 'student-unit-1';

function createServices(db, overrides = {}) {
  return createTestAttemptService({
    db,
    now: () => NOW,
    generateAttemptId: () => 'attempt-unit-1',
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
  partId = null,
  syllabusUnitId = undefined,
  majorStudyAreaId = null,
  contentTopicId = null,
  topicId = null,
  correctOption = 'B',
}) {
  const resolvedUnitId =
    syllabusUnitId === undefined
      ? (topicId || majorStudyAreaId || null)
      : syllabusUnitId;
  await db.collection('questions').doc(id).set({
    id,
    courseId,
    paperId,
    ...(partId ? { partId } : {}),
    ...(resolvedUnitId ? { syllabusUnitId: resolvedUnitId } : {}),
    ...(majorStudyAreaId ? { majorStudyAreaId } : {}),
    ...(contentTopicId ? { contentTopicId } : {}),
    ...(topicId ? { topicId } : {}),
    isActive: true,
    question: `Question ${id}`,
    explanation: `Explanation ${id}`,
    correctOption,
    options: [
      { label: 'A', text: 'A' },
      { label: 'B', text: 'B' },
      { label: 'C', text: 'C' },
      { label: 'D', text: 'D' },
    ],
  });
}

async function seedTest(db, {
  testId,
  courseId,
  questionIds,
  paperId,
  partId = null,
  syllabusUnitId = null,
  totalMarks = null,
  negativeMarks = 0,
}) {
  await db.collection('tests').doc(testId).set({
    id: testId,
    courseId,
    title: testId,
    category: 'chapter',
    questionCount: questionIds.length,
    totalMarks: totalMarks ?? questionIds.length,
    durationMinutes: 30,
    negativeMarks,
    questionIds,
    paperId,
    ...(partId ? { partId } : {}),
    ...(syllabusUnitId ? { syllabusUnitId } : {}),
    status: 'published',
    isPublished: true,
  });
}

function unitPath(uid, scopeKey) {
  return `user_progress/${uid}/unit_performance/${scopeKey}`;
}

test('1/5/6/7/8/9: Group-III attempt updates one unit with scoring metrics', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  const unit =
    'group-iii-paper-ii-part-i-unit-02';
  await seedQuestion(db, {
    id: 'gq1',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
    correctOption: 'B',
  });
  await seedQuestion(db, {
    id: 'gq2',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
    correctOption: 'A',
  });
  await seedTest(db, {
    testId: 'giii-test',
    courseId: 'group-iii',
    questionIds: ['gq1', 'gq2'],
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-i',
    syllabusUnitId: unit,
    totalMarks: 2,
    negativeMarks: 0,
  });

  const service = createServices(db, {
    generateAttemptId: () => 'attempt-giii-1',
  });
  const started = await service.startAttempt({ uid: UID,
    testId: 'giii-test', startRequestId: 'req-unit_performance.test-1' });
  await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [
      { questionId: 'gq1', selectedOption: 'B' },
      { questionId: 'gq2', selectedOption: 'C' },
    ],
  });

  const scopeKey =
    `v1|group-iii|group-iii-paper-ii|group-iii-paper-ii-part-i|${unit}`;
  const perf = db._store.get(unitPath(UID, scopeKey));
  assert.ok(perf);
  assert.equal(perf.syllabusUnitId, unit);
  assert.equal(perf.testsAttempted, 1);
  assert.equal(perf.testsCompleted, 1);
  assert.equal(perf.correct, 1);
  assert.equal(perf.wrong, 1);
  assert.equal(perf.skipped, 0);
  assert.equal(perf.questionsAttempted, 2);
  assert.equal(perf.marksObtained, 1);
  assert.equal(perf.totalMarks, 2);
  assert.equal(perf.accuracy, 50);
  assert.equal(perf.percentage, 50);
  assert.equal(perf.bestMarks, 1);
  assert.equal(perf.bestPercentage, 50);
  assert.equal(perf.lastAttemptId, 'attempt-giii-1');
  assert.equal(perf.lastTestId, 'giii-test');
  assert.equal(perf.authority, 'server_verified');

  // Legacy course progress still updated and unchanged in shape.
  const legacy = db._store.get(`user_progress/${UID}/courses/group-iii`);
  assert.ok(legacy);
  assert.equal(legacy.overall.questionsAttempted, 2);
  assert.equal(legacy.overall.questionsCorrect, 1);
  assert.deepEqual(legacy.papers, {});
  assert.deepEqual(legacy.chapters, {});
});

test('2/4/18: Group-II Papers II-IV use canonical topic as syllabusUnitId', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  const topic = 'group-ii-paper-ii-part-01-topic-04';
  await seedQuestion(db, {
    id: 'q17',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    topicId: topic,
    correctOption: 'B',
  });
  await seedTest(db, {
    testId: 'gii-part-test',
    courseId: 'group-ii',
    questionIds: ['q17'],
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    syllabusUnitId: topic,
    totalMarks: 1,
  });

  const service = createServices(db, {
    generateAttemptId: () => 'attempt-gii-part',
  });
  const started = await service.startAttempt({ uid: UID,
    testId: 'gii-part-test', startRequestId: 'req-unit_performance.test-2' });
  await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q17', selectedOption: 'B' }],
  });

  const scopeKey =
    `v1|group-ii|group-ii-paper-ii|group-ii-paper-ii-part-01|${topic}`;
  const perf = db._store.get(unitPath(UID, scopeKey));
  assert.ok(perf);
  assert.equal(perf.syllabusUnitId, topic);
  assert.equal(perf.correct, 1);
  assert.equal(perf.marksObtained, 1);
});

test('3: Group-II Paper-I uses majorStudyAreaId as syllabusUnitId', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-ii');
  await seedQuestion(db, {
    id: 'qi1',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    majorStudyAreaId: 'group-ii-paper-i-area-01',
    contentTopicId: 'group-ii-paper-i-area-01-topic-01',
    correctOption: 'A',
  });
  await seedTest(db, {
    testId: 'gii-paper-i-test',
    courseId: 'group-ii',
    questionIds: ['qi1'],
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
    totalMarks: 1,
  });

  const service = createServices(db, {
    generateAttemptId: () => 'attempt-gii-p1',
  });
  const started = await service.startAttempt({ uid: UID,
    testId: 'gii-paper-i-test', startRequestId: 'req-unit_performance.test-3' });
  await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'qi1', selectedOption: 'A' }],
  });

  const scopeKey = 'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01';
  const perf = db._store.get(unitPath(UID, scopeKey));
  assert.ok(perf);
  assert.equal(perf.syllabusUnitId, 'group-ii-paper-i-area-01');
  assert.notEqual(perf.syllabusUnitId, 'group-ii-paper-i-area-01-topic-01');
  assert.equal(perf.partId, null);
});

test('10/11: best score remains highest; latest attempt updates', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  const unit = 'group-iii-paper-i-unit-01';
  await seedQuestion(db, {
    id: 'u1',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: unit,
    correctOption: 'B',
  });
  await seedTest(db, {
    testId: 'best-test',
    courseId: 'group-iii',
    questionIds: ['u1'],
    paperId: 'group-iii-paper-i',
    syllabusUnitId: unit,
    totalMarks: 1,
  });

  let attemptN = 0;
  const service = createServices(db, {
    generateAttemptId: () => `attempt-best-${++attemptN}`,
  });

  const first = await service.startAttempt({ uid: UID, testId: 'best-test', startRequestId: 'req-unit_performance.test-4' });
  await service.submitAttempt({
    uid: UID,
    attemptId: first.attemptId,
    selectedAnswers: [{ questionId: 'u1', selectedOption: 'B' }],
  });

  const second = await service.startAttempt({ uid: UID, testId: 'best-test', startRequestId: 'req-unit_performance.test-5' });
  await service.submitAttempt({
    uid: UID,
    attemptId: second.attemptId,
    selectedAnswers: [{ questionId: 'u1', selectedOption: 'A' }],
  });

  const scopeKey = `v1|group-iii|group-iii-paper-i||${unit}`;
  const perf = db._store.get(unitPath(UID, scopeKey));
  assert.equal(perf.testsAttempted, 2);
  assert.equal(perf.correct, 1);
  assert.equal(perf.wrong, 1);
  assert.equal(perf.bestMarks, 1);
  assert.equal(perf.bestPercentage, 100);
  assert.equal(perf.lastAttemptId, 'attempt-best-2');
  assert.equal(perf.marksObtained, 1); // 1 + 0
});

test('12: duplicate submission does not double-count', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db, 'group-iii');
  const unit = 'group-iii-paper-i-unit-02';
  await seedQuestion(db, {
    id: 'd1',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: unit,
    correctOption: 'B',
  });
  await seedTest(db, {
    testId: 'dup-test',
    courseId: 'group-iii',
    questionIds: ['d1'],
    paperId: 'group-iii-paper-i',
    syllabusUnitId: unit,
  });

  const service = createServices(db, {
    generateAttemptId: () => 'attempt-dup',
  });
  const started = await service.startAttempt({ uid: UID, testId: 'dup-test', startRequestId: 'req-unit_performance.test-6' });
  await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'd1', selectedOption: 'B' }],
  });
  await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'd1', selectedOption: 'A' }],
  });

  const scopeKey = `v1|group-iii|group-iii-paper-i||${unit}`;
  const perf = db._store.get(unitPath(UID, scopeKey));
  assert.equal(perf.testsAttempted, 1);
  assert.equal(perf.correct, 1);
  assert.equal(perf.wrong, 0);

  const event = db._store.get('test_attempt_events/attempt-dup');
  assert.equal(event.unitPerformanceApplied, true);
});

test('13: concurrent side-effect application does not double-count', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const scopeKey =
    'v1|group-iii|group-iii-paper-i||group-iii-paper-i-unit-03';
  const progress = createProgressRevisionService({ db, now: () => NOW });

  const attempt = {
    attemptId: 'attempt-concurrent',
    uid: UID,
    courseId: 'group-iii',
    testId: 't-concurrent',
    status: 'submitted',
    authority: 'server_verified',
    correct: 1,
    wrong: 0,
    skipped: 0,
    attempted: 1,
    score: 1,
    totalMarks: 1,
    totalQuestions: 1,
    negativeMarks: 0,
    answers: [{ questionId: 'c1', selectedOption: 'B' }],
    questionSnapshots: [
      {
        questionId: 'c1',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: 'group-iii-paper-i-unit-03',
        correctOption: 'B',
        scopeShape: 'groupIiiPaperUnit',
        scopeKey,
      },
    ],
  };

  await db.collection('test_attempts').doc('attempt-concurrent').set(attempt);

  const [a, b] = await Promise.all([
    progress.applyVerifiedTestAttemptSideEffects({
      attemptId: 'attempt-concurrent',
      attempt,
      questionSnapshots: attempt.questionSnapshots,
      answers: attempt.answers,
    }),
    progress.applyVerifiedTestAttemptSideEffects({
      attemptId: 'attempt-concurrent',
      attempt,
      questionSnapshots: attempt.questionSnapshots,
      answers: attempt.answers,
    }),
  ]);

  assert.equal(
    [a.duplicate, b.duplicate].filter(Boolean).length >= 1 ||
      a.scopesUpdated?.length === 1,
    true,
  );

  const perf = db._store.get(unitPath(UID, scopeKey));
  assert.equal(perf.testsAttempted, 1);
  assert.equal(perf.correct, 1);
});

test('14: multiple units in one test aggregate separately', () => {
  const deltas = buildUnitPerformanceDeltas({
    courseId: 'group-iii',
    testId: 'multi',
    attemptId: 'a1',
    totalMarks: 30,
    totalQuestions: 30,
    negativeMarks: 0,
    answers: [
      { questionId: 'a1', selectedOption: 'A' },
      { questionId: 'a2', selectedOption: 'B' },
      { questionId: 'b1', selectedOption: 'A' },
    ],
    questionSnapshots: [
      {
        questionId: 'a1',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-ii',
        partId: 'group-iii-paper-ii-part-i',
        syllabusUnitId: 'unit-a',
        correctOption: 'A',
        scopeShape: 'groupIiiPartUnit',
      },
      {
        questionId: 'a2',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-ii',
        partId: 'group-iii-paper-ii-part-i',
        syllabusUnitId: 'unit-a',
        correctOption: 'A',
        scopeShape: 'groupIiiPartUnit',
      },
      {
        questionId: 'b1',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-ii',
        partId: 'group-iii-paper-ii-part-i',
        syllabusUnitId: 'unit-b',
        correctOption: 'A',
        scopeShape: 'groupIiiPartUnit',
      },
    ],
  });

  assert.equal(deltas.length, 2);
  const unitA = deltas.find((d) => d.syllabusUnitId === 'unit-a');
  const unitB = deltas.find((d) => d.syllabusUnitId === 'unit-b');
  assert.equal(unitA.correct, 1);
  assert.equal(unitA.wrong, 1);
  assert.equal(unitA.questionsAttempted, 2);
  assert.equal(unitA.totalMarks, 2);
  assert.equal(unitA.marksObtained, 1);
  assert.equal(unitB.correct, 1);
  assert.equal(unitB.wrong, 0);
  assert.equal(unitB.totalMarks, 1);
  assert.equal(unitB.marksObtained, 1);
});

test('16/17: legacy progress unchanged; legacy attempts without snapshot skip unit write', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  const progress = createProgressRevisionService({ db, now: () => NOW });

  await db.collection('user_progress').doc(UID).collection('courses').doc('group-ii').set({
    uid: UID,
    courseId: 'group-ii',
    overall: {
      completion: 12,
      accuracy: 40,
      chaptersCompleted: 2,
      totalChapters: 10,
      questionsAttempted: 5,
      questionsCorrect: 2,
    },
    papers: { 'paper-legacy': { done: true } },
    chapters: { 'chapter-legacy': { done: true } },
  });

  await progress.applyVerifiedTestAttemptSideEffects({
    attemptId: 'legacy-attempt',
    attempt: {
      attemptId: 'legacy-attempt',
      uid: UID,
      courseId: 'group-ii',
      testId: 'legacy-test',
      status: 'submitted',
      authority: 'server_verified',
      correct: 1,
      wrong: 0,
      skipped: 0,
      attempted: 1,
      score: 1,
      totalMarks: 1,
      totalQuestions: 1,
      negativeMarks: 0,
      // No snapshotSchemaVersion / questionSnapshots
      answers: [{ questionId: 'old', selectedOption: 'A' }],
    },
    answers: [{ questionId: 'old', selectedOption: 'A' }],
    questionSnapshots: [],
  });

  const legacy = db._store.get(`user_progress/${UID}/courses/group-ii`);
  assert.equal(legacy.overall.questionsAttempted, 6);
  assert.equal(legacy.overall.questionsCorrect, 3);
  assert.deepEqual(legacy.papers, { 'paper-legacy': { done: true } });
  assert.deepEqual(legacy.chapters, { 'chapter-legacy': { done: true } });

  const unitKeys = [...db._store.keys()].filter((k) =>
    k.startsWith(`user_progress/${UID}/unit_performance/`),
  );
  assert.equal(unitKeys.length, 0);

  const event = db._store.get('test_attempt_events/legacy-attempt');
  assert.equal(event.unitPerformanceApplied, true);
  assert.deepEqual(event.unitPerformanceScopeKeys, []);
});

test('mergeUnitPerformance keeps best marks higher', () => {
  const merged = mergeUnitPerformance(
    {
      correct: 2,
      wrong: 0,
      skipped: 0,
      questionsAttempted: 2,
      testsAttempted: 1,
      testsCompleted: 1,
      totalMarks: 2,
      marksObtained: 2,
      bestMarks: 2,
      bestPercentage: 100,
    },
    {
      scopeKey: 'v1|group-iii|group-iii-paper-i||u1',
      courseId: 'group-iii',
      paperId: 'group-iii-paper-i',
      partId: null,
      syllabusUnitId: 'u1',
      testsAttempted: 1,
      testsCompleted: 1,
      questionsAttempted: 1,
      correct: 0,
      wrong: 1,
      skipped: 0,
      totalMarks: 1,
      marksObtained: 0,
      accuracy: 0,
      percentage: 0,
      lastTestId: 't2',
      lastAttemptId: 'a2',
    },
  );
  assert.equal(merged.bestMarks, 2);
  assert.equal(merged.bestPercentage, 100);
  assert.equal(merged.testsAttempted, 2);
  assert.equal(merged.lastAttemptId, 'a2');
});
