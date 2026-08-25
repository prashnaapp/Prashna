/**
 * Trusted Admin SDK writes for questions and tests.
 * Callers must already have passed assertAdmin().
 */
import { FieldValue } from 'firebase-admin/firestore';

import {
  MAX_QUESTION_BATCH,
  fail,
  prepareQuestionWrite,
  prepareTestWrite,
  trimToNull,
  validateQuestionPayload,
  validateTestPayload,
  assertQuestionCompatibleWithTest,
} from './content_validation_service.js';

function questionsCol(db) {
  return db.collection('questions');
}

function testsCol(db) {
  return db.collection('tests');
}

async function readQuestion(db, questionId, tx) {
  const ref = questionsCol(db).doc(questionId);
  const snap = tx ? await tx.get(ref) : await ref.get();
  return { ref, snap, data: snap.exists ? snap.data() : null };
}

async function readTest(db, testId, tx) {
  const ref = testsCol(db).doc(testId);
  const snap = tx ? await tx.get(ref) : await ref.get();
  return { ref, snap, data: snap.exists ? snap.data() : null };
}

async function assertAssignedQuestions(db, testData, questionIds, tx) {
  for (const questionId of questionIds) {
    const { data } = await readQuestion(db, questionId, tx);
    assertQuestionCompatibleWithTest(data, testData, questionId);
  }
}

export function createAdminContentService(db) {
  return {
    async createQuestion({ questionId, data } = {}) {
      const id = trimToNull(questionId) || trimToNull(data?.id);
      if (!id) fail('invalid-argument', 'Question ID is required.');
      const payload = prepareQuestionWrite(data || {}, { documentId: id });
      const ref = questionsCol(db).doc(id);
      const existing = await ref.get();
      if (existing.exists) {
        fail('already-exists', `Question already exists: ${id}.`);
      }
      await ref.create(payload);
      return { questionId: id };
    },

    async updateQuestion({ questionId, data } = {}) {
      const id = trimToNull(questionId) || trimToNull(data?.id);
      if (!id) fail('invalid-argument', 'Question ID is required.');
      const { snap, data: existing } = await readQuestion(db, id);
      if (!snap.exists) fail('not-found', 'Question was not found.');
      const payload = prepareQuestionWrite(data || {}, {
        documentId: id,
        forUpdate: true,
        existing,
      });
      await questionsCol(db).doc(id).update(payload);
      return { questionId: id };
    },

    async createQuestionsBatch({ items } = {}) {
      if (!Array.isArray(items) || items.length === 0) {
        return { questionIds: [] };
      }
      if (items.length > MAX_QUESTION_BATCH) {
        fail(
          'invalid-argument',
          `Batch import supports at most ${MAX_QUESTION_BATCH} questions per request.`,
        );
      }

      const prepared = [];
      const seen = new Set();
      for (const item of items) {
        const id = trimToNull(item?.questionId) || trimToNull(item?.data?.id);
        if (!id) fail('invalid-argument', 'Question ID is required.');
        if (seen.has(id)) {
          fail('already-exists', `Duplicate question ID in batch: ${id}.`);
        }
        seen.add(id);
        prepared.push({
          questionId: id,
          data: prepareQuestionWrite(item.data || {}, { documentId: id }),
        });
      }

      await db.runTransaction(async (tx) => {
        const collisions = [];
        const refs = prepared.map((item) => questionsCol(db).doc(item.questionId));
        for (let i = 0; i < refs.length; i += 1) {
          const snap = await tx.get(refs[i]);
          if (snap.exists) collisions.push(prepared[i].questionId);
        }
        if (collisions.length > 0) {
          fail('already-exists', `Question already exists: ${collisions.join(', ')}.`);
        }
        for (let i = 0; i < refs.length; i += 1) {
          tx.set(refs[i], prepared[i].data);
        }
      });

      return { questionIds: prepared.map((item) => item.questionId) };
    },

    async setQuestionStatus({ questionId, status } = {}) {
      const id = trimToNull(questionId);
      const nextStatus = trimToNull(status);
      if (!id) fail('invalid-argument', 'Question ID is required.');
      if (!nextStatus) fail('invalid-argument', 'Question status is required.');

      const { snap, data } = await readQuestion(db, id);
      if (!snap.exists) fail('not-found', 'Question was not found.');

      const next = {
        ...data,
        status: nextStatus,
        isActive: nextStatus === 'published',
      };
      if (nextStatus === 'published') {
        validateQuestionPayload(next, { documentId: id });
      } else if (!['draft', 'archived'].includes(nextStatus)) {
        fail('invalid-argument', `Invalid question status "${nextStatus}".`);
      }
      await questionsCol(db).doc(id).update({
        status: nextStatus,
        isActive: nextStatus === 'published',
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { questionId: id, status: nextStatus };
    },

    async setQuestionActive({ questionId, isActive } = {}) {
      const id = trimToNull(questionId);
      if (!id) fail('invalid-argument', 'Question ID is required.');
      if (typeof isActive !== 'boolean') {
        fail('invalid-argument', 'isActive must be a boolean.');
      }
      const { snap, data } = await readQuestion(db, id);
      if (!snap.exists) fail('not-found', 'Question was not found.');

      if (isActive) {
        const next = {
          ...data,
          status: 'published',
          isActive: true,
        };
        validateQuestionPayload(next, { documentId: id });
        await questionsCol(db).doc(id).update({
          status: 'published',
          isActive: true,
          updatedAt: FieldValue.serverTimestamp(),
        });
        return { questionId: id, isActive: true, status: 'published' };
      }

      const currentStatus = trimToNull(data.status);
      const patch = {
        isActive: false,
        updatedAt: FieldValue.serverTimestamp(),
      };
      // Keep published => active. Deactivate availability without publishing.
      if (currentStatus === 'published') {
        patch.status = 'archived';
      }
      await questionsCol(db).doc(id).update(patch);
      return {
        questionId: id,
        isActive: false,
        status: patch.status || currentStatus,
      };
    },

    async createTest({ testId, data } = {}) {
      const id = trimToNull(testId) || trimToNull(data?.id);
      if (!id) fail('invalid-argument', 'Test ID is required.');
      const payload = prepareTestWrite(
        { ...(data || {}), status: 'draft', isPublished: false, id },
        { documentId: id },
      );
      payload.status = 'draft';
      payload.isPublished = false;
      if (payload.questionIds?.length) {
        await assertAssignedQuestions(db, payload, payload.questionIds);
      }
      const ref = testsCol(db).doc(id);
      const existing = await ref.get();
      if (existing.exists) fail('already-exists', `Test already exists: ${id}.`);
      await ref.create(payload);
      return { testId: id };
    },

    async updateTest({ testId, data } = {}) {
      const id = trimToNull(testId) || trimToNull(data?.id);
      if (!id) fail('invalid-argument', 'Test ID is required.');
      const payload = prepareTestWrite(data || {}, { documentId: id, forUpdate: true });
      const { snap } = await readTest(db, id);
      if (!snap.exists) fail('not-found', 'Test was not found.');
      if (payload.questionIds?.length) {
        await assertAssignedQuestions(db, payload, payload.questionIds);
      }
      await testsCol(db).doc(id).update(payload);
      return { testId: id };
    },

    async publishTest({ testId } = {}) {
      const id = trimToNull(testId);
      if (!id) fail('invalid-argument', 'Test ID is required.');

      await db.runTransaction(async (tx) => {
        const { snap, data, ref } = await readTest(db, id, tx);
        if (!snap.exists) fail('not-found', 'Test was not found.');
        if (trimToNull(data.status) === 'archived') {
          fail('failed-precondition', 'Archived tests cannot be published.');
        }

        const authoritative = {
          ...data,
          status: 'published',
          isPublished: true,
        };
        const validated = validateTestPayload(authoritative, {
          documentId: id,
          requireExistingId: true,
        });
        if (validated.questionIds.length) {
          await assertAssignedQuestions(db, authoritative, validated.questionIds, tx);
        }
        tx.update(ref, {
          status: 'published',
          isPublished: true,
        });
      });

      return { testId: id, status: 'published', isPublished: true };
    },

    async setTestStatus({ testId, status } = {}) {
      const id = trimToNull(testId);
      const nextStatus = trimToNull(status);
      if (!id) fail('invalid-argument', 'Test ID is required.');
      if (!nextStatus) fail('invalid-argument', 'Test status is required.');
      if (nextStatus === 'published') {
        return this.publishTest({ testId: id });
      }
      if (!['draft', 'archived'].includes(nextStatus)) {
        fail('invalid-argument', `Invalid test status "${nextStatus}".`);
      }
      const { snap } = await readTest(db, id);
      if (!snap.exists) fail('not-found', 'Test was not found.');
      await testsCol(db).doc(id).update({
        status: nextStatus,
        isPublished: false,
      });
      return { testId: id, status: nextStatus, isPublished: false };
    },
  };
}
