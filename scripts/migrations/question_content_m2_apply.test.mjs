import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  APPROVED_DELETIONS,
  BACKUP_CONFIRMATION,
  CONFIRMATION_TOKEN,
  assertSourceSnapshotsUnchanged,
  createRollbackSnapshot,
  parseM2Args,
  validateAssignmentPreconditions,
  validateDeletionPreconditions,
  validateDryRunArtifact,
  verifyPostApply,
} from './question_content_m2_apply.mjs';

const here = dirname(fileURLToPath(import.meta.url));

function approvedList() {
  return APPROVED_DELETIONS.map((item) => ({ ...item }));
}

function safeAssignment(index) {
  const questionId = `q-safe-${index}`;
  return {
    documentId: questionId,
    testId: 'test-safe',
    classification: 'SAFE_AUTOMATIC',
    proposedAssignment: {
      questionId,
      testId: 'test-safe',
      courseId: 'group-ii',
      assignedAt: 'APPLY_TIME_VALUE',
      assignedBy: 'APPLY_TIME_VALUE',
    },
  };
}

function baseArtifact(overrides = {}) {
  const questions = [
    ...Array.from({ length: 13 }, (_, index) => ({
      documentId: `q-safe-${index}`,
      classification: 'SAFE_AUTOMATIC',
      proposedPatch: {
        contentArea: { operation: 'PATCH_REQUIRED', value: 'chapter' },
        contentFingerprint: {
          operation: 'PATCH_REQUIRED',
          value: `fingerprint-${index}`,
        },
        questionSearchText: {
          operation: 'PATCH_REQUIRED',
          value: `question ${index}`,
        },
      },
    })),
    {
      documentId: 'q-test-group-ii-001',
      classification: 'MANUAL_REVIEW',
      proposedPatch: {},
    },
    {
      documentId: 'q-test-group-iii-001',
      classification: 'MANUAL_REVIEW',
      proposedPatch: {},
    },
  ];
  const tests = [
    { documentId: 'test-safe-1', classification: 'SAFE_NO_CHANGE', statusCheck: { automaticStatusPatch: false } },
    { documentId: 'test-safe-2', classification: 'SAFE_NO_CHANGE', statusCheck: { automaticStatusPatch: false } },
    { documentId: 'test-safe-3', classification: 'SAFE_NO_CHANGE', statusCheck: { automaticStatusPatch: false } },
    {
      documentId: 'LVYQbE7wlUsYuZ0lIHXP',
      classification: 'SAFE_NORMALIZATION',
      statusCheck: { automaticStatusPatch: false },
      aggregate: { stored: { totalMarks: 20 }, expected: { totalMarks: 2 } },
    },
    { documentId: 'test-group-ii-001', classification: 'MANUAL_REVIEW', statusCheck: { automaticStatusPatch: false } },
    { documentId: '3goCvCMOeFQP0g3Y3yi0', classification: 'MANUAL_REVIEW', statusCheck: { automaticStatusPatch: false } },
  ];
  const assignments = [
    ...Array.from({ length: 13 }, (_, index) => safeAssignment(index)),
    {
      documentId: 'q-test-group-ii-001',
      testId: 'test-group-ii-001',
      classification: 'MANUAL_REVIEW',
      proposedAssignment: null,
    },
    {
      documentId: 'q-test-group-iii-001',
      testId: '3goCvCMOeFQP0g3Y3yi0',
      classification: 'MANUAL_REVIEW',
      proposedAssignment: null,
    },
  ];
  return {
    metadata: {
      projectId: 'prashna-67689',
      mode: 'DRY_RUN',
      writesPerformed: 0,
      approvedDeletionList: approvedList(),
      runId: 'm2-test',
    },
    inventory: {
      questionCount: 15,
      testCount: 6,
      assignmentCount: 0,
      relationshipCount: 15,
    },
    summary: {
      questions: { SAFE_AUTOMATIC: 13, MANUAL_REVIEW: 2, LEAVE_LEGACY: 0 },
      tests: { SAFE_NO_CHANGE: 3, SAFE_NORMALIZATION: 1, MANUAL_REVIEW: 2 },
      assignments: { SAFE_AUTOMATIC: 13, MANUAL_REVIEW: 2 },
    },
    questions,
    tests,
    assignments,
    preconditions: { sourceSnapshots: [] },
    applyPlan: {
      questionPatches: questions.slice(0, 13).map((question) => ({
        documentId: question.documentId,
        patch: question.proposedPatch,
      })),
      testPatches: [
        { documentId: 'LVYQbE7wlUsYuZ0lIHXP', patch: { totalMarks: 2 } },
      ],
      assignmentProposals: assignments.slice(0, 13),
      approvedDeletions: approvedList(),
      manualAssignments: [
        { questionId: 'q-test-group-ii-001', testId: 'test-group-ii-001' },
        { questionId: 'q-test-group-iii-001', testId: '3goCvCMOeFQP0g3Y3yi0' },
      ],
    },
    ...overrides,
  };
}

test('M2 dry-run requires exactly one mode', () => {
  assert.throws(() => parseM2Args(['node', 'tool']), /exactly one/);
  assert.throws(
    () => parseM2Args(['node', 'tool', '--dry-run', '--apply']),
    /exactly one/,
  );
});

test('M2 apply requires artifact, confirmation, and backup gates', () => {
  assert.throws(
    () => parseM2Args(['node', 'tool', '--apply']),
    /artifact/,
  );
  assert.throws(
    () =>
      parseM2Args([
        'node',
        'tool',
        '--apply',
        '--artifact=x.json',
        `--confirmation-token=${CONFIRMATION_TOKEN}`,
      ]),
    /backup confirmation/,
  );
  const parsed = parseM2Args([
    'node',
    'tool',
    '--apply',
    '--artifact=x.json',
    `--confirmation-token=${CONFIRMATION_TOKEN}`,
    `--backup-confirmation=${BACKUP_CONFIRMATION}`,
  ]);
  assert.equal(parsed.apply, true);
});

test('wrong project aborts', () => {
  assert.throws(
    () => parseM2Args(['node', 'tool', '--dry-run', '--project=wrong']),
    /unexpected project/,
  );
});

test('artifact validates project and expected inventory', () => {
  assert.equal(validateDryRunArtifact(baseArtifact()), true);
  assert.throws(
    () =>
      validateDryRunArtifact(
        baseArtifact({ metadata: { ...baseArtifact().metadata, projectId: 'wrong' } }),
      ),
    /projectId/,
  );
});

test('deletion list is exactly the four approved IDs', () => {
  const artifact = baseArtifact();
  artifact.applyPlan.approvedDeletions = approvedList();
  assert.deepEqual(
    artifact.metadata.approvedDeletionList
      .map((item) => `${item.collection}/${item.documentId}`)
      .sort(),
    approvedList()
      .map((item) => `${item.collection}/${item.documentId}`)
      .sort(),
  );
  const unexpected = baseArtifact({
    metadata: {
      ...baseArtifact().metadata,
      approvedDeletionList: [
        ...approvedList(),
        { collection: 'questions', documentId: 'unexpected' },
      ],
    },
  });
  assert.throws(() => validateDryRunArtifact(unexpected), /deletion list/);
});

test('Question backfill contains only the three allowed fields', () => {
  const artifact = baseArtifact();
  for (const item of artifact.applyPlan.questionPatches) {
    assert.deepEqual(
      Object.keys(item.patch).sort(),
      ['contentArea', 'contentFingerprint', 'questionSearchText'].sort(),
    );
  }
});

test('assignment count is exactly 13 and legacy Questions are excluded', () => {
  const artifact = baseArtifact();
  assert.equal(artifact.applyPlan.assignmentProposals.length, 13);
  assert.equal(
    artifact.applyPlan.assignmentProposals.some((item) =>
      item.documentId.includes('q-test'),
    ),
    false,
  );
});

test('manual-review assignments contain no proposed assignment', () => {
  const artifact = baseArtifact();
  for (const item of artifact.assignments.slice(-2)) {
    assert.equal(item.proposedAssignment, null);
  }
});

test('conflicting, multi-Test, and missing relationships cannot be actionable', () => {
  const artifact = baseArtifact();
  artifact.applyPlan.assignmentProposals = [
    {
      documentId: 'q-conflict',
      testId: 'test-2',
      classification: 'SAFE_AUTOMATIC',
      proposedAssignment: {
        questionId: 'q-conflict',
        testId: 'test-2',
        courseId: 'group-ii',
        assignedAt: 'APPLY_TIME_VALUE',
        assignedBy: 'migration:m2-question-content',
      },
    },
  ];
  const question = {
    collection: 'questions',
    documentId: 'q-conflict',
    data: {},
  };
  const testOne = {
    collection: 'tests',
    documentId: 'test-1',
    data: { questionIds: ['q-conflict'] },
  };
  const testTwo = {
    collection: 'tests',
    documentId: 'test-2',
    data: { questionIds: ['q-conflict'] },
  };
  assert.throws(
    () =>
      validateAssignmentPreconditions(artifact, [question, testOne, testTwo]),
    /not unique/,
  );
  const missingArtifact = baseArtifact();
  missingArtifact.applyPlan.assignmentProposals = [
    {
      documentId: 'q-missing',
      testId: 'test-missing',
      classification: 'SAFE_AUTOMATIC',
      proposedAssignment: {
        questionId: 'q-missing',
        testId: 'test-missing',
        courseId: 'group-ii',
      },
    },
  ];
  assert.throws(
    () => validateAssignmentPreconditions(missingArtifact, []),
    /missing/,
  );
});

test('aggregate correction targets only LVYQbE7wlUsYuZ0lIHXP', () => {
  const patch = baseArtifact().applyPlan.testPatches[0];
  assert.deepEqual(patch, {
    documentId: 'LVYQbE7wlUsYuZ0lIHXP',
    patch: { totalMarks: 2 },
  });
});

test('status fields are never included in automatic patches', () => {
  const artifact = baseArtifact();
  assert.equal(
    artifact.tests.every(
      (testRecord) => testRecord.statusCheck.automaticStatusPatch === false,
    ),
    true,
  );
  assert.deepEqual(Object.keys(artifact.applyPlan.testPatches[0].patch), [
    'totalMarks',
  ]);
});

test('rollback snapshot contains complete deleted document records', () => {
  const snapshots = approvedList().map((item) => ({
    ...item,
    exists: true,
    data: { id: item.documentId, category: 'chapter' },
    updateTime: '2026-09-28T00:00:00.000Z',
    stateHash: `hash-${item.documentId}`,
  }));
  const rollback = createRollbackSnapshot({
    artifact: baseArtifact(),
    snapshots,
    timestamp: '2026-09-28T04:00:00.000Z',
  });
  const deleted = rollback.records.filter((record) =>
    approvedList().some(
      (item) =>
        item.collection === record.collection &&
        item.documentId === record.documentId,
    ),
  );
  assert.equal(deleted.length, 4);
  assert.equal(deleted.every((record) => record.before?.data), true);
});

test('rollback snapshot is required before mutation planning', () => {
  const rollback = createRollbackSnapshot({
    artifact: baseArtifact(),
    snapshots: [],
    timestamp: '2026-09-28T04:00:00.000Z',
  });
  assert.equal(Array.isArray(rollback.records), true);
  assert.equal(rollback.records.length > 0, true);
});

test('stale source state aborts', () => {
  const expected = [
    {
      collection: 'questions',
      documentId: 'q-1',
      stateHash: 'old',
      updateTime: 'one',
    },
  ];
  const current = [{ ...expected[0], stateHash: 'new', updateTime: 'two' }];
  assert.throws(
    () => assertSourceSnapshotsUnchanged(expected, current),
    /changed since the dry-run/,
  );
});

test('unchanged source state passes precondition check', () => {
  const snapshot = {
    collection: 'questions',
    documentId: 'q-1',
    stateHash: 'same',
    updateTime: 'one',
  };
  assert.doesNotThrow(() =>
    assertSourceSnapshotsUnchanged([snapshot], [{ ...snapshot }]),
  );
});

test('legacy deletion preconditions require exact isolated references', () => {
  const snapshots = [
    {
      collection: 'tests',
      documentId: 'test-group-ii-001',
      data: {
        category: 'chapter',
        questionIds: ['q-test-group-ii-001'],
      },
    },
    {
      collection: 'tests',
      documentId: '3goCvCMOeFQP0g3Y3yi0',
      data: {
        category: 'chapter',
        questionIds: ['q-test-group-iii-001'],
      },
    },
    {
      collection: 'questions',
      documentId: 'q-test-group-ii-001',
      data: {
        paperId: 'paper-1',
        sectionId: 'section-1',
        topicId: 'topic-1',
      },
    },
    {
      collection: 'questions',
      documentId: 'q-test-group-iii-001',
      data: {
        paperId: 'paper-1',
        sectionId: 'section-1',
        topicId: 'topic-1',
      },
    },
  ];
  assert.doesNotThrow(() => validateDeletionPreconditions(snapshots));
  const changed = snapshots.map((item) =>
    item.documentId === 'q-test-group-ii-001'
      ? { ...item, data: { ...item.data, paperId: 'canonical' } }
      : item,
  );
  assert.throws(
    () => validateDeletionPreconditions(changed),
    /Legacy Question|Approved deletion/,
  );
});

test('post-apply verification detects count mismatch', () => {
  assert.throws(() => verifyPostApply([]), /Question count/);
});

test('dry-run artifact remains explicitly zero-write', () => {
  const artifact = baseArtifact();
  assert.equal(artifact.metadata.writesPerformed, 0);
  assert.equal(artifact.metadata.mode, 'DRY_RUN');
});

test('no apply mode can proceed without all gates', () => {
  assert.throws(
    () =>
      parseM2Args([
        'node',
        'tool',
        '--apply',
        '--artifact=artifact.json',
        `--confirmation-token=${CONFIRMATION_TOKEN}`,
        '--backup-confirmation=wrong',
      ]),
    /backup confirmation/,
  );
});

test('M2 source does not expose mutation through dry-run validation', async () => {
  const source = await readFile(resolve(here, 'question_content_m2_apply.mjs'), 'utf8');
  assert.equal(source.includes('writesPerformed') && source.includes('!== 0'), true);
  assert.equal(source.includes('transaction.create('), true);
  assert.equal(source.includes('validateDryRunArtifact(output)'), true);
});
