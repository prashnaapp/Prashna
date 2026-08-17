#!/usr/bin/env node
/**
 * ONE-TIME Admin repair: overwrite a divergent course progress document
 * from its legacy parent.
 *
 * Source (READ ONLY — never written):
 *   user_progress/{uid}
 *
 * Target (ONLY document that may be overwritten):
 *   user_progress/{uid}/courses/{courseId}
 *
 * This is NOT a replacement for migrate_user_progress.mjs.
 * The migrator intentionally skips existing targets; this tool repairs
 * an already-existing divergent target by explicit overwrite.
 *
 * SAFETY
 * ------
 * - Default mode is DRY-RUN (no writes).
 * - Writes require BOTH --apply AND --confirm-project=prashna-67689.
 * - Project allowlist: prashna-67689 only.
 * - --uid and --course are required (no silent defaults).
 * - Legacy parent is NEVER modified or deleted.
 * - No other users' documents are touched.
 *
 * CREDENTIALS
 * -----------
 *   export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/service-account.json"
 *
 * USAGE
 * -----
 *   cd scripts
 *   npm run repair:user-progress-course -- \
 *     --uid=H1piWEtLsmcQVXXsq8OloqMeUSV2 \
 *     --course=group-ii \
 *     --dry-run
 *
 *   npm run repair:user-progress-course -- \
 *     --uid=H1piWEtLsmcQVXXsq8OloqMeUSV2 \
 *     --course=group-ii \
 *     --apply \
 *     --confirm-project=prashna-67689
 *
 * LOCAL FIXTURE (no Firebase / no production):
 *   npm run repair:user-progress-course -- \
 *     --fixture=./fixtures/user_progress_course_repair_sample.json \
 *     --uid=security-student-a \
 *     --course=group-ii \
 *     --dry-run
 */

import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { initializeApp, applicationDefault, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const ALLOWED_PROJECT_IDS = Object.freeze(['prashna-67689']);
const DEFAULT_PROJECT_ID = 'prashna-67689';
const COLLECTION = 'user_progress';
const COURSES_SUBCOLLECTION = 'courses';
const SCHEMA_VERSION = 1;

function printUsageAndExit(code = 1) {
  console.error(`
Usage:
  npm run repair:user-progress-course -- --uid=<uid> --course=<courseId> --dry-run
  npm run repair:user-progress-course -- --uid=<uid> --course=<courseId> --apply --confirm-project=${DEFAULT_PROJECT_ID}
  npm run repair:user-progress-course -- --fixture=./fixtures/user_progress_course_repair_sample.json --uid=<uid> --course=<courseId> --dry-run

Flags:
  --uid=<uid>                       REQUIRED. Exact user id to repair.
  --course=<courseId>               REQUIRED. Exact course id (must match source.courseId).
  --dry-run                         Read + report only (default if --apply omitted).
  --apply                           Perform overwrite write (requires --confirm-project).
  --confirm-project=<projectId>     Must exactly match active project (${DEFAULT_PROJECT_ID}).
  --allow-create                    Permit creating the target when missing (explicit only).
  --fixture=<path.json>             Local fixture mode (no Firebase connection).
  -h, --help                        Show this help.

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
  let uid = null;
  let courseId = null;
  let allowCreate = false;

  for (const arg of args) {
    if (arg === '--apply') {
      apply = true;
      continue;
    }
    if (arg === '--dry-run') {
      dryRun = true;
      continue;
    }
    if (arg === '--allow-create') {
      allowCreate = true;
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
      uid = arg.slice('--uid='.length);
      continue;
    }
    if (arg.startsWith('--course=')) {
      courseId = arg.slice('--course='.length);
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

  if (uid == null || uid.trim().length === 0) {
    console.error('Error: --uid=<uid> is required.');
    printUsageAndExit(1);
  }
  if (courseId == null || courseId.trim().length === 0) {
    console.error('Error: --course=<courseId> is required.');
    printUsageAndExit(1);
  }

  return {
    apply,
    dryRun,
    confirmProject,
    fixturePath,
    uid: uid.trim(),
    courseId: courseId.trim(),
    allowCreate,
  };
}

function isPlainObject(value) {
  return value != null && typeof value === 'object' && !Array.isArray(value);
}

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
  if (isPlainObject(value) && typeof value._seconds === 'number') {
    return new Date(value._seconds * 1000);
  }
  if (typeof value === 'string') {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
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

function validateCourseId(courseId) {
  if (typeof courseId !== 'string' || courseId.trim().length === 0) {
    return { ok: false, message: 'courseId must be a non-empty string' };
  }
  const trimmed = courseId.trim();
  if (trimmed.includes('/') || trimmed.includes('..')) {
    return {
      ok: false,
      message: 'courseId contains illegal path characters',
    };
  }
  return { ok: true, courseId: trimmed };
}

/**
 * Build repair payload from LEGACY SOURCE only.
 * Copies: uid, courseId, overall, papers, chapters, lastUpdated, appVersion
 * Adds: schemaVersion = 1
 *
 * @param {string} uid
 * @param {string} courseId
 * @param {Record<string, unknown>} source
 */
function buildRepairPayload(uid, courseId, source) {
  if (!isPlainObject(source)) {
    return { ok: false, message: 'source missing or not an object' };
  }

  const sourceUid = source.uid;
  if (typeof sourceUid !== 'string' || sourceUid !== uid) {
    return {
      ok: false,
      message: `source.uid mismatch: expected "${uid}", got ${JSON.stringify(sourceUid)}`,
    };
  }

  const sourceCourseId = source.courseId;
  if (sourceCourseId == null || sourceCourseId === '') {
    return { ok: false, message: 'source.courseId is missing/null' };
  }
  if (typeof sourceCourseId !== 'string') {
    return { ok: false, message: 'source.courseId is not a string' };
  }
  if (sourceCourseId.trim() !== courseId) {
    return {
      ok: false,
      message: `source.courseId mismatch: expected "${courseId}", got "${sourceCourseId}"`,
    };
  }

  if (!isPlainObject(source.overall)) {
    return { ok: false, message: 'source.overall must be an object map' };
  }
  if (!isPlainObject(source.papers)) {
    return { ok: false, message: 'source.papers must be an object map' };
  }
  if (!isPlainObject(source.chapters)) {
    return { ok: false, message: 'source.chapters must be an object map' };
  }

  const lastUpdated = normalizeTimestamp(source.lastUpdated);
  const appVersion =
    typeof source.appVersion === 'string' ? source.appVersion : null;

  const payload = {
    uid,
    courseId,
    overall: source.overall,
    papers: source.papers,
    chapters: source.chapters,
    lastUpdated,
    appVersion,
    schemaVersion: SCHEMA_VERSION,
  };

  return { ok: true, payload };
}

function validateTargetIdentity(target, uid, courseId) {
  if (target == null) return { ok: true };
  if (!isPlainObject(target)) {
    return { ok: false, message: 'target exists but is not an object' };
  }
  if (target.uid != null && target.uid !== uid) {
    return {
      ok: false,
      message: `target.uid mismatch: expected "${uid}", got ${JSON.stringify(target.uid)}`,
    };
  }
  if (target.courseId != null && target.courseId !== courseId) {
    return {
      ok: false,
      message: `target.courseId mismatch: expected "${courseId}", got ${JSON.stringify(target.courseId)}`,
    };
  }
  return { ok: true };
}

function progressSummary(label, data) {
  if (data == null) {
    return { label, exists: false };
  }
  const overall = isPlainObject(data.overall) ? data.overall : {};
  const papers = isPlainObject(data.papers) ? data.papers : {};
  const chapters = isPlainObject(data.chapters) ? data.chapters : {};
  return {
    label,
    exists: true,
    uid: data.uid ?? null,
    courseId: data.courseId ?? null,
    appVersion: data.appVersion ?? null,
    schemaVersion: data.schemaVersion ?? null,
    lastUpdated:
      data.lastUpdated instanceof Date
        ? data.lastUpdated.toISOString()
        : data.lastUpdated ?? null,
    overall: {
      completion: overall.completion ?? null,
      accuracy: overall.accuracy ?? null,
      chaptersCompleted: overall.chaptersCompleted ?? null,
      totalChapters: overall.totalChapters ?? null,
      questionsAttempted: overall.questionsAttempted ?? null,
      questionsCorrect: overall.questionsCorrect ?? null,
    },
    paperCount: Object.keys(papers).length,
    chapterCount: Object.keys(chapters).length,
  };
}

function deepEqualJson(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

/**
 * Verify repaired target matches source-derived payload for required fields.
 */
function verifyRepairedTarget(actual, payload) {
  const errors = [];
  if (!isPlainObject(actual)) {
    return ['post-write target missing or not an object'];
  }
  if (actual.uid !== payload.uid) {
    errors.push(`uid: expected ${payload.uid}, got ${actual.uid}`);
  }
  if (actual.courseId !== payload.courseId) {
    errors.push(`courseId: expected ${payload.courseId}, got ${actual.courseId}`);
  }
  if (!deepEqualJson(actual.overall, payload.overall)) {
    errors.push('overall does not match source-derived payload');
  }
  if (!deepEqualJson(actual.papers, payload.papers)) {
    errors.push('papers does not match source-derived payload');
  }
  if (!deepEqualJson(actual.chapters, payload.chapters)) {
    errors.push('chapters does not match source-derived payload');
  }
  if (actual.schemaVersion !== SCHEMA_VERSION) {
    errors.push(
      `schemaVersion: expected ${SCHEMA_VERSION}, got ${actual.schemaVersion}`,
    );
  }
  return errors;
}

function printBanner({ projectId, mode, uid, courseId }) {
  console.log('============================================================');
  console.log(`PROJECT: ${projectId}`);
  console.log(`MODE: ${mode}`);
  console.log(`UID: ${uid}`);
  console.log(`COURSE: ${courseId}`);
  console.log(
    `SOURCE: ${COLLECTION}/${uid}  (READ-ONLY — never modified)`,
  );
  console.log(
    `TARGET: ${COLLECTION}/${uid}/${COURSES_SUBCOLLECTION}/${courseId}`,
  );
  console.log('============================================================');
}

function printBefore({ source, target, sourcePath, targetPath }) {
  console.log('');
  console.log('--- BEFORE ---');
  console.log(`source path: ${sourcePath}`);
  console.log(JSON.stringify(progressSummary('source', source), null, 2));
  console.log(`target path: ${targetPath}`);
  console.log(JSON.stringify(progressSummary('target', target), null, 2));
}

/**
 * @param {{
 *   projectId: string,
 *   dryRun: boolean,
 *   apply: boolean,
 *   uid: string,
 *   courseId: string,
 *   allowCreate: boolean,
 *   source: Record<string, unknown> | null,
 *   target: Record<string, unknown> | null,
 *   targetExists: boolean,
 *   writeFn?: (payload: Record<string, unknown>) => Promise<Record<string, unknown>>,
 * }} opts
 */
async function runRepair(opts) {
  const {
    projectId,
    dryRun,
    apply,
    uid,
    courseId,
    allowCreate,
    source,
    target,
    targetExists,
    writeFn,
  } = opts;

  const sourcePath = `${COLLECTION}/${uid}`;
  const targetPath = `${COLLECTION}/${uid}/${COURSES_SUBCOLLECTION}/${courseId}`;

  printBanner({
    projectId,
    mode: apply ? 'APPLY' : 'DRY-RUN',
    uid,
    courseId,
  });

  const courseCheck = validateCourseId(courseId);
  if (!courseCheck.ok) {
    console.error(`Error: ${courseCheck.message}`);
    return 1;
  }

  if (source == null) {
    console.error(`Error: source document missing: ${sourcePath}`);
    console.error('Refuse repair — legacy parent is required.');
    return 1;
  }

  const built = buildRepairPayload(uid, courseId, source);
  if (!built.ok) {
    console.error(`Error: source validation failed: ${built.message}`);
    return 1;
  }

  const targetId = validateTargetIdentity(target, uid, courseId);
  if (!targetId.ok) {
    console.error(`Error: target validation failed: ${targetId.message}`);
    return 1;
  }

  if (!targetExists) {
    if (!allowCreate) {
      console.error(`Error: target document missing: ${targetPath}`);
      console.error(
        'Refuse silent create. Re-run with --allow-create if you intentionally want to create the target from the source.',
      );
      return 1;
    }
  }

  printBefore({ source, target, sourcePath, targetPath });

  console.log('');
  console.log('--- REPAIR PAYLOAD (from LEGACY SOURCE) ---');
  console.log(
    JSON.stringify(
      {
        ...built.payload,
        lastUpdated:
          built.payload.lastUpdated instanceof Date
            ? built.payload.lastUpdated.toISOString()
            : built.payload.lastUpdated,
      },
      null,
      2,
    ),
  );

  console.log('');
  console.log(`EXACT TARGET PATH: ${targetPath}`);
  console.log('');

  if (dryRun) {
    if (!targetExists && allowCreate) {
      console.log('WOULD CREATE (then seed from source)');
    } else {
      console.log('WOULD REPAIR');
    }
    console.log(`source: ${sourcePath}`);
    console.log(`target: ${targetPath}`);
    console.log('');
    console.log('No writes performed (dry-run).');
    console.log('Legacy parent was NOT modified.');
    return 0;
  }

  // APPLY
  if (typeof writeFn !== 'function') {
    console.error('Error: internal write function missing.');
    return 1;
  }

  console.log('APPLY MODE — overwriting ONLY the course document.');
  console.log(`target: ${targetPath}`);
  console.log('Legacy parent will NOT be modified.');
  console.log('');

  let written;
  try {
    written = await writeFn(built.payload);
  } catch (error) {
    console.error('Error: write failed.');
    console.error(error?.message || error);
    return 1;
  }

  const verifyErrors = verifyRepairedTarget(written, built.payload);
  if (verifyErrors.length > 0) {
    console.error('ERROR: post-write verification failed:');
    for (const err of verifyErrors) {
      console.error(`  - ${err}`);
    }
    return 1;
  }

  console.log('REPAIRED');
  console.log(`target: ${targetPath}`);
  console.log(JSON.stringify(progressSummary('repaired_target', written), null, 2));
  console.log('');
  console.log('Legacy parent was NOT modified.');
  return 0;
}

async function runFixtureMode({
  fixturePath,
  dryRun,
  apply,
  uid,
  courseId,
  allowCreate,
}) {
  if (apply) {
    console.error(
      'Error: --apply is not supported with --fixture (fixture mode is read-only simulation).',
    );
    process.exit(1);
  }

  const absolute = resolve(process.cwd(), fixturePath);
  const raw = JSON.parse(readFileSync(absolute, 'utf8'));
  if (!isPlainObject(raw) || !isPlainObject(raw.source)) {
    console.error('Error: fixture must contain { source, target?, targetExists? }.');
    process.exit(1);
  }

  const source = raw.source;
  const targetExists = raw.targetExists === true || isPlainObject(raw.target);
  const target = targetExists ? (raw.target ?? null) : null;

  // Fixture identity must match requested uid/course when provided on source.
  if (source.uid != null && source.uid !== uid) {
    console.error(
      `Error: fixture source.uid "${source.uid}" does not match --uid "${uid}".`,
    );
    process.exit(1);
  }

  return runRepair({
    projectId: 'fixture-local',
    dryRun: true,
    apply: false,
    uid,
    courseId,
    allowCreate,
    source,
    target,
    targetExists,
  });
}

async function runFirebaseMode({
  projectId,
  dryRun,
  apply,
  uid,
  courseId,
  allowCreate,
}) {
  if (getApps().length === 0) {
    initializeApp({
      credential: applicationDefault(),
      projectId,
    });
  }

  const db = getFirestore();
  const sourceRef = db.collection(COLLECTION).doc(uid);
  const targetRef = sourceRef.collection(COURSES_SUBCOLLECTION).doc(courseId);

  const [sourceSnap, targetSnap] = await Promise.all([
    sourceRef.get(),
    targetRef.get(),
  ]);

  const source = sourceSnap.exists ? sourceSnap.data() : null;
  const targetExists = targetSnap.exists;
  const target = targetExists ? targetSnap.data() : null;

  return runRepair({
    projectId,
    dryRun,
    apply,
    uid,
    courseId,
    allowCreate,
    source,
    target,
    targetExists,
    writeFn: async (payload) => {
      // Explicit transaction: re-read source + target, verify identity, then
      // overwrite ONLY the course document. Parent is never written.
      await db.runTransaction(async (tx) => {
        const freshSource = await tx.get(sourceRef);
        const freshTarget = await tx.get(targetRef);

        if (!freshSource.exists) {
          throw new Error(`source disappeared during repair: ${sourceRef.path}`);
        }

        const freshSourceData = freshSource.data();
        const rebuilt = buildRepairPayload(uid, courseId, freshSourceData);
        if (!rebuilt.ok) {
          throw new Error(`source re-validation failed: ${rebuilt.message}`);
        }

        // Ensure payload still matches what we planned (path identity).
        if (
          rebuilt.payload.uid !== payload.uid ||
          rebuilt.payload.courseId !== payload.courseId
        ) {
          throw new Error('path identity changed during transaction — abort');
        }

        if (freshTarget.exists) {
          const t = freshTarget.data();
          const idCheck = validateTargetIdentity(t, uid, courseId);
          if (!idCheck.ok) {
            throw new Error(`target re-validation failed: ${idCheck.message}`);
          }
        } else if (!allowCreate) {
          throw new Error(
            `target missing during apply and --allow-create not set: ${targetRef.path}`,
          );
        }

        // Full overwrite of the course document only.
        tx.set(targetRef, rebuilt.payload, { merge: false });
      });

      const after = await targetRef.get();
      if (!after.exists) {
        throw new Error(`target missing after write: ${targetRef.path}`);
      }
      return after.data();
    },
  });
}

async function main() {
  const {
    apply,
    dryRun,
    confirmProject,
    fixturePath,
    uid,
    courseId,
    allowCreate,
  } = parseArgs(process.argv);

  if (fixturePath) {
    const code = await runFixtureMode({
      fixturePath,
      dryRun,
      apply,
      uid,
      courseId,
      allowCreate,
    });
    process.exit(code);
  }

  const projectId = resolveProjectId();
  assertProjectSafety({ projectId, apply, confirmProject });

  if (apply) {
    console.log('');
    console.log('APPLY MODE ARMED');
    console.log(`PROJECT: ${projectId}`);
    console.log(`UID: ${uid}`);
    console.log(`COURSE: ${courseId}`);
    console.log(
      `TARGET ONLY: ${COLLECTION}/${uid}/${COURSES_SUBCOLLECTION}/${courseId}`,
    );
    console.log('Legacy parent will NOT be modified or deleted.');
    console.log('');
  }

  const code = await runFirebaseMode({
    projectId,
    dryRun,
    apply,
    uid,
    courseId,
    allowCreate,
  });
  process.exit(code);
}

main().catch((error) => {
  console.error('Fatal error during user_progress course repair:');
  console.error(error?.message || error);
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error(
      '\nHint: set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON path,',
    );
    console.error(
      'or use --fixture=./fixtures/user_progress_course_repair_sample.json for local dry-run.',
    );
  }
  process.exit(1);
});
