import assert from 'node:assert/strict';
import test from 'node:test';

import { assertAdmin } from '../src/callables.js';
import { createAdminContentService } from '../src/admin_content_service.js';
import { FakeFirestore } from './fake_firestore.mjs';

function adminRequest(data = {}) {
  return {
    auth: { uid: 'admin-1', token: { admin: true } },
    data,
  };
}

async function invoke(handler, request) {
  assertAdmin(request);
  const svc = request._service || createAdminContentService(new FakeFirestore());
  return handler(svc, request.data || {});
}

test('admin content callables reject unauthenticated and non-admin callers', () => {
  assert.throws(
    () => assertAdmin({ auth: null, data: {} }),
    (err) => err.code === 'unauthenticated',
  );
  assert.throws(
    () => assertAdmin({ auth: { uid: 'student', token: {} }, data: { isAdmin: true, admin: true } }),
    (err) => err.code === 'permission-denied',
  );
  assert.doesNotThrow(() => assertAdmin(adminRequest({ isAdmin: false })));
});

test('client-supplied admin flags never grant access', () => {
  assert.throws(
    () => assertAdmin({
      auth: { uid: 'spoof', token: { isAdmin: true } },
      data: { admin: true, isAdmin: true },
    }),
    (err) => err.code === 'permission-denied',
  );
});

test('admin create question is accepted after claim check', async () => {
  const db = new FakeFirestore();
  const svc = createAdminContentService(db);
  const result = await invoke(
    (content, data) => content.createQuestion(data),
    {
      ...adminRequest({
        questionId: 'q-valid-1',
        data: {
          id: 'q-valid-1',
          courseId: 'group-ii',
          question: 'Capital?',
          options: ['Hyderabad', 'Warangal'],
          correctOption: 'A',
          explanation: 'Hyderabad',
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
        },
      }),
      _service: svc,
    },
  );
  assert.equal(result.questionId, 'q-valid-1');
  assert.equal((await db.collection('questions').doc('q-valid-1').get()).exists, true);
});

function draftQuestionData(id) {
  return {
    id,
    courseId: 'group-ii',
    question: 'Capital?',
    options: ['Hyderabad', 'Warangal'],
    correctOption: 'A',
    explanation: 'Hyderabad',
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
  };
}

test('adminSetQuestionActive: draft + activate becomes published', async () => {
  const db = new FakeFirestore();
  const svc = createAdminContentService(db);
  await svc.createQuestion({
    questionId: 'q-draft-1',
    data: draftQuestionData('q-draft-1'),
  });

  const result = await invoke(
    (content, data) => content.setQuestionActive(data),
    {
      ...adminRequest({ questionId: 'q-draft-1', isActive: true }),
      _service: svc,
    },
  );

  assert.equal(result.isActive, true);
  assert.equal(result.status, 'published');
  const stored = (await db.collection('questions').doc('q-draft-1').get()).data();
  assert.equal(stored.isActive, true);
  assert.equal(stored.status, 'published');
});

test('adminSetQuestionActive: published + deactivate is allowed without publishing', async () => {
  const db = new FakeFirestore();
  const svc = createAdminContentService(db);
  await svc.createQuestion({
    questionId: 'q-pub-1',
    data: { ...draftQuestionData('q-pub-1'), status: 'published', isActive: true },
  });

  const result = await invoke(
    (content, data) => content.setQuestionActive(data),
    {
      ...adminRequest({ questionId: 'q-pub-1', isActive: false }),
      _service: svc,
    },
  );

  assert.equal(result.isActive, false);
  assert.notEqual(result.status, 'published');
  const stored = (await db.collection('questions').doc('q-pub-1').get()).data();
  assert.equal(stored.isActive, false);
  assert.equal(stored.status, 'archived');
});

test('adminSetQuestionActive: published + activate is allowed', async () => {
  const db = new FakeFirestore();
  const svc = createAdminContentService(db);
  await svc.createQuestion({
    questionId: 'q-pub-2',
    data: { ...draftQuestionData('q-pub-2'), status: 'published', isActive: true },
  });

  const result = await invoke(
    (content, data) => content.setQuestionActive(data),
    {
      ...adminRequest({ questionId: 'q-pub-2', isActive: true }),
      _service: svc,
    },
  );

  assert.equal(result.isActive, true);
  assert.equal(result.status, 'published');
  const stored = (await db.collection('questions').doc('q-pub-2').get()).data();
  assert.equal(stored.isActive, true);
  assert.equal(stored.status, 'published');
});

test('adminSetQuestionActive: non-admin is rejected', () => {
  assert.throws(
    () => assertAdmin({
      auth: { uid: 'student', token: {} },
      data: { questionId: 'q-pub-1', isActive: true, isAdmin: true, admin: true },
    }),
    (err) => err.code === 'permission-denied',
  );
});

test('adminUpdateQuestion: non-admin is still rejected', () => {
  assert.throws(
    () => assertAdmin({
      auth: { uid: 'student', token: {} },
      data: {
        questionId: 'q-legacy-1',
        isAdmin: true,
        admin: true,
        data: { paperId: 'paper-1' },
      },
    }),
    (err) => err.code === 'permission-denied',
  );
});

test('adminUpdateQuestion: existing legacy Group-II paper-1 can be updated', async () => {
  const db = new FakeFirestore();
  const svc = createAdminContentService(db);
  await db.collection('questions').doc('q-legacy-1').set({
    id: 'q-legacy-1',
    courseId: 'group-ii',
    paperId: 'paper-1',
    sectionId: 'section-1',
    topicId: 'topic-1',
    question: 'Legacy stem?',
    options: ['A', 'B', 'C', 'D'],
    correctOption: 'A',
    explanation: 'Because',
    difficulty: 'easy',
    questionType: 'practice',
    language: 'en',
    marks: 1,
    negativeMarks: 0,
    estimatedTimeSeconds: 60,
    isActive: false,
  });

  const result = await invoke(
    (content, data) => content.updateQuestion(data),
    {
      ...adminRequest({
        questionId: 'q-legacy-1',
        data: {
          id: 'q-legacy-1',
          courseId: 'group-ii',
          paperId: 'paper-1',
          sectionId: 'section-1',
          topicId: 'topic-1',
          question: 'Updated legacy stem?',
          options: ['A', 'B', 'C', 'D'],
          correctOption: 'A',
          explanation: 'Because',
          difficulty: 'easy',
          questionType: 'practice',
          language: 'en',
          marks: 1,
          negativeMarks: 0,
          estimatedTimeSeconds: 60,
          isActive: false,
        },
      }),
      _service: svc,
    },
  );

  assert.equal(result.questionId, 'q-legacy-1');
  const stored = (await db.collection('questions').doc('q-legacy-1').get()).data();
  assert.equal(stored.question, 'Updated legacy stem?');
  assert.equal(stored.paperId, 'paper-1');
  assert.equal(stored.sectionId, 'section-1');
  assert.equal(stored.topicId, 'topic-1');
});
