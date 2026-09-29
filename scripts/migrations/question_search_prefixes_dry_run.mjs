#!/usr/bin/env node

/**
 * Read-only backfill preflight for questionSearchPrefixes.
 * There is no apply path. Production mode only reads questions.
 */

import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { getApps, initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

export const FIELD = 'questionSearchPrefixes';
export const MIN_PREFIX_LENGTH = 2;
export const MAX_PREFIX_LENGTH = 32;
export const MAX_PREFIXES = 800;
export const DEFAULT_OUTPUT =
  '/tmp/prashna-question-search-prefixes-dry-run.json';

export function normalize(value) {
  return String(value ?? '').trim().toLowerCase().replace(/\s+/g, ' ');
}

export function tokenize(value) {
  const normalized = normalize(value);
  if (!normalized) return [];
  return normalized.split(/[^a-z0-9]+/).filter(Boolean);
}

export function prefixesForQuestion(value) {
  const words = new Set();
  const shorter = new Set();
  for (const token of tokenize(value)) {
    if (token.length < MIN_PREFIX_LENGTH) continue;
    const limit = Math.min(token.length, MAX_PREFIX_LENGTH);
    const capped = token.slice(0, limit);
    words.add(capped);
    for (let length = MIN_PREFIX_LENGTH; length < limit; length += 1) {
      shorter.add(capped.slice(0, length));
    }
  }
  const combined = [...words].sort().concat([...shorter].sort());
  return combined.slice(0, MAX_PREFIXES).sort();
}

export function englishQuestionText(data) {
  const top = String(data?.question ?? '').trim();
  if (top) return top;
  return String(data?.content?.en?.question ?? '').trim();
}

export function questionSearchText(value) {
  return normalize(value);
}

export function sourceFingerprint(data) {
  // The English question is the only source field used to derive these two
  // values. Hashing it is stable even when snapshot updateTime is unavailable.
  const source = { englishQuestionText: englishQuestionText(data) };
  return createHash('sha256').update(JSON.stringify(source)).digest('hex');
}

export function needsPrefixBackfill(data) {
  const expected = prefixesForQuestion(englishQuestionText(data));
  const expectedText = questionSearchText(englishQuestionText(data));
  const current = Array.isArray(data?.[FIELD]) ? data[FIELD] : null;
  return (
    !current ||
    current.length !== expected.length ||
    current.some((value, index) => value !== expected[index]) ||
    data?.questionSearchText !== expectedText
  );
}

function parseArgs(argv) {
  if (!argv.includes('--dry-run')) {
    throw new Error('This tool is read-only and requires --dry-run.');
  }
  if (argv.includes('--apply')) {
    throw new Error('--apply is not supported.');
  }
  const output = argv.find((arg) => arg.startsWith('--output='));
  return {
    projectId: 'prashna-67689',
    outputPath: output?.slice('--output='.length) || DEFAULT_OUTPUT,
  };
}

async function main() {
  const { projectId, outputPath } = parseArgs(process.argv.slice(2));
  if (getApps().length === 0) {
    initializeApp({ credential: applicationDefault(), projectId });
  }
  const snapshot = await getFirestore()
    .collection('questions')
    .select('question', 'content', FIELD, 'questionSearchText')
    .get();
  const documents = [];
  let updatesRequired = 0;
  let alreadyCurrent = 0;
  let invalid = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const text = englishQuestionText(data);
    const proposedText = questionSearchText(text);
    const proposedPrefixes = prefixesForQuestion(text);
    const usable = text.length > 0;
    const currentPrefixes = Array.isArray(data[FIELD]) ? data[FIELD] : null;
    const updateRequired =
      usable && needsPrefixBackfill(data);
    if (!usable) invalid += 1;
    else if (updateRequired) updatesRequired += 1;
    else alreadyCurrent += 1;
    documents.push({
      questionId: doc.id,
      currentQuestionSearchText: data.questionSearchText ?? null,
      proposedQuestionSearchText: usable ? proposedText : null,
      currentPrefixesPresent: currentPrefixes != null,
      currentPrefixesCount: currentPrefixes?.length ?? 0,
      proposedPrefixesCount: usable ? proposedPrefixes.length : 0,
      updateRequired,
      invalidEnglishQuestionText: !usable,
      sourceFingerprint: sourceFingerprint(data),
    });
  }
  const artifact = {
    schemaVersion: 1,
    mode: 'DRY_RUN',
    projectId,
    generatedAt: new Date().toISOString(),
    precondition:
      'Before a later apply, reread each document and require the SHA-256 '
      + 'of {englishQuestionText} to match. The English question is the '
      + 'only source field used to derive the proposed metadata.',
    proposedFields: [FIELD, 'questionSearchText'],
    summary: {
      questionsScanned: snapshot.size,
      updatesRequired,
      alreadyCurrent,
      invalidOrSkipped: invalid,
      errors: 0,
      writes: 0,
    },
    documents,
  };
  const { writeFile } = await import('node:fs/promises');
  await writeFile(outputPath, `${JSON.stringify(artifact, null, 2)}\n`);
  console.log(JSON.stringify({ ...artifact.summary, artifactPath: outputPath }));
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
