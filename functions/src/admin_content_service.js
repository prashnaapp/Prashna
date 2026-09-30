/**
 * Trusted Admin SDK writes for questions and tests.
 * Callers must already have passed assertAdmin().
 */
import { FieldValue } from 'firebase-admin/firestore';

import {
  MAX_QUESTION_BATCH,
  QUESTION_ASSIGNMENTS_COLLECTION,
  fail,
  prepareQuestionWrite,
  prepareTestWrite,
  trimToNull,
  validateQuestionPayload,
  validateTestPayload,
  assertQuestionCompatibleWithTest,
  orderedUniqueQuestionIds,
} from './content_validation_service.js';

function questionsCol(db) {
  return db.collection('questions');
}

function testsCol(db) {
  return db.collection('tests');
}

function assignmentsCol(db) {
  return db.collection(QUESTION_ASSIGNMENTS_COLLECTION);
}

function actorId(assignedBy) {
  return trimToNull(assignedBy) || 'server';
}

function questionPublicationForTestStatus(status) {
  if (status === 'published') return { status: 'published', isActive: true };
  if (status === 'archived') return { status: 'archived', isActive: false };
  return { status: 'draft', isActive: false };
}

function marksValue(data) {
  const marks = Number(data?.marks);
  return Number.isFinite(marks) && marks > 0 ? marks : 1;
}

function sumMarks(questionDocs) {
  return questionDocs.reduce((total, doc) => total + marksValue(doc?.data), 0);
}

function assignmentAggregates(testData, questionDocs, questionIds) {
  if (questionIds.length > 0) {
    return {
      questionCount: questionIds.length,
      totalMarks: sumMarks(questionDocs),
      durationMinutes: questionIds.length,
    };
  }
  return {
    questionCount: Number(testData.questionCount),
    totalMarks: Number(testData.totalMarks ?? testData.marks ?? 0),
    durationMinutes: Number(testData.durationMinutes),
  };
}

function rejectAssignedStatusChange(questionId) {
  fail(
    'failed-precondition',
    `Question "${questionId}" is assigned to a test. Change the test status, or remove the question from the test, before changing its status.`,
  );
}

function effectiveQuestionStatus(data) {
  const status = trimToNull(data?.status);
  if (status) return status;
  return data?.isActive === true ? 'published' : 'draft';
}

async function readQuestionForDelete(db, tx, questionId) {
  const { snap, data, ref } = await readQuestion(db, questionId, tx);
  if (!snap.exists) fail('not-found', 'Question was not found.');

  const status = effectiveQuestionStatus(data);
  if (status === 'published') {
    fail(
      'failed-precondition',
      `Question "${questionId}" is published and cannot be deleted.`,
    );
  }
  if (!['draft', 'archived'].includes(status)) {
    fail(
      'failed-precondition',
      `Question "${questionId}" cannot be deleted while status is "${status}".`,
    );
  }

  const assignment = await tx.get(assignmentsCol(db).doc(questionId));
  if (assignment.exists) {
    const owner = trimToNull(assignment.data()?.testId);
    fail(
      'failed-precondition',
      owner
        ? `Question "${questionId}" is assigned to test "${owner}". Remove it from the test before deleting.`
        : `Question "${questionId}" has an ownership record and cannot be deleted.`,
    );
  }

  const testsSnap = await tx.get(
    testsCol(db).where('questionIds', 'array-contains', questionId),
  );
  if (!testsSnap.empty) {
    const testIds = testsSnap.docs.map((doc) => doc.id);
    fail(
      'failed-precondition',
      `Question "${questionId}" is still referenced by test(s): ${testIds.join(', ')}. Remove it from the test before deleting.`,
    );
  }

  return { ref };
}

/**
 * Claim/release assignment docs, align assigned question status, and return
 * server aggregates. Every read happens before any write. Must run inside the
 * same transaction as the test write. Does not delete Question documents and
 * does not change contentArea. Released questions become draft/inactive.
 */
async function syncAssignmentsInTransaction(db, tx, {
  testId,
  courseId,
  testData,
  previousIds,
  nextIds,
  assignedBy,
  targetStatus,
}) {
  const loaded = [];
  const previousSet = new Set(previousIds);
  for (const questionId of nextIds) {
    const question = await readQuestion(db, questionId, tx);
    if (
      trimToNull(question.data?.status) === 'archived'
      && !previousSet.has(questionId)
    ) {
      fail(
        'failed-precondition',
        `Archived Question "${questionId}" cannot be assigned to a test.`,
      );
    }
    assertQuestionCompatibleWithTest(question.data, testData, questionId);
    if (targetStatus === 'published') {
      validateQuestionPayload(
        { ...question.data, status: 'published', isActive: true },
        { documentId: questionId },
      );
    }
    loaded.push(question);
  }

  const nextSet = new Set(nextIds);
  const released = new Map();
  for (const questionId of previousIds) {
    if (nextSet.has(questionId)) continue;
    const question = await readQuestion(db, questionId, tx);
    if (question.snap.exists) released.set(questionId, question);
  }

  const assignmentIds = [];
  const seenAssignments = new Set();
  for (const questionId of [...previousIds, ...nextIds]) {
    if (seenAssignments.has(questionId)) continue;
    seenAssignments.add(questionId);
    assignmentIds.push(questionId);
  }
  const assignments = new Map();
  for (const questionId of assignmentIds) {
    const ref = assignmentsCol(db).doc(questionId);
    assignments.set(questionId, { ref, snap: await tx.get(ref) });
  }

  for (const questionId of previousIds) {
    if (nextSet.has(questionId)) continue;
    const { ref, snap } = assignments.get(questionId);
    if (!snap.exists) continue;
    const owner = trimToNull(snap.data()?.testId);
    if (owner === testId) tx.delete(ref);
  }

  for (const questionId of nextIds) {
    const { ref, snap } = assignments.get(questionId);
    if (!snap.exists) {
      tx.set(ref, {
        questionId,
        testId,
        courseId,
        assignedAt: FieldValue.serverTimestamp(),
        assignedBy,
      });
      continue;
    }
    const owner = trimToNull(snap.data()?.testId);
    if (owner !== testId) {
      fail(
        'failed-precondition',
        `Question "${questionId}" is already assigned to another test.`,
      );
    }
  }

  const publication = questionPublicationForTestStatus(targetStatus);
  for (const question of loaded) {
    tx.update(question.ref, {
      status: publication.status,
      isActive: publication.isActive,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  for (const [questionId, question] of released.entries()) {
    const assignment = assignments.get(questionId)?.snap;
    const owner = assignment?.exists
      ? trimToNull(assignment.data()?.testId)
      : null;
    if (owner && owner !== testId) continue;
    tx.update(question.ref, {
      status: 'draft',
      isActive: false,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  return assignmentAggregates(testData, loaded, nextIds);
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
      await db.runTransaction(async (tx) => {
        const { snap, data: existing, ref } = await readQuestion(db, id, tx);
        if (!snap.exists) fail('not-found', 'Question was not found.');
        const payload = prepareQuestionWrite(data || {}, {
          documentId: id,
          forUpdate: true,
          existing,
        });
        const assignment = await tx.get(assignmentsCol(db).doc(id));
        const nextStatus = trimToNull(payload.status);
        const statusChanging = (nextStatus != null && nextStatus !== trimToNull(existing?.status))
          || (typeof payload.isActive === 'boolean' && payload.isActive !== existing?.isActive);
        if (assignment.exists && statusChanging) {
          rejectAssignedStatusChange(id);
        }
        if (
          assignment.exists
          && Number(existing?.marks) !== Number(payload.marks)
        ) {
          const assignedTestId = trimToNull(assignment.data()?.testId);
          if (assignedTestId) {
            const test = await readTest(db, assignedTestId, tx);
            if (test.snap.exists) {
              const ids = orderedUniqueQuestionIds(test.data?.questionIds);
              let totalMarks = 0;
              for (const assignedQuestionId of ids) {
                if (assignedQuestionId === id) {
                  totalMarks += marksValue(payload);
                  continue;
                }
                const assignedQuestion = await readQuestion(db, assignedQuestionId, tx);
                totalMarks += marksValue(assignedQuestion.data);
              }
              tx.update(test.ref, {
                questionCount: ids.length,
                totalMarks,
                durationMinutes: ids.length,
              });
            }
          }
        }
        tx.update(ref, payload);
      });
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

      await db.runTransaction(async (tx) => {
        const { snap, data, ref } = await readQuestion(db, id, tx);
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
        const assignment = await tx.get(assignmentsCol(db).doc(id));
        if (assignment.exists) rejectAssignedStatusChange(id);
        tx.update(ref, {
          status: nextStatus,
          isActive: nextStatus === 'published',
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
      return { questionId: id, status: nextStatus };
    },

    async deleteQuestion({ questionId } = {}) {
      const id = trimToNull(questionId);
      if (!id) fail('invalid-argument', 'Question ID is required.');
      await db.runTransaction(async (tx) => {
        const { ref } = await readQuestionForDelete(db, tx, id);
        tx.delete(ref);
      });
      return { questionId: id, deleted: true };
    },

    async setQuestionActive({ questionId, isActive } = {}) {
      const id = trimToNull(questionId);
      if (!id) fail('invalid-argument', 'Question ID is required.');
      if (typeof isActive !== 'boolean') {
        fail('invalid-argument', 'isActive must be a boolean.');
      }
      let result;
      await db.runTransaction(async (tx) => {
        const { snap, data, ref } = await readQuestion(db, id, tx);
        if (!snap.exists) fail('not-found', 'Question was not found.');
        const assignment = await tx.get(assignmentsCol(db).doc(id));
        if (assignment.exists) rejectAssignedStatusChange(id);

        if (isActive) {
          const next = {
            ...data,
            status: 'published',
            isActive: true,
          };
          validateQuestionPayload(next, { documentId: id });
          tx.update(ref, {
            status: 'published',
            isActive: true,
            updatedAt: FieldValue.serverTimestamp(),
          });
          result = { questionId: id, isActive: true, status: 'published' };
          return;
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
        tx.update(ref, patch);
        result = {
          questionId: id,
          isActive: false,
          status: patch.status || currentStatus,
        };
      });
      return result;
    },

    async getQuestionAssignments({ questionIds } = {}) {
      if (!Array.isArray(questionIds) || questionIds.length > 500) {
        fail(
          'invalid-argument',
          'Question assignment lookup supports at most 500 question IDs.',
        );
      }
      const ids = [];
      const seen = new Set();
      for (const value of questionIds) {
        const id = trimToNull(value);
        if (!id || seen.has(id)) continue;
        seen.add(id);
        ids.push(id);
      }
      if (ids.length === 0) return { assignments: [] };

      const snapshots = await db.getAll(
        ...ids.map((id) => assignmentsCol(db).doc(id)),
      );
      const legacyReferences = new Map(ids.map((id) => [id, new Set()]));
      for (let i = 0; i < ids.length; i += 30) {
        const chunk = ids.slice(i, i + 30);
        const tests = await testsCol(db)
          .where('questionIds', 'array-contains-any', chunk)
          .get();
        for (const test of tests.docs) {
          const questionIds = Array.isArray(test.data()?.questionIds)
            ? test.data().questionIds
            : [];
          for (const questionId of chunk) {
            if (questionIds.includes(questionId)) {
              legacyReferences.get(questionId).add(test.id);
            }
          }
        }
      }
      return {
        assignments: snapshots
          .filter((snapshot) => snapshot.exists)
          .map((snapshot) => ({
            questionId: snapshot.id,
            testId: trimToNull(snapshot.data()?.testId),
          }))
          .filter((assignment) => assignment.testId),
        legacyReferences: [...legacyReferences.entries()]
          .filter(([, testIds]) => testIds.size > 0)
          .map(([questionId, testIds]) => ({
            questionId,
            testIds: [...testIds],
          })),
      };
    },

    async createTest({ testId, data } = {}, options = {}) {
      const id = trimToNull(testId) || trimToNull(data?.id);
      if (!id) fail('invalid-argument', 'Test ID is required.');
      const assignedBy = actorId(options.assignedBy);
      const payload = prepareTestWrite(
        { ...(data || {}), status: 'draft', isPublished: false, id },
        { documentId: id },
      );
      payload.status = 'draft';
      payload.isPublished = false;
      delete payload.assignedBy;
      if (payload.negativeMarks == null) payload.negativeMarks = 0;
      const nextIds = orderedUniqueQuestionIds(payload.questionIds);
      const ref = testsCol(db).doc(id);

      const aggregates = await db.runTransaction(async (tx) => {
        const existing = await tx.get(ref);
        if (existing.exists) fail('already-exists', `Test already exists: ${id}.`);
        const totals = await syncAssignmentsInTransaction(db, tx, {
          testId: id,
          courseId: payload.courseId,
          testData: { ...payload, questionIds: nextIds },
          previousIds: [],
          nextIds,
          assignedBy,
          targetStatus: 'draft',
        });
        tx.set(ref, {
          ...payload,
          questionIds: nextIds,
          ...totals,
        });
        return totals;
      });

      return { testId: id, ...aggregates, status: 'draft', isPublished: false };
    },

    async updateTest({ testId, data, preserveQuestionAssignments = false } = {}, options = {}) {
      const id = trimToNull(testId) || trimToNull(data?.id);
      if (!id) fail('invalid-argument', 'Test ID is required.');
      const assignedBy = actorId(options.assignedBy);
      const ref = testsCol(db).doc(id);
      let writtenStatus;

      const aggregates = await db.runTransaction(async (tx) => {
        const current = await readTest(db, id, tx);
        if (!current.snap.exists) fail('not-found', 'Test was not found.');
        const previousIds = orderedUniqueQuestionIds(current.data?.questionIds);
        const intended = preserveQuestionAssignments === true
          ? { ...(data || {}), questionIds: previousIds }
          : (data || {});
        const payload = prepareTestWrite(intended, {
          documentId: id,
          forUpdate: true,
        });
        delete payload.assignedBy;
        if (payload.negativeMarks == null) payload.negativeMarks = 0;
        const nextIds = preserveQuestionAssignments === true
          ? previousIds
          : orderedUniqueQuestionIds(payload.questionIds);
        const totals = await syncAssignmentsInTransaction(db, tx, {
          testId: id,
          courseId: payload.courseId,
          testData: { ...payload, questionIds: nextIds },
          previousIds,
          nextIds,
          assignedBy,
          targetStatus: payload.status,
        });
        tx.update(ref, {
          ...payload,
          questionIds: nextIds,
          ...totals,
        });
        writtenStatus = payload.status;
        return totals;
      });

      return {
        testId: id,
        ...aggregates,
        status: writtenStatus,
        isPublished: writtenStatus === 'published',
      };
    },

    async publishTest({ testId } = {}, options = {}) {
      const id = trimToNull(testId);
      if (!id) fail('invalid-argument', 'Test ID is required.');
      const assignedBy = actorId(options.assignedBy);
      const ref = testsCol(db).doc(id);
      let nextIds = [];

      const aggregates = await db.runTransaction(async (tx) => {
        const current = await readTest(db, id, tx);
        if (!current.snap.exists) fail('not-found', 'Test was not found.');
        if (trimToNull(current.data?.status) === 'archived') {
          fail('failed-precondition', 'Archived tests cannot be published.');
        }
        const authoritative = {
          ...current.data,
          id,
          status: 'published',
          isPublished: true,
        };
        const validated = validateTestPayload(authoritative, {
          documentId: id,
          requireExistingId: true,
        });
        nextIds = validated.questionIds;
        const previousIds = orderedUniqueQuestionIds(current.data?.questionIds);
        const totals = await syncAssignmentsInTransaction(db, tx, {
          testId: id,
          courseId: validated.courseId,
          testData: authoritative,
          previousIds,
          nextIds,
          assignedBy,
          targetStatus: 'published',
        });
        tx.update(ref, {
          status: 'published',
          isPublished: true,
          questionIds: nextIds,
          ...totals,
        });
        return totals;
      });

      return { testId: id, status: 'published', isPublished: true, ...aggregates };
    },

    async setTestStatus({ testId, status } = {}, options = {}) {
      const id = trimToNull(testId);
      const nextStatus = trimToNull(status);
      if (!id) fail('invalid-argument', 'Test ID is required.');
      if (!nextStatus) fail('invalid-argument', 'Test status is required.');
      if (nextStatus === 'published') {
        return this.publishTest({ testId: id }, options);
      }
      if (!['draft', 'archived'].includes(nextStatus)) {
        fail('invalid-argument', `Invalid test status "${nextStatus}".`);
      }
      const assignedBy = actorId(options.assignedBy);
      const ref = testsCol(db).doc(id);
      let nextIds = [];

      await db.runTransaction(async (tx) => {
        const current = await readTest(db, id, tx);
        if (!current.snap.exists) fail('not-found', 'Test was not found.');
        nextIds = orderedUniqueQuestionIds(current.data?.questionIds);
        const authoritative = {
          ...current.data,
          id,
          status: nextStatus,
          isPublished: false,
          questionIds: nextIds,
        };
        validateTestPayload(authoritative, {
          documentId: id,
          requireExistingId: true,
        });
        const totals = await syncAssignmentsInTransaction(db, tx, {
          testId: id,
          courseId: authoritative.courseId,
          testData: authoritative,
          previousIds: nextIds,
          nextIds,
          assignedBy,
          targetStatus: nextStatus,
        });
        tx.update(ref, {
          status: nextStatus,
          isPublished: false,
          questionIds: nextIds,
          ...totals,
        });
      });

      return { testId: id, status: nextStatus, isPublished: false };
    },
  };
}
