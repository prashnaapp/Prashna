#!/usr/bin/env node

/**
 * Phase M2 controlled migration.
 *
 * Dry-run is the only mode exercised during M2 pre-apply review. Apply mode
 * exists behind explicit artifact, project, backup, and confirmation gates.
 */

import { createHash } from 'node:crypto';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';

import {
  buildDryRunReport,
  EXPECTED_PROJECT_ID,
  COLLECTIONS,
  DATABASE_ID,
  MODE as DRY_RUN_MODE,
  readProductionData,
} from './question_content_m1_dry_run.mjs';

export const M2_VERSION = 'm2.0.0';
export const MIGRATION_ACTOR = 'migration:m2-question-content';
export const CONFIRMATION_TOKEN = 'M2-APPLY-prashna-67689';
export const BACKUP_CONFIRMATION = 'LOCAL_ROLLBACK_SNAPSHOT';

export const APPROVED_DELETIONS = Object.freeze([
  Object.freeze({ collection: 'tests', documentId: 'test-group-ii-001' }),
  Object.freeze({
    collection: 'tests',
    documentId: '3goCvCMOeFQP0g3Y3yi0',
  }),
  Object.freeze({ collection: 'questions', documentId: 'q-test-group-ii-001' }),
  Object.freeze({
    collection: 'questions',
    documentId: 'q-test-group-iii-001',
  }),
]);

const EXPECTED_INVENTORY = Object.freeze({
  questionCount: 15,
  testCount: 6,
  assignmentCount: 0,
  relationshipCount: 15,
});

const EXPECTED_SUMMARY = Object.freeze({
  questions: Object.freeze({
    SAFE_AUTOMATIC: 13,
    MANUAL_REVIEW: 2,
    LEAVE_LEGACY: 0,
  }),
  tests: Object.freeze({
    SAFE_NO_CHANGE: 3,
    SAFE_NORMALIZATION: 1,
    MANUAL_REVIEW: 2,
  }),
  assignments: Object.freeze({
    SAFE_AUTOMATIC: 13,
    MANUAL_REVIEW: 2,
  }),
});

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');

export function parseM2Args(argv) {
  const args = argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const apply = args.includes('--apply');
  if (dryRun === apply) {
    throw new Error('Specify exactly one of --dry-run or --apply.');
  }

  const result = {
    dryRun,
    apply,
    artifactPath: null,
    confirmationToken: null,
    backupConfirmation: null,
    projectId: process.env.FIREBASE_PROJECT_ID || EXPECTED_PROJECT_ID,
  };
  for (const arg of args) {
    if (arg === '--dry-run' || arg === '--apply') continue;
    if (arg.startsWith('--artifact=')) {
      result.artifactPath = arg.slice('--artifact='.length);
      continue;
    }
    if (arg.startsWith('--confirmation-token=')) {
      result.confirmationToken = arg.slice('--confirmation-token='.length);
      continue;
    }
    if (arg.startsWith('--backup-confirmation=')) {
      result.backupConfirmation = arg.slice('--backup-confirmation='.length);
      continue;
    }
    if (arg.startsWith('--project=')) {
      result.projectId = arg.slice('--project='.length);
      continue;
    }
    throw new Error(`Unsupported argument: ${arg}`);
  }

  if (result.apply) {
    if (!result.artifactPath) {
      throw new Error('Apply mode requires --artifact=<dry-run-artifact>.');
    }
    if (result.confirmationToken !== CONFIRMATION_TOKEN) {
      throw new Error('Apply mode requires the exact confirmation token.');
    }
    if (result.backupConfirmation !== BACKUP_CONFIRMATION) {
      throw new Error('Apply mode requires the backup confirmation gate.');
    }
  }
  if (result.projectId !== EXPECTED_PROJECT_ID) {
    throw new Error(`Refusing unexpected project "${result.projectId}".`);
  }
  return result;
}

function isObject(value) {
  return value != null && typeof value === 'object' && !Array.isArray(value);
}

function serializable(value) {
  if (value == null) return value;
  if (typeof value?.toDate === 'function') {
    return { __type: 'timestamp', value: value.toDate().toISOString() };
  }
  if (value instanceof Date) {
    return { __type: 'timestamp', value: value.toISOString() };
  }
  if (Array.isArray(value)) return value.map(serializable);
  if (isObject(value)) {
    return Object.fromEntries(
      Object.entries(value)
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([key, item]) => [key, serializable(item)]),
    );
  }
  return value;
}

function stateHash(data) {
  return createHash('sha256')
    .update(JSON.stringify(serializable(data)))
    .digest('hex');
}

function updateTimeValue(snapshot) {
  if (!snapshot?.updateTime) return null;
  if (typeof snapshot.updateTime.toDate === 'function') {
    return snapshot.updateTime.toDate().toISOString();
  }
  return String(snapshot.updateTime);
}

function sourceSnapshot(collection, document) {
  return {
    collection,
    documentId: document.id,
    exists: true,
    data: serializable(document.data()),
    updateTime: updateTimeValue(document),
    stateHash: stateHash(document.data()),
  };
}

async function readCollectionSnapshots(db, collection) {
  if (!COLLECTIONS.includes(collection)) {
    throw new Error(`Collection is outside the M2 read allowlist: ${collection}`);
  }
  const snapshot = await db.collection(collection).orderBy('__name__').get();
  return snapshot.docs.map((document) => sourceSnapshot(collection, document));
}

export async function readM2ProductionSnapshots(db) {
  const snapshots = [];
  for (const collection of COLLECTIONS) {
    snapshots.push(...(await readCollectionSnapshots(db, collection)));
  }
  return snapshots;
}

function snapshotToDocument(snapshot) {
  return { id: snapshot.documentId, data: snapshot.data };
}

function approvedDeletionKeys() {
  return APPROVED_DELETIONS.map(
    ({ collection, documentId }) => `${collection}/${documentId}`,
  ).sort();
}

function assertExactArray(actual, expected, label) {
  const actualKeys = actual.map(
    ({ collection, documentId }) => `${collection}/${documentId}`,
  ).sort();
  const expectedKeys = expected
    .map((item) =>
      typeof item === 'string'
        ? item
        : `${item.collection}/${item.documentId}`,
    )
    .sort();
  assertEqual(actualKeys, expectedKeys, label);
}

function assertEqual(actual, expected, label) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

function safeAssignmentProposals(report) {
  return report.assignments.filter(
    (assignment) =>
      assignment.classification === 'SAFE_AUTOMATIC' &&
      assignment.proposedAssignment != null,
  );
}

function buildQuestionPatches(report) {
  return report.questions
    .filter((question) => question.classification === 'SAFE_AUTOMATIC')
    .map((question) => ({
      documentId: question.documentId,
      patch: question.proposedPatch,
    }));
}

function buildAggregatePatches(report) {
  return report.tests
    .filter(
      (test) =>
        test.documentId === 'LVYQbE7wlUsYuZ0lIHXP' &&
        test.classification === 'SAFE_NORMALIZATION',
    )
    .map((test) => {
      const changes = {};
      for (const [field, expected] of Object.entries(
        test.aggregate.proposedPatch,
      )) {
        if (test.aggregate.stored[field] !== expected) {
          changes[field] = expected;
        }
      }
      return { documentId: test.documentId, patch: changes };
    });
}

function buildM2Plan(report) {
  const manualAssignments = report.assignments.filter(
    (assignment) =>
      assignment.classification !== 'SAFE_AUTOMATIC' ||
      assignment.proposedAssignment == null,
  );
  return {
    questionPatches: buildQuestionPatches(report),
    testPatches: buildAggregatePatches(report),
    assignmentProposals: safeAssignmentProposals(report),
    approvedDeletions: APPROVED_DELETIONS,
    manualAssignments: manualAssignments.map((assignment) => ({
      questionId: assignment.documentId,
      testId: assignment.testId,
      reasons: assignment.reasons,
    })),
  };
}

export function buildM2DryRunReport({
  projectId = EXPECTED_PROJECT_ID,
  questions,
  tests,
  assignments,
  snapshots,
  timestamp = new Date().toISOString(),
  runId = `m2-${timestamp.replace(/[^0-9]/g, '').slice(0, 14)}`,
  gitCommit = null,
  catalog = [],
}) {
  const report = buildDryRunReport({
    projectId,
    questions,
    tests,
    assignments,
    timestamp,
    runId,
    gitCommit,
    catalog,
  });
  const plan = buildM2Plan(report);
  const sourceSnapshots = snapshots ?? [];
  const output = {
    ...report,
    metadata: {
      ...report.metadata,
      m2Version: M2_VERSION,
      approvedDeletionList: APPROVED_DELETIONS,
      rollbackRequired: true,
    },
    preconditions: {
      expectedInventory: EXPECTED_INVENTORY,
      expectedSummary: EXPECTED_SUMMARY,
      sourceSnapshots,
    },
    applyPlan: plan,
  };
  validateDryRunArtifact(output);
  return output;
}

export function validateDryRunArtifact(artifact) {
  if (artifact?.metadata?.projectId !== EXPECTED_PROJECT_ID) {
    throw new Error('Artifact projectId is not the production project.');
  }
  if (artifact?.metadata?.mode !== DRY_RUN_MODE) {
    throw new Error('Apply requires an artifact generated in DRY_RUN mode.');
  }
  if (artifact?.metadata?.writesPerformed !== 0) {
    throw new Error('Artifact is not zero-write.');
  }
  assertEqual(
    artifact.inventory,
    EXPECTED_INVENTORY,
    'Artifact inventory mismatch',
  );
  assertEqual(
    {
      questions: artifact.summary.questions,
      tests: artifact.summary.tests,
      assignments: artifact.summary.assignments,
    },
    EXPECTED_SUMMARY,
    'Artifact classification mismatch',
  );
  assertExactArray(
    artifact.metadata.approvedDeletionList ?? [],
    approvedDeletionKeys(),
    'Approved deletion list mismatch',
  );
  const manualWithProposal = artifact.assignments.filter(
    (assignment) =>
      assignment.classification !== 'SAFE_AUTOMATIC' &&
      assignment.proposedAssignment != null,
  );
  if (manualWithProposal.length > 0) {
    throw new Error('Manual assignment contains an actionable proposal.');
  }
  if (
    artifact.applyPlan?.assignmentProposals?.length !==
    EXPECTED_SUMMARY.assignments.SAFE_AUTOMATIC
  ) {
    throw new Error('Safe assignment proposal count mismatch.');
  }
  if (artifact.applyPlan?.questionPatches?.length !== 13) {
    throw new Error('Safe Question patch count mismatch.');
  }
  if (artifact.applyPlan?.testPatches?.length !== 1) {
    throw new Error('Aggregate patch count mismatch.');
  }
  if (
    artifact.applyPlan.testPatches[0].documentId !== 'LVYQbE7wlUsYuZ0lIHXP' ||
    Object.keys(artifact.applyPlan.testPatches[0].patch).some(
      (field) => field !== 'totalMarks',
    )
  ) {
    throw new Error('Unexpected aggregate patch target.');
  }
  for (const question of artifact.questions) {
    if (
      question.classification !== 'SAFE_AUTOMATIC' &&
      Object.keys(question.proposedPatch ?? {}).length > 0
    ) {
      throw new Error('Manual Question contains an ownership patch.');
    }
  }
  for (const test of artifact.tests) {
    if (test.statusCheck?.automaticStatusPatch !== false) {
      throw new Error('Status coupling is not allowed in M2.');
    }
  }
  if (!Array.isArray(artifact.preconditions?.sourceSnapshots)) {
    throw new Error('Artifact is missing source snapshots.');
  }
  return true;
}

function snapshotMap(snapshots) {
  return new Map(
    snapshots.map((snapshot) => [
      `${snapshot.collection}/${snapshot.documentId}`,
      snapshot,
    ]),
  );
}

export function assertSourceSnapshotsUnchanged(expected, current) {
  const expectedMap = snapshotMap(expected);
  const currentMap = snapshotMap(current);
  if (expectedMap.size !== currentMap.size) {
    throw new Error('Production inventory changed since the dry-run.');
  }
  for (const [key, expectedSnapshot] of expectedMap) {
    const currentSnapshot = currentMap.get(key);
    if (!currentSnapshot || currentSnapshot.stateHash !== expectedSnapshot.stateHash) {
      throw new Error(`Production document changed since the dry-run: ${key}`);
    }
    if (
      expectedSnapshot.updateTime &&
      currentSnapshot.updateTime &&
      expectedSnapshot.updateTime !== currentSnapshot.updateTime
    ) {
      throw new Error(`Production updateTime changed since the dry-run: ${key}`);
    }
  }
}

function documentData(snapshots, collection, documentId) {
  return snapshots.find(
    (snapshot) =>
      snapshot.collection === collection && snapshot.documentId === documentId,
  )?.data;
}

function currentQuestionIds(test) {
  return Array.isArray(test?.questionIds)
    ? test.questionIds.filter((id) => typeof id === 'string')
    : [];
}

export function validateDeletionPreconditions(snapshots) {
  const tests = snapshots.filter((snapshot) => snapshot.collection === 'tests');
  const questions = snapshots.filter(
    (snapshot) => snapshot.collection === 'questions',
  );
  const assignments = new Set(
    snapshots
      .filter((snapshot) => snapshot.collection === 'question_assignments')
      .map((snapshot) => snapshot.documentId),
  );
  const refs = new Map();
  for (const test of tests) {
    for (const questionId of currentQuestionIds(test.data)) {
      const list = refs.get(questionId) ?? [];
      list.push(test.documentId);
      refs.set(questionId, list);
    }
  }
  for (const deletion of APPROVED_DELETIONS) {
    const data = documentData(snapshots, deletion.collection, deletion.documentId);
    if (!data) throw new Error(`Approved deletion is missing: ${deletion.collection}/${deletion.documentId}`);
    if (deletion.collection === 'questions') {
      if (
        data.paperId !== 'paper-1' ||
        data.sectionId !== 'section-1' ||
        data.topicId !== 'topic-1'
      ) {
        throw new Error(`Legacy Question shape changed: ${deletion.documentId}`);
      }
      const owners = refs.get(deletion.documentId) ?? [];
      const expectedTest =
        deletion.documentId === 'q-test-group-ii-001'
          ? 'test-group-ii-001'
          : '3goCvCMOeFQP0g3Y3yi0';
      if (JSON.stringify(owners) !== JSON.stringify([expectedTest])) {
        throw new Error(`Unexpected Test references legacy Question ${deletion.documentId}.`);
      }
      if (assignments.has(deletion.documentId)) {
        throw new Error(`Legacy Question has an assignment: ${deletion.documentId}`);
      }
    }
    if (deletion.collection === 'tests') {
      const expectedQuestionId =
        deletion.documentId === 'test-group-ii-001'
          ? 'q-test-group-ii-001'
          : 'q-test-group-iii-001';
      if (
        data.category !== 'chapter' ||
        JSON.stringify(currentQuestionIds(data)) !==
          JSON.stringify([expectedQuestionId])
      ) {
        throw new Error(`Legacy Test category changed: ${deletion.documentId}`);
      }
    }
  }
  return true;
}

export function validateAssignmentPreconditions(artifact, snapshots) {
  const questions = new Map(
    snapshots
      .filter((snapshot) => snapshot.collection === 'questions')
      .map((snapshot) => [snapshot.documentId, snapshot.data]),
  );
  const tests = new Map(
    snapshots
      .filter((snapshot) => snapshot.collection === 'tests')
      .map((snapshot) => [snapshot.documentId, snapshot.data]),
  );
  const assignmentIds = new Set(
    snapshots
      .filter((snapshot) => snapshot.collection === 'question_assignments')
      .map((snapshot) => snapshot.documentId),
  );
  const owners = new Map();
  for (const [testId, test] of tests) {
    for (const questionId of currentQuestionIds(test)) {
      const refs = owners.get(questionId) ?? [];
      refs.push(testId);
      owners.set(questionId, refs);
    }
  }
  const seen = new Set();
  for (const item of artifact.applyPlan.assignmentProposals) {
    const proposal = item.proposedAssignment;
    if (!proposal || item.classification !== 'SAFE_AUTOMATIC') {
      throw new Error('Assignment plan contains a non-actionable proposal.');
    }
    if (seen.has(proposal.questionId)) {
      throw new Error(`Duplicate assignment proposal: ${proposal.questionId}`);
    }
    seen.add(proposal.questionId);
    if (!questions.has(proposal.questionId)) {
      throw new Error(`Assignment Question is missing: ${proposal.questionId}`);
    }
    if (!tests.has(proposal.testId)) {
      throw new Error(`Assignment Test is missing: ${proposal.testId}`);
    }
    if (assignmentIds.has(proposal.questionId)) {
      throw new Error(`Assignment already exists: ${proposal.questionId}`);
    }
    const references = owners.get(proposal.questionId) ?? [];
    if (
      references.length !== 1 ||
      references[0] !== proposal.testId
    ) {
      throw new Error(
        `Assignment relationship is not unique: ${proposal.questionId}`,
      );
    }
  }
  return true;
}

export function createRollbackSnapshot({ artifact, snapshots, timestamp }) {
  const plan = artifact.applyPlan;
  const keys = new Set([
    ...plan.questionPatches.map((item) => `questions/${item.documentId}`),
    ...plan.testPatches.map((item) => `tests/${item.documentId}`),
    ...plan.assignmentProposals.map(
      (item) => `question_assignments/${item.documentId}`,
    ),
    ...APPROVED_DELETIONS.map(
      ({ collection, documentId }) => `${collection}/${documentId}`,
    ),
  ]);
  const byKey = snapshotMap(snapshots);
  const records = [];
  for (const key of keys) {
    const before = byKey.get(key);
    records.push({
      collection: key.split('/')[0],
      documentId: key.split('/')[1],
      before: before ?? null,
      proposedMutation:
        key.startsWith('question_assignments/')
          ? plan.assignmentProposals.find(
              (item) => `question_assignments/${item.documentId}` === key,
            )?.proposedAssignment ?? null
          : key.startsWith('questions/')
            ? plan.questionPatches.find(
                (item) => `questions/${item.documentId}` === key,
              )?.patch ?? null
            : plan.testPatches.find(
                (item) => `tests/${item.documentId}` === key,
              )?.patch ?? null,
    });
  }
  return {
    migrationRunId: artifact.metadata.runId,
    createdAt: timestamp,
    projectId: EXPECTED_PROJECT_ID,
    records,
  };
}

function defaultDryRunPath(timestamp) {
  return `/tmp/prashna-migration-dry-run/migration-m2-dry-run-${timestamp
    .replace(/[^0-9]/g, '')
    .slice(0, 14)}.json`;
}

function defaultRollbackPath(timestamp) {
  return `/tmp/prashna-migration-dry-run/migration-m2-rollback-${timestamp
    .replace(/[^0-9]/g, '')
    .slice(0, 14)}.json`;
}

async function loadCatalog() {
  const module = await import('../../functions/src/canonical_syllabus_catalog.js');
  return module.CANONICAL_SYLLABUS_UNITS;
}

function gitCommit() {
  try {
    return execFileSync('git', ['rev-parse', 'HEAD'], {
      cwd: repoRoot,
      encoding: 'utf8',
    }).trim();
  } catch {
    return null;
  }
}

async function loadAdminDb() {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error(
      'Refusing production mode while FIRESTORE_EMULATOR_HOST is set.',
    );
  }
  const { getApps, initializeApp, applicationDefault } =
    await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  if (getApps().length === 0) {
    initializeApp({
      credential: applicationDefault(),
      projectId: EXPECTED_PROJECT_ID,
    });
  }
  return getFirestore();
}

async function writeJson(path, value) {
  await mkdir(dirname(resolve(path)), { recursive: true });
  await writeFile(resolve(path), `${JSON.stringify(value, null, 2)}\n`, 'utf8');
  return resolve(path);
}

async function runDryRun() {
  const db = await loadAdminDb();
  const snapshots = await readM2ProductionSnapshots(db);
  const data = {
    questions: snapshots
      .filter((snapshot) => snapshot.collection === 'questions')
      .map(snapshotToDocument),
    tests: snapshots
      .filter((snapshot) => snapshot.collection === 'tests')
      .map(snapshotToDocument),
    assignments: snapshots
      .filter((snapshot) => snapshot.collection === 'question_assignments')
      .map(snapshotToDocument),
  };
  const report = buildM2DryRunReport({
    projectId: EXPECTED_PROJECT_ID,
    ...data,
    snapshots,
    timestamp: new Date().toISOString(),
    gitCommit: gitCommit(),
    catalog: await loadCatalog(),
  });
  const path = await writeJson(
    defaultDryRunPath(report.metadata.timestamp),
    report,
  );
  console.log('READ-ONLY M2 DRY RUN');
  console.log(`Project: ${EXPECTED_PROJECT_ID}`);
  console.log(`Artifact: ${path}`);
  console.log(
    `Questions: SAFE_AUTOMATIC=${report.summary.questions.SAFE_AUTOMATIC} ` +
      `MANUAL_REVIEW=${report.summary.questions.MANUAL_REVIEW} ` +
      `LEAVE_LEGACY=${report.summary.questions.LEAVE_LEGACY}`,
  );
  console.log(
    `Tests: SAFE_NO_CHANGE=${report.summary.tests.SAFE_NO_CHANGE} ` +
      `SAFE_NORMALIZATION=${report.summary.tests.SAFE_NORMALIZATION} ` +
      `MANUAL_REVIEW=${report.summary.tests.MANUAL_REVIEW}`,
  );
  console.log(
    `Assignments: SAFE_AUTOMATIC=${report.summary.assignments.SAFE_AUTOMATIC} ` +
      `MANUAL_REVIEW=${report.summary.assignments.MANUAL_REVIEW}`,
  );
  console.log('Writes performed: 0');
  return path;
}

async function loadArtifact(path) {
  return JSON.parse(await readFile(resolve(path), 'utf8'));
}

async function runApply(options) {
  const artifact = await loadArtifact(options.artifactPath);
  validateDryRunArtifact(artifact);
  const db = await loadAdminDb();
  const currentSnapshots = await readM2ProductionSnapshots(db);
  assertSourceSnapshotsUnchanged(
    artifact.preconditions.sourceSnapshots,
    currentSnapshots,
  );
  validateDeletionPreconditions(currentSnapshots);
  validateAssignmentPreconditions(artifact, currentSnapshots);

  const rollback = createRollbackSnapshot({
    artifact,
    snapshots: currentSnapshots,
    timestamp: new Date().toISOString(),
  });
  const rollbackPath = await writeJson(
    defaultRollbackPath(rollback.createdAt),
    rollback,
  );
  const rollbackCheck = await readFile(rollbackPath, 'utf8');
  if (!rollbackCheck.trim()) {
    throw new Error('Rollback snapshot verification failed; aborting.');
  }

  const { FieldValue } = await import('firebase-admin/firestore');
  try {
    await db.runTransaction(async (transaction) => {
      const refs = [
        ...currentSnapshots.map((snapshot) =>
          db.collection(snapshot.collection).doc(snapshot.documentId),
        ),
      ];
      for (const ref of refs) await transaction.get(ref);

      for (const deletion of APPROVED_DELETIONS.filter(
        ({ collection }) => collection === 'tests',
      )) {
        transaction.delete(
          db.collection(deletion.collection).doc(deletion.documentId),
        );
      }
      for (const deletion of APPROVED_DELETIONS.filter(
        ({ collection }) => collection === 'questions',
      )) {
        transaction.delete(
          db.collection(deletion.collection).doc(deletion.documentId),
        );
      }
      for (const item of artifact.applyPlan.questionPatches) {
        const patch = {};
        for (const [field, detail] of Object.entries(item.patch)) {
          if (detail.operation === 'PATCH_REQUIRED') {
            patch[field] = detail.value;
          }
        }
        if (Object.keys(patch).length > 0) {
          transaction.update(db.collection('questions').doc(item.documentId), patch);
        }
      }
      for (const item of artifact.applyPlan.testPatches) {
        if (Object.keys(item.patch).length > 0) {
          transaction.update(db.collection('tests').doc(item.documentId), item.patch);
        }
      }
      for (const item of artifact.applyPlan.assignmentProposals) {
        const proposal = item.proposedAssignment;
        transaction.create(
          db.collection('question_assignments').doc(proposal.questionId),
          {
            questionId: proposal.questionId,
            testId: proposal.testId,
            courseId: proposal.courseId,
            assignedAt: FieldValue.serverTimestamp(),
            assignedBy: MIGRATION_ACTOR,
          },
        );
      }
    });
  } catch (error) {
    const recoveryPath = `${rollbackPath.replace(/\.json$/, '')}-recovery.json`;
    await writeJson(recoveryPath, {
      migrationRunId: artifact.metadata.runId,
      rollbackPath,
      status: 'TRANSACTION_FAILED_OR_REQUIRES_RECOVERY',
      error: String(error?.message || error),
    });
    throw new Error(
      `M2 transaction failed; stopped. Rollback artifact: ${rollbackPath}`,
    );
  }

  const after = await readM2ProductionSnapshots(db);
  verifyPostApply(after);
  console.log(`M2 apply completed. Rollback artifact: ${rollbackPath}`);
  return rollbackPath;
}

export function verifyPostApply(snapshots) {
  const questions = snapshots.filter((item) => item.collection === 'questions');
  const tests = snapshots.filter((item) => item.collection === 'tests');
  const assignments = snapshots.filter(
    (item) => item.collection === 'question_assignments',
  );
  assertEqual(questions.length, 13, 'Post-apply Question count');
  assertEqual(tests.length, 4, 'Post-apply Test count');
  assertEqual(assignments.length, 13, 'Post-apply assignment count');
  for (const question of questions) {
    if (
      question.data.contentArea !== 'chapter' ||
      !question.data.contentFingerprint ||
      !question.data.questionSearchText
    ) {
      throw new Error(`Post-apply Question fields incomplete: ${question.documentId}`);
    }
  }
  for (const deletion of APPROVED_DELETIONS) {
    if (
      snapshots.some(
        (item) =>
          item.collection === deletion.collection &&
          item.documentId === deletion.documentId,
      )
    ) {
      throw new Error(`Approved deletion still exists: ${deletion.collection}/${deletion.documentId}`);
    }
  }
  const test = documentData(
    snapshots,
    'tests',
    'LVYQbE7wlUsYuZ0lIHXP',
  );
  assertEqual(test?.questionCount, 2, 'Post-apply aggregate questionCount');
  assertEqual(test?.totalMarks, 2, 'Post-apply aggregate totalMarks');
  assertEqual(test?.durationMinutes, 2, 'Post-apply aggregate durationMinutes');
  return true;
}

const invokedPath = process.argv[1]
  ? pathToFileURL(resolve(process.argv[1])).href
  : null;
if (invokedPath && import.meta.url === invokedPath) {
  (async () => {
    try {
      const options = parseM2Args(process.argv);
      if (options.dryRun) {
        await runDryRun();
      } else {
        await runApply(options);
      }
    } catch (error) {
      console.error(`M2 refused/stopped: ${error.message}`);
      process.exitCode = 1;
    }
  })();
}
