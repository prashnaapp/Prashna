import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

import {
  buildDryRunReport,
  computeContentFingerprint,
  normalizeQuestionSearchText,
  parseCliArgs,
  readProductionData,
} from './question_content_m1_dry_run.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const golden = JSON.parse(
  await readFile(resolve(here, 'fixtures/question_content_m1_golden.json'), 'utf8'),
);

const catalog = [
  {
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    partId: null,
    syllabusUnitId: 'group-ii-paper-i-area-01',
  },
  {
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-02',
    syllabusUnitId: 'group-ii-paper-ii-part-02-topic-01',
  },
  {
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    partId: null,
    syllabusUnitId: 'group-iii-paper-i-unit-01',
  },
];

function question(id, overrides = {}) {
  return {
    id,
    data: {
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-02',
      topicId: 'group-ii-paper-ii-part-02-topic-01',
      question: 'A valid Question',
      options: ['A', 'B'],
      correctOption: 'A',
      marks: 1,
      estimatedTimeSeconds: 60,
      status: 'published',
      isActive: true,
      ...overrides,
    },
  };
}

function chapterTest(id, questionIds, overrides = {}) {
  return {
    id,
    data: {
      courseId: 'group-ii',
      category: 'chapter',
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-02',
      syllabusUnitId: 'group-ii-paper-ii-part-02-topic-01',
      status: 'published',
      isPublished: true,
      questionIds,
      questionCount: questionIds.length,
      totalMarks: questionIds.length,
      durationMinutes: questionIds.length,
      ...overrides,
    },
  };
}

function report({ questions, tests, assignments = [] }) {
  return buildDryRunReport({
    projectId: 'prashna-67689',
    questions,
    tests,
    assignments,
    catalog,
    timestamp: '2026-09-28T03:00:00.000Z',
    runId: 'm1-test',
    gitCommit: 'test-commit',
  });
}

test('CLI requires --dry-run', () => {
  assert.throws(() => parseCliArgs(['node', 'tool']), /requires the --dry-run/);
});

test('CLI has no apply mode', () => {
  assert.throws(
    () => parseCliArgs(['node', 'tool', '--dry-run', '--apply']),
    /--apply is not supported/,
  );
});

test('production reader allowlists only the three read collections', async () => {
  const calls = [];
  const db = {
    collection(name) {
      calls.push(name);
      return {
        orderBy() {
          return {
            async get() {
              return { docs: [] };
            },
          };
        },
      };
    },
  };
  const result = await readProductionData(db);
  assert.deepEqual(result, { questions: [], tests: [], assignments: [] });
  assert.deepEqual(calls.sort(), [
    'question_assignments',
    'questions',
    'tests',
  ]);
});

test('migration module contains no Firestore mutation method calls', async () => {
  const source = await readFile(
    resolve(here, 'question_content_m1_dry_run.mjs'),
    'utf8',
  );
  assert.equal(source.includes('db.batch('), false);
  assert.equal(source.includes('db.runTransaction('), false);
  assert.equal(source.includes('db.bulkWriter('), false);
  assert.equal(source.includes('.update('), false);
  assert.equal(source.includes('.create('), false);
  assert.equal(source.includes('.delete('), false);
});

test('canonical Paper-II Question is SAFE_AUTOMATIC', () => {
  const result = report({
    questions: [question('q-paper-ii')],
    tests: [chapterTest('test-1', ['q-paper-ii'])],
  });
  assert.equal(result.questions[0].classification, 'SAFE_AUTOMATIC');
  assert.equal(result.questions[0].proposedPatch.contentArea.value, 'chapter');
});

test('canonical Paper-I Question is SAFE_AUTOMATIC', () => {
  const result = report({
    questions: [
      question('q-paper-i', {
        paperId: 'group-ii-paper-i',
        partId: undefined,
        topicId: undefined,
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      }),
    ],
    tests: [
      chapterTest('test-1', ['q-paper-i'], {
        paperId: 'group-ii-paper-i',
        partId: undefined,
        syllabusUnitId: 'group-ii-paper-i-area-01',
      }),
    ],
  });
  assert.equal(result.questions[0].classification, 'SAFE_AUTOMATIC');
});

test('legacy paper-1 Question is MANUAL_REVIEW without ownership patch', () => {
  const result = report({
    questions: [
      question('q-legacy', {
        paperId: 'paper-1',
        partId: undefined,
        topicId: 'topic-1',
        sectionId: 'section-1',
      }),
    ],
    tests: [
      chapterTest('test-1', ['q-legacy'], {
        paperId: undefined,
        partId: undefined,
        syllabusUnitId: undefined,
      }),
    ],
  });
  assert.equal(result.questions[0].classification, 'MANUAL_REVIEW');
  assert.deepEqual(result.questions[0].proposedPatch, {});
});

test('Group-III malformed Question is MANUAL_REVIEW', () => {
  const result = report({
    questions: [
      question('q-group-iii', {
        courseId: 'group-iii',
        paperId: 'paper-1',
        partId: undefined,
        topicId: 'topic-1',
        sectionId: 'section-1',
      }),
    ],
    tests: [
      {
        id: 'test-1',
        data: {
          courseId: 'group-iii',
          category: 'chapter',
          status: 'draft',
          isPublished: false,
          questionIds: ['q-group-iii'],
          questionCount: 1,
          totalMarks: 1,
          durationMinutes: 1,
        },
      },
    ],
  });
  assert.equal(result.questions[0].classification, 'MANUAL_REVIEW');
  assert.deepEqual(result.questions[0].proposedPatch, {});
});

for (const goldenCase of golden.cases) {
  test(`golden fingerprint parity: ${goldenCase.name}`, () => {
    assert.equal(
      computeContentFingerprint(goldenCase.question),
      goldenCase.expectedFingerprint,
    );
    assert.equal(
      normalizeQuestionSearchText(goldenCase.question),
      goldenCase.expectedSearchText,
    );
  });
}

test('existing derived fields produce NO_OP', () => {
  const base = question('q-existing');
  const fingerprint = computeContentFingerprint(base.data);
  const searchText = normalizeQuestionSearchText(base.data);
  const result = report({
    questions: [
      question('q-existing', {
        contentArea: 'chapter',
        contentFingerprint: fingerprint,
        questionSearchText: searchText,
      }),
    ],
    tests: [chapterTest('test-1', ['q-existing'])],
  });
  assert.equal(
    result.questions[0].proposedPatch.contentArea.operation,
    'NO_OP',
  );
  assert.equal(
    result.questions[0].proposedPatch.contentFingerprint.operation,
    'NO_OP',
  );
  assert.equal(
    result.questions[0].proposedPatch.questionSearchText.operation,
    'NO_OP',
  );
});

test('missing derived fields produce PATCH_REQUIRED', () => {
  const result = report({
    questions: [question('q-missing-fields')],
    tests: [chapterTest('test-1', ['q-missing-fields'])],
  });
  assert.equal(
    result.questions[0].proposedPatch.contentFingerprint.operation,
    'PATCH_REQUIRED',
  );
  assert.equal(
    result.questions[0].proposedPatch.questionSearchText.operation,
    'PATCH_REQUIRED',
  );
});

test('unique compatible edge produces safe assignment proposal', () => {
  const result = report({
    questions: [question('q-1')],
    tests: [chapterTest('test-1', ['q-1'])],
  });
  assert.equal(result.assignments[0].classification, 'SAFE_AUTOMATIC');
  assert.deepEqual(result.assignments[0].proposedAssignment, {
    questionId: 'q-1',
    testId: 'test-1',
    courseId: 'group-ii',
    assignedAt: 'APPLY_TIME_VALUE',
    assignedBy: 'APPLY_TIME_VALUE',
  });
});

test('ambiguous legacy edge is MANUAL_REVIEW', () => {
  const result = report({
    questions: [question('q-legacy', { paperId: 'paper-1' })],
    tests: [chapterTest('test-1', ['q-legacy'])],
  });
  assert.equal(result.assignments[0].classification, 'MANUAL_REVIEW');
  assert.equal(result.assignments[0].proposedAssignment, null);
});

test('multi-Test Question fixture is MANUAL_REVIEW', () => {
  const result = report({
    questions: [question('q-shared')],
    tests: [
      chapterTest('test-1', ['q-shared']),
      chapterTest('test-2', ['q-shared']),
    ],
  });
  assert.equal(result.questions[0].classification, 'MANUAL_REVIEW');
  assert.equal(result.assignments[0].classification, 'MANUAL_REVIEW');
  assert.equal(result.assignments[1].classification, 'MANUAL_REVIEW');
  assert.equal(result.assignments[0].proposedAssignment, null);
  assert.equal(result.assignments[1].proposedAssignment, null);
});

test('missing Question fixture is MANUAL_REVIEW', () => {
  const result = report({
    questions: [],
    tests: [chapterTest('test-1', ['q-missing'])],
  });
  assert.equal(result.tests[0].aggregate.status, 'CANNOT_VERIFY');
  assert.equal(result.assignments[0].classification, 'MANUAL_REVIEW');
  assert.equal(result.assignments[0].proposedAssignment, null);
});

test('aggregate match is detected', () => {
  const result = report({
    questions: [question('q-1'), question('q-2')],
    tests: [chapterTest('test-1', ['q-1', 'q-2'])],
  });
  assert.equal(result.tests[0].aggregate.status, 'MATCH');
  assert.equal(result.tests[0].classification, 'SAFE_NO_CHANGE');
});

test('stale totalMarks is detected without a mutation proposal beyond aggregates', () => {
  const result = report({
    questions: [question('q-1'), question('q-2')],
    tests: [
      chapterTest('test-1', ['q-1', 'q-2'], {
        totalMarks: 20,
      }),
    ],
  });
  assert.equal(result.tests[0].aggregate.status, 'STALE');
  assert.equal(result.tests[0].aggregate.proposedPatch.totalMarks, 2);
  assert.equal(result.tests[0].statusCheck.automaticStatusPatch, false);
});

test('status mismatch is reported but never auto-patched', () => {
  const result = report({
    questions: [question('q-1', { status: 'archived', isActive: false })],
    tests: [chapterTest('test-1', ['q-1'])],
  });
  assert.equal(result.tests[0].statusCheck.mismatches.length, 1);
  assert.equal(result.tests[0].statusCheck.automaticStatusPatch, false);
});

test('report declares zero writes and no mutation calls', () => {
  const result = report({
    questions: [question('q-1')],
    tests: [chapterTest('test-1', ['q-1'])],
  });
  assert.equal(result.metadata.writesPerformed, 0);
  assert.deepEqual(result.metadata.firestoreMutationMethodsCalled, []);
});

test('manual-review Question receives no automatic canonical ownership patch', () => {
  const result = report({
    questions: [question('q-legacy', { paperId: 'paper-1' })],
    tests: [chapterTest('test-1', ['q-legacy'])],
  });
  assert.equal(result.questions[0].classification, 'MANUAL_REVIEW');
  assert.equal('contentArea' in result.questions[0].proposedPatch, false);
  assert.equal(result.assignments[0].proposedAssignment, null);
});

test('assignment summary counts remain unchanged after proposal gating', () => {
  const result = report({
    questions: [
      question('q-safe'),
      question('q-legacy', { paperId: 'paper-1' }),
    ],
    tests: [
      chapterTest('test-safe', ['q-safe']),
      chapterTest('test-manual', ['q-legacy']),
    ],
  });
  assert.deepEqual(result.summary.assignments, {
    SAFE_AUTOMATIC: 1,
    MANUAL_REVIEW: 1,
  });
  assert.equal(result.metadata.writesPerformed, 0);
});
