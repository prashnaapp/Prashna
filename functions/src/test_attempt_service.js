/**
 * Server-authoritative test attempt lifecycle.
 *
 * startAttempt → in_progress snapshot
 * submitAttempt → verified scoring + idempotent side-effect markers
 *
 * Clients must never write authoritative score/result fields.
 */
import { randomUUID } from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

import { assertCourseAccess } from './course_access.js';
import {
  createProgressRevisionService,
  deriveWrongQuestionIds,
} from './progress_revision_service.js';
import {
  GRADING_SNAPSHOT_COLLECTION,
  SNAPSHOT_SCHEMA_VERSION,
  buildQuestionSnapshot,
  buildTestSnapshot,
  gradingMapsFromSnapshots,
  isSnapshotEnabledAttempt,
  toStudentSafeQuestion,
} from './attempt_snapshot.js';
import { tryResolveCanonicalScope } from './canonical_scope.js';
import { calculateScoreV1, SCORING_VERSION_V1 } from './test_scoring.js';

export const ATTEMPT_STATUS_IN_PROGRESS = 'in_progress';
export const ATTEMPT_STATUS_SUBMITTED = 'submitted';
export const AUTHORITY_SERVER_VERIFIED = 'server_verified';
export const AUTHORITY_LEGACY_CLIENT = 'legacy_client';
export {
  GRADING_SNAPSHOT_COLLECTION,
  SNAPSHOT_SCHEMA_VERSION,
  isSnapshotEnabledAttempt,
};

/** Extra seconds allowed after duration for network latency. Inclusive. */
export const SUBMISSION_GRACE_SECONDS = 60;

const VALID_OPTIONS = new Set(['A', 'B', 'C', 'D']);

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

/**
 * Deadline is startedAt + durationSeconds + grace, inclusive.
 * Returns null when duration cannot be enforced (missing start or zero duration).
 */
export function resolveAttemptDeadlineMs({
  startedAt,
  durationSeconds,
  graceSeconds = SUBMISSION_GRACE_SECONDS,
}) {
  const started = toDate(startedAt);
  const duration = Number(durationSeconds);
  if (!started || !Number.isFinite(duration) || duration <= 0) return null;
  const grace = Number.isFinite(Number(graceSeconds)) ? Number(graceSeconds) : 0;
  return started.getTime() + (duration + Math.max(0, grace)) * 1000;
}

export function assertSubmissionWithinDeadline({
  startedAt,
  durationSeconds,
  now,
  graceSeconds = SUBMISSION_GRACE_SECONDS,
}) {
  const deadlineMs = resolveAttemptDeadlineMs({
    startedAt,
    durationSeconds,
    graceSeconds,
  });
  if (deadlineMs == null) return;
  const current = now instanceof Date ? now : new Date();
  if (current.getTime() > deadlineMs) {
    const error = new Error('Test time has expired.');
    error.code = 'failed-precondition';
    throw error;
  }
}

function asPublicationStatus(data) {
  const status = String(data?.status || '').trim().toLowerCase();
  if (status === 'published' || status === 'draft' || status === 'archived') {
    return status;
  }
  if (data?.isPublished === true) return 'published';
  return status || 'draft';
}

function parseNegativeMarks(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const cleaned = value.replace(/[^0-9.]/g, '');
    const parsed = Number(cleaned);
    if (Number.isFinite(parsed)) return parsed;
  }
  return 0.25;
}

function optionalTrimmedId(value) {
  const trimmed = String(value || '').trim();
  return trimmed || null;
}

/**
 * Dynamic pool filter for tests with syllabus location.
 * Retains topicId/areaId matching for legacy Group-II question docs.
 */
function questionMatchesTestScope(data, testData) {
  const courseId = String(testData.courseId || '').trim();
  if (String(data?.courseId || '') !== courseId) return false;
  if (data?.isActive !== true) return false;

  const paperId = String(testData.paperId || '').trim();
  const partId = String(testData.partId || '').trim();
  const unitId = String(testData.syllabusUnitId || '').trim();

  if (paperId && String(data?.paperId || '') !== paperId) return false;
  if (partId && String(data?.partId || '') !== partId) return false;
  if (unitId) {
    const questionUnit = String(data?.syllabusUnitId || '').trim();
    const topicId = String(data?.topicId || '').trim();
    const areaId = String(data?.majorStudyAreaId || '').trim();
    if (questionUnit !== unitId && topicId !== unitId && areaId !== unitId) {
      return false;
    }
  }
  return true;
}

/**
 * Exact canonical Chapter/Topic for configured questionIds.
 *
 * Compares resolved canonical syllabusUnitId, not raw Firestore
 * `question.syllabusUnitId`. Group-II Paper I stores the unit on
 * `majorStudyAreaId`; Papers II–IV store it on `topicId`.
 * Paper-only matching is not sufficient.
 */
export function questionMatchesExactCanonicalScope(data, testData) {
  const courseId = String(testData.courseId || '').trim();
  if (!courseId || String(data?.courseId || '').trim() !== courseId) {
    return false;
  }

  const testPaperId = optionalTrimmedId(testData.paperId);
  const testPartId = optionalTrimmedId(testData.partId);
  const testUnitId = optionalTrimmedId(testData.syllabusUnitId);

  if (!testPaperId || !testUnitId) return false;

  if (optionalTrimmedId(data?.paperId) !== testPaperId) return false;
  if (optionalTrimmedId(data?.partId) !== testPartId) return false;

  const questionScope = tryResolveCanonicalScope({
    courseId: data?.courseId,
    paperId: data?.paperId,
    partId: data?.partId,
    syllabusUnitId: data?.syllabusUnitId,
    majorStudyAreaId: data?.majorStudyAreaId,
    contentTopicId: data?.contentTopicId,
    topicId: data?.topicId,
    lessonId: data?.lessonId,
    shape: data?.scopeShape || data?.shape,
  });
  if (!questionScope) return false;
  if (questionScope.paperId !== testPaperId) return false;
  if (optionalTrimmedId(questionScope.partId) !== testPartId) return false;
  return questionScope.syllabusUnitId === testUnitId;
}

function hasCanonicalSyllabusMetadata(testData) {
  return Boolean(
    optionalTrimmedId(testData?.paperId)
    && optionalTrimmedId(testData?.syllabusUnitId),
  );
}

function hasSyllabusScope(testData) {
  return Boolean(
    String(testData?.paperId || '').trim()
    || String(testData?.partId || '').trim()
    || String(testData?.syllabusUnitId || '').trim(),
  );
}

export function assertNoDuplicateQuestionIds(questionIds) {
  const seen = new Set();
  for (const id of questionIds || []) {
    const clean = String(id || '').trim();
    if (!clean) continue;
    if (seen.has(clean)) {
      const error = new Error(
        `Test configuration invalid: duplicate questionId ${clean}.`,
      );
      error.code = 'failed-precondition';
      throw error;
    }
    seen.add(clean);
  }
}

/**
 * Deterministically reconstruct wrong IDs from immutable snapshots + answers.
 */
export function reconstructWrongQuestionIds({ answers, questionSnapshots }) {
  if (!Array.isArray(questionSnapshots) || questionSnapshots.length === 0) {
    return null;
  }
  const { correctByQuestionId } = gradingMapsFromSnapshots(questionSnapshots);
  return deriveWrongQuestionIds(answers, correctByQuestionId);
}

export function startRequestDocId(uid, startRequestId) {
  // Keyed by startRequestId alone so a second user cannot reuse the same key.
  // Ownership is enforced via the stored uid field.
  void uid;
  return String(startRequestId).trim();
}

function shuffleCopy(items, random = Math.random) {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i -= 1) {
    const j = Math.floor(random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

function serializeResult(result, extras = {}) {
  return {
    score: result.score,
    correct: result.correct,
    wrong: result.wrong,
    skipped: result.skipped,
    attempted: result.attempted,
    totalQuestions: result.totalQuestions,
    accuracy: result.accuracy,
    percentage: result.percentage,
    passed: result.passed,
    scoringVersion: result.scoringVersion,
    ...extras,
  };
}

export function resolveAuthority(data) {
  const raw = String(data?.authority || '').trim();
  if (raw === AUTHORITY_SERVER_VERIFIED) return AUTHORITY_SERVER_VERIFIED;
  return AUTHORITY_LEGACY_CLIENT;
}

export function createTestAttemptService({
  db,
  now = () => new Date(),
  random = Math.random,
  generateAttemptId = () => randomUUID(),
  listActiveQuestionIds,
} = {}) {
  if (!db) throw new Error('db is required');

  async function defaultListActiveQuestionIds(courseId) {
    // Production path: Firestore query. Tests may inject listActiveQuestionIds.
    if (typeof db.collection !== 'function') return [];
    try {
      const snap = await db
        .collection('questions')
        .where('courseId', '==', courseId)
        .where('isActive', '==', true)
        .get();
      return snap.docs.map((doc) => doc.id);
    } catch {
      // FakeFirestore has no query support — fall back to scanning store if present.
      if (db._store instanceof Map) {
        const ids = [];
        for (const [path, data] of db._store.entries()) {
          if (!path.startsWith('questions/')) continue;
          if (data?.courseId === courseId && data?.isActive === true) {
            ids.push(path.slice('questions/'.length));
          }
        }
        return ids;
      }
      throw new Error('Unable to list active questions for course.');
    }
  }

  const listQuestions =
    listActiveQuestionIds || defaultListActiveQuestionIds;

  const progressRevision = createProgressRevisionService({ db, now });

  async function loadPublishedTest(testId) {
    const snap = await db.collection('tests').doc(testId).get();
    if (!snap.exists) {
      const error = new Error(`Test not found: ${testId}`);
      error.code = 'not-found';
      throw error;
    }
    const data = snap.data() || {};
    const status = asPublicationStatus(data);
    if (status === 'draft') {
      const error = new Error('Draft tests cannot be started.');
      error.code = 'failed-precondition';
      throw error;
    }
    if (status === 'archived') {
      const error = new Error('Archived tests cannot be started.');
      error.code = 'failed-precondition';
      throw error;
    }
    if (status !== 'published' || data.isPublished !== true) {
      const error = new Error('Test is not available for new attempts.');
      error.code = 'failed-precondition';
      throw error;
    }

    const courseId = String(data.courseId || '').trim();
    if (!courseId) {
      const error = new Error('Test is missing courseId.');
      error.code = 'failed-precondition';
      throw error;
    }

    return { id: testId, ...data, courseId, status };
  }

  async function assertConfiguredQuestionsExactScope(questionIds, testData) {
    if (!hasCanonicalSyllabusMetadata(testData)) return;

    for (const questionId of questionIds) {
      // eslint-disable-next-line no-await-in-loop
      const snap = await db.collection('questions').doc(questionId).get();
      if (!snap.exists) {
        const error = new Error(`Question missing: ${questionId}`);
        error.code = 'failed-precondition';
        throw error;
      }
      const data = snap.data() || {};
      if (data.isActive !== true) {
        const error = new Error(`Question inactive: ${questionId}`);
        error.code = 'failed-precondition';
        throw error;
      }
      if (!questionMatchesExactCanonicalScope(data, testData)) {
        const error = new Error(
          `Question outside exact canonical syllabus scope: ${questionId}`,
        );
        error.code = 'failed-precondition';
        throw error;
      }
    }
  }

  async function resolveQuestionIds(testData) {
    const configured = Array.isArray(testData.questionIds)
      ? testData.questionIds.map((id) => String(id).trim()).filter(Boolean)
      : [];

    if (configured.length > 0) {
      assertNoDuplicateQuestionIds(configured);
      const expected = Number(testData.questionCount) || configured.length;
      if (configured.length !== expected) {
        const error = new Error(
          'Test configuration invalid: questionIds length mismatch.',
        );
        error.code = 'failed-precondition';
        throw error;
      }
      await assertConfiguredQuestionsExactScope(configured, testData);
      return configured;
    }

    const count = Number(testData.questionCount) || 0;
    if (count <= 0) {
      const error = new Error(
        'Test configuration invalid: questionCount must be positive.',
      );
      error.code = 'failed-precondition';
      throw error;
    }

    const pool = await listQuestions(testData.courseId);
    let scoped = pool;
    if (hasSyllabusScope(testData)) {
      scoped = [];
      for (const questionId of pool) {
        // eslint-disable-next-line no-await-in-loop
        const snap = await db.collection('questions').doc(questionId).get();
        if (!snap.exists) continue;
        if (questionMatchesTestScope(snap.data() || {}, testData)) {
          scoped.push(questionId);
        }
      }
      if (scoped.length < count) {
        const error = new Error(
          'Not enough questions in the selected syllabus scope.',
        );
        error.code = 'failed-precondition';
        throw error;
      }
    } else if (pool.length < count) {
      const error = new Error(
        `Not enough active questions for course ${testData.courseId}.`,
      );
      error.code = 'failed-precondition';
      throw error;
    }

    return shuffleCopy(scoped, random).slice(0, count);
  }

  async function loadLiveQuestionDocuments(questionIds, courseId) {
    const docs = [];
    for (const questionId of questionIds) {
      // Sequential reads keep FakeFirestore simple and avoid unbounded Promise.all.
      // eslint-disable-next-line no-await-in-loop
      const snap = await db.collection('questions').doc(questionId).get();
      if (!snap.exists) {
        const error = new Error(`Question missing: ${questionId}`);
        error.code = 'failed-precondition';
        throw error;
      }
      const data = snap.data() || {};
      if (data.isActive !== true) {
        const error = new Error(`Question inactive: ${questionId}`);
        error.code = 'failed-precondition';
        throw error;
      }
      if (String(data.courseId || '') !== courseId) {
        const error = new Error(
          `Question course mismatch for ${questionId}.`,
        );
        error.code = 'failed-precondition';
        throw error;
      }
      docs.push({ questionId, data });
    }
    return docs;
  }

  /** Legacy path only — live bank keys. Snapshot attempts must not use this. */
  async function loadCorrectOptions(questionIds, courseId) {
    const docs = await loadLiveQuestionDocuments(questionIds, courseId);
    const correctByQuestionId = {};
    const optionLabelsByQuestionId = {};
    for (const { questionId, data } of docs) {
      const correctOption = String(data.correctOption || '').trim().toUpperCase();
      if (!correctOption) {
        const error = new Error(
          `Question missing correctOption: ${questionId}`,
        );
        error.code = 'failed-precondition';
        throw error;
      }
      correctByQuestionId[questionId] = correctOption;

      const labels = new Set();
      if (Array.isArray(data.options)) {
        for (const option of data.options) {
          if (typeof option === 'string') {
            // Bare strings — labels are positional A/B/C/D.
            continue;
          }
          const label = String(option?.label || '').trim().toUpperCase();
          if (label) labels.add(label);
        }
      }
      if (labels.size === 0) {
        for (const label of VALID_OPTIONS) labels.add(label);
      }
      optionLabelsByQuestionId[questionId] = labels;
    }
    return { correctByQuestionId, optionLabelsByQuestionId };
  }

  async function loadGradingSnapshot(attemptId) {
    const snap = await db
      .collection(GRADING_SNAPSHOT_COLLECTION)
      .doc(attemptId)
      .get();
    if (!snap.exists) return null;
    return snap.data() || null;
  }

  function normalizeSelectedAnswers(selectedAnswers, questionIds, optionLabelsByQuestionId) {
    if (!Array.isArray(selectedAnswers)) {
      const error = new Error('selectedAnswers must be an array.');
      error.code = 'invalid-argument';
      throw error;
    }

    const allowed = new Set(questionIds);
    const seen = new Set();
    const normalized = [];

    for (const item of selectedAnswers) {
      const questionId = String(item?.questionId || '').trim();
      if (!questionId) {
        const error = new Error('selectedAnswers entries require questionId.');
        error.code = 'invalid-argument';
        throw error;
      }
      if (!allowed.has(questionId)) {
        const error = new Error(
          `Question outside attempt: ${questionId}`,
        );
        error.code = 'invalid-argument';
        throw error;
      }
      if (seen.has(questionId)) {
        const error = new Error(
          `Duplicate questionId in selectedAnswers: ${questionId}`,
        );
        error.code = 'invalid-argument';
        throw error;
      }
      seen.add(questionId);

      const rawSelected = item?.selectedOption;
      if (rawSelected == null || String(rawSelected).trim() === '') {
        // Unanswered — omit from scoring answers (matches client skipped behavior).
        continue;
      }

      const selectedOption = String(rawSelected).trim().toUpperCase();
      const validLabels = optionLabelsByQuestionId[questionId] || VALID_OPTIONS;
      if (!validLabels.has(selectedOption)) {
        const error = new Error(
          `Invalid option for ${questionId}: ${selectedOption}`,
        );
        error.code = 'invalid-argument';
        throw error;
      }

      // Reject client-supplied correctOption fields — never trust them.
      if (
        Object.prototype.hasOwnProperty.call(item || {}, 'correctOption')
        || Object.prototype.hasOwnProperty.call(item || {}, 'score')
        || Object.prototype.hasOwnProperty.call(item || {}, 'marks')
      ) {
        const error = new Error(
          'Client must not submit correctOption/score/marks.',
        );
        error.code = 'invalid-argument';
        throw error;
      }

      normalized.push({ questionId, selectedOption });
    }

    return normalized;
  }

  async function resolveSideEffectInputs({
    attempt,
    answersOverride = null,
    questionSnapshotsOverride = null,
  }) {
    const answers = Array.isArray(answersOverride)
      ? answersOverride
      : Array.isArray(attempt.answers)
        ? attempt.answers
        : [];

    let questionSnapshots = Array.isArray(questionSnapshotsOverride)
      ? questionSnapshotsOverride
      : Array.isArray(attempt.questionSnapshots)
        ? attempt.questionSnapshots
        : null;

    if (
      (!questionSnapshots || questionSnapshots.length === 0)
      && isSnapshotEnabledAttempt(attempt)
    ) {
      const grading = await loadGradingSnapshot(attempt.attemptId);
      if (grading && Array.isArray(grading.questions)) {
        questionSnapshots = grading.questions;
      }
    }

    let wrongQuestionIds = Array.isArray(attempt.wrongQuestionIds)
      ? [...attempt.wrongQuestionIds]
      : null;

    const canReconstruct =
      Array.isArray(questionSnapshots) && questionSnapshots.length > 0;
    const needsReconstruction =
      wrongQuestionIds == null
      || (Number(attempt.wrong) > 0 && wrongQuestionIds.length === 0);

    if (canReconstruct && needsReconstruction) {
      const reconstructed = reconstructWrongQuestionIds({
        answers,
        questionSnapshots,
      });
      if (reconstructed != null) {
        wrongQuestionIds = reconstructed;
      }
    }

    if (wrongQuestionIds == null) wrongQuestionIds = [];

    return { answers, questionSnapshots, wrongQuestionIds };
  }

  return {
    /**
     * Create an in_progress attempt snapshot.
     * Exactly-once for (uid, startRequestId).
     */
    async startAttempt({ uid, testId, startRequestId }) {
      const cleanUid = String(uid || '').trim();
      const cleanTestId = String(testId || '').trim();
      const cleanStartRequestId = String(startRequestId || '').trim();
      if (!cleanUid) {
        const error = new Error('Authentication required.');
        error.code = 'unauthenticated';
        throw error;
      }
      if (!cleanTestId) {
        const error = new Error('testId is required.');
        error.code = 'invalid-argument';
        throw error;
      }
      if (!cleanStartRequestId) {
        const error = new Error('startRequestId is required.');
        error.code = 'invalid-argument';
        throw error;
      }

      const startRequestRef = db
        .collection('test_attempt_start_requests')
        .doc(startRequestDocId(cleanUid, cleanStartRequestId));

      const existingStart = await startRequestRef.get();
      if (existingStart.exists) {
        const existing = existingStart.data() || {};
        if (String(existing.uid || '') !== cleanUid) {
          const error = new Error('startRequestId belongs to another user.');
          error.code = 'permission-denied';
          throw error;
        }
        const existingAttemptId = String(existing.attemptId || '').trim();
        if (!existingAttemptId) {
          const error = new Error('Corrupt start request mapping.');
          error.code = 'failed-precondition';
          throw error;
        }
        const attemptSnap = await db
          .collection('test_attempts')
          .doc(existingAttemptId)
          .get();
        if (!attemptSnap.exists) {
          const error = new Error(
            `Mapped attempt missing for startRequestId: ${cleanStartRequestId}`,
          );
          error.code = 'failed-precondition';
          throw error;
        }
        const attempt = attemptSnap.data() || {};
        if (String(attempt.uid || '') !== cleanUid) {
          const error = new Error('Cross-user startRequestId rejected.');
          error.code = 'permission-denied';
          throw error;
        }
        return {
          attemptId: existingAttemptId,
          testId: attempt.testId,
          courseId: attempt.courseId,
          questionIds: attempt.questionIds || [],
          studentQuestions: attempt.studentQuestions || [],
          testSnapshot: attempt.testSnapshot || null,
          snapshotSchemaVersion: attempt.snapshotSchemaVersion || SNAPSHOT_SCHEMA_VERSION,
          totalMarks: attempt.totalMarks,
          negativeMarks: attempt.negativeMarks,
          totalQuestions: attempt.totalQuestions,
          durationSeconds: attempt.durationSeconds,
          scoringVersion: attempt.scoringVersion || SCORING_VERSION_V1,
          status: attempt.status || ATTEMPT_STATUS_IN_PROGRESS,
          authority: attempt.authority || AUTHORITY_SERVER_VERIFIED,
          startRequestId: cleanStartRequestId,
          duplicate: true,
        };
      }

      const testData = await loadPublishedTest(cleanTestId);
      await assertCourseAccess(db, cleanUid, testData.courseId, { now });

      const questionIds = await resolveQuestionIds(testData);
      const liveDocs = await loadLiveQuestionDocuments(
        questionIds,
        testData.courseId,
      );

      const totalMarks = Number(testData.totalMarks) || 0;
      const negativeMarks = parseNegativeMarks(testData.negativeMarks);
      const durationMinutes = Number(testData.durationMinutes) || 0;
      const durationSeconds = Math.max(0, Math.floor(durationMinutes * 60));
      const totalQuestions = questionIds.length;

      const questionSnapshots = liveDocs.map(({ questionId, data }, index) =>
        buildQuestionSnapshot(questionId, data, index, testData.courseId),
      );
      const studentQuestions = questionSnapshots.map(toStudentSafeQuestion);
      const testSnapshot = buildTestSnapshot(testData, {
        questionCount: totalQuestions,
        totalMarks,
        durationSeconds,
        negativeMarks,
        scoringVersion: SCORING_VERSION_V1,
      });

      const attemptId = generateAttemptId();
      const attemptRef = db.collection('test_attempts').doc(attemptId);
      const gradingRef = db
        .collection(GRADING_SNAPSHOT_COLLECTION)
        .doc(attemptId);

      const attemptPayload = {
        attemptId,
        uid: cleanUid,
        testId: cleanTestId,
        courseId: testData.courseId,
        testTitle: String(testData.title || cleanTestId),
        questionIds,
        totalMarks,
        negativeMarks,
        totalQuestions,
        durationSeconds,
        scoringVersion: SCORING_VERSION_V1,
        snapshotSchemaVersion: SNAPSHOT_SCHEMA_VERSION,
        testSnapshot,
        studentQuestions,
        status: ATTEMPT_STATUS_IN_PROGRESS,
        authority: AUTHORITY_SERVER_VERIFIED,
        startRequestId: cleanStartRequestId,
        startedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      };

      const gradingPayload = {
        attemptId,
        uid: cleanUid,
        testId: cleanTestId,
        courseId: testData.courseId,
        snapshotSchemaVersion: SNAPSHOT_SCHEMA_VERSION,
        scoring: {
          scoringVersion: SCORING_VERSION_V1,
          totalMarks,
          negativeMarks,
          questionCount: totalQuestions,
        },
        testSnapshot,
        questions: questionSnapshots,
        createdAt: FieldValue.serverTimestamp(),
      };

      const startRequestPayload = {
        uid: cleanUid,
        startRequestId: cleanStartRequestId,
        attemptId,
        testId: cleanTestId,
        courseId: testData.courseId,
        createdAt: FieldValue.serverTimestamp(),
      };

      // Atomic: mapping + attempt + grading land together, or neither does.
      // Concurrent retries with the same startRequestId re-read the winner.
      const committed = await db.runTransaction(async (tx) => {
        const keySnap = await tx.get(startRequestRef);
        if (keySnap.exists) {
          const existing = keySnap.data() || {};
          if (String(existing.uid || '') !== cleanUid) {
            const error = new Error('startRequestId belongs to another user.');
            error.code = 'permission-denied';
            throw error;
          }
          return {
            duplicate: true,
            attemptId: String(existing.attemptId || '').trim(),
          };
        }
        tx.set(startRequestRef, startRequestPayload);
        tx.set(gradingRef, gradingPayload);
        tx.set(attemptRef, attemptPayload);
        return { duplicate: false, attemptId };
      });

      if (committed.duplicate) {
        const attemptSnap = await db
          .collection('test_attempts')
          .doc(committed.attemptId)
          .get();
        const attempt = attemptSnap.exists ? attemptSnap.data() || {} : {};
        return {
          attemptId: committed.attemptId,
          testId: attempt.testId || cleanTestId,
          courseId: attempt.courseId || testData.courseId,
          questionIds: attempt.questionIds || questionIds,
          studentQuestions: attempt.studentQuestions || studentQuestions,
          testSnapshot: attempt.testSnapshot || testSnapshot,
          snapshotSchemaVersion:
            attempt.snapshotSchemaVersion || SNAPSHOT_SCHEMA_VERSION,
          totalMarks: attempt.totalMarks ?? totalMarks,
          negativeMarks: attempt.negativeMarks ?? negativeMarks,
          totalQuestions: attempt.totalQuestions ?? totalQuestions,
          durationSeconds: attempt.durationSeconds ?? durationSeconds,
          scoringVersion: attempt.scoringVersion || SCORING_VERSION_V1,
          status: attempt.status || ATTEMPT_STATUS_IN_PROGRESS,
          authority: attempt.authority || AUTHORITY_SERVER_VERIFIED,
          startRequestId: cleanStartRequestId,
          duplicate: true,
        };
      }

      return {
        attemptId,
        testId: cleanTestId,
        courseId: testData.courseId,
        questionIds,
        studentQuestions,
        testSnapshot,
        snapshotSchemaVersion: SNAPSHOT_SCHEMA_VERSION,
        totalMarks,
        negativeMarks,
        totalQuestions,
        durationSeconds,
        scoringVersion: SCORING_VERSION_V1,
        status: ATTEMPT_STATUS_IN_PROGRESS,
        authority: AUTHORITY_SERVER_VERIFIED,
        startRequestId: cleanStartRequestId,
        duplicate: false,
      };
    },

    /**
     * Score and finalize an attempt. Idempotent on attemptId.
     */
    async submitAttempt({ uid, attemptId, selectedAnswers }) {
      const cleanUid = String(uid || '').trim();
      const cleanAttemptId = String(attemptId || '').trim();
      if (!cleanUid) {
        const error = new Error('Authentication required.');
        error.code = 'unauthenticated';
        throw error;
      }
      if (!cleanAttemptId) {
        const error = new Error('attemptId is required.');
        error.code = 'invalid-argument';
        throw error;
      }

      const attemptRef = db.collection('test_attempts').doc(cleanAttemptId);

      const outcome = await db.runTransaction(async (tx) => {
        const snap = await tx.get(attemptRef);
        if (!snap.exists) {
          const error = new Error(`Attempt not found: ${cleanAttemptId}`);
          error.code = 'not-found';
          throw error;
        }

        const attempt = snap.data() || {};
        if (String(attempt.uid || '') !== cleanUid) {
          const error = new Error('Cross-user submission rejected.');
          error.code = 'permission-denied';
          throw error;
        }

        if (attempt.status === ATTEMPT_STATUS_SUBMITTED) {
          return {
            duplicate: true,
            attempt: { ...attempt, attemptId: cleanAttemptId },
          };
        }

        if (attempt.status !== ATTEMPT_STATUS_IN_PROGRESS) {
          const error = new Error(
            `Attempt is not in progress (status=${attempt.status}).`,
          );
          error.code = 'failed-precondition';
          throw error;
        }

        assertSubmissionWithinDeadline({
          startedAt: attempt.startedAt,
          durationSeconds:
            Number(attempt.durationSeconds) ||
            Math.max(0, Math.floor(Number(attempt.durationMinutes || 0) * 60)),
          now: now(),
        });

        const questionIds = Array.isArray(attempt.questionIds)
          ? attempt.questionIds.map((id) => String(id))
          : [];
        if (questionIds.length === 0) {
          const error = new Error('Attempt is missing questionIds snapshot.');
          error.code = 'failed-precondition';
          throw error;
        }

        // Reads outside transaction mutation are done after collecting IDs —
        // loadCorrectOptions uses db directly; re-validate inside by IDs only.
        return {
          duplicate: false,
          attempt: { ...attempt, attemptId: cleanAttemptId },
          questionIds,
          needsScore: true,
        };
      });

      if (outcome.duplicate) {
        const a = outcome.attempt;
        const sideEffects = await resolveSideEffectInputs({ attempt: a });
        await progressRevision.applyVerifiedTestAttemptSideEffects({
          attemptId: cleanAttemptId,
          attempt: {
            ...a,
            status: ATTEMPT_STATUS_SUBMITTED,
            authority: a.authority || AUTHORITY_SERVER_VERIFIED,
            wrongQuestionIds: sideEffects.wrongQuestionIds,
            answers: sideEffects.answers,
            questionSnapshots: sideEffects.questionSnapshots,
          },
          wrongQuestionIds: sideEffects.wrongQuestionIds,
          answers: sideEffects.answers,
          questionSnapshots: sideEffects.questionSnapshots,
        });
        if (
          sideEffects.wrongQuestionIds.length > 0
          && !Array.isArray(a.wrongQuestionIds)
        ) {
          await attemptRef.set(
            { wrongQuestionIds: sideEffects.wrongQuestionIds },
            { merge: true },
          );
        }
        return {
          attemptId: cleanAttemptId,
          duplicate: true,
          authority: resolveAuthority(a),
          status: ATTEMPT_STATUS_SUBMITTED,
          ...serializeResult({
            score: a.score ?? 0,
            correct: a.correct ?? 0,
            wrong: a.wrong ?? 0,
            skipped: a.skipped ?? 0,
            attempted: a.attempted ?? 0,
            totalQuestions: a.totalQuestions ?? 0,
            accuracy: a.accuracy ?? 0,
            percentage: a.percentage ?? 0,
            passed: a.passed === true,
            scoringVersion: a.scoringVersion || SCORING_VERSION_V1,
          }),
          testId: a.testId,
          courseId: a.courseId,
        };
      }

      const attempt = outcome.attempt;
      const questionIds = outcome.questionIds;

      let correctByQuestionId;
      let optionLabelsByQuestionId;
      let questionSnapshotsForReveal = null;
      let scoringConfig = {
        totalQuestions: Number(attempt.totalQuestions) || questionIds.length,
        totalMarks: Number(attempt.totalMarks) || 0,
        negativeMarks: Number(attempt.negativeMarks) || 0,
      };

      if (isSnapshotEnabledAttempt(attempt)) {
        const grading = await loadGradingSnapshot(cleanAttemptId);
        if (!grading || !Array.isArray(grading.questions) || grading.questions.length === 0) {
          const error = new Error(
            'Attempt grading snapshot is missing. Cannot score without frozen keys.',
          );
          error.code = 'failed-precondition';
          throw error;
        }
        const maps = gradingMapsFromSnapshots(grading.questions);
        correctByQuestionId = maps.correctByQuestionId;
        optionLabelsByQuestionId = maps.optionLabelsByQuestionId;
        questionSnapshotsForReveal = grading.questions;
        if (grading.scoring) {
          scoringConfig = {
            totalQuestions:
              Number(grading.scoring.questionCount) || scoringConfig.totalQuestions,
            totalMarks:
              Number(grading.scoring.totalMarks) || scoringConfig.totalMarks,
            negativeMarks:
              Number(grading.scoring.negativeMarks) || scoringConfig.negativeMarks,
          };
        }
      } else {
        // Legacy attempts without snapshots — preserve prior live-bank behavior.
        const maps = await loadCorrectOptions(questionIds, attempt.courseId);
        correctByQuestionId = maps.correctByQuestionId;
        optionLabelsByQuestionId = maps.optionLabelsByQuestionId;
      }

      const answers = normalizeSelectedAnswers(
        selectedAnswers,
        questionIds,
        optionLabelsByQuestionId,
      );

      const result = calculateScoreV1({
        totalQuestions: scoringConfig.totalQuestions,
        totalMarks: scoringConfig.totalMarks,
        negativeMarks: scoringConfig.negativeMarks,
        answers,
        correctByQuestionId,
      });

      // Duration is enforced from attempt.startedAt + durationSeconds + grace.
      // Client timer is UX-only and cannot extend the server deadline.
      const startedAt = attempt.startedAt;
      let serverDurationSeconds = null;
      if (startedAt && typeof startedAt.toDate === 'function') {
        serverDurationSeconds = Math.max(
          0,
          Math.floor((now().getTime() - startedAt.toDate().getTime()) / 1000),
        );
      }

      const answerMaps = answers.map((item) => ({
        questionId: item.questionId,
        selectedOption: item.selectedOption,
        answered: true,
      }));

      const writeOutcome = await db.runTransaction(async (tx) => {
        const snap = await tx.get(attemptRef);
        if (!snap.exists) {
          const error = new Error(`Attempt not found: ${cleanAttemptId}`);
          error.code = 'not-found';
          throw error;
        }
        const current = snap.data() || {};
        if (String(current.uid || '') !== cleanUid) {
          const error = new Error('Cross-user submission rejected.');
          error.code = 'permission-denied';
          throw error;
        }
        if (current.status === ATTEMPT_STATUS_SUBMITTED) {
          return {
            duplicate: true,
            attempt: { ...current, attemptId: cleanAttemptId },
          };
        }
        tx.set(
          attemptRef,
          {
            status: ATTEMPT_STATUS_SUBMITTED,
            authority: AUTHORITY_SERVER_VERIFIED,
            scoringVersion: SCORING_VERSION_V1,
            answers: answerMaps,
            score: result.score,
            correct: result.correct,
            wrong: result.wrong,
            skipped: result.skipped,
            attempted: result.attempted,
            totalQuestions: result.totalQuestions,
            accuracy: result.accuracy,
            percentage: result.percentage,
            passed: result.passed,
            submittedAt: FieldValue.serverTimestamp(),
            serverDurationSeconds,
            timeSpentSeconds: serverDurationSeconds,
            progressEventPending: true,
            revisionEventPending: true,
            ...(questionSnapshotsForReveal
              ? {
                  // Reveal frozen content only after submission for historical review.
                  questionSnapshots: questionSnapshotsForReveal,
                }
              : {}),
          },
          { merge: true },
        );
        return { duplicate: false };
      });

      if (writeOutcome.duplicate) {
        const a = writeOutcome.attempt;
        // Heal analytics if a prior submit wrote the attempt but side effects failed.
        const sideEffects = await resolveSideEffectInputs({
          attempt: a,
          answersOverride: Array.isArray(a.answers) ? a.answers : answers,
          questionSnapshotsOverride: Array.isArray(a.questionSnapshots)
            ? a.questionSnapshots
            : questionSnapshotsForReveal,
        });
        await progressRevision.applyVerifiedTestAttemptSideEffects({
          attemptId: cleanAttemptId,
          attempt: {
            ...a,
            status: ATTEMPT_STATUS_SUBMITTED,
            authority: AUTHORITY_SERVER_VERIFIED,
            wrongQuestionIds: sideEffects.wrongQuestionIds,
            answers: sideEffects.answers,
            questionSnapshots: sideEffects.questionSnapshots,
          },
          wrongQuestionIds: sideEffects.wrongQuestionIds,
          answers: sideEffects.answers,
          questionSnapshots: sideEffects.questionSnapshots,
        });
        if (
          sideEffects.wrongQuestionIds.length > 0
          && !Array.isArray(a.wrongQuestionIds)
        ) {
          await attemptRef.set(
            { wrongQuestionIds: sideEffects.wrongQuestionIds },
            { merge: true },
          );
        }
        return {
          attemptId: cleanAttemptId,
          duplicate: true,
          authority: resolveAuthority(a),
          status: ATTEMPT_STATUS_SUBMITTED,
          ...serializeResult({
            score: a.score ?? 0,
            correct: a.correct ?? 0,
            wrong: a.wrong ?? 0,
            skipped: a.skipped ?? 0,
            attempted: a.attempted ?? 0,
            totalQuestions: a.totalQuestions ?? 0,
            accuracy: a.accuracy ?? 0,
            percentage: a.percentage ?? 0,
            passed: a.passed === true,
            scoringVersion: a.scoringVersion || SCORING_VERSION_V1,
          }),
          testId: a.testId,
          courseId: a.courseId,
        };
      }

      const wrongQuestionIds = deriveWrongQuestionIds(
        answers,
        correctByQuestionId,
      );

      await progressRevision.applyVerifiedTestAttemptSideEffects({
        attemptId: cleanAttemptId,
        attempt: {
          ...attempt,
          score: result.score,
          correct: result.correct,
          wrong: result.wrong,
          skipped: result.skipped,
          attempted: result.attempted,
          totalMarks: scoringConfig.totalMarks,
          negativeMarks: scoringConfig.negativeMarks,
          totalQuestions: scoringConfig.totalQuestions,
          status: ATTEMPT_STATUS_SUBMITTED,
          authority: AUTHORITY_SERVER_VERIFIED,
          wrongQuestionIds,
          answers: answerMaps,
          questionSnapshots: questionSnapshotsForReveal,
        },
        wrongQuestionIds,
        answers: answerMaps,
        questionSnapshots: questionSnapshotsForReveal,
      });

      await attemptRef.set(
        {
          progressEventPending: false,
          revisionEventPending: false,
          progressEventApplied: true,
          revisionEventApplied: true,
          wrongQuestionIds,
        },
        { merge: true },
      );

      return {
        attemptId: cleanAttemptId,
        duplicate: false,
        authority: AUTHORITY_SERVER_VERIFIED,
        status: ATTEMPT_STATUS_SUBMITTED,
        ...serializeResult(result),
        testId: attempt.testId,
        courseId: attempt.courseId,
        serverDurationSeconds,
        snapshotSchemaVersion: isSnapshotEnabledAttempt(attempt)
          ? SNAPSHOT_SCHEMA_VERSION
          : null,
        ...(questionSnapshotsForReveal
          ? { questionSnapshots: questionSnapshotsForReveal }
          : {}),
      };
    },
  };
}
