#!/usr/bin/env node

/**
 * Controlled production apply for questionSearchPrefixes.
 *
 * This is intentionally separate from the dry-run tool. It has no implicit
 * apply mode and updates only the two approved search metadata fields.
 */

import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import {
  getApps,
  initializeApp,
  applicationDefault,
} from 'firebase-admin/app';
import { FieldPath, getFirestore } from 'firebase-admin/firestore';
import {
  englishQuestionText,
  prefixesForQuestion,
  questionSearchText,
  sourceFingerprint,
} from './question_search_prefixes_dry_run.mjs';

export const EXPECTED_PROJECT_ID = 'prashna-67689';
export const EXPECTED_TOKEN = 'SEARCH-PREFIXES-APPLY-prashna-67689';
export const ALLOWED_FIELDS = Object.freeze([
  'questionSearchPrefixes',
  'questionSearchText',
]);

function parseArgs(argv) {
  if (!argv.includes('--apply')) {
    throw new Error('Refusing to run without the explicit --apply flag.');
  }
  const artifactArg = argv.find((arg) => arg.startsWith('--artifact='));
  const tokenArg = argv.find((arg) =>
    arg.startsWith('--confirmation-token='),
  );
  const artifact = artifactArg?.slice('--artifact='.length);
  const token = tokenArg?.slice('--confirmation-token='.length);
  if (!artifact) throw new Error('Missing required --artifact path.');
  if (artifact !== '/tmp/prashna-question-search-prefixes-dry-run.json') {
    throw new Error('Artifact path is not the approved dry-run artifact.');
  }
  if (token !== EXPECTED_TOKEN) {
    throw new Error('Confirmation token does not match prashna-67689.');
  }
  return { artifact, token };
}

function stable(value) {
  if (value && typeof value.toMillis === 'function') {
    return { __timestampMillis: value.toMillis() };
  }
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.keys(value)
        .sort()
        .map((key) => [key, stable(value[key])]),
    );
  }
  return value;
}

function equal(a, b) {
  return JSON.stringify(stable(a)) === JSON.stringify(stable(b));
}

function allowedOnly(before, after) {
  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  return [...keys].filter(
    (key) => !ALLOWED_FIELDS.includes(key) && !equal(before[key], after[key]),
  );
}

function previousField(data, field) {
  return Object.prototype.hasOwnProperty.call(data, field)
    ? { present: true, value: data[field] }
    : { present: false, value: null };
}

async function main() {
  const { artifact } = parseArgs(process.argv.slice(2));
  const parsed = JSON.parse(await readFile(artifact, 'utf8'));
  if (parsed.mode !== 'DRY_RUN') {
    throw new Error('Artifact mode must be DRY_RUN.');
  }
  if (parsed.projectId !== EXPECTED_PROJECT_ID) {
    throw new Error(`Artifact projectId must be ${EXPECTED_PROJECT_ID}.`);
  }
  const rows = parsed.documents;
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error('Artifact contains no target documents.');
  }
  if (
    JSON.stringify(parsed.proposedFields) !==
    JSON.stringify([...ALLOWED_FIELDS])
  ) {
    throw new Error('Artifact proposed fields are not exactly the approved fields.');
  }

  if (getApps().length === 0) {
    initializeApp({
      credential: applicationDefault(),
      projectId: EXPECTED_PROJECT_ID,
    });
  }
  const db = getFirestore();
  const collection = db.collection('questions');
  const refs = rows.map((row) => collection.doc(row.questionId));
  const beforeSnapshots = await db.runTransaction(async (transaction) => {
    const snapshots = [];
    for (const ref of refs) snapshots.push(await transaction.get(ref));
    return snapshots;
  });

  const mismatches = [];
  const invalid = [];
  const plans = [];
  for (let index = 0; index < rows.length; index += 1) {
    const row = rows[index];
    const snapshot = beforeSnapshots[index];
    if (!snapshot.exists) {
      mismatches.push({ questionId: row.questionId, reason: 'missing document' });
      continue;
    }
    const data = snapshot.data() ?? {};
    const text = englishQuestionText(data);
    if (!text) {
      invalid.push(row.questionId);
      continue;
    }
    const fingerprint = sourceFingerprint(data);
    if (fingerprint !== row.sourceFingerprint) {
      mismatches.push({
        questionId: row.questionId,
        reason: 'source fingerprint drift',
        expected: row.sourceFingerprint,
        actual: fingerprint,
      });
      continue;
    }
    plans.push({
      ref: refs[index],
      questionId: row.questionId,
      before: data,
      proposed: {
        questionSearchPrefixes: prefixesForQuestion(text),
        questionSearchText: questionSearchText(text),
      },
    });
  }
  if (mismatches.length || invalid.length || plans.length !== rows.length) {
    throw new Error(
      JSON.stringify({ preconditionFailed: true, mismatches, invalid }),
    );
  }

  const rollbackPath =
    `/tmp/prashna-question-search-prefixes-rollback-${Date.now()}.json`;
  const rollback = {
    schemaVersion: 1,
    mode: 'ROLLBACK_ONLY_APPROVED_FIELDS',
    projectId: EXPECTED_PROJECT_ID,
    sourceArtifact: artifact,
    documents: plans.map((plan) => ({
      questionId: plan.questionId,
      sourceFingerprint: sourceFingerprint(plan.before),
      questionSearchPrefixes: previousField(
        plan.before,
        'questionSearchPrefixes',
      ),
      questionSearchText: previousField(plan.before, 'questionSearchText'),
    })),
  };
  await writeFile(rollbackPath, `${JSON.stringify(rollback, null, 2)}\n`);

  const batch = db.batch();
  for (const plan of plans) {
    batch.update(plan.ref, plan.proposed);
  }
  await batch.commit();

  const afterSnapshots = await db.runTransaction(async (transaction) => {
    const snapshots = [];
    for (const ref of refs) snapshots.push(await transaction.get(ref));
    return snapshots;
  });
  const integrityMismatches = [];
  const fieldMismatches = [];
  for (let index = 0; index < plans.length; index += 1) {
    const plan = plans[index];
    const after = afterSnapshots[index].data() ?? {};
    const changed = allowedOnly(plan.before, after);
    if (changed.length) {
      integrityMismatches.push({
        questionId: plan.questionId,
        unexpectedChangedFields: changed,
      });
    }
    for (const field of ALLOWED_FIELDS) {
      if (!equal(after[field], plan.proposed[field])) {
        fieldMismatches.push({ questionId: plan.questionId, field });
      }
    }
  }
  if (integrityMismatches.length || fieldMismatches.length) {
    throw new Error(
      JSON.stringify({ postApplyVerificationFailed: true, integrityMismatches, fieldMismatches }),
    );
  }

  const terms = ['date', 'constitution', 'mini'];
  const searches = {};
  for (const term of terms) {
    const snapshot = await collection
      .where('questionSearchPrefixes', 'array-contains', term)
      .orderBy(FieldPath.documentId())
      .get();
    searches[term] = {
      count: snapshot.size,
      questionIds: snapshot.docs.map((doc) => doc.id),
    };
  }
  const firstText = englishQuestionText(afterSnapshots[0].data() ?? {});
  const firstToken = firstText
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter(Boolean)[0];
  if (firstToken) {
    const snapshot = await collection
      .where('questionSearchPrefixes', 'array-contains', firstToken)
      .orderBy(FieldPath.documentId())
      .get();
    searches.beginningWord = {
      term: firstToken,
      count: snapshot.size,
      questionIds: snapshot.docs.map((doc) => doc.id),
    };
  }

  console.log(
    JSON.stringify(
      {
        projectId: EXPECTED_PROJECT_ID,
        targetDocuments: rows.length,
        fingerprintsMatched: plans.length,
        driftMismatches: 0,
        writesAttempted: plans.length,
        writesSucceeded: plans.length,
        writesFailed: 0,
        rollbackPath,
        postApply: {
          prefixesVerified: plans.length,
          searchTextVerified: plans.length,
          unexpectedFieldChanges: 0,
          searches,
        },
      },
      null,
      2,
    ),
  );
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    console.error(error.message);
    process.exit(1);
  });
}
