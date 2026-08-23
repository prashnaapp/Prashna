import assert from 'node:assert/strict';
import test from 'node:test';

import { FieldValue } from 'firebase-admin/firestore';

import { createAdminContentService } from '../src/admin_content_service.js';
import {
  decodeWriteData,
  FIELD_DELETE_SENTINEL,
  validateQuestionPayload,
  validateTestPayload,
} from '../src/content_validation_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

function validQuestion(overrides = {}) {
  return {
    id: 'q-valid-1',
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
    paperId: 'group-ii-paper-i',
    majorStudyAreaId: 'group-ii-paper-i-area-01',
    contentTopicId: 'group-ii-paper-i-area-01-topic-01',
    content: {
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
    },
    ...overrides,
  };
}

function validGroupIiiQuestion(overrides = {}) {
  return validQuestion({
    id: 'q-giii-1',
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    majorStudyAreaId: undefined,
    contentTopicId: undefined,
    syllabusUnitId: 'group-iii-paper-i-unit-01',
    ...overrides,
  });
}

function validTest(overrides = {}) {
  return {
    id: 't-valid-1',
    courseId: 'group-ii',
    title: 'Practice Test 1',
    description: '',
    category: 'part',
    questionCount: 1,
    totalMarks: 1,
    durationMinutes: 30,
    negativeMarks: 0,
    difficulty: 'Medium',
    questionIds: ['q-valid-1'],
    status: 'draft',
    isPublished: false,
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
    ...overrides,
  };
}

function publishedQuestion(overrides = {}) {
  return validQuestion({
    status: 'published',
    isActive: true,
    ...overrides,
  });
}

test('question: valid create payload is accepted', () => {
  assert.equal(
    validateQuestionPayload(validQuestion(), { documentId: 'q-valid-1' }).id,
    'q-valid-1',
  );
});

test('question: required fields, correct answer, and marks are rejected when invalid', () => {
  assert.throws(
    () => validateQuestionPayload(validQuestion({ question: '', content: null })),
    (err) => /Question text/.test(err.message),
  );
  assert.throws(
    () => validateQuestionPayload(validQuestion({ correctOption: 'Z' })),
    (err) => /Correct option/.test(err.message),
  );
  assert.throws(
    () => validateQuestionPayload(validQuestion({ marks: 0 })),
    (err) => /Marks/.test(err.message),
  );
  assert.throws(
    () => validateQuestionPayload(validQuestion({ id: 'other' }), { documentId: 'q-valid-1' }),
    (err) => /must match/.test(err.message),
  );
});

test('question: invalid bilingual structure is rejected for published canonical questions', () => {
  assert.throws(
    () => validateQuestionPayload(publishedQuestion({
      content: {
        en: {
          question: 'English',
          options: ['A', 'B', 'C', 'D'],
          explanation: 'Because',
        },
        te: {
          question: 'Telugu',
          options: ['A', 'B'],
          explanation: 'Because',
        },
      },
    })),
    (err) => /option counts/.test(err.message),
  );
});

test('question: invalid syllabus and cross-course scope are rejected', () => {
  assert.throws(
    () => validateQuestionPayload(validQuestion({
      paperId: 'group-iii-paper-i',
    })),
    (err) => /incompatible|does not belong/.test(err.message),
  );
  assert.throws(
    () => validateQuestionPayload(validQuestion({
      paperId: 'group-ii-paper-ii',
      partId: null,
      topicId: null,
    })),
    (err) => /Part and Topic/.test(err.message),
  );
  assert.throws(
    () => validateQuestionPayload(validGroupIiiQuestion({
      topicId: 'legacy-topic',
    })),
    (err) => /Paper \/ Part \/ Syllabus Unit/.test(err.message),
  );
});

test('question: invalid publication state is rejected', () => {
  assert.throws(
    () => validateQuestionPayload(validQuestion({ status: 'published', isActive: false })),
    (err) => /must be active/.test(err.message),
  );
});

test('decodeWriteData converts explicit clear sentinels to FieldValue.delete', () => {
  const decoded = decodeWriteData({
    topicId: { [FIELD_DELETE_SENTINEL]: true },
    syllabusUnitId: 'unit-a',
  });
  assert.equal(decoded.syllabusUnitId, 'unit-a');
  assert.equal(typeof decoded.topicId.isEqual, 'function');
  assert.equal(decoded.topicId.isEqual(FieldValue.delete()), true);
});

test('question service: create, update, and optional-field clearing', async () => {
  const isolated = new FakeFirestore();
  const svc = createAdminContentService(isolated);
  await svc.createQuestion({
    questionId: 'q-valid-1',
    data: validQuestion({ topicId: 'old-topic' }),
  });
  await svc.updateQuestion({
    questionId: 'q-valid-1',
    data: validQuestion({
      question: 'Updated stem',
      topicId: { [FIELD_DELETE_SENTINEL]: true },
      'syllabus.topicId': { [FIELD_DELETE_SENTINEL]: true },
    }),
  });
  const stored = (await isolated.collection('questions').doc('q-valid-1').get()).data();
  assert.equal(stored.question, 'Updated stem');
  assert.equal(stored.topicId, undefined);
  assert.equal(stored.courseId, 'group-ii');
  assert.equal(stored.id, 'q-valid-1');
});

test('question batch is atomic and rejects duplicate IDs', async () => {
  const isolated = new FakeFirestore();
  const svc = createAdminContentService(isolated);
  await assert.rejects(
    () => svc.createQuestionsBatch({
      items: [
        { questionId: 'dup', data: validQuestion({ id: 'dup' }) },
        { questionId: 'dup', data: validQuestion({ id: 'dup' }) },
      ],
    }),
    (err) => err.code === 'already-exists',
  );

  await svc.createQuestion({
    questionId: 'existing',
    data: validQuestion({ id: 'existing' }),
  });
  await assert.rejects(
    () => svc.createQuestionsBatch({
      items: [
        { questionId: 'new-a', data: validQuestion({ id: 'new-a' }) },
        { questionId: 'existing', data: validQuestion({ id: 'existing' }) },
      ],
    }),
    (err) => err.code === 'already-exists',
  );
  assert.equal((await isolated.collection('questions').doc('new-a').get()).exists, false);

  const result = await svc.createQuestionsBatch({
    items: [
      { questionId: 'batch-1', data: validQuestion({ id: 'batch-1' }) },
      { questionId: 'batch-2', data: validQuestion({ id: 'batch-2' }) },
    ],
  });
  assert.deepEqual(result.questionIds, ['batch-1', 'batch-2']);
});

test('test: valid create payload is accepted', () => {
  assert.equal(
    validateTestPayload(validTest({ questionIds: [] }), { documentId: 't-valid-1' }).id,
    't-valid-1',
  );
});

test('test: invalid metadata, category, status, and questionCount are rejected', () => {
  assert.throws(
    () => validateTestPayload(validTest({ title: '' })),
    (err) => /Title/.test(err.message),
  );
  assert.throws(
    () => validateTestPayload(validTest({ category: 'unknown' })),
    (err) => /Category/.test(err.message),
  );
  assert.throws(
    () => validateTestPayload(validTest({ status: 'published', isPublished: false })),
    (err) => /isPublished/.test(err.message),
  );
  assert.throws(
    () => validateTestPayload(validTest({ questionCount: 2, questionIds: ['q-valid-1'] })),
    (err) => /Question count/.test(err.message),
  );
  assert.throws(
    () => validateTestPayload(validTest({ paperId: 'group-iii-paper-i' })),
    (err) => /does not belong/.test(err.message),
  );
});

test('test service: assigned question invariants', async () => {
  const isolated = new FakeFirestore();
  const svc = createAdminContentService(isolated);
  await svc.createQuestion({
    questionId: 'q-valid-1',
    data: publishedQuestion(),
  });

  await svc.createTest({ testId: 't-valid-1', data: validTest() });

  await assert.rejects(
    () => svc.createTest({
      testId: 't-missing',
      data: validTest({ id: 't-missing', questionIds: ['missing-q'] }),
    }),
    (err) => /does not exist/.test(err.message),
  );

  await isolated.collection('questions').doc('q-inactive').set(
    publishedQuestion({ id: 'q-inactive', isActive: false, status: 'draft' }),
  );
  await assert.rejects(
    () => svc.createTest({
      testId: 't-inactive',
      data: validTest({ id: 't-inactive', questionIds: ['q-inactive'] }),
    }),
    (err) => /inactive/.test(err.message),
  );

  await svc.createQuestion({
    questionId: 'q-giii-1',
    data: validGroupIiiQuestion({ status: 'published', isActive: true }),
  });
  await assert.rejects(
    () => svc.createTest({
      testId: 't-cross',
      data: validTest({ id: 't-cross', questionIds: ['q-giii-1'] }),
    }),
    (err) => /another course/.test(err.message),
  );
});

test('publication re-reads the authoritative test and referenced questions', async () => {
  const isolated = new FakeFirestore();
  const svc = createAdminContentService(isolated);
  await svc.createQuestion({
    questionId: 'q-valid-1',
    data: publishedQuestion(),
  });
  await svc.createTest({ testId: 't-valid-1', data: validTest() });

  const published = await svc.publishTest({ testId: 't-valid-1' });
  assert.equal(published.isPublished, true);
  const stored = (await isolated.collection('tests').doc('t-valid-1').get()).data();
  assert.equal(stored.status, 'published');
  assert.equal(stored.isPublished, true);

  await isolated.collection('tests').doc('t-broken').set(
    validTest({ id: 't-broken', questionIds: ['ghost'], status: 'draft', isPublished: false }),
  );
  await assert.rejects(
    () => svc.publishTest({ testId: 't-broken' }),
    (err) => /does not exist/.test(err.message),
  );

  await isolated.collection('tests').doc('t-archived').set(
    validTest({ id: 't-archived', status: 'archived', isPublished: false, questionIds: [] }),
  );
  await assert.rejects(
    () => svc.publishTest({ testId: 't-archived' }),
    (err) => /Archived/.test(err.message),
  );

  await isolated.collection('questions').doc('q-valid-1').update({ isActive: false });
  await isolated.collection('tests').doc('t-stale').set(
    validTest({ id: 't-stale', status: 'draft', isPublished: false }),
  );
  await assert.rejects(
    () => svc.publishTest({ testId: 't-stale' }),
    (err) => /inactive/.test(err.message),
  );
});
