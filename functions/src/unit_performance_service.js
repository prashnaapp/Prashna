/**
 * Canonical unit performance aggregation from verified submitted attempts.
 *
 * Storage: user_progress/{uid}/unit_performance/{scopeKey}
 * Idempotency: test_attempt_events.unitPerformanceApplied
 *
 * Only snapshot-attributed questions with a verified CanonicalScope contribute.
 * Legacy mutable question docs are never used for attribution.
 */

import { tryResolveCanonicalScope } from './canonical_scope.js';

function asInt(value, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? Math.trunc(n) : fallback;
}

function asNumber(value, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function trimString(value) {
  if (value == null) return '';
  return String(value).trim();
}

function optionalString(value) {
  const trimmed = trimString(value);
  return trimmed || null;
}

/**
 * Resolve verified canonical scope from a frozen question snapshot.
 * Returns null when attribution is missing or ambiguous.
 */
export function resolveScopeFromQuestionSnapshot(snapshot, fallbackCourseId) {
  if (!snapshot || typeof snapshot !== 'object') return null;

  if (optionalString(snapshot.scopeKey) && optionalString(snapshot.syllabusUnitId)) {
    const fromKey = tryResolveCanonicalScope({
      courseId: snapshot.courseId || fallbackCourseId,
      paperId: snapshot.paperId,
      partId: snapshot.partId,
      syllabusUnitId: snapshot.syllabusUnitId,
      majorStudyAreaId: snapshot.majorStudyAreaId,
      contentTopicId: snapshot.contentTopicId,
      topicId: snapshot.canonicalTopicId || snapshot.topicId,
      lessonId: snapshot.lessonId,
      shape: snapshot.scopeShape || snapshot.shape,
    });
    if (fromKey) return fromKey;
  }

  return tryResolveCanonicalScope({
    courseId: snapshot.courseId || fallbackCourseId,
    paperId: snapshot.paperId,
    partId: snapshot.partId,
    syllabusUnitId: snapshot.syllabusUnitId,
    majorStudyAreaId: snapshot.majorStudyAreaId,
    contentTopicId: snapshot.contentTopicId,
    topicId: snapshot.canonicalTopicId || snapshot.topicId,
    lessonId: snapshot.lessonId,
    shape: snapshot.scopeShape || snapshot.shape,
  });
}

/**
 * Build per-scope deltas for one completed attempt.
 *
 * Scoring uses the frozen attempt formula:
 *   marksPerQuestion = totalMarks / totalQuestions
 *   marksObtained = correct * marksPerQuestion - wrong * negativeMarks (clamped ≥ 0)
 */
export function buildUnitPerformanceDeltas({
  questionSnapshots,
  answers,
  totalMarks,
  totalQuestions,
  negativeMarks,
  testId,
  attemptId,
  courseId,
}) {
  const snapshots = Array.isArray(questionSnapshots) ? questionSnapshots : [];
  if (snapshots.length === 0) return [];

  const selectedByQuestionId = {};
  for (const answer of answers || []) {
    const questionId = trimString(answer?.questionId);
    if (!questionId) continue;
    const selected = optionalString(answer?.selectedOption);
    if (!selected) continue;
    selectedByQuestionId[questionId] = selected;
  }

  const questionCount = asInt(totalQuestions, snapshots.length);
  const marks = asNumber(totalMarks);
  const neg = asNumber(negativeMarks);
  const marksPerQuestion = questionCount === 0 ? 0 : marks / questionCount;

  const correctByQuestionId = {};
  for (const snapshot of snapshots) {
    const questionId = trimString(snapshot?.questionId);
    if (!questionId) continue;
    const correct = optionalString(snapshot?.correctOption);
    if (correct) correctByQuestionId[questionId] = correct;
  }

  /** @type {Map<string, object>} */
  const byScope = new Map();

  for (const snapshot of snapshots) {
    const questionId = trimString(snapshot?.questionId);
    if (!questionId) continue;

    const scope = resolveScopeFromQuestionSnapshot(snapshot, courseId);
    if (!scope) continue;

    let bucket = byScope.get(scope.scopeKey);
    if (!bucket) {
      bucket = {
        scopeKey: scope.scopeKey,
        courseId: scope.courseId,
        paperId: scope.paperId,
        partId: scope.partId,
        syllabusUnitId: scope.syllabusUnitId,
        scopeShape: scope.shape,
        correct: 0,
        wrong: 0,
        skipped: 0,
        questionCount: 0,
      };
      byScope.set(scope.scopeKey, bucket);
    }

    bucket.questionCount += 1;
    const selected = selectedByQuestionId[questionId];
    const correctOption = correctByQuestionId[questionId];
    if (!selected || !correctOption) {
      bucket.skipped += 1;
      continue;
    }
    if (selected === correctOption) {
      bucket.correct += 1;
    } else {
      bucket.wrong += 1;
    }
  }

  const deltas = [];
  for (const bucket of byScope.values()) {
    const rawMarks =
      bucket.correct * marksPerQuestion - bucket.wrong * neg;
    const marksObtained = Number((rawMarks < 0 ? 0 : rawMarks).toFixed(2));
    const totalMarksForScope = Number(
      (bucket.questionCount * marksPerQuestion).toFixed(2),
    );
    const answered = bucket.correct + bucket.wrong;
    const accuracy =
      answered === 0 ? 0 : Number(((bucket.correct / answered) * 100).toFixed(1));
    const percentage =
      totalMarksForScope === 0
        ? 0
        : Number(((marksObtained / totalMarksForScope) * 100).toFixed(1));

    deltas.push({
      scopeKey: bucket.scopeKey,
      courseId: bucket.courseId,
      paperId: bucket.paperId,
      partId: bucket.partId,
      syllabusUnitId: bucket.syllabusUnitId,
      scopeShape: bucket.scopeShape,
      testsAttempted: 1,
      testsCompleted: 1,
      questionsAttempted: answered,
      correct: bucket.correct,
      wrong: bucket.wrong,
      skipped: bucket.skipped,
      totalMarks: totalMarksForScope,
      marksObtained,
      accuracy,
      percentage,
      lastTestId: trimString(testId) || null,
      lastAttemptId: trimString(attemptId) || null,
    });
  }

  return deltas;
}

/**
 * Merge one attempt delta into a prior unit performance document.
 */
export function mergeUnitPerformance(prior, delta, { latestAttemptAt } = {}) {
  const prev = prior && typeof prior === 'object' ? prior : {};
  const correct = asInt(prev.correct) + asInt(delta.correct);
  const wrong = asInt(prev.wrong) + asInt(delta.wrong);
  const skipped = asInt(prev.skipped) + asInt(delta.skipped);
  const questionsAttempted =
    asInt(prev.questionsAttempted) + asInt(delta.questionsAttempted);
  const marksObtained = Number(
    (asNumber(prev.marksObtained) + asNumber(delta.marksObtained)).toFixed(2),
  );
  const totalMarks = Number(
    (asNumber(prev.totalMarks) + asNumber(delta.totalMarks)).toFixed(2),
  );
  const answered = correct + wrong;
  const accuracy =
    answered === 0 ? 0 : Number(((correct / answered) * 100).toFixed(1));
  const percentage =
    totalMarks === 0 ? 0 : Number(((marksObtained / totalMarks) * 100).toFixed(1));

  const priorBestMarks = asNumber(prev.bestMarks);
  const priorBestPercentage = asNumber(prev.bestPercentage);
  const bestMarks = Math.max(priorBestMarks, asNumber(delta.marksObtained));
  const bestPercentage = Math.max(
    priorBestPercentage,
    asNumber(delta.percentage),
  );

  return {
    scopeKey: delta.scopeKey,
    courseId: delta.courseId,
    paperId: delta.paperId,
    partId: delta.partId ?? null,
    syllabusUnitId: delta.syllabusUnitId,
    scopeShape: delta.scopeShape || prev.scopeShape || null,
    testsAttempted: asInt(prev.testsAttempted) + asInt(delta.testsAttempted),
    testsCompleted: asInt(prev.testsCompleted) + asInt(delta.testsCompleted),
    questionsAttempted,
    correct,
    wrong,
    skipped,
    totalMarks,
    marksObtained,
    accuracy,
    percentage,
    bestMarks: Number(bestMarks.toFixed(2)),
    bestPercentage: Number(bestPercentage.toFixed(1)),
    latestAttemptAt: latestAttemptAt ?? prev.latestAttemptAt ?? null,
    lastTestId: delta.lastTestId || prev.lastTestId || null,
    lastAttemptId: delta.lastAttemptId || prev.lastAttemptId || null,
    authority: 'server_verified',
    schemaVersion: 1,
  };
}

export function unitPerformanceRef(db, uid, scopeKey) {
  return db
    .collection('user_progress')
    .doc(uid)
    .collection('unit_performance')
    .doc(scopeKey);
}
