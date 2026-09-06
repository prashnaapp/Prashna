/**
 * Verified non-catalog question activity → shared revision side effects.
 *
 * Trust model (distinct from catalog submitTestAttempt):
 * - Server verifies questionId exists, is active, and selectedOption vs
 *   authoritative correctOption.
 * - Server does NOT independently prove the student encountered the question
 *   in a published catalog attempt (no serverAttemptId / grading snapshot).
 * - Idempotency: question_activity_events/{activityEventId}
 *
 * Catalog path remains submitTestAttempt → applyVerifiedTestAttemptSideEffects.
 */
import { FieldValue } from 'firebase-admin/firestore';

import {
  AUTHORITY_SERVER_VERIFIED,
  mergeTrustedWrongQuestionsIntoRevision,
} from './progress_revision_service.js';

export const QUESTION_ACTIVITY_EVENTS_COLLECTION = 'question_activity_events';
export const QUESTION_ACTIVITY_SOURCE = 'reportQuestionActivity';
export const QUESTION_ACTIVITY_AUTHORITY = 'server_verified_question_option';

const APP_VERSION = 'server-5.27';
const MAX_EVENT_ID_LENGTH = 128;
const ALLOWED_SOURCE_MODULES = new Set([
  'chapters',
  'testSeries',
  'practice',
  'revision',
  'currentAffairs',
  'other',
  'unknown',
]);

function asString(value) {
  return String(value ?? '').trim();
}

function cleanOptional(value) {
  const s = asString(value);
  return s || null;
}

/**
 * @param {object} deps
 * @param {FirebaseFirestore.Firestore} deps.db
 * @param {() => Date} [deps.now]
 */
export function createQuestionActivityService({
  db,
  now = () => new Date(),
} = {}) {
  if (!db) throw new Error('db is required');

  function eventRef(activityEventId) {
    return db.collection(QUESTION_ACTIVITY_EVENTS_COLLECTION).doc(activityEventId);
  }

  function revisionRef(uid) {
    return db.collection('user_revision').doc(uid);
  }

  /**
   * Report one answered question for revision authority (practice-first).
   *
   * @param {object} input
   * @param {string} input.uid authenticated uid (from request.auth)
   * @param {string} input.activityEventId stable idempotency key
   * @param {string} input.questionId
   * @param {string} input.selectedOption
   * @param {string} [input.sourceModule]
   * @param {string} [input.sourceType]
   * @param {string} [input.encounterId]
   * @param {object} [input.context] optional encounter fields
   */
  async function reportQuestionActivity(input = {}) {
    const uid = asString(input.uid);
    if (!uid) {
      const error = new Error('uid is required.');
      error.code = 'unauthenticated';
      throw error;
    }

    const activityEventId = asString(input.activityEventId);
    if (!activityEventId) {
      const error = new Error('activityEventId is required.');
      error.code = 'invalid-argument';
      throw error;
    }
    if (activityEventId.length > MAX_EVENT_ID_LENGTH) {
      const error = new Error('activityEventId is too long.');
      error.code = 'invalid-argument';
      throw error;
    }
    if (!/^[A-Za-z0-9._:-]+$/.test(activityEventId)) {
      const error = new Error('activityEventId has invalid characters.');
      error.code = 'invalid-argument';
      throw error;
    }

    const questionId = asString(input.questionId);
    if (!questionId) {
      const error = new Error('questionId is required.');
      error.code = 'invalid-argument';
      throw error;
    }

    const selectedOption = asString(input.selectedOption).toUpperCase();
    if (!selectedOption) {
      const error = new Error('selectedOption is required.');
      error.code = 'invalid-argument';
      throw error;
    }

    const sourceModuleRaw = asString(input.sourceModule) || 'unknown';
    const sourceModule = ALLOWED_SOURCE_MODULES.has(sourceModuleRaw)
      ? sourceModuleRaw
      : 'unknown';
    const sourceType = cleanOptional(input.sourceType) || 'unknown';
    const encounterId = cleanOptional(input.encounterId);
    const context =
      input.context && typeof input.context === 'object' ? input.context : {};

    const questionSnap = await db.collection('questions').doc(questionId).get();
    if (!questionSnap.exists) {
      const error = new Error(`Question not found: ${questionId}`);
      error.code = 'not-found';
      throw error;
    }
    const question = questionSnap.data() || {};
    if (question.isActive !== true) {
      const error = new Error(`Question inactive: ${questionId}`);
      error.code = 'failed-precondition';
      throw error;
    }
    const correctOption = asString(question.correctOption).toUpperCase();
    if (!correctOption) {
      const error = new Error(`Question missing correctOption: ${questionId}`);
      error.code = 'failed-precondition';
      throw error;
    }
    const courseId = asString(question.courseId);
    if (!courseId) {
      const error = new Error(`Question missing courseId: ${questionId}`);
      error.code = 'failed-precondition';
      throw error;
    }

    const isWrong = selectedOption !== correctOption;

    const outcome = await db.runTransaction(async (tx) => {
      const eRef = eventRef(activityEventId);
      const rRef = revisionRef(uid);
      const [eventSnap, revisionSnap] = await Promise.all([
        tx.get(eRef),
        tx.get(rRef),
      ]);

      if (eventSnap.exists) {
        const prior = eventSnap.data() || {};
        if (prior.uid && asString(prior.uid) !== uid) {
          const error = new Error(
            'activityEventId belongs to a different user.',
          );
          error.code = 'permission-denied';
          throw error;
        }
        return {
          duplicate: true,
          isWrong: prior.isWrong === true,
          revisionApplied: prior.revisionApplied === true,
          wrongQuestionIds: Array.isArray(prior.wrongQuestionIds)
            ? prior.wrongQuestionIds
            : [],
          questionId: asString(prior.questionId) || questionId,
          courseId: asString(prior.courseId) || courseId,
        };
      }

      const trustedWrongIds = isWrong ? [questionId] : [];
      let revisionApplied = false;
      let wrongQuestionIds = [];

      if (isWrong) {
        const priorRevision = revisionSnap.exists
          ? revisionSnap.data() || {}
          : {};
        const merged = mergeTrustedWrongQuestionsIntoRevision({
          priorRevision,
          trustedWrongIds,
          courseId,
          uid,
          appVersion: APP_VERSION,
        });
        tx.set(
          rRef,
          {
            ...merged,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: false },
        );
        revisionApplied = true;
        wrongQuestionIds = trustedWrongIds;
      }

      const encounterContext = {
        sourceModule,
        sourceType,
        encounterId,
        testId: cleanOptional(context.testId),
        testTitle: cleanOptional(context.testTitle),
        paperId: cleanOptional(context.paperId),
        sectionId: cleanOptional(context.sectionId),
        partId: cleanOptional(context.partId),
        topicId: cleanOptional(context.topicId),
        lessonId: cleanOptional(context.lessonId),
        majorStudyAreaId: cleanOptional(context.majorStudyAreaId),
        contentTopicId: cleanOptional(context.contentTopicId),
        syllabusUnitId: cleanOptional(context.syllabusUnitId),
        seriesId: cleanOptional(context.seriesId),
        year:
          context.year == null || context.year === ''
            ? null
            : Number.isFinite(Number(context.year))
              ? Math.trunc(Number(context.year))
              : null,
        currentAffairsSetId: cleanOptional(context.currentAffairsSetId),
      };

      tx.set(
        eRef,
        {
          activityEventId,
          uid,
          questionId,
          selectedOption,
          correctOption,
          isWrong,
          courseId,
          sourceModule,
          sourceType,
          encounterId,
          encounterContext,
          wrongQuestionIds,
          revisionApplied,
          appliedAt: FieldValue.serverTimestamp(),
          source: QUESTION_ACTIVITY_SOURCE,
          authority: QUESTION_ACTIVITY_AUTHORITY,
          revisionAuthority: AUTHORITY_SERVER_VERIFIED,
          appVersion: APP_VERSION,
        },
        { merge: false },
      );

      return {
        duplicate: false,
        isWrong,
        revisionApplied,
        wrongQuestionIds,
        questionId,
        courseId,
      };
    });

    return {
      activityEventId,
      uid,
      ...outcome,
      appliedAt: now().toISOString(),
    };
  }

  return {
    reportQuestionActivity,
  };
}
