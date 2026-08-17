#!/usr/bin/env node
/**
 * Migrate legacy user_progress/{uid} → user_progress/{uid}/courses/{courseId}
 *
 * ARCHITECTURE (LOCKED)
 * ---------------------
 * - Target: user_progress/{uid}/courses/{courseId}
 * - Executor: Admin SDK offline script (PRIMARY)
 * - Legacy parent is NEVER deleted
 * - Existing target course docs are NEVER overwritten
 * - courseId is NEVER invented
 *
 * SAFETY
 * ------
 * - Default mode is DRY-RUN (no writes).
 * - Writes require BOTH --apply AND --confirm-project=<exact projectId>.
 * - Unknown Firebase project IDs are refused.
 * - Do NOT commit service-account JSON.
 *
 * CREDENTIALS
 * -----------
 *   export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/service-account.json"
 *
 * USAGE
 * -----
 *   cd scripts
 *   npm install
 *   npm run migrate:user-progress -- --dry-run
 *   npm run migrate:user-progress -- --apply --confirm-project=prashna-67689
 *
 * LOCAL FIXTURE (no Firebase / no production):
 *   npm run migrate:user-progress -- --fixture=./fixtures/user_progress_migration_sample.json --dry-run
 */

import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { initializeApp, applicationDefault, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const ALLOWED_PROJECT_IDS = Object.freeze(['prashna-67689']);
const DEFAULT_PROJECT_ID = 'prashna-67689';
const COLLECTION = 'user_progress';
const COURSES_SUBCOLLECTION = 'courses';
const SCHEMA_VERSION = 1;
const PAGE_SIZE = 100;
const WRITE_BATCH_LIMIT = 100;
const MAX_RETRIES = 3;
const RETRY_BASE_MS = 250;

/**
 * @typedef {'migrate' | 'skip_exists' | 'skip_missing_course_id' | 'skip_malformed' | 'error'} Outcome
 * @typedef {{
 *   uid: string,
 *   outcome: Outcome,
 *   courseId?: string | null,
 *   targetPath?: string,
 *   message?: string,
 * }} ResultRow
 */

function printUsageAndExit(code = 1) {
  console.error(`
Usage:
  npm run migrate:user-progress -- --dry-run
  npm run migrate:user-progress -- --apply --confirm-project=${DEFAULT_PROJECT_ID}
  npm run migrate:user-progress -- --fixture=./fixtures/user_progress_migration_sample.json --dry-run

Flags:
  --dry-run                         Read + report only (default if --apply omitted)
  --apply                           Perform writes (requires --confirm-project)
  --confirm-project=<projectId>     Must exactly match the active Firebase project
  --fixture=<path.json>             Local fixture mode (no Firebase connection)
  --uid=<uid>                       Limit to a single parent document (Firebase mode)
  -h, --help                        Show this help

Environment:
  GOOGLE_APPLICATION_CREDENTIALS    Service-account JSON path (Firebase modes)
  FIREBASE_PROJECT_ID               Project override (must be allowlisted)
`);
  process.exit(code);
}

function resolveProjectId() {
  return (
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    DEFAULT_PROJECT_ID
  );
}

function parseArgs(argv) {
  const args = argv.slice(2).filter((a) => a.trim().length > 0);
  if (args.includes('-h') || args.includes('--help')) {
    printUsageAndExit(0);
  }

  let apply = false;
  let dryRun = false;
  let confirmProject = null;
  let fixturePath = null;
  let onlyUid = null;

  for (const arg of args) {
    if (arg === '--apply') {
      apply = true;
      continue;
    }
    if (arg === '--dry-run') {
      dryRun = true;
      continue;
    }
    if (arg.startsWith('--confirm-project=')) {
      confirmProject = arg.slice('--confirm-project='.length);
      continue;
    }
    if (arg.startsWith('--fixture=')) {
      fixturePath = arg.slice('--fixture='.length);
      continue;
    }
    if (arg.startsWith('--uid=')) {
      onlyUid = arg.slice('--uid='.length);
      continue;
    }
    console.error(`Error: unknown argument: ${arg}`);
    printUsageAndExit(1);
  }

  // Default is dry-run unless --apply is present.
  if (!apply) {
    dryRun = true;
  }

  if (apply && dryRun && args.includes('--dry-run')) {
    console.error('Error: --apply and --dry-run are mutually exclusive.');
    process.exit(1);
  }

  if (apply) {
    dryRun = false;
  }

  return { apply, dryRun, confirmProject, fixturePath, onlyUid };
}

function sleep(ms) {
  return new Promise((resolvePromise) => setTimeout(resolvePromise, ms));
}

async function withRetries(label, fn) {
  let lastError;
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      const retryable =
        error?.code === 4 ||
        error?.code === 8 ||
        error?.code === 14 ||
        /UNAVAILABLE|DEADLINE|RESOURCE_EXHAUSTED|ABORTED/i.test(
          String(error?.message || error),
        );
      if (!retryable || attempt === MAX_RETRIES) break;
      const delay = RETRY_BASE_MS * 2 ** (attempt - 1);
      console.error(
        `Retry ${attempt}/${MAX_RETRIES} for ${label}: ${error?.message || error}`,
      );
      await sleep(delay);
    }
  }
  throw lastError;
}

function isPlainObject(value) {
  return value != null && typeof value === 'object' && !Array.isArray(value);
}

/**
 * Normalize Firestore Timestamp / Date / number into a Date or null.
 */
function normalizeTimestamp(value) {
  if (value == null) return null;
  if (value instanceof Date) return value;
  if (typeof value?.toDate === 'function') {
    try {
      return value.toDate();
    } catch {
      return null;
    }
  }
  if (typeof value === 'number' && Number.isFinite(value)) {
    return new Date(value);
  }
  if (
    isPlainObject(value) &&
    typeof value._seconds === 'number'
  ) {
    return new Date(value._seconds * 1000);
  }
  return null;
}

/**
 * Classify a legacy parent document and build a target payload when eligible.
 *
 * @param {string} uid
 * @param {Record<string, unknown> | undefined | null} data
 */
function planMigration(uid, data) {
  if (!isPlainObject(data)) {
    return {
      outcome: /** @type {Outcome} */ ('skip_malformed'),
      message: 'parent missing or not an object',
    };
  }

  const courseIdRaw = data.courseId;
  if (courseIdRaw == null || courseIdRaw === '') {
    return {
      outcome: /** @type {Outcome} */ ('skip_missing_course_id'),
      courseId: courseIdRaw == null ? null : String(courseIdRaw),
      message: 'missing courseId',
    };
  }

  if (typeof courseIdRaw !== 'string') {
    return {
      outcome: /** @type {Outcome} */ ('skip_malformed'),
      courseId: String(courseIdRaw),
      message: 'courseId is not a string',
    };
  }

  const courseId = courseIdRaw.trim();
  if (courseId.length === 0) {
    return {
      outcome: /** @type {Outcome} */ ('skip_missing_course_id'),
      courseId: '',
      message: 'missing courseId',
    };
  }

  // Refuse path-hostile courseIds.
  if (courseId.includes('/') || courseId.includes('..')) {
    return {
      outcome: /** @type {Outcome} */ ('skip_malformed'),
      courseId,
      message: 'courseId contains illegal path characters',
    };
  }

  const overall = isPlainObject(data.overall) ? data.overall : null;
  const papers = isPlainObject(data.papers) ? data.papers : null;
  const chapters = isPlainObject(data.chapters) ? data.chapters : null;

  if (overall == null || papers == null || chapters == null) {
    return {
      outcome: /** @type {Outcome} */ ('skip_malformed'),
      courseId,
      message: 'missing overall/papers/chapters object map(s)',
    };
  }

  const lastUpdated = normalizeTimestamp(data.lastUpdated);
  const appVersion =
    typeof data.appVersion === 'string' ? data.appVersion : null;

  const targetPath = `${COLLECTION}/${uid}/${COURSES_SUBCOLLECTION}/${courseId}`;
  const payload = {
    uid,
    courseId,
    overall,
    papers,
    chapters,
    lastUpdated: lastUpdated, // may be null; writer substitutes serverTimestamp
    appVersion,
    schemaVersion: SCHEMA_VERSION,
  };

  return {
    outcome: /** @type {Outcome} */ ('migrate'),
    courseId,
    targetPath,
    payload,
  };
}

function printBanner({ projectId, mode }) {
  console.log('============================================================');
  console.log(`PROJECT: ${projectId}`);
  console.log(`MODE: ${mode}`);
  console.log(`TARGET: ${COLLECTION}/{uid}/${COURSES_SUBCOLLECTION}/{courseId}`);
  console.log('============================================================');
}

function summarize(results) {
  const counts = {
    total_parents_scanned: results.length,
    eligible_migrations: 0,
    already_migrated: 0,
    missing_courseId: 0,
    malformed_documents: 0,
    errors: 0,
    written: 0,
  };

  for (const row of results) {
    switch (row.outcome) {
      case 'migrate':
        counts.eligible_migrations += 1;
        break;
      case 'skip_exists':
        counts.already_migrated += 1;
        break;
      case 'skip_missing_course_id':
        counts.missing_courseId += 1;
        break;
      case 'skip_malformed':
        counts.malformed_documents += 1;
        break;
      case 'error':
        counts.errors += 1;
        break;
      default:
        break;
    }
    if (row.written) counts.written += 1;
  }
  return counts;
}

function printReport(results, counts, { dryRun }) {
  console.log('');
  console.log('--- Per-document results ---');
  for (const row of results) {
    const bits = [
      row.uid,
      row.outcome,
      row.courseId != null ? `courseId=${row.courseId}` : null,
      row.targetPath ? `target=${row.targetPath}` : null,
      row.message ? `msg=${row.message}` : null,
      row.written ? 'WRITTEN' : dryRun ? 'DRY-RUN' : null,
    ].filter(Boolean);
    console.log(bits.join(' | '));
  }

  console.log('');
  console.log('--- Summary ---');
  console.log(`total parents scanned : ${counts.total_parents_scanned}`);
  console.log(`eligible migrations   : ${counts.eligible_migrations}`);
  console.log(`already migrated      : ${counts.already_migrated}`);
  console.log(`missing courseId      : ${counts.missing_courseId}`);
  console.log(`malformed documents   : ${counts.malformed_documents}`);
  console.log(`errors                : ${counts.errors}`);
  if (!dryRun) {
    console.log(`written               : ${counts.written}`);
  }
}

async function runFixtureMode({ fixturePath, dryRun }) {
  const absolute = resolve(process.cwd(), fixturePath);
  const raw = JSON.parse(readFileSync(absolute, 'utf8'));
  if (!Array.isArray(raw.parents)) {
    throw new Error('Fixture must be { "parents": [ { "uid", "data", "targetExists?" } ] }');
  }

  printBanner({ projectId: 'fixture-local', mode: dryRun ? 'DRY-RUN' : 'APPLY' });
  if (!dryRun) {
    console.error(
      'Error: --apply is not supported with --fixture (fixture mode is read-only simulation).',
    );
    process.exit(1);
  }

  /** @type {ResultRow[]} */
  const results = [];

  for (const parent of raw.parents) {
    const uid = parent.uid;
    if (typeof uid !== 'string' || uid.length === 0) {
      results.push({
        uid: String(uid ?? '(invalid)'),
        outcome: 'skip_malformed',
        message: 'fixture parent missing uid',
      });
      continue;
    }

    const plan = planMigration(uid, parent.data);
    if (plan.outcome !== 'migrate') {
      results.push({
        uid,
        outcome: plan.outcome,
        courseId: plan.courseId,
        message: plan.message,
      });
      continue;
    }

    if (parent.targetExists === true) {
      results.push({
        uid,
        outcome: 'skip_exists',
        courseId: plan.courseId,
        targetPath: plan.targetPath,
        message: 'target already exists',
      });
      continue;
    }

    results.push({
      uid,
      outcome: 'migrate',
      courseId: plan.courseId,
      targetPath: plan.targetPath,
      message: 'would copy legacy → course doc',
    });
  }

  const counts = summarize(results);
  printReport(results, counts, { dryRun: true });
  return counts.errors > 0 ? 1 : 0;
}

function assertProjectSafety({ projectId, apply, confirmProject }) {
  if (!ALLOWED_PROJECT_IDS.includes(projectId)) {
    console.error(
      `Error: project "${projectId}" is not in the allowlist: ${ALLOWED_PROJECT_IDS.join(', ')}`,
    );
    process.exit(1);
  }

  if (!apply) return;

  if (!confirmProject) {
    console.error(
      'Error: --apply requires --confirm-project=<projectId> matching the active project.',
    );
    process.exit(1);
  }

  if (confirmProject !== projectId) {
    console.error(
      `Error: --confirm-project="${confirmProject}" does not match active project "${projectId}". ABORT.`,
    );
    process.exit(1);
  }
}

async function* iterateParents(db, onlyUid) {
  if (onlyUid) {
    const snap = await withRetries(`get ${COLLECTION}/${onlyUid}`, () =>
      db.collection(COLLECTION).doc(onlyUid).get(),
    );
    if (snap.exists) {
      yield snap;
    }
    return;
  }

  let lastDoc = null;
  for (;;) {
    let query = db.collection(COLLECTION).orderBy('__name__').limit(PAGE_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);
    const page = await withRetries('list user_progress page', () => query.get());
    if (page.empty) break;
    for (const doc of page.docs) {
      yield doc;
    }
    lastDoc = page.docs[page.docs.length - 1];
    if (page.size < PAGE_SIZE) break;
  }
}

function buildWritePayload(plan) {
  const payload = { ...plan.payload };
  if (payload.lastUpdated == null) {
    payload.lastUpdated = FieldValue.serverTimestamp();
  }
  if (payload.appVersion == null) {
    // Preserve absence of appVersion as null rather than inventing a version.
    payload.appVersion = null;
  }
  return payload;
}

async function flushBatch(db, ops) {
  if (ops.length === 0) return;
  const batch = db.batch();
  for (const op of ops) {
    batch.set(op.ref, op.data, { merge: false });
  }
  await withRetries(`commit batch (${ops.length})`, () => batch.commit());
}

async function runFirebaseMode({ projectId, dryRun, apply, onlyUid }) {
  printBanner({
    projectId,
    mode: apply ? 'APPLY' : 'DRY-RUN',
  });

  if (getApps().length === 0) {
    initializeApp({
      credential: applicationDefault(),
      projectId,
    });
  }

  const db = getFirestore();
  /** @type {ResultRow[]} */
  const results = [];
  /** @type {{ ref: FirebaseFirestore.DocumentReference, data: object, row: ResultRow }[]} */
  const pendingWrites = [];

  for await (const parentSnap of iterateParents(db, onlyUid)) {
    const uid = parentSnap.id;
    const data = parentSnap.data();
    const plan = planMigration(uid, data);

    if (plan.outcome !== 'migrate') {
      results.push({
        uid,
        outcome: plan.outcome,
        courseId: plan.courseId ?? null,
        message: plan.message,
      });
      continue;
    }

    const targetRef = db
      .collection(COLLECTION)
      .doc(uid)
      .collection(COURSES_SUBCOLLECTION)
      .doc(plan.courseId);

    let targetExists = false;
    try {
      const targetSnap = await withRetries(`get ${plan.targetPath}`, () =>
        targetRef.get(),
      );
      targetExists = targetSnap.exists;
    } catch (error) {
      results.push({
        uid,
        outcome: 'error',
        courseId: plan.courseId,
        targetPath: plan.targetPath,
        message: `target read failed: ${error?.message || error}`,
      });
      continue;
    }

    if (targetExists) {
      results.push({
        uid,
        outcome: 'skip_exists',
        courseId: plan.courseId,
        targetPath: plan.targetPath,
        message: 'target already exists',
      });
      continue;
    }

    const row = {
      uid,
      outcome: 'migrate',
      courseId: plan.courseId,
      targetPath: plan.targetPath,
      message: dryRun
        ? 'would copy legacy → course doc'
        : 'queued copy legacy → course doc',
      written: false,
    };
    results.push(row);

    if (apply) {
      pendingWrites.push({
        ref: targetRef,
        data: buildWritePayload(plan),
        row,
      });

      if (pendingWrites.length >= WRITE_BATCH_LIMIT) {
        try {
          await flushBatch(
            db,
            pendingWrites.map((p) => ({ ref: p.ref, data: p.data })),
          );
          for (const p of pendingWrites) {
            p.row.written = true;
            p.row.message = 'copied legacy → course doc';
          }
        } catch (error) {
          for (const p of pendingWrites) {
            p.row.outcome = 'error';
            p.row.message = `write failed: ${error?.message || error}`;
          }
        }
        pendingWrites.length = 0;
      }
    }
  }

  if (apply && pendingWrites.length > 0) {
    try {
      await flushBatch(
        db,
        pendingWrites.map((p) => ({ ref: p.ref, data: p.data })),
      );
      for (const p of pendingWrites) {
        p.row.written = true;
        p.row.message = 'copied legacy → course doc';
      }
    } catch (error) {
      for (const p of pendingWrites) {
        p.row.outcome = 'error';
        p.row.message = `write failed: ${error?.message || error}`;
      }
    }
  }

  const counts = summarize(results);
  printReport(results, counts, { dryRun });
  return counts.errors > 0 ? 1 : 0;
}

async function main() {
  const { apply, dryRun, confirmProject, fixturePath, onlyUid } = parseArgs(
    process.argv,
  );

  if (fixturePath) {
    const code = await runFixtureMode({ fixturePath, dryRun });
    process.exit(code);
  }

  const projectId = resolveProjectId();
  assertProjectSafety({ projectId, apply, confirmProject });

  if (apply) {
    console.log('');
    console.log('APPLY MODE ARMED');
    console.log(`PROJECT: ${projectId}`);
    console.log('MODE: APPLY');
    console.log(
      `TARGET: ${COLLECTION}/{uid}/${COURSES_SUBCOLLECTION}/{courseId}`,
    );
    console.log('Legacy parents will NOT be deleted.');
    console.log('Existing targets will NOT be overwritten.');
    console.log('');
  }

  const code = await runFirebaseMode({
    projectId,
    dryRun,
    apply,
    onlyUid,
  });
  process.exit(code);
}

main().catch((error) => {
  console.error('Fatal error during user_progress migration:');
  console.error(error?.message || error);
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error(
      '\nHint: set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON path,',
    );
    console.error(
      'or use --fixture=./fixtures/user_progress_migration_sample.json for local dry-run.',
    );
  }
  process.exit(1);
});
