import assert from 'node:assert/strict';
import test from 'node:test';

import { planPaperWiseHierarchyCleanup } from './paper_wise_question_hierarchy_dry_run.mjs';

test('plans removal of stale hierarchy fields only', () => {
  const plan = planPaperWiseHierarchyCleanup({
    questions: [
      {
        id: 'q-stale',
        contentArea: 'testSeries',
        testSeriesCategory: 'part',
        courseId: 'group-ii',
        paperId: 'group-ii-paper-iv',
        partId: 'group-ii-paper-iv-part-01',
        topicId: 'topic-1',
        status: 'draft',
      },
      {
        id: 'q-clean',
        contentArea: 'testSeries',
        testSeriesCategory: 'part',
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
      },
      {
        id: 'q-chapter',
        contentArea: 'chapter',
        courseId: 'group-ii',
        partId: 'keep-me',
      },
    ],
    assignments: [{ questionId: 'q-stale', testId: 't-paper-iv' }],
    tests: [{ id: 't-paper-iv', questionIds: ['q-stale'] }],
  });

  assert.equal(plan.apply, false);
  assert.equal(plan.changes.length, 1);
  assert.deepEqual(plan.changes[0], {
    questionId: 'q-stale',
    courseId: 'group-ii',
    paperId: 'group-ii-paper-iv',
    fieldsToRemove: ['partId', 'topicId'],
    assignmentOwner: 't-paper-iv',
    referencingTestId: 't-paper-iv',
  });
});
