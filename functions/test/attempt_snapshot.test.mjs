import assert from 'node:assert/strict';
import test from 'node:test';

import {
  GRADING_SNAPSHOT_COLLECTION,
  SNAPSHOT_SCHEMA_VERSION,
  toStudentSafeQuestion,
} from '../src/attempt_snapshot.js';
import { createEntitlementService } from '../src/entitlement_service.js';
import { createTestAttemptService } from '../src/test_attempt_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

const NOW = new Date('2026-08-15T12:00:00.000Z');
const UID = 'student-1';

function createService(db, overrides = {}) {
  return createTestAttemptService({
    db,
    now: () => NOW,
    generateAttemptId: () => 'attempt-snap-1',
    ...overrides,
  });
}

async function seedAccess(db, courseId = 'group-ii') {
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
  courseId = 'group-ii',
  correctOption = 'B',
  text = 'Version 1 text',
  explanation = 'Explanation 1',
  paperId = 'group-ii-paper-ii',
  partId = 'group-ii-paper-ii-part-01',
  topicId = 'group-ii-paper-ii-part-01-topic-04',
  syllabusUnitId = undefined,
  options = null,
}) {
  const resolvedUnitId =
    syllabusUnitId === undefined ? topicId : syllabusUnitId;
  await db.collection('questions').doc(id).set({
    id,
    courseId,
    paperId,
    partId,
    ...(topicId ? { topicId } : {}),
    ...(resolvedUnitId ? { syllabusUnitId: resolvedUnitId } : {}),
    isActive: true,
    question: text,
    explanation,
    correctOption,
    questionType: 'practice',
    difficulty: 'medium',
    marks: 1,
    options: options || [
      { label: 'A', text: 'Opt A' },
      { label: 'B', text: 'Opt B' },
      { label: 'C', text: 'Opt C' },
      { label: 'D', text: 'Opt D' },
    ],
  });
}

async function seedTest(db, {
  testId = 'test-snap-1',
  courseId = 'group-ii',
  questionIds = ['q17'],
  paperId = 'group-ii-paper-ii',
  partId = 'group-ii-paper-ii-part-01',
  syllabusUnitId = 'group-ii-paper-ii-part-01-topic-04',
  title = 'Snapshot Test',
  totalMarks = null,
  negativeMarks = 0,
  durationMinutes = 10,
} = {}) {
  await db.collection('tests').doc(testId).set({
    id: testId,
    courseId,
    title,
    description: 'Original description',
    category: 'chapter',
    questionCount: questionIds.length,
    totalMarks: totalMarks ?? questionIds.length,
    durationMinutes,
    negativeMarks,
    questionIds,
    paperId,
    partId,
    syllabusUnitId,
    instructions: ['Read carefully'],
    status: 'published',
    isPublished: true,
  });
}

test('1/2/3/4/5: snapshot created at START with order, keys, text, scoring', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedQuestion(db, { id: 'q17', correctOption: 'B', text: 'Version 1 text' });
  await seedQuestion(db, {
    id: 'q18',
    correctOption: 'A',
    text: 'Second question',
    explanation: 'Second explanation',
  });
  await seedTest(db, { questionIds: ['q17', 'q18'] });

  const started = await createService(db).startAttempt({ uid: UID,
    testId: 'test-snap-1', startRequestId: 'req-attempt_snapshot.test-1' });

  assert.equal(started.snapshotSchemaVersion, SNAPSHOT_SCHEMA_VERSION);
  assert.deepEqual(started.questionIds, ['q17', 'q18']);
  assert.equal(started.studentQuestions.length, 2);
  assert.equal(started.studentQuestions[0].questionId, 'q17');
  assert.equal(started.studentQuestions[0].position, 0);
  assert.equal(started.studentQuestions[0].text, 'Version 1 text');
  assert.equal(started.studentQuestions[0].options[1].text, 'Opt B');
  assert.equal(started.studentQuestions[0].correctOption, undefined);
  assert.equal(started.studentQuestions[0].explanation, undefined);
  assert.equal(started.testSnapshot.totalMarks, 2);
  assert.equal(started.testSnapshot.negativeMarks, 0);
  assert.equal(started.testSnapshot.scoringVersion, 'v1');
  assert.equal(started.testSnapshot.syllabusUnitId, 'group-ii-paper-ii-part-01-topic-04');

  const attempt = db._store.get('test_attempts/attempt-snap-1');
  assert.equal(attempt.snapshotSchemaVersion, SNAPSHOT_SCHEMA_VERSION);
  assert.equal(attempt.studentQuestions[0].correctOption, undefined);
  assert.ok(!('correctOption' in (attempt.studentQuestions[0] || {})));

  const grading = db._store.get(`${GRADING_SNAPSHOT_COLLECTION}/attempt-snap-1`);
  assert.ok(grading);
  assert.equal(grading.questions[0].correctOption, 'B');
  assert.equal(grading.questions[0].text, 'Version 1 text');
  assert.equal(grading.questions[0].explanation, 'Explanation 1');
  assert.deepEqual(
    grading.questions.map((q) => q.questionId),
    ['q17', 'q18'],
  );
  assert.equal(grading.scoring.totalMarks, 2);
});

test('6/10: editing question after START does not change grading', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedQuestion(db, { id: 'q17', correctOption: 'B', text: 'Version 1 text' });
  await seedTest(db, { questionIds: ['q17'], totalMarks: 1 });

  const service = createService(db);
  const started = await service.startAttempt({ uid: UID, testId: 'test-snap-1', startRequestId: 'req-attempt_snapshot.test-2' });

  await db.collection('questions').doc('q17').set({
    id: 'q17',
    courseId: 'group-ii',
    isActive: true,
    question: 'Version 2 text',
    explanation: 'Explanation 2',
    correctOption: 'C',
    options: [
      { label: 'A', text: 'Opt A' },
      { label: 'B', text: 'Opt B' },
      { label: 'C', text: 'Opt C' },
      { label: 'D', text: 'Opt D' },
    ],
  });

  const submitted = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q17', selectedOption: 'B' }],
  });

  assert.equal(submitted.correct, 1);
  assert.equal(submitted.wrong, 0);
  assert.equal(submitted.score, 1);
  assert.equal(submitted.questionSnapshots[0].correctOption, 'B');
  assert.equal(submitted.questionSnapshots[0].text, 'Version 1 text');
  assert.equal(submitted.questionSnapshots[0].explanation, 'Explanation 1');

  const attempt = db._store.get('test_attempts/attempt-snap-1');
  assert.equal(attempt.questionSnapshots[0].correctOption, 'B');
  assert.equal(attempt.score, 1);
});

test('7: editing test after START does not change scoring config', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedQuestion(db, { id: 'q17', correctOption: 'B' });
  await seedTest(db, {
    questionIds: ['q17'],
    totalMarks: 1,
    negativeMarks: 0.25,
  });

  const service = createService(db);
  const started = await service.startAttempt({ uid: UID, testId: 'test-snap-1', startRequestId: 'req-attempt_snapshot.test-3' });

  await db.collection('tests').doc('test-snap-1').set({
    id: 'test-snap-1',
    courseId: 'group-ii',
    title: 'Edited title',
    category: 'chapter',
    questionCount: 1,
    totalMarks: 99,
    durationMinutes: 10,
    negativeMarks: 5,
    questionIds: ['q17'],
    status: 'published',
    isPublished: true,
  });

  const submitted = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q17', selectedOption: 'A' }],
  });

  // Wrong answer with frozen negativeMarks 0.25 and totalMarks 1.
  assert.equal(submitted.wrong, 1);
  assert.equal(submitted.score, 0);
  assert.equal(submitted.totalQuestions, 1);
  assert.equal(started.testSnapshot.totalMarks, 1);
  assert.equal(started.testSnapshot.negativeMarks, 0.25);
});

test('8: syllabus metadata edit after START does not change attribution', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedQuestion(db, {
    id: 'q17',
    topicId: 'group-ii-paper-ii-part-01-topic-04',
  });
  await seedTest(db, {
    questionIds: ['q17'],
    syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
  });

  const started = await createService(db).startAttempt({ uid: UID,
    testId: 'test-snap-1', startRequestId: 'req-attempt_snapshot.test-4' });

  await db.collection('questions').doc('q17').set({
    id: 'q17',
    courseId: 'group-ii',
    isActive: true,
    question: 'Version 1 text',
    explanation: 'Explanation 1',
    correctOption: 'B',
    topicId: 'group-ii-paper-ii-part-01-topic-99',
    paperId: 'group-ii-paper-iv',
    partId: 'group-ii-paper-iv-part-01',
    options: [
      { label: 'A', text: 'Opt A' },
      { label: 'B', text: 'Opt B' },
      { label: 'C', text: 'Opt C' },
      { label: 'D', text: 'Opt D' },
    ],
  });

  const grading = db._store.get(`${GRADING_SNAPSHOT_COLLECTION}/attempt-snap-1`);
  assert.equal(
    grading.questions[0].syllabusUnitId,
    'group-ii-paper-ii-part-01-topic-04',
  );
  assert.equal(
    grading.questions[0].canonicalTopicId,
    'group-ii-paper-ii-part-01-topic-04',
  );
  assert.equal(grading.questions[0].scopeShape, 'groupIiPartUnit');
  assert.equal(grading.questions[0].paperId, 'group-ii-paper-ii');
  assert.equal(
    started.studentQuestions[0].syllabusUnitId,
    'group-ii-paper-ii-part-01-topic-04',
  );
  assert.equal(
    started.studentQuestions[0].scopeKey,
    'v1|group-ii|group-ii-paper-ii|group-ii-paper-ii-part-01|'
      + 'group-ii-paper-ii-part-01-topic-04',
  );
});

test('9: student-safe payload never includes answer key', () => {
  const safe = toStudentSafeQuestion({
    questionId: 'q17',
    position: 0,
    text: 'Version 1',
    options: [{ label: 'A', text: 'A' }, { label: 'B', text: 'B' }],
    correctOption: 'B',
    explanation: 'secret',
    questionType: 'practice',
    marks: 1,
    difficulty: 'medium',
    courseId: 'group-ii',
    paperId: 'p',
    partId: 'part',
    syllabusUnitId: 'unit',
  });
  assert.equal(safe.correctOption, undefined);
  assert.equal(safe.explanation, undefined);
  assert.ok(!('correctOption' in safe));
  assert.ok(!('explanation' in safe));
});

test('11: legacy attempts without snapshot still score from live bank', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedQuestion(db, { id: 'q17', correctOption: 'B' });

  // Manually seed a legacy in-progress attempt (no snapshotSchemaVersion).
  await db.collection('test_attempts').doc('legacy-1').set({
    attemptId: 'legacy-1',
    uid: UID,
    testId: 'test-snap-1',
    courseId: 'group-ii',
    questionIds: ['q17'],
    totalMarks: 1,
    negativeMarks: 0,
    totalQuestions: 1,
    durationSeconds: 600,
    scoringVersion: 'v1',
    status: 'in_progress',
    authority: 'server_verified',
    startedAt: NOW,
  });

  await db.collection('questions').doc('q17').set({
    id: 'q17',
    courseId: 'group-ii',
    isActive: true,
    question: 'Live edited',
    explanation: 'Live',
    correctOption: 'C',
    options: [
      { label: 'A', text: 'Opt A' },
      { label: 'B', text: 'Opt B' },
      { label: 'C', text: 'Opt C' },
      { label: 'D', text: 'Opt D' },
    ],
  });

  const submitted = await createService(db).submitAttempt({
    uid: UID,
    attemptId: 'legacy-1',
    selectedAnswers: [{ questionId: 'q17', selectedOption: 'C' }],
  });
  assert.equal(submitted.correct, 1);
  assert.equal(submitted.snapshotSchemaVersion, null);
});

test('12: failed snapshot creation does not leave a usable attempt', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  // Missing question text / options will fail snapshot build after resolve.
  await db.collection('questions').doc('broken').set({
    id: 'broken',
    courseId: 'group-ii',
    isActive: true,
    correctOption: 'A',
    options: [],
  });
  await seedTest(db, { questionIds: ['broken'] });

  await assert.rejects(
    () => createService(db).startAttempt({ uid: UID, testId: 'test-snap-1' , startRequestId: 'req-attempt_snapshot.test'}),
    (error) => {
      assert.equal(error.code, 'failed-precondition');
      return true;
    },
  );

  const attempts = [...db._store.keys()].filter((k) =>
    k.startsWith('test_attempts/'),
  );
  const grading = [...db._store.keys()].filter((k) =>
    k.startsWith(`${GRADING_SNAPSHOT_COLLECTION}/`),
  );
  assert.equal(attempts.length, 0);
  assert.equal(grading.length, 0);
});

test('13/14: Group-II and Group-III snapshot start works', async () => {
  for (const courseId of ['group-ii', 'group-iii']) {
    const db = new FakeFirestore({ now: () => NOW });
    await seedAccess(db, courseId);
    const qid = `q-${courseId}`;
    const isIii = courseId === 'group-iii';
    await seedQuestion(db, {
      id: qid,
      courseId,
      paperId: isIii ? 'group-iii-paper-ii' : 'group-ii-paper-ii',
      partId: isIii
        ? 'group-iii-paper-ii-part-i'
        : 'group-ii-paper-ii-part-01',
      topicId: isIii ? null : 'group-ii-paper-ii-part-01-topic-04',
      syllabusUnitId: isIii
        ? 'group-iii-paper-ii-part-i-unit-02'
        : 'group-ii-paper-ii-part-01-topic-04',
      text: `${courseId} question`,
    });
    await seedTest(db, {
      testId: `test-${courseId}`,
      courseId,
      questionIds: [qid],
      paperId: isIii ? 'group-iii-paper-ii' : 'group-ii-paper-ii',
      partId: isIii
        ? 'group-iii-paper-ii-part-i'
        : 'group-ii-paper-ii-part-01',
      syllabusUnitId: isIii
        ? 'group-iii-paper-ii-part-i-unit-02'
        : 'group-ii-paper-ii-part-01-topic-04',
    });

    const started = await createService(db, {
      generateAttemptId: () => `attempt-${courseId}`,
    }).startAttempt({
      uid: UID,
      testId: `test-${courseId}`,
      startRequestId: `req-snap-${courseId}`,
    });

    assert.equal(started.courseId, courseId);
    assert.equal(started.snapshotSchemaVersion, SNAPSHOT_SCHEMA_VERSION);
    assert.equal(started.studentQuestions[0].courseId, courseId);
  }
});

test('15: duplicate submission remains idempotent with snapshots', async () => {
  const db = new FakeFirestore({ now: () => NOW });
  await seedAccess(db);
  await seedQuestion(db, { id: 'q17', correctOption: 'B' });
  await seedTest(db, { questionIds: ['q17'], totalMarks: 1 });

  const service = createService(db);
  const started = await service.startAttempt({ uid: UID, testId: 'test-snap-1', startRequestId: 'req-attempt_snapshot.test-5' });
  const first = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q17', selectedOption: 'B' }],
  });
  const second = await service.submitAttempt({
    uid: UID,
    attemptId: started.attemptId,
    selectedAnswers: [{ questionId: 'q17', selectedOption: 'A' }],
  });
  assert.equal(first.duplicate, false);
  assert.equal(second.duplicate, true);
  assert.equal(second.score, first.score);
  assert.equal(second.correct, 1);
});
