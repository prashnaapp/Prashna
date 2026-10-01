import assert from 'node:assert/strict';
import test from 'node:test';
import { FieldValue } from 'firebase-admin/firestore';

import { createAdminContentService } from '../src/admin_content_service.js';
import {
  MAX_ASSIGNED_QUESTIONS_PER_TEST,
  assertQuestionCompatibleWithTest,
  validateQuestionPayload,
  validateTestPayload,
} from '../src/content_validation_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

const ACTOR = 'admin-1';

function bilingual() {
  return {
    en: {
      question: 'What is the capital of Telangana?',
      options: ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
      explanation: 'Hyderabad is the capital.',
    },
    te: {
      question: 'తెలంగాణ రాజధాని ఏది?',
      options: ['హైదరాబాద్', 'వరంగల్', 'నిజామాబాద్', 'కరీంనగర్'],
      explanation: 'హైదరాబాద్ రాజధాని.',
    },
  };
}

function question(overrides = {}) {
  return {
    id: 'q1',
    courseId: 'group-ii',
    question: 'What is the capital of Telangana?',
    options: ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
    correctOption: 'A',
    explanation: 'Hyderabad is the capital.',
    difficulty: 'easy',
    questionType: 'practice',
    language: 'en',
    marks: 1,
    negativeMarks: 0,
    estimatedTimeSeconds: 60,
    isActive: false,
    status: 'draft',
    content: bilingual(),
    ...overrides,
  };
}

function chapterQuestion(overrides = {}) {
  return question({
    id: 'q-chapter',
    contentArea: 'chapter',
    paperId: 'group-ii-paper-i',
    majorStudyAreaId: 'group-ii-paper-i-area-01',
    contentTopicId: 'group-ii-paper-i-area-01-topic-01',
    ...overrides,
  });
}

function paperWiseQuestion(overrides = {}) {
  return question({
    id: 'q-part',
    contentArea: 'testSeries',
    testSeriesCategory: 'part',
    paperId: 'group-ii-paper-i',
    ...overrides,
  });
}

function grandQuestion(overrides = {}) {
  return question({
    id: 'q-grand',
    contentArea: 'testSeries',
    testSeriesCategory: 'mock',
    seriesId: 'Grand Test - I',
    ...overrides,
  });
}

function previousQuestion(overrides = {}) {
  return question({
    id: 'q-year',
    contentArea: 'testSeries',
    testSeriesCategory: 'previousyear',
    year: 2024,
    ...overrides,
  });
}

function draftTest(overrides = {}) {
  return {
    id: 't1',
    courseId: 'group-ii',
    title: 'Paper-wise draft',
    description: '',
    category: 'part',
    questionCount: 0,
    totalMarks: 0,
    durationMinutes: 0,
    negativeMarks: 0,
    difficulty: 'Medium',
    questionIds: [],
    status: 'draft',
    isPublished: false,
    paperId: 'group-ii-paper-i',
    ...overrides,
  };
}

function mockTest(overrides = {}) {
  return draftTest({
    id: 't-grand',
    title: 'Grand draft',
    category: 'mock',
    seriesId: 'Grand Test - I',
    paperId: 'group-ii-paper-iii',
    ...overrides,
  });
}

function previousPaperTest(overrides = {}) {
  return draftTest({
    id: 't-year',
    title: 'Previous draft',
    category: 'previousyear',
    year: 2024,
    paperId: 'group-ii-paper-ii',
    ...overrides,
  });
}

function chapterTest(overrides = {}) {
  return draftTest({
    id: 't-chapter',
    title: 'Chapter draft',
    category: 'chapter',
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
    ...overrides,
  });
}

function harness() {
  const db = new FakeFirestore();
  return { db, svc: createAdminContentService(db) };
}

test('empty draft test is created with zero aggregates', async () => {
  const { db, svc } = harness();
  const created = await svc.createTest(
    { testId: 't-empty', data: draftTest({ id: 't-empty' }) },
    { assignedBy: ACTOR },
  );
  assert.equal(created.testId, 't-empty');
  assert.equal(created.questionCount, 0);
  assert.equal(created.totalMarks, 0);
  assert.equal(created.durationMinutes, 0);
  assert.equal(created.status, 'draft');
  assert.equal(created.isPublished, false);
  const stored = (await db.collection('tests').doc('t-empty').get()).data();
  assert.deepEqual(stored.questionIds, []);
  assert.equal(stored.questionCount, 0);
  assert.equal(stored.totalMarks, 0);
  assert.equal(stored.durationMinutes, 0);
  assert.equal(stored.negativeMarks, 0);
});

test('zero-question draft preserves planning count, marks, and duration', async () => {
  const { db, svc } = harness();
  await svc.createTest(
    {
      testId: 't-planning',
      data: draftTest({
        id: 't-planning',
        questionCount: 10,
        totalMarks: 15,
        durationMinutes: 30,
      }),
    },
    { assignedBy: ACTOR },
  );

  const stored = (await db.collection('tests').doc('t-planning').get()).data();
  assert.deepEqual(stored.questionIds, []);
  assert.equal(stored.questionCount, 10);
  assert.equal(stored.totalMarks, 15);
  assert.equal(stored.durationMinutes, 30);
});

test('empty draft test cannot be published', async () => {
  const { svc } = harness();
  await svc.createTest(
    { testId: 't-empty', data: draftTest({ id: 't-empty' }) },
    { assignedBy: ACTOR },
  );
  await assert.rejects(
    () => svc.publishTest({ testId: 't-empty' }, { assignedBy: ACTOR }),
    (err) => /no questions/.test(err.message),
  );
});

test('draft question assigns to a draft test and records the reservation', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({
    questionId: 'q-part',
    data: paperWiseQuestion({ isActive: false, status: 'draft' }),
  });
  await svc.createTest(
    {
      testId: 't1',
      data: draftTest({
        id: 't1',
        questionIds: ['q-part'],
        questionCount: 99,
        totalMarks: 50,
        durationMinutes: 40,
      }),
    },
    { assignedBy: ACTOR },
  );

  const assignment = (await db.collection('question_assignments').doc('q-part').get()).data();
  assert.equal(assignment.questionId, 'q-part');
  assert.equal(assignment.testId, 't1');
  assert.equal(assignment.courseId, 'group-ii');
  assert.equal(assignment.assignedBy, ACTOR);
  assert.ok(assignment.assignedAt);

  const testDoc = (await db.collection('tests').doc('t1').get()).data();
  assert.deepEqual(testDoc.questionIds, ['q-part']);
  assert.equal(testDoc.questionCount, 1);
  assert.equal(testDoc.totalMarks, 1);
  assert.equal(testDoc.durationMinutes, 1);

  const storedQuestion = (await db.collection('questions').doc('q-part').get()).data();
  assert.equal(storedQuestion.status, 'draft');
  assert.equal(storedQuestion.isActive, false);
  assert.equal(storedQuestion.contentArea, 'testSeries');
});

test('the same question cannot be claimed by a second test', async () => {
  const { svc } = harness();
  await svc.createQuestion({ questionId: 'q-part', data: paperWiseQuestion() });
  await svc.createTest(
    { testId: 't1', data: draftTest({ id: 't1', questionIds: ['q-part'] }) },
    { assignedBy: ACTOR },
  );
  await assert.rejects(
    () => svc.createTest(
      { testId: 't2', data: draftTest({ id: 't2', questionIds: ['q-part'] }) },
      { assignedBy: 'admin-2' },
    ),
    (err) => /already assigned/.test(err.message),
  );
});

test('reordering inside the owning test keeps assignment and order', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({
    questionId: 'q-a',
    data: paperWiseQuestion({ id: 'q-a', marks: 2 }),
  });
  await svc.createQuestion({
    questionId: 'q-b',
    data: paperWiseQuestion({ id: 'q-b', marks: 3 }),
  });
  await svc.createTest(
    {
      testId: 't1',
      data: draftTest({ id: 't1', questionIds: ['q-a', 'q-b'] }),
    },
    { assignedBy: ACTOR },
  );

  await svc.updateTest(
    {
      testId: 't1',
      data: draftTest({
        id: 't1',
        questionIds: ['q-b', 'q-a'],
        questionCount: 9,
        totalMarks: 9,
        durationMinutes: 30,
      }),
    },
    { assignedBy: 'admin-2' },
  );

  const stored = (await db.collection('tests').doc('t1').get()).data();
  assert.deepEqual(stored.questionIds, ['q-b', 'q-a']);
  assert.equal(stored.questionCount, 2);
  assert.equal(stored.totalMarks, 5);
  assert.equal(stored.durationMinutes, 2);
  assert.equal(
    (await db.collection('question_assignments').doc('q-a').get()).data().testId,
    't1',
  );
  assert.equal(
    (await db.collection('question_assignments').doc('q-a').get()).data().assignedBy,
    ACTOR,
  );
  assert.equal(
    (await db.collection('question_assignments').doc('q-b').get()).data().testId,
    't1',
  );
});

test('removing a question releases only the assignment', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({ questionId: 'q-a', data: paperWiseQuestion({ id: 'q-a' }) });
  await svc.createQuestion({ questionId: 'q-b', data: paperWiseQuestion({ id: 'q-b' }) });
  await svc.createTest(
    {
      testId: 't1',
      data: draftTest({ id: 't1', questionIds: ['q-a', 'q-b'] }),
    },
    { assignedBy: ACTOR },
  );
  await svc.publishTest({ testId: 't1' }, { assignedBy: ACTOR });

  await svc.updateTest(
    {
      testId: 't1',
      data: draftTest({
        id: 't1',
        questionIds: ['q-b'],
        status: 'published',
        isPublished: true,
      }),
    },
    { assignedBy: ACTOR },
  );

  assert.equal((await db.collection('question_assignments').doc('q-a').get()).exists, false);
  const kept = (await db.collection('questions').doc('q-a').get()).data();
  assert.equal(kept.contentArea, 'testSeries');
  assert.equal(kept.testSeriesCategory, 'part');
  assert.equal(kept.paperId, 'group-ii-paper-i');
  assert.equal(kept.status, 'draft');
  assert.equal(kept.isActive, false);
  assert.equal((await db.collection('questions').doc('q-a').get()).exists, true);
  const stored = (await db.collection('tests').doc('t1').get()).data();
  assert.deepEqual(stored.questionIds, ['q-b']);
  assert.equal(stored.questionCount, 1);
  assert.equal(stored.totalMarks, 1);
  assert.equal(stored.durationMinutes, 1);
});

test('assigning to an already-published test publishes the added question', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({ questionId: 'q-a', data: paperWiseQuestion({ id: 'q-a' }) });
  await svc.createQuestion({ questionId: 'q-b', data: paperWiseQuestion({ id: 'q-b' }) });
  await svc.createTest(
    { testId: 't-live', data: draftTest({ id: 't-live', questionIds: ['q-a'] }) },
    { assignedBy: ACTOR },
  );
  await svc.publishTest({ testId: 't-live' }, { assignedBy: ACTOR });

  await svc.updateTest(
    {
      testId: 't-live',
      data: draftTest({
        id: 't-live',
        questionIds: ['q-a', 'q-b'],
        status: 'published',
        isPublished: true,
      }),
    },
    { assignedBy: ACTOR },
  );

  const added = (await db.collection('questions').doc('q-b').get()).data();
  assert.equal(added.status, 'published');
  assert.equal(added.isActive, true);
  assert.equal(
    (await db.collection('question_assignments').doc('q-b').get()).data().testId,
    't-live',
  );
});

test('archived questions cannot be newly assigned', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({
    questionId: 'q-archived',
    data: paperWiseQuestion({
      id: 'q-archived',
      status: 'archived',
      isActive: false,
    }),
  });

  await assert.rejects(
    () => svc.createTest(
      {
        testId: 't-archived-question',
        data: draftTest({
          id: 't-archived-question',
          questionIds: ['q-archived'],
        }),
      },
      { assignedBy: ACTOR },
    ),
    (err) => err.code === 'failed-precondition' && /Archived Question/.test(err.message),
  );
  assert.equal((await db.collection('tests').doc('t-archived-question').get()).exists, false);
  assert.equal(
    (await db.collection('question_assignments').doc('q-archived').get()).exists,
    false,
  );
});

test('metadata-only updates preserve canonical membership in both stale directions', async () => {
  const { db, svc } = harness();
  const ids = ['q-1', 'q-2', 'q-3', 'q-4', 'q-5'];
  for (const id of ids) {
    await svc.createQuestion({ questionId: id, data: paperWiseQuestion({ id }) });
  }
  await svc.createTest(
    { testId: 't-metadata', data: draftTest({ id: 't-metadata', questionIds: ids }) },
    { assignedBy: ACTOR },
  );

  await svc.updateTest(
    {
      testId: 't-metadata',
      preserveQuestionAssignments: true,
      data: draftTest({
        id: 't-metadata',
        title: 'Stale form with four',
        questionIds: ids.slice(0, 4),
      }),
    },
    { assignedBy: ACTOR },
  );
  let stored = (await db.collection('tests').doc('t-metadata').get()).data();
  assert.deepEqual(stored.questionIds, ids);
  assert.equal(stored.questionCount, 5);

  await svc.updateTest(
    {
      testId: 't-metadata',
      data: draftTest({ id: 't-metadata', questionIds: ids.slice(0, 4) }),
    },
    { assignedBy: ACTOR },
  );
  await svc.updateTest(
    {
      testId: 't-metadata',
      preserveQuestionAssignments: true,
      data: draftTest({
        id: 't-metadata',
        title: 'Stale form with five',
        questionIds: ids,
      }),
    },
    { assignedBy: ACTOR },
  );
  stored = (await db.collection('tests').doc('t-metadata').get()).data();
  assert.deepEqual(stored.questionIds, ids.slice(0, 4));
  assert.equal(stored.questionCount, 4);
  assert.equal((await db.collection('question_assignments').doc('q-5').get()).exists, false);
});

test('decoded delete marker is absent during compatibility checks', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({ questionId: 'q-no-part', data: paperWiseQuestion({ id: 'q-no-part' }) });
  await svc.createTest(
    {
      testId: 't-no-part',
      data: draftTest({ id: 't-no-part', questionIds: ['q-no-part'] }),
    },
    { assignedBy: ACTOR },
  );

  await svc.updateTest(
    {
      testId: 't-no-part',
      preserveQuestionAssignments: true,
      data: draftTest({
        id: 't-no-part',
        title: 'No false part mismatch',
        partId: { _fieldDelete: true },
        questionIds: ['stale-id'],
      }),
    },
    { assignedBy: ACTOR },
  );

  const stored = (await db.collection('tests').doc('t-no-part').get()).data();
  assert.equal(stored.partId, undefined);
  assert.deepEqual(stored.questionIds, ['q-no-part']);
  assert.doesNotThrow(() => assertQuestionCompatibleWithTest(
    paperWiseQuestion({ id: 'q-delete' }),
    draftTest({ partId: FieldValue.delete() }),
    'q-delete',
  ));
  assert.doesNotThrow(() => assertQuestionCompatibleWithTest(
    paperWiseQuestion({ id: 'q-stale-part', partId: 'part-b', paperId: 'group-ii-paper-i' }),
    draftTest({ partId: 'part-a', paperId: 'group-ii-paper-i' }),
    'q-stale-part',
  ));
  assert.throws(
    () => assertQuestionCompatibleWithTest(
      paperWiseQuestion({ id: 'q-wrong-paper', paperId: 'group-ii-paper-ii' }),
      draftTest({ paperId: 'group-ii-paper-i' }),
      'q-wrong-paper',
    ),
    (err) => err.code === 'failed-precondition' && /test paper/.test(err.message),
  );
});

test('editing assigned question marks refreshes test totalMarks', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({
    questionId: 'q-a',
    data: paperWiseQuestion({ id: 'q-a', marks: 2 }),
  });
  await svc.createQuestion({
    questionId: 'q-b',
    data: paperWiseQuestion({ id: 'q-b', marks: 3 }),
  });
  await svc.createTest(
    {
      testId: 't1',
      data: draftTest({ id: 't1', questionIds: ['q-a', 'q-b'] }),
    },
    { assignedBy: ACTOR },
  );
  assert.equal((await db.collection('tests').doc('t1').get()).data().totalMarks, 5);

  await svc.updateQuestion({
    questionId: 'q-a',
    data: paperWiseQuestion({ id: 'q-a', marks: 4 }),
  });
  assert.equal((await db.collection('tests').doc('t1').get()).data().totalMarks, 7);
  assert.equal((await db.collection('tests').doc('t1').get()).data().durationMinutes, 2);
});

test('publish, draft, and archive follow the test without releasing assignments', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({ questionId: 'q-part', data: paperWiseQuestion() });
  await svc.createTest(
    { testId: 't1', data: draftTest({ id: 't1', questionIds: ['q-part'] }) },
    { assignedBy: ACTOR },
  );

  await svc.publishTest({ testId: 't1' }, { assignedBy: ACTOR });
  let questionDoc = (await db.collection('questions').doc('q-part').get()).data();
  assert.equal(questionDoc.status, 'published');
  assert.equal(questionDoc.isActive, true);
  assert.equal((await db.collection('tests').doc('t1').get()).data().isPublished, true);
  assert.equal((await db.collection('question_assignments').doc('q-part').get()).exists, true);

  await svc.setTestStatus({ testId: 't1', status: 'draft' }, { assignedBy: ACTOR });
  questionDoc = (await db.collection('questions').doc('q-part').get()).data();
  assert.equal(questionDoc.status, 'draft');
  assert.equal(questionDoc.isActive, false);
  assert.equal((await db.collection('question_assignments').doc('q-part').get()).exists, true);

  await svc.publishTest({ testId: 't1' }, { assignedBy: ACTOR });
  await svc.setTestStatus({ testId: 't1', status: 'archived' }, { assignedBy: ACTOR });
  questionDoc = (await db.collection('questions').doc('q-part').get()).data();
  assert.equal(questionDoc.status, 'archived');
  assert.equal(questionDoc.isActive, false);
  assert.equal((await db.collection('tests').doc('t1').get()).data().status, 'archived');
  assert.equal((await db.collection('question_assignments').doc('q-part').get()).data().testId, 't1');
});

test('restoring an archived test to draft preserves ownership and aggregates', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({
    questionId: 'q-restore-a',
    data: paperWiseQuestion({ id: 'q-restore-a', marks: 2 }),
  });
  await svc.createQuestion({
    questionId: 'q-restore-b',
    data: paperWiseQuestion({ id: 'q-restore-b', marks: 3 }),
  });
  await svc.createTest(
    {
      testId: 't-restore',
      data: draftTest({
        id: 't-restore',
        questionIds: ['q-restore-b', 'q-restore-a'],
      }),
    },
    { assignedBy: ACTOR },
  );

  await svc.setTestStatus(
    { testId: 't-restore', status: 'archived' },
    { assignedBy: ACTOR },
  );
  for (const id of ['q-restore-b', 'q-restore-a']) {
    const questionData = (await db.collection('questions').doc(id).get()).data();
    assert.equal(questionData.status, 'archived');
    assert.equal(questionData.isActive, false);
    assert.equal(
      (await db.collection('question_assignments').doc(id).get()).data().testId,
      't-restore',
    );
  }

  await svc.setTestStatus(
    { testId: 't-restore', status: 'draft' },
    { assignedBy: ACTOR },
  );

  const restored = (await db.collection('tests').doc('t-restore').get()).data();
  assert.equal(restored.status, 'draft');
  assert.equal(restored.isPublished, false);
  assert.deepEqual(restored.questionIds, ['q-restore-b', 'q-restore-a']);
  assert.equal(restored.questionCount, 2);
  assert.equal(restored.totalMarks, 5);
  assert.equal(restored.durationMinutes, 2);
  for (const id of restored.questionIds) {
    const questionData = (await db.collection('questions').doc(id).get()).data();
    assert.equal(questionData.status, 'draft');
    assert.equal(questionData.isActive, false);
    assert.equal(
      (await db.collection('question_assignments').doc(id).get()).data().testId,
      't-restore',
    );
  }
});

test('question context accepts chapter, paper-wise, grand, and previous shapes', () => {
  const chapter = validateQuestionPayload(chapterQuestion(), { documentId: 'q-chapter' });
  assert.equal(chapter.id, 'q-chapter');

  const paperWise = validateQuestionPayload(paperWiseQuestion(), { documentId: 'q-part' });
  assert.equal(paperWise.courseId, 'group-ii');
  assert.equal(paperWiseQuestion().partId, undefined);
  assert.throws(
    () => validateQuestionPayload(
      paperWiseQuestion({ id: 'q-part-field', partId: 'group-ii-paper-i-part' }),
      { documentId: 'q-part-field' },
    ),
    (err) => /cannot set partId/.test(err.message),
  );

  const paperTwo = validateQuestionPayload(
    paperWiseQuestion({
      id: 'q-paper-ii',
      paperId: 'group-ii-paper-ii',
    }),
    { documentId: 'q-paper-ii' },
  );
  assert.equal(paperTwo.id, 'q-paper-ii');

  validateQuestionPayload(
    question({
      id: 'q-grand',
      contentArea: 'testSeries',
      testSeriesCategory: 'mock',
      seriesId: 'Grand Test - I',
    }),
    { documentId: 'q-grand' },
  );

  validateQuestionPayload(
    question({
      id: 'q-year',
      contentArea: 'testSeries',
      testSeriesCategory: 'previousyear',
      year: 2016,
    }),
    { documentId: 'q-year' },
  );

  assert.throws(
    () => validateQuestionPayload(
      question({ id: 'q-bad', contentArea: 'testSeries' }),
      { documentId: 'q-bad' },
    ),
    (err) => /testSeriesCategory/.test(err.message),
  );
  assert.throws(
    () => validateQuestionPayload(
      chapterQuestion({ testSeriesCategory: 'part' }),
      { documentId: 'q-chapter' },
    ),
    (err) => /must not set testSeriesCategory/.test(err.message),
  );
  assert.throws(
    () => validateQuestionPayload(
      question({
        id: 'q-nopaper',
        contentArea: 'testSeries',
        testSeriesCategory: 'part',
      }),
      { documentId: 'q-nopaper' },
    ),
    (err) => /Paper is required/.test(err.message),
  );
  assert.throws(
    () => validateQuestionPayload(
      question({
        id: 'q-noseries',
        contentArea: 'testSeries',
        testSeriesCategory: 'mock',
      }),
      { documentId: 'q-noseries' },
    ),
    (err) => /Grand Test group/.test(err.message),
  );
  assert.throws(
    () => validateQuestionPayload(
      question({
        id: 'q-noyear',
        contentArea: 'testSeries',
        testSeriesCategory: 'previousyear',
      }),
      { documentId: 'q-noyear' },
    ),
    (err) => /exam year/.test(err.message),
  );
});

test('legacy question without contentArea remains readable', () => {
  const legacy = question({ id: 'q-legacy' });
  delete legacy.contentArea;
  delete legacy.testSeriesCategory;
  const parsed = validateQuestionPayload(legacy, { documentId: 'q-legacy' });
  assert.equal(parsed.id, 'q-legacy');
  assert.equal(legacy.contentArea, undefined);
});

test('legacy test questionIds are claimed once on the first admin save', async () => {
  const { db, svc } = harness();
  const legacy = question({ id: 'q-legacy' });
  delete legacy.contentArea;
  await db.collection('questions').doc('q-legacy').set(legacy);
  await db.collection('tests').doc('t-legacy').set(draftTest({
    id: 't-legacy',
    questionIds: ['q-legacy'],
    questionCount: 1,
    totalMarks: 1,
    durationMinutes: 30,
  }));

  await svc.updateTest(
    {
      testId: 't-legacy',
      data: draftTest({
        id: 't-legacy',
        questionIds: ['q-legacy'],
        questionCount: 1,
        totalMarks: 1,
        durationMinutes: 30,
      }),
    },
    { assignedBy: ACTOR },
  );
  await svc.updateTest(
    {
      testId: 't-legacy',
      data: draftTest({
        id: 't-legacy',
        questionIds: ['q-legacy'],
        questionCount: 8,
        totalMarks: 8,
        durationMinutes: 30,
      }),
    },
    { assignedBy: 'admin-2' },
  );

  const snaps = await db.collection('question_assignments').get();
  assert.equal(snaps.size, 1);
  assert.equal(snaps.docs[0].id, 'q-legacy');
  assert.equal(snaps.docs[0].data().testId, 't-legacy');
  assert.equal(snaps.docs[0].data().assignedBy, ACTOR);
  const storedQuestion = (await db.collection('questions').doc('q-legacy').get()).data();
  assert.equal(storedQuestion.contentArea, undefined);
  assert.equal((await db.collection('tests').doc('t-legacy').get()).data().questionCount, 1);
  assert.equal((await db.collection('tests').doc('t-legacy').get()).data().durationMinutes, 1);
});

test('competing claims of one question let exactly one test win', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({ questionId: 'q-race', data: paperWiseQuestion({ id: 'q-race' }) });
  const results = await Promise.allSettled([
    svc.createTest(
      { testId: 't-a', data: draftTest({ id: 't-a', questionIds: ['q-race'] }) },
      { assignedBy: 'admin-a' },
    ),
    svc.createTest(
      { testId: 't-b', data: draftTest({ id: 't-b', questionIds: ['q-race'] }) },
      { assignedBy: 'admin-b' },
    ),
  ]);
  assert.equal(results.filter((result) => result.status === 'fulfilled').length, 1);
  assert.equal(results.filter((result) => result.status === 'rejected').length, 1);

  const assignment = (await db.collection('question_assignments').doc('q-race').get()).data();
  assert.ok(assignment.testId === 't-a' || assignment.testId === 't-b');
  const winner = assignment.testId;
  const loser = winner === 't-a' ? 't-b' : 't-a';
  assert.equal((await db.collection('tests').doc(winner).get()).data().questionIds[0], 'q-race');
  assert.equal((await db.collection('tests').doc(loser).get()).exists, false);
});

test('assignment cap is the documented 160-question transaction budget', () => {
  const ids = Array.from({ length: MAX_ASSIGNED_QUESTIONS_PER_TEST + 1 }, (_, i) => `q-${i}`);
  assert.throws(
    () => validateTestPayload(draftTest({
      id: 't-cap',
      questionIds: ids,
      questionCount: ids.length,
      totalMarks: ids.length,
      durationMinutes: ids.length,
    }), { documentId: 't-cap' }),
    (err) => /at most 160/.test(err.message),
  );
  assert.equal(MAX_ASSIGNED_QUESTIONS_PER_TEST, 160);
});

test('a 150-question draft assignment commits in one save', async () => {
  const { db, svc } = harness();
  const ids = [];
  for (let i = 0; i < 150; i += 1) {
    const id = `q-${i}`;
    ids.push(id);
    await db.collection('questions').doc(id).set(paperWiseQuestion({
      id,
      marks: i === 0 ? undefined : 1,
    }));
  }
  await svc.createTest(
    {
      testId: 't-wide',
      data: draftTest({
        id: 't-wide',
        questionIds: ids,
        questionCount: 0,
        totalMarks: 0,
        durationMinutes: 0,
      }),
    },
    { assignedBy: ACTOR },
  );
  const stored = (await db.collection('tests').doc('t-wide').get()).data();
  assert.equal(stored.questionCount, 150);
  assert.equal(stored.durationMinutes, 150);
  assert.equal(stored.totalMarks, 150);
  assert.equal(stored.questionIds[0], 'q-0');
  assert.equal(stored.questionIds[149], 'q-149');
  assert.equal((await db.collection('question_assignments').get()).size, 150);
  const first = (await db.collection('questions').doc('q-0').get()).data();
  assert.equal(first.status, 'draft');
  assert.equal(first.isActive, false);
});

async function seedAssignedTest(db, svc, count, testId) {
  const ids = [];
  for (let i = 0; i < count; i += 1) {
    const id = `${testId}-q-${i}`;
    ids.push(id);
    await db.collection('questions').doc(id).set(paperWiseQuestion({ id, marks: 1 }));
  }
  await svc.createTest(
    {
      testId,
      data: draftTest({
        id: testId,
        questionIds: ids,
        questionCount: 0,
        totalMarks: 0,
        durationMinutes: 0,
      }),
    },
    { assignedBy: ACTOR },
  );
  return ids;
}

async function assertCoupledStatus(db, ids, status, isActive) {
  for (const id of ids) {
    const data = (await db.collection('questions').doc(id).get()).data();
    assert.equal(data.status, status);
    assert.equal(data.isActive, isActive);
    assert.equal((await db.collection('question_assignments').doc(id).get()).data().testId != null, true);
  }
}

test('publish, draft, and archive commit question status with the test', async () => {
  const { db, svc } = harness();
  const ids = await seedAssignedTest(db, svc, 2, 't-status');

  await svc.publishTest({ testId: 't-status' }, { assignedBy: ACTOR });
  const published = (await db.collection('tests').doc('t-status').get()).data();
  assert.equal(published.status, 'published');
  assert.equal(published.isPublished, true);
  await assertCoupledStatus(db, ids, 'published', true);

  await svc.setTestStatus({ testId: 't-status', status: 'draft' }, { assignedBy: ACTOR });
  const drafted = (await db.collection('tests').doc('t-status').get()).data();
  assert.equal(drafted.status, 'draft');
  assert.equal(drafted.isPublished, false);
  await assertCoupledStatus(db, ids, 'draft', false);

  await svc.setTestStatus({ testId: 't-status', status: 'archived' }, { assignedBy: ACTOR });
  const archived = (await db.collection('tests').doc('t-status').get()).data();
  assert.equal(archived.status, 'archived');
  assert.equal(archived.isPublished, false);
  await assertCoupledStatus(db, ids, 'archived', false);
});

test('a failed status transaction leaves the previous test and questions', async () => {
  const { db, svc } = harness();
  const ids = await seedAssignedTest(db, svc, 2, 't-atomic');
  const beforeTest = (await db.collection('tests').doc('t-atomic').get()).data();
  const beforeQuestions = [];
  for (const id of ids) {
    beforeQuestions.push((await db.collection('questions').doc(id).get()).data());
  }

  const original = db.runTransaction.bind(db);
  db.runTransaction = (updateFunction) => original(async (tx) => {
    await updateFunction(tx);
    const error = new Error('injected status failure');
    error.code = 'aborted';
    throw error;
  });

  await assert.rejects(
    () => svc.publishTest({ testId: 't-atomic' }, { assignedBy: ACTOR }),
    (err) => err.code === 'aborted',
  );

  const afterTest = (await db.collection('tests').doc('t-atomic').get()).data();
  assert.equal(afterTest.status, beforeTest.status);
  assert.equal(afterTest.isPublished, false);
  for (let i = 0; i < ids.length; i += 1) {
    const after = (await db.collection('questions').doc(ids[i]).get()).data();
    assert.equal(after.status, beforeQuestions[i].status);
    assert.equal(after.isActive, beforeQuestions[i].isActive);
    assert.equal((await db.collection('question_assignments').doc(ids[i]).get()).exists, true);
  }
});

test('assigned question status changes are rejected until the question is released', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({ questionId: 'q-free', data: paperWiseQuestion({ id: 'q-free' }) });
  await svc.setQuestionStatus({ questionId: 'q-free', status: 'archived' });
  assert.equal((await db.collection('questions').doc('q-free').get()).data().status, 'archived');

  await svc.createQuestion({ questionId: 'q-held', data: paperWiseQuestion({ id: 'q-held' }) });
  await svc.createTest(
    { testId: 't-held', data: draftTest({ id: 't-held', questionIds: ['q-held'] }) },
    { assignedBy: ACTOR },
  );
  await assert.rejects(
    () => svc.setQuestionStatus({ questionId: 'q-held', status: 'archived' }),
    (err) => err.code === 'failed-precondition' && /assigned to a test/.test(err.message),
  );
  const held = (await db.collection('questions').doc('q-held').get()).data();
  assert.equal(held.status, 'draft');
  assert.equal(held.isActive, false);

  await svc.updateTest(
    { testId: 't-held', data: draftTest({ id: 't-held', questionIds: [] }) },
    { assignedBy: ACTOR },
  );
  assert.equal((await db.collection('question_assignments').doc('q-held').get()).exists, false);
  await svc.setQuestionStatus({ questionId: 'q-held', status: 'archived' });
  assert.equal((await db.collection('questions').doc('q-held').get()).data().status, 'archived');
  assert.equal((await db.collection('questions').doc('q-held').get()).data().contentArea, 'testSeries');
});

test('150-question status transitions stay in one transaction', async () => {
  const { db, svc } = harness();
  const ids = await seedAssignedTest(db, svc, 150, 't-150');
  await svc.publishTest({ testId: 't-150' }, { assignedBy: ACTOR });
  await assertCoupledStatus(db, ids, 'published', true);
  assert.equal((await db.collection('tests').doc('t-150').get()).data().isPublished, true);

  await svc.setTestStatus({ testId: 't-150', status: 'draft' }, { assignedBy: ACTOR });
  await assertCoupledStatus(db, ids, 'draft', false);

  await svc.setTestStatus({ testId: 't-150', status: 'archived' }, { assignedBy: ACTOR });
  await assertCoupledStatus(db, ids, 'archived', false);
  assert.equal((await db.collection('question_assignments').get()).size, 150);
});

test('160 assigned questions can change status together and 161 cannot be assigned', async () => {
  const { db, svc } = harness();
  const ids = await seedAssignedTest(db, svc, 160, 't-160');
  await svc.publishTest({ testId: 't-160' }, { assignedBy: ACTOR });
  const stored = (await db.collection('tests').doc('t-160').get()).data();
  assert.equal(stored.status, 'published');
  assert.equal(stored.questionCount, 160);
  assert.equal((await db.collection('questions').doc(ids[0]).get()).data().status, 'published');
  assert.equal((await db.collection('questions').doc(ids[159]).get()).data().isActive, true);
  assert.equal((await db.collection('question_assignments').get()).size, 160);

  const tooMany = Array.from({ length: 161 }, (_, i) => `extra-${i}`);
  await assert.rejects(
    () => svc.createTest(
      {
        testId: 't-161',
        data: draftTest({
          id: 't-161',
          questionIds: tooMany,
          questionCount: 161,
          totalMarks: 161,
          durationMinutes: 161,
        }),
      },
      { assignedBy: ACTOR },
    ),
    (err) => /at most 160/.test(err.message),
  );
});

function expectCompatible(questionData, testData, questionId = questionData.id) {
  assert.doesNotThrow(
    () => assertQuestionCompatibleWithTest(questionData, testData, questionId),
  );
}

function expectIncompatible(questionData, testData, pattern, questionId = questionData.id) {
  assert.throws(
    () => assertQuestionCompatibleWithTest(questionData, testData, questionId),
    (err) => err.code === 'failed-precondition' && pattern.test(err.message),
  );
}

test('assignment compatibility: paper-wise matches paper, not part', () => {
  expectCompatible(paperWiseQuestion(), draftTest());
  expectIncompatible(
    paperWiseQuestion(),
    draftTest({
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
    }),
    /test paper/,
  );
});

test('assignment compatibility: grand matches series and does not require question paperId', () => {
  const q = grandQuestion();
  assert.equal(q.paperId, undefined);
  expectCompatible(q, mockTest());
  expectCompatible(q, mockTest({ paperId: 'group-ii-paper-i' }));
  expectIncompatible(
    q,
    mockTest({ seriesId: 'Grand Test - II' }),
    /test series/,
  );
});

test('assignment compatibility: previous matches year and does not require question paperId', () => {
  const q = previousQuestion();
  assert.equal(q.paperId, undefined);
  expectCompatible(q, previousPaperTest());
  expectCompatible(q, previousPaperTest({ paperId: 'group-ii-paper-i' }));
  expectIncompatible(
    q,
    previousPaperTest({ year: 2016 }),
    /test year/,
  );
});

test('assignment compatibility: wrong course or category fails', () => {
  expectIncompatible(
    paperWiseQuestion(),
    draftTest({ courseId: 'group-iii', paperId: 'group-iii-paper-i' }),
    /another course/,
  );
  expectIncompatible(paperWiseQuestion(), mockTest(), /test category/);
  expectIncompatible(grandQuestion(), previousPaperTest(), /test category/);
  expectIncompatible(previousQuestion(), draftTest(), /test category/);
});

test('assignment compatibility: chapter rules stay unchanged', () => {
  expectCompatible(chapterQuestion(), chapterTest());
  expectIncompatible(chapterQuestion(), mockTest(), /Chapter Question/);
  expectIncompatible(chapterQuestion(), previousPaperTest(), /Chapter Question/);
  expectIncompatible(
    chapterQuestion(),
    chapterTest({ paperId: 'group-ii-paper-ii', partId: 'group-ii-paper-ii-part-01', syllabusUnitId: 'group-ii-paper-ii-part-01-topic-01' }),
    /test paper/,
  );
});

test('assignment mutation: grand and previous use series/year, not question paperId', async () => {
  const { db, svc } = harness();
  await svc.createQuestion({ questionId: 'q-grand', data: grandQuestion({ id: 'q-grand' }) });
  await svc.createQuestion({ questionId: 'q-year', data: previousQuestion({ id: 'q-year' }) });

  const grandStored = (await db.collection('questions').doc('q-grand').get()).data();
  const yearStored = (await db.collection('questions').doc('q-year').get()).data();
  assert.equal(grandStored.paperId, undefined);
  assert.equal(yearStored.paperId, undefined);

  await svc.createTest(
    { testId: 't-grand', data: mockTest({ id: 't-grand', questionIds: ['q-grand'] }) },
    { assignedBy: ACTOR },
  );
  await svc.createTest(
    { testId: 't-year', data: previousPaperTest({ id: 't-year', questionIds: ['q-year'] }) },
    { assignedBy: ACTOR },
  );
  assert.equal(
    (await db.collection('question_assignments').doc('q-grand').get()).data().testId,
    't-grand',
  );
  assert.equal(
    (await db.collection('question_assignments').doc('q-year').get()).data().testId,
    't-year',
  );

  await svc.createQuestion({
    questionId: 'q-grand-ii',
    data: grandQuestion({ id: 'q-grand-ii', seriesId: 'Grand Test - II' }),
  });
  await svc.createQuestion({
    questionId: 'q-year-2016',
    data: previousQuestion({ id: 'q-year-2016', year: 2016 }),
  });
  await assert.rejects(
    () => svc.createTest(
      { testId: 't-grand-mismatch', data: mockTest({ id: 't-grand-mismatch', questionIds: ['q-grand-ii'] }) },
      { assignedBy: ACTOR },
    ),
    (err) => /test series/.test(err.message),
  );
  await assert.rejects(
    () => svc.createTest(
      { testId: 't-year-mismatch', data: previousPaperTest({ id: 't-year-mismatch', questionIds: ['q-year-2016'] }) },
      { assignedBy: ACTOR },
    ),
    (err) => /test year/.test(err.message),
  );
});

test('assignment mutation: part paper mismatch is rejected', async () => {
  const { svc } = harness();
  await svc.createQuestion({ questionId: 'q-part', data: paperWiseQuestion() });
  await assert.rejects(
    () => svc.createTest(
      {
        testId: 't-wrong-paper',
        data: draftTest({
          id: 't-wrong-paper',
          paperId: 'group-ii-paper-ii',
          questionIds: ['q-part'],
        }),
      },
      { assignedBy: ACTOR },
    ),
    (err) => /test paper/.test(err.message),
  );
});
