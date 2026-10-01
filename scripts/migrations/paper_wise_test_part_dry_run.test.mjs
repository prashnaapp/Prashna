import test from 'node:test';
import assert from 'node:assert/strict';

import {
  planPaperWiseTestPartCleanup,
} from './paper_wise_test_part_dry_run.mjs';

test('plans only Paper-wise tests with a stored partId', () => {
  const report = planPaperWiseTestPartCleanup({
    tests: [
      {
        id: 't-legacy',
        title: 'Legacy Paper IV',
        courseId: 'group-ii',
        paperId: 'group-ii-paper-iv',
        category: 'part',
        partId: 'old-part',
        status: 'draft',
        questionCount: 2,
        questionIds: ['q1', 'q2'],
      },
      {
        id: 't-canonical',
        category: 'part',
        paperId: 'group-ii-paper-iv',
        questionIds: ['q3'],
      },
      {
        id: 't-chapter',
        category: 'chapter',
        partId: 'chapter-part',
      },
    ],
    assignments: [
      { testId: 't-legacy', questionId: 'q1' },
    ],
  });

  assert.equal(report.mode, 'dry-run');
  assert.equal(report.apply, false);
  assert.deepEqual(report.changes, [{
    testId: 't-legacy',
    title: 'Legacy Paper IV',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-iv',
    partId: 'old-part',
    status: 'draft',
    questionCount: 2,
    questionIdsCount: 2,
    assignmentQuestionIds: ['q1'],
  }]);
});

