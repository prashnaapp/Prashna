/**
 * Server-authoritative progress + revision + unit performance from verified
 * attempts.
 *
 * Mirrors ProgressService cloud snapshot deltas and RevisionService wrong-list
 * semantics without trusting client-submitted analytics.
 *
 * Idempotency: test_attempt_events/{attemptId}
 *   progressApplied + revisionApplied + unitPerformanceApplied
 */
import { FieldValue } from 'firebase-admin/firestore';

import {
  buildUnitPerformanceDeltas,
  mergeUnitPerformance,
  unitPerformanceRef,
} from './unit_performance_service.js';

export const AUTHORITY_SERVER_VERIFIED = 'server_verified';
export const FREQUENT_WRONG_MIN = 2;
const ATTEMPT_STATUS_SUBMITTED = 'submitted';
const APP_VERSION = 'server-5.27';

function resolveAuthority(data) {
  const raw = String(data?.authority || '').trim();
  if (raw === AUTHORITY_SERVER_VERIFIED) return AUTHORITY_SERVER_VERIFIED;
  return 'legacy_client';
}

function asInt(value, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? Math.trunc(n) : fallback;
}

function asNumber(value, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function uniqueStrings(values) {
  const out = [];
  const seen = new Set();
  for (const value of values || []) {
    const id = String(value || '').trim();
    if (!id || seen.has(id)) continue;
    seen.add(id);
    out.push(id);
  }
  return out;
}

/**
 * Derive wrong question IDs from verified answers + canonical correct map.
 */
export function deriveWrongQuestionIds(answers, correctByQuestionId) {
  const wrong = [];
  for (const answer of answers || []) {
    const questionId = String(answer?.questionId || '').trim();
    if (!questionId) continue;
    const selected = String(answer?.selectedOption || '').trim();
    if (!selected) continue;
    const correct = String(correctByQuestionId?.[questionId] || '').trim();
    if (!correct) continue;
    if (selected !== correct) wrong.push(questionId);
  }
  return uniqueStrings(wrong);
}

/**
 * Shared revision merge for trusted wrong IDs (catalog attempts + question activity).
 *
 * Does not write Firestore — callers apply inside their own transactions.
 * mistakeCounts increment once per trusted wrong id in this batch.
 * frequentlyWrongQuestions rebuilt from counts using FREQUENT_WRONG_MIN.
 *
 * @param {object} input
 * @param {object} [input.priorRevision] existing user_revision data (or {})
 * @param {string[]} input.trustedWrongIds server-derived wrong question IDs
 * @param {string} input.courseId course stamped on the revision document
 * @param {string} [input.uid]
 * @param {string} [input.appVersion]
 * @returns {{ wrongQuestions: string[], weakQuestions: string[],
 *   frequentlyWrongQuestions: string[], mistakeCounts: Object,
 *   courseId: string, uid?: string, appVersion: string,
 *   authority: string }}
 */
export function mergeTrustedWrongQuestionsIntoRevision({
  priorRevision = {},
  trustedWrongIds = [],
  courseId,
  uid = null,
  appVersion = APP_VERSION,
} = {}) {
  const cleanCourseId = String(courseId || '').trim();
  const ids = uniqueStrings(trustedWrongIds);
  const priorWrong = uniqueStrings(priorRevision.wrongQuestions);
  const priorWeak = uniqueStrings(priorRevision.weakQuestions);
  const priorCounts = {
    ...(priorRevision.mistakeCounts &&
    typeof priorRevision.mistakeCounts === 'object'
      ? priorRevision.mistakeCounts
      : {}),
  };

  const nextWrong = uniqueStrings([...priorWrong, ...ids]);
  for (const qid of ids) {
    priorCounts[qid] = asInt(priorCounts[qid]) + 1;
  }

  const frequent = [];
  for (const [qid, count] of Object.entries(priorCounts)) {
    if (asInt(count) >= FREQUENT_WRONG_MIN) frequent.push(qid);
  }
  for (const qid of uniqueStrings(priorRevision.frequentlyWrongQuestions)) {
    if (
      !frequent.includes(qid) &&
      asInt(priorCounts[qid]) >= FREQUENT_WRONG_MIN
    ) {
      frequent.push(qid);
    }
  }

  return {
    ...(uid ? { uid: String(uid).trim() } : {}),
    courseId: cleanCourseId,
    wrongQuestions: nextWrong,
    weakQuestions: priorWeak,
    frequentlyWrongQuestions: uniqueStrings(frequent),
    mistakeCounts: priorCounts,
    appVersion,
    authority: AUTHORITY_SERVER_VERIFIED,
  };
}

export function createProgressRevisionService({ db, now = () => new Date() } = {}) {
  if (!db) throw new Error('db is required');

  function progressRef(uid, courseId) {
    return db.collection('user_progress').doc(uid).collection('courses').doc(courseId);
  }

  function revisionRef(uid) {
    return db.collection('user_revision').doc(uid);
  }

  function eventRef(attemptId) {
    return db.collection('test_attempt_events').doc(attemptId);
  }

  /**
   * Apply progress + revision + unit performance for a verified submitted attempt.
   * Safe to call repeatedly — attemptId is the idempotency key.
   *
   * @param {object} input
   * @param {string} input.attemptId
   * @param {object} [input.attempt] preloaded attempt data (must include uid/courseId/scores)
   * @param {string[]} [input.wrongQuestionIds] trusted wrong IDs (server-derived)
   * @param {Array} [input.answers] selected answers for unit aggregation
   * @param {Array} [input.questionSnapshots] frozen question snapshots
   */
  async function applyVerifiedTestAttemptSideEffects({
    attemptId,
    attempt: attemptOverride = null,
    wrongQuestionIds = null,
    answers = null,
    questionSnapshots = null,
  }) {
    const cleanAttemptId = String(attemptId || '').trim();
    if (!cleanAttemptId) {
      const error = new Error('attemptId is required.');
      error.code = 'invalid-argument';
      throw error;
    }

    let attempt = attemptOverride;
    if (!attempt) {
      const snap = await db.collection('test_attempts').doc(cleanAttemptId).get();
      if (!snap.exists) {
        const error = new Error(`Attempt not found: ${cleanAttemptId}`);
        error.code = 'not-found';
        throw error;
      }
      attempt = { ...snap.data(), attemptId: cleanAttemptId };
    } else {
      attempt = { ...attempt, attemptId: cleanAttemptId };
    }

    if (resolveAuthority(attempt) !== AUTHORITY_SERVER_VERIFIED) {
      const error = new Error(
        'Only server_verified attempts can update authoritative analytics.',
      );
      error.code = 'failed-precondition';
      throw error;
    }
    if (attempt.status !== ATTEMPT_STATUS_SUBMITTED) {
      const error = new Error(
        'Attempt must be submitted before analytics apply.',
      );
      error.code = 'failed-precondition';
      throw error;
    }

    const uid = String(attempt.uid || '').trim();
    const courseId = String(attempt.courseId || '').trim();
    const testId = String(attempt.testId || '').trim();
    if (!uid || !courseId) {
      const error = new Error('Verified attempt missing uid/courseId.');
      error.code = 'failed-precondition';
      throw error;
    }

    const correct = asInt(attempt.correct);
    const wrong = asInt(attempt.wrong);
    const skipped = asInt(attempt.skipped);
    const attempted = asInt(
      attempt.attempted,
      correct + wrong,
    );
    // Match ProgressService cloud delta: correct + wrong + skipped
    const deltaAttempted = correct + wrong + skipped;
    const deltaCorrect = correct;

    const resolvedAnswers = Array.isArray(answers)
      ? answers
      : Array.isArray(attempt.answers)
        ? attempt.answers
        : [];
    const resolvedSnapshots = Array.isArray(questionSnapshots)
      ? questionSnapshots
      : Array.isArray(attempt.questionSnapshots)
        ? attempt.questionSnapshots
        : [];

    const explicitWrongIds = Array.isArray(wrongQuestionIds)
      ? uniqueStrings(wrongQuestionIds)
      : Array.isArray(attempt.wrongQuestionIds)
        ? uniqueStrings(attempt.wrongQuestionIds)
        : null;

    let trustedWrongIds = explicitWrongIds;
    const needsReconstruction =
      trustedWrongIds == null
      || (asInt(attempt.wrong) > 0 && trustedWrongIds.length === 0);

    if (needsReconstruction && resolvedSnapshots.length > 0) {
      const correctByQuestionId = {};
      for (const snapshot of resolvedSnapshots) {
        const questionId = String(snapshot?.questionId || '').trim();
        const correct = String(snapshot?.correctOption || '').trim();
        if (questionId && correct) {
          correctByQuestionId[questionId] = correct;
        }
      }
      trustedWrongIds = deriveWrongQuestionIds(
        resolvedAnswers,
        correctByQuestionId,
      );
    }
    if (trustedWrongIds == null) trustedWrongIds = [];

    const unitDeltas = buildUnitPerformanceDeltas({
      questionSnapshots: resolvedSnapshots,
      answers: resolvedAnswers,
      totalMarks: asNumber(attempt.totalMarks),
      totalQuestions: asInt(attempt.totalQuestions, resolvedSnapshots.length),
      negativeMarks: asNumber(attempt.negativeMarks),
      testId,
      attemptId: cleanAttemptId,
      courseId,
    });

    const outcome = await db.runTransaction(async (tx) => {
      const eRef = eventRef(cleanAttemptId);
      const pRef = progressRef(uid, courseId);
      const rRef = revisionRef(uid);

      const unitRefs = unitDeltas.map((delta) =>
        unitPerformanceRef(db, uid, delta.scopeKey),
      );

      const [eventSnap, progressSnap, revisionSnap, ...unitSnaps] =
        await Promise.all([
          tx.get(eRef),
          tx.get(pRef),
          tx.get(rRef),
          ...unitRefs.map((ref) => tx.get(ref)),
        ]);

      const existingEvent = eventSnap.exists ? eventSnap.data() || {} : {};
      const progressDone = existingEvent.progressApplied === true;
      const revisionDone = existingEvent.revisionApplied === true;
      const unitDone = existingEvent.unitPerformanceApplied === true;

      if (progressDone && revisionDone && unitDone) {
        return {
          duplicate: true,
          progressApplied: true,
          revisionApplied: true,
          unitPerformanceApplied: true,
          scopesUpdated: Array.isArray(existingEvent.unitPerformanceScopeKeys)
            ? existingEvent.unitPerformanceScopeKeys
            : [],
          questionsAttempted: asInt(
            progressSnap.exists
              ? progressSnap.data()?.overall?.questionsAttempted
              : 0,
          ),
          questionsCorrect: asInt(
            progressSnap.exists
              ? progressSnap.data()?.overall?.questionsCorrect
              : 0,
          ),
          wrongCount: Array.isArray(revisionSnap.data()?.wrongQuestions)
            ? revisionSnap.data().wrongQuestions.length
            : 0,
        };
      }

      let nextAttempted = asInt(
        progressSnap.exists
          ? progressSnap.data()?.overall?.questionsAttempted
          : 0,
      );
      let nextCorrect = asInt(
        progressSnap.exists
          ? progressSnap.data()?.overall?.questionsCorrect
          : 0,
      );
      let nextWrongCount = Array.isArray(revisionSnap.data()?.wrongQuestions)
        ? revisionSnap.data().wrongQuestions.length
        : 0;

      // --- Progress (only when not yet applied) ---
      if (!progressDone) {
        const priorOverall = progressSnap.exists
          ? progressSnap.data()?.overall || {}
          : {};
        const priorPapers = progressSnap.exists
          ? progressSnap.data()?.papers || {}
          : {};
        const priorChapters = progressSnap.exists
          ? progressSnap.data()?.chapters || {}
          : {};

        nextAttempted = asInt(priorOverall.questionsAttempted) + deltaAttempted;
        nextCorrect = asInt(priorOverall.questionsCorrect) + deltaCorrect;

        // Preserve completion/accuracy/chapters — legacy semantics unchanged.
        tx.set(
          pRef,
          {
            uid,
            courseId,
            overall: {
              completion: asNumber(priorOverall.completion),
              accuracy: asNumber(priorOverall.accuracy),
              chaptersCompleted: asInt(priorOverall.chaptersCompleted),
              totalChapters: asInt(priorOverall.totalChapters),
              questionsAttempted: nextAttempted,
              questionsCorrect: nextCorrect,
            },
            papers: priorPapers,
            chapters: priorChapters,
            lastUpdated: FieldValue.serverTimestamp(),
            appVersion: APP_VERSION,
            schemaVersion: 1,
            authority: AUTHORITY_SERVER_VERIFIED,
          },
          { merge: false },
        );
      }

      // --- Revision (only when not yet applied) ---
      if (!revisionDone) {
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
        nextWrongCount = merged.wrongQuestions.length;

        tx.set(
          rRef,
          {
            ...merged,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: false },
        );
      }

      // --- Canonical unit performance (additive; only when not yet applied) ---
      const scopesUpdated = [];
      if (!unitDone) {
        for (let i = 0; i < unitDeltas.length; i += 1) {
          const delta = unitDeltas[i];
          const prior = unitSnaps[i]?.exists ? unitSnaps[i].data() || {} : {};
          const merged = mergeUnitPerformance(prior, delta, {
            latestAttemptAt: FieldValue.serverTimestamp(),
          });
          tx.set(
            unitRefs[i],
            {
              ...merged,
              uid,
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: false },
          );
          scopesUpdated.push(delta.scopeKey);
        }
      }

      tx.set(
        eRef,
        {
          attemptId: cleanAttemptId,
          uid,
          testId,
          courseId,
          progressApplied: true,
          revisionApplied: true,
          unitPerformanceApplied: true,
          unitPerformanceScopeKeys: unitDone
            ? existingEvent.unitPerformanceScopeKeys || []
            : scopesUpdated,
          score: asNumber(attempt.score),
          correct,
          wrong,
          skipped,
          attempted,
          wrongQuestionIds: trustedWrongIds,
          appliedAt: FieldValue.serverTimestamp(),
          source: 'submitTestAttempt',
          authority: AUTHORITY_SERVER_VERIFIED,
        },
        { merge: true },
      );

      return {
        duplicate: false,
        progressApplied: true,
        revisionApplied: true,
        unitPerformanceApplied: true,
        scopesUpdated: unitDone
          ? existingEvent.unitPerformanceScopeKeys || []
          : scopesUpdated,
        questionsAttempted: nextAttempted,
        questionsCorrect: nextCorrect,
        wrongCount: nextWrongCount,
        wrongQuestionIds: trustedWrongIds,
      };
    });

    return {
      attemptId: cleanAttemptId,
      uid,
      courseId,
      testId,
      ...outcome,
      appliedAt: now().toISOString(),
    };
  }

  return {
    applyVerifiedTestAttemptSideEffects,
    applyVerifiedTestAttemptProgress: (args) =>
      applyVerifiedTestAttemptSideEffects(args),
    applyVerifiedTestAttemptRevision: (args) =>
      applyVerifiedTestAttemptSideEffects(args),
  };
}
