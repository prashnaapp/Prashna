#!/usr/bin/env node

/**
 * Read-only planner for legacy Paper-wise Tests that still store partId.
 *
 * This module accepts already-read documents so it cannot access Firestore or
 * mutate production data. A future migration may remove only partId after
 * reviewing this report and preserving a rollback snapshot.
 */

export function planPaperWiseTestPartCleanup({
  tests = [],
  assignments = [],
} = {}) {
  const owners = new Map(
    assignments
      .filter((row) => row.testId && row.questionId)
      .map((row) => [row.testId, row.questionId]),
  );
  const changes = [];
  for (const test of tests) {
    if (test.category !== 'part') continue;
    if (test.partId == null || String(test.partId).trim() === '') continue;
    const questionIds = Array.isArray(test.questionIds)
      ? test.questionIds.filter((id) => String(id ?? '').trim() !== '')
      : [];
    changes.push({
      testId: test.id ?? null,
      title: test.title ?? null,
      courseId: test.courseId ?? null,
      paperId: test.paperId ?? null,
      partId: test.partId,
      status: test.status ?? null,
      questionCount: test.questionCount ?? null,
      questionIdsCount: questionIds.length,
      assignmentQuestionIds: [...owners.entries()]
        .filter(([testId]) => testId === test.id)
        .map(([, questionId]) => questionId),
    });
  }
  return {
    mode: 'dry-run',
    apply: false,
    changes,
    preserve: [
      'id',
      'title',
      'courseId',
      'paperId',
      'questionIds',
      'question_assignments',
      'status',
      'isPublished',
      'questionCount',
      'totalMarks',
      'durationMinutes',
    ],
    rollback: 'Snapshot each removed partId before any future delete.',
  };
}

if (process.argv[1]?.endsWith('paper_wise_test_part_dry_run.mjs')) {
  if (process.argv.includes('--apply')) {
    console.error('Apply is not implemented. This script is dry-run only.');
    process.exit(1);
  }
  console.log(JSON.stringify(planPaperWiseTestPartCleanup(), null, 2));
}
