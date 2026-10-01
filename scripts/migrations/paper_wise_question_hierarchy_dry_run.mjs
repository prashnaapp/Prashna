#!/usr/bin/env node

/**
 * Dry-run planner for Paper-wise Test Series Questions that still store
 * Chapter hierarchy fields.
 *
 * This file does not connect to Firestore and has no apply path.
 * A future apply must delete only the listed fields and write a rollback
 * snapshot of those values first.
 */

export const HIERARCHY_FIELDS = Object.freeze([
  'partId',
  'topicId',
  'lessonId',
  'majorStudyAreaId',
  'contentTopicId',
  'syllabusUnitId',
]);

export function planPaperWiseHierarchyCleanup({
  questions = [],
  assignments = [],
  tests = [],
} = {}) {
  const owners = new Map(
    assignments
      .filter((row) => row.questionId && row.testId)
      .map((row) => [row.questionId, row.testId]),
  );
  const testsById = new Map(tests.map((test) => [test.id, test]));
  const changes = [];
  for (const question of questions) {
    if (question.contentArea !== 'testSeries') continue;
    if (question.testSeriesCategory !== 'part') continue;
    const fields = HIERARCHY_FIELDS.filter((field) => {
      const value = question[field];
      return value != null && String(value).trim() !== '';
    });
    if (fields.length === 0) continue;
    const owner = owners.get(question.id) ?? null;
    const test = owner ? testsById.get(owner) : null;
    changes.push({
      questionId: question.id,
      courseId: question.courseId ?? null,
      paperId: question.paperId ?? null,
      fieldsToRemove: fields,
      assignmentOwner: owner,
      referencingTestId: test?.id ?? owner,
    });
  }
  return {
    mode: 'dry-run',
    apply: false,
    preserve: [
      'content',
      'status',
      'isActive',
      'contentArea',
      'testSeriesCategory',
      'courseId',
      'paperId',
      'question_assignments',
      'tests.questionIds',
    ],
    rollback: 'Snapshot fieldsToRemove values before any future delete.',
    changes,
  };
}

if (process.argv[1] && process.argv[1].endsWith('paper_wise_question_hierarchy_dry_run.mjs')) {
  if (process.argv.includes('--apply')) {
    console.error('Apply is not implemented. This script is dry-run only.');
    process.exit(1);
  }
  console.log(JSON.stringify(planPaperWiseHierarchyCleanup(), null, 2));
}
