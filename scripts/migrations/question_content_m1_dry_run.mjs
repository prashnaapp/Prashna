#!/usr/bin/env node

/**
 * Phase M1 production migration preflight.
 *
 * This module intentionally has no Firestore mutation path. Production mode
 * only calls collection().get() for the three approved collections.
 */

import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';

export const EXPECTED_PROJECT_ID = 'prashna-67689';
export const DATABASE_ID = '(default)';
export const MODE = 'DRY_RUN';
export const COLLECTIONS = Object.freeze([
  'questions',
  'tests',
  'question_assignments',
]);
export const SCRIPT_VERSION = 'm1.0.0';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');

export function parseCliArgs(argv) {
  const args = argv.slice(2);
  if (!args.includes('--dry-run')) {
    throw new Error(
      'This Phase M1 tool is read-only and requires the --dry-run flag.',
    );
  }

  const parsed = {
    dryRun: true,
    fixturePath: null,
    outputPath: null,
    projectId:
      process.env.FIREBASE_PROJECT_ID ||
      process.env.GCLOUD_PROJECT ||
      process.env.GOOGLE_CLOUD_PROJECT ||
      EXPECTED_PROJECT_ID,
  };

  for (const arg of args) {
    if (arg === '--dry-run') continue;
    if (arg === '--apply') {
      throw new Error('--apply is not supported in Phase M1.');
    }
    if (arg.startsWith('--fixture=')) {
      parsed.fixturePath = arg.slice('--fixture='.length);
      continue;
    }
    if (arg.startsWith('--output=')) {
      parsed.outputPath = arg.slice('--output='.length);
      continue;
    }
    if (arg.startsWith('--project=')) {
      parsed.projectId = arg.slice('--project='.length);
      continue;
    }
    throw new Error(`Unsupported argument: ${arg}`);
  }

  if (parsed.projectId !== EXPECTED_PROJECT_ID && !parsed.fixturePath) {
    throw new Error(
      `Refusing unexpected production project "${parsed.projectId}".`,
    );
  }
  return parsed;
}

function trim(value) {
  return value == null ? '' : String(value).trim();
}

function asNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function asStringList(value) {
  return Array.isArray(value)
    ? value.filter((item) => typeof item === 'string').map((item) => item.trim())
    : [];
}

function asObject(value) {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? value
    : null;
}

function fieldPresence(data, field) {
  if (!Object.hasOwn(data, field)) return 'absent';
  if (data[field] == null) return 'empty';
  if (typeof data[field] === 'string' && data[field].trim() === '') {
    return 'empty';
  }
  return 'present';
}

function readOptionText(option) {
  if (typeof option === 'string') return option;
  if (asObject(option) && typeof option.text === 'string') return option.text;
  return '';
}

function localized(data, language) {
  return asObject(asObject(data.content)?.[language]);
}

function englishQuestion(data) {
  const nested = trim(localized(data, 'en')?.question);
  return nested || trim(data.question);
}

function englishOptions(data) {
  const nested = localized(data, 'en')?.options;
  const raw = Array.isArray(nested) ? nested : data.options;
  return Array.isArray(raw) ? raw.map(readOptionText) : [];
}

function teluguOptions(data) {
  const raw = localized(data, 'te')?.options;
  return Array.isArray(raw) ? raw.map(readOptionText) : [];
}

function englishStatements(data) {
  const raw = localized(data, 'en')?.statements;
  return Array.isArray(raw) ? raw.map((item) => String(item ?? '')) : [];
}

function teluguStatements(data) {
  const raw = localized(data, 'te')?.statements;
  return Array.isArray(raw) ? raw.map((item) => String(item ?? '')) : [];
}

function resolvedItemFormat(data) {
  return trim(data.itemFormat).toLowerCase() === 'statement_mcq'
    ? 'statement_mcq'
    : 'standard_mcq';
}

/**
 * Exact equivalent of QuestionContentFingerprint.fromQuestion + compute.
 *
 * Keep this implementation beside golden fixtures. It intentionally does not
 * normalize internal English whitespace because the Dart contract does not.
 */
export function computeContentFingerprint(data) {
  const enOptions = englishOptions(data);
  const teOptions = teluguOptions(data);
  const enStatements = englishStatements(data);
  const teStatements = teluguStatements(data);
  const optionText = enOptions
    .map(
      (option, index) =>
        `${option.trim()}|${(teOptions[index] ?? '').trim()}`,
    )
    .join('||');
  const statementCount = Math.max(enStatements.length, teStatements.length);
  const statementText = Array.from({ length: statementCount }, (_, index) =>
    `${(enStatements[index] ?? '').trim()}|${(teStatements[index] ?? '').trim()}`,
  ).join('||');

  return [
    trim(data.courseId).toLowerCase(),
    trim(data.paperId).toLowerCase(),
    resolvedItemFormat(data),
    englishQuestion(data).trim().toLowerCase(),
    trim(localized(data, 'te')?.question),
    trim(data.correctOption).toUpperCase(),
    optionText.toLowerCase(),
    statementText.toLowerCase(),
  ].join('::');
}

/** Exact equivalent of QuestionSearchText.normalize for English text. */
export function normalizeQuestionSearchText(data) {
  return englishQuestion(data).trim().toLowerCase().replace(/\s+/g, ' ');
}

function canonicalLocation(data, catalog) {
  const courseId = trim(data.courseId);
  const paperId = trim(data.paperId);
  if (!courseId || !paperId) return false;

  const majorStudyAreaId = trim(data.majorStudyAreaId);
  const contentTopicId = trim(data.contentTopicId);
  const unitId =
    trim(data.syllabusUnitId) ||
    majorStudyAreaId ||
    trim(data.topicId);
  const partId = trim(data.partId) || null;
  const candidates = catalog.filter(
    (unit) =>
      unit.courseId === courseId &&
      unit.paperId === paperId &&
      unit.partId === partId &&
      unit.syllabusUnitId === unitId,
  );
  if (candidates.length !== 1) return false;

  if (courseId === 'group-ii' && paperId === 'group-ii-paper-i') {
    return Boolean(majorStudyAreaId && majorStudyAreaId === unitId);
  }
  if (courseId === 'group-ii') {
    return Boolean(partId && (data.syllabusUnitId || data.topicId));
  }
  if (courseId === 'group-iii') {
    return Boolean(data.syllabusUnitId);
  }
  return false;
}

function testLocationCompatible(question, test) {
  const questionArea = trim(question.contentArea);
  const category = trim(test.category);
  if (
    questionArea === 'chapter' &&
    category &&
    category !== 'chapter' &&
    category !== 'paper'
  ) {
    return false;
  }
  if (questionArea === 'testSeries') {
    const subtype = trim(question.testSeriesCategory);
    if (subtype && category && subtype !== category) return false;
    if (subtype === 'part') {
      return trim(question.paperId) !== '' &&
        trim(question.paperId) === trim(test.paperId);
    }
    if (subtype === 'mock') {
      return trim(question.seriesId) !== '' &&
        trim(question.seriesId) === trim(test.seriesId);
    }
    if (subtype === 'previousyear') {
      return (
        Number.isInteger(asNumber(question.year)) &&
        Number.isInteger(asNumber(test.year)) &&
        asNumber(question.year) === asNumber(test.year)
      );
    }
  }
  if (
    trim(test.paperId) &&
    trim(question.paperId) &&
    trim(test.paperId) !== trim(question.paperId)
  ) {
    return false;
  }
  if (
    trim(test.partId) &&
    trim(question.partId) &&
    trim(test.partId) !== trim(question.partId)
  ) {
    return false;
  }
  const testUnit = trim(test.syllabusUnitId);
  if (testUnit && questionArea !== 'testSeries') {
    return (
      trim(question.syllabusUnitId) === testUnit ||
      trim(question.topicId) === testUnit ||
      trim(question.majorStudyAreaId) === testUnit
    );
  }
  return true;
}

function questionSummary(id, data) {
  return {
    documentId: id,
    courseId: data.courseId ?? null,
    paperId: data.paperId ?? null,
    contentArea: data.contentArea ?? null,
    testSeriesCategory: data.testSeriesCategory ?? null,
    partId: data.partId ?? null,
    sectionId: data.sectionId ?? null,
    areaId: data.areaId ?? null,
    majorStudyAreaId: data.majorStudyAreaId ?? null,
    contentTopicId: data.contentTopicId ?? null,
    topicId: data.topicId ?? null,
    syllabusUnitId: data.syllabusUnitId ?? null,
    lessonId: data.lessonId ?? null,
    questionType: data.questionType ?? null,
    itemFormat: data.itemFormat ?? null,
    status: data.status ?? null,
    isActive: data.isActive ?? null,
    marks: data.marks ?? null,
    contentFingerprint: {
      presence: fieldPresence(data, 'contentFingerprint'),
      value: data.contentFingerprint ?? null,
    },
    questionSearchText: {
      presence: fieldPresence(data, 'questionSearchText'),
      value: data.questionSearchText ?? null,
    },
  };
}

function questionClassification(question, refs, testsById, catalog) {
  const reasons = [];
  if (!question) return { classification: 'MANUAL_REVIEW', reasons: ['Question document is missing.'] };
  if (refs.length === 0) {
    return {
      classification: 'LEAVE_LEGACY',
      reasons: ['No Test relationship proves ownership.'],
    };
  }
  if (refs.length > 1) {
    return {
      classification: 'MANUAL_REVIEW',
      reasons: ['Question is referenced by multiple Tests.'],
    };
  }
  const test = testsById.get(refs[0].testId);
  if (!test) {
    return {
      classification: 'MANUAL_REVIEW',
      reasons: ['Referenced Test document is missing.'],
    };
  }
  if (refs[0].duplicate) reasons.push('Duplicate Question ID inside Test.');
  if (test.data.category !== 'chapter') {
    reasons.push('Existing relationship does not prove Chapter ownership.');
  }
  if (!canonicalLocation(question.data, catalog)) {
    reasons.push('Canonical Question location is not deterministically proven.');
  }
  if (!question.data.courseId || !question.data.paperId) {
    reasons.push('courseId and paperId are required for the fingerprint.');
  }
  if (!englishQuestion(question.data)) {
    reasons.push('English Question text is missing.');
  }
  if (englishOptions(question.data).length < 2) {
    reasons.push('At least two Question options are required.');
  }
  if (reasons.length > 0) {
    return { classification: 'MANUAL_REVIEW', reasons };
  }
  return {
    classification: 'SAFE_AUTOMATIC',
    reasons: [
      'Exactly one existing Chapter Test relationship proves Question ownership.',
      'Canonical Question location and fingerprint/search inputs are valid.',
    ],
  };
}

function patchField(data, field, value) {
  return {
    operation: data[field] === value ? 'NO_OP' : 'PATCH_REQUIRED',
    value,
  };
}

function relationshipRefs(tests) {
  const refsByQuestion = new Map();
  for (const test of tests) {
    const ids = Array.isArray(test.data.questionIds)
      ? test.data.questionIds
      : [];
    const seen = new Set();
    for (const rawId of ids) {
      const questionId = trim(rawId);
      if (!questionId) continue;
      const duplicate = seen.has(questionId);
      seen.add(questionId);
      const refs = refsByQuestion.get(questionId) ?? [];
      refs.push({ testId: test.id, duplicate });
      refsByQuestion.set(questionId, refs);
    }
  }
  return refsByQuestion;
}

function buildQuestionResults(questions, tests, assignments, catalog) {
  const refsByQuestion = relationshipRefs(tests);
  const testsById = new Map(tests.map((test) => [test.id, test]));
  const assignmentsByQuestion = new Map(
    assignments.map((assignment) => [assignment.id, assignment.data]),
  );

  return questions.map((question) => {
    const refs = refsByQuestion.get(question.id) ?? [];
    const result = questionClassification(question, refs, testsById, catalog);
    const fingerprint = computeContentFingerprint(question.data);
    const searchText = normalizeQuestionSearchText(question.data);
    const technicallyDerivable =
      Boolean(trim(question.data.courseId)) &&
      Boolean(trim(question.data.paperId)) &&
      Boolean(englishQuestion(question.data)) &&
      englishOptions(question.data).length >= 2;
    const proposedPatch =
      result.classification === 'SAFE_AUTOMATIC'
        ? {
            contentArea: patchField(question.data, 'contentArea', 'chapter'),
            contentFingerprint: patchField(
              question.data,
              'contentFingerprint',
              fingerprint,
            ),
            questionSearchText: patchField(
              question.data,
              'questionSearchText',
              searchText,
            ),
          }
        : {};
    return {
      documentId: question.id,
      classification: result.classification,
      reasons: result.reasons,
      current: questionSummary(question.id, question.data),
      relationshipTestIds: refs.map((ref) => ref.testId),
      technicallyDerivable: technicallyDerivable
        ? {
            contentFingerprint: fingerprint,
            questionSearchText: searchText,
          }
        : null,
      proposedPatch,
      assignmentOwner: assignmentsByQuestion.get(question.id)?.testId ?? null,
      ownershipPatchApplied: false,
    };
  });
}

function effectivePublicationState(test) {
  if (test.data.status === 'published' || test.data.isPublished === true) {
    return 'published';
  }
  if (test.data.status === 'archived') return 'archived';
  return 'draft';
}

function testSummary(test) {
  return {
    documentId: test.id,
    title: test.data.title ?? null,
    courseId: test.data.courseId ?? null,
    category: test.data.category ?? null,
    paperId: test.data.paperId ?? null,
    partId: test.data.partId ?? null,
    syllabusUnitId: test.data.syllabusUnitId ?? null,
    majorStudyAreaId: test.data.majorStudyAreaId ?? null,
    contentTopicId: test.data.contentTopicId ?? null,
    canonicalTopicId: test.data.canonicalTopicId ?? null,
    lessonId: test.data.lessonId ?? null,
    seriesId: test.data.seriesId ?? null,
    year: test.data.year ?? null,
    status: test.data.status ?? null,
    isPublished: test.data.isPublished ?? null,
    questionIds: Array.isArray(test.data.questionIds)
      ? test.data.questionIds
      : [],
    questionCount: test.data.questionCount ?? null,
    totalMarks: test.data.totalMarks ?? test.data.marks ?? null,
    durationMinutes: test.data.durationMinutes ?? null,
    negativeMarks: test.data.negativeMarks ?? test.data.negativeMarking ?? null,
  };
}

function buildTestResults(tests, questionsById, questionResultsById) {
  return tests.map((test) => {
    const ids = Array.isArray(test.data.questionIds)
      ? test.data.questionIds.map(trim).filter(Boolean)
      : [];
    const loaded = ids.map((id) => questionsById.get(id));
    const missing = loaded.some((question) => !question);
    const duplicate = new Set(ids).size !== ids.length;
    const marks = loaded.map((question) => asNumber(question?.data.marks));
    const canVerify = !missing && !duplicate && marks.every((value) => value != null);
    const expected = canVerify
      ? {
          questionCount: ids.length,
          totalMarks: marks.reduce((sum, value) => sum + value, 0),
          durationMinutes: ids.length,
        }
      : null;
    const stored = {
      questionCount: asNumber(test.data.questionCount),
      totalMarks: asNumber(test.data.totalMarks ?? test.data.marks),
      durationMinutes: asNumber(test.data.durationMinutes),
    };
    const aggregateStatus = !expected
      ? 'CANNOT_VERIFY'
      : Object.keys(expected).every((key) => stored[key] === expected[key])
        ? 'MATCH'
        : 'STALE';
    const refsManual = ids.some(
      (id) => questionResultsById.get(id)?.classification === 'MANUAL_REVIEW',
    );
    const statusMissingButPublished =
      test.data.status == null && test.data.isPublished === true;
    const reasons = [];
    if (refsManual) reasons.push('Contains a manually reviewed Question relationship.');
    if (statusMissingButPublished) {
      reasons.push('isPublished=true but status is missing.');
    }
    if (missing) reasons.push('One or more referenced Questions are missing.');
    if (duplicate) reasons.push('Duplicate Question IDs are present.');
    const manualReview = reasons.length > 0;
    const classification = manualReview
      ? 'MANUAL_REVIEW'
      : aggregateStatus === 'STALE'
        ? 'SAFE_NORMALIZATION'
        : 'SAFE_NO_CHANGE';
    const mismatches = [];
    const effectiveStatus = effectivePublicationState(test);
    for (const id of ids) {
      const question = questionsById.get(id);
      if (!question) continue;
      const questionStatus =
        question.data.status ??
        (question.data.isActive === true ? 'published' : 'draft');
      const expectedActive = effectiveStatus === 'published';
      if (
        questionStatus !== effectiveStatus ||
        Boolean(question.data.isActive) !== expectedActive
      ) {
        mismatches.push({
          questionId: id,
          questionStatus,
          questionIsActive: question.data.isActive ?? null,
        });
      }
    }
    return {
      documentId: test.id,
      classification,
      reasons,
      current: testSummary(test),
      effectivePublicationState: effectiveStatus,
      aggregate: {
        status: aggregateStatus,
        stored,
        expected,
        proposedPatch:
          classification === 'SAFE_NORMALIZATION' && expected
            ? expected
            : {},
      },
      statusCheck: {
        mismatches,
        automaticStatusPatch: false,
      },
    };
  });
}

function assignmentCompatibility(question, test) {
  if (!question || !test) return false;
  if (trim(question.data.courseId) !== trim(test.data.courseId)) return false;
  return testLocationCompatible(question.data, test.data);
}

function buildAssignmentResults(tests, questionsById, assignmentsById, questionResultsById, testResultsById) {
  const refsByQuestion = new Map();
  const results = [];
  for (const test of tests) {
    const ids = Array.isArray(test.data.questionIds)
      ? test.data.questionIds.map(trim).filter(Boolean)
      : [];
    const seen = new Set();
    for (const questionId of ids) {
      const question = questionsById.get(questionId);
      const previous = refsByQuestion.get(questionId) ?? [];
      const duplicate = seen.has(questionId);
      seen.add(questionId);
      previous.push(test.id);
      refsByQuestion.set(questionId, previous);
      const reasons = [];
      if (!question) reasons.push('Question document is missing.');
      if (previous.length > 1) reasons.push('Question is referenced by multiple Tests.');
      if (duplicate) reasons.push('Duplicate Question ID inside Test.');
      if (!assignmentCompatibility(question, test)) {
        reasons.push('Question/Test canonical compatibility is not proven.');
      }
      if (questionResultsById.get(questionId)?.classification !== 'SAFE_AUTOMATIC') {
        reasons.push('Question is manually reviewed for ownership/location.');
      }
      if (testResultsById.get(test.id)?.classification === 'MANUAL_REVIEW') {
        reasons.push('Test is manually reviewed.');
      }
      const existing = assignmentsById.get(questionId);
      if (existing?.testId && existing.testId !== test.id) {
        reasons.push(`Assignment document belongs to Test "${existing.testId}".`);
      }
      const safe = reasons.length === 0;
      results.push({
        documentId: questionId,
        testId: test.id,
        classification: safe ? 'SAFE_AUTOMATIC' : 'MANUAL_REVIEW',
        reasons: safe ? ['Unique compatible relationship with no assignment conflict.'] : reasons,
        proposedAssignment: safe
          ? {
              questionId,
              testId: test.id,
              courseId: test.data.courseId ?? null,
              assignedAt: 'APPLY_TIME_VALUE',
              assignedBy: 'APPLY_TIME_VALUE',
            }
          : null,
        existingAssignment: existing
          ? {
              questionId,
              testId: existing.testId ?? null,
              courseId: existing.courseId ?? null,
            }
          : null,
        mutationPerformed: false,
      });
    }
  }
  return results;
}

function normalizeDocument(document) {
  return {
    id: document.id,
    data: document.data ?? {},
  };
}

function normalizeFixture(raw) {
  const normalizeCollection = (value) =>
    Array.isArray(value) ? value.map(normalizeDocument) : [];
  return {
    questions: normalizeCollection(raw.questions),
    tests: normalizeCollection(raw.tests),
    assignments: normalizeCollection(raw.assignments),
  };
}

export function buildDryRunReport({
  projectId = EXPECTED_PROJECT_ID,
  questions: rawQuestions = [],
  tests: rawTests = [],
  assignments: rawAssignments = [],
  timestamp = new Date().toISOString(),
  runId = `m1-${timestamp.replace(/[^0-9]/g, '').slice(0, 14)}`,
  gitCommit = null,
  catalog = [],
}) {
  const questions = rawQuestions.map(normalizeDocument);
  const tests = rawTests.map(normalizeDocument);
  const assignments = rawAssignments.map(normalizeDocument);
  const questionsById = new Map(questions.map((question) => [question.id, question]));
  const assignmentsById = new Map(
    assignments.map((assignment) => [assignment.id, assignment.data]),
  );
  const questionRefs = relationshipRefs(tests);
  const questionResults = buildQuestionResults(
    questions,
    tests,
    assignments,
    catalog,
  );
  const questionResultsById = new Map(
    questionResults.map((result) => [result.documentId, result]),
  );
  const testResults = buildTestResults(
    tests,
    questionsById,
    questionResultsById,
  );
  const testResultsById = new Map(
    testResults.map((result) => [result.documentId, result]),
  );
  const assignmentResults = buildAssignmentResults(
    tests,
    questionsById,
    assignmentsById,
    questionResultsById,
    testResultsById,
  );

  const count = (items, value) =>
    items.filter((item) => item.classification === value).length;
  const report = {
    metadata: {
      runId,
      timestamp,
      projectId,
      databaseId: DATABASE_ID,
      mode: MODE,
      scriptVersion: SCRIPT_VERSION,
      gitCommit,
      writesPerformed: 0,
      firestoreMutationMethodsCalled: [],
      readCollections: COLLECTIONS,
    },
    inventory: {
      questionCount: questions.length,
      testCount: tests.length,
      assignmentCount: assignments.length,
      relationshipCount: assignmentResults.length,
    },
    questions: questionResults,
    tests: testResults,
    assignments: assignmentResults,
    summary: {
      questions: {
        SAFE_AUTOMATIC: count(questionResults, 'SAFE_AUTOMATIC'),
        MANUAL_REVIEW: count(questionResults, 'MANUAL_REVIEW'),
        LEAVE_LEGACY: count(questionResults, 'LEAVE_LEGACY'),
      },
      tests: {
        SAFE_NO_CHANGE: count(testResults, 'SAFE_NO_CHANGE'),
        SAFE_NORMALIZATION: count(testResults, 'SAFE_NORMALIZATION'),
        MANUAL_REVIEW: count(testResults, 'MANUAL_REVIEW'),
      },
      assignments: {
        SAFE_AUTOMATIC: count(assignmentResults, 'SAFE_AUTOMATIC'),
        MANUAL_REVIEW: count(assignmentResults, 'MANUAL_REVIEW'),
      },
      staleAggregates: testResults.filter(
        (test) => test.aggregate.status === 'STALE',
      ).length,
      unresolvedDecisions: [
        ...questionResults
          .filter((question) => question.classification === 'MANUAL_REVIEW')
          .map((question) => question.documentId),
        ...testResults
          .filter((test) => test.classification === 'MANUAL_REVIEW')
          .map((test) => test.documentId),
      ],
    },
  };

  // Keep this explicit assertion close to report construction. A future
  // apply phase must not silently reuse this M1 module as a writer.
  if (report.metadata.writesPerformed !== 0) {
    throw new Error('M1 safety assertion failed: writes were performed.');
  }
  return report;
}

async function readCollection(db, collectionName) {
  if (!COLLECTIONS.includes(collectionName)) {
    throw new Error(`Collection is outside the M1 read allowlist: ${collectionName}`);
  }
  const snapshot = await db.collection(collectionName).orderBy('__name__').get();
  return snapshot.docs.map((document) => ({
    id: document.id,
    data: document.data(),
  }));
}

export async function readProductionData(db) {
  const [questions, tests, assignments] = await Promise.all(
    COLLECTIONS.map((collectionName) => readCollection(db, collectionName)),
  );
  return { questions, tests, assignments };
}

async function loadCatalog() {
  const module = await import('../../functions/src/canonical_syllabus_catalog.js');
  return module.CANONICAL_SYLLABUS_UNITS;
}

function readGitCommit() {
  try {
    return execFileSync('git', ['rev-parse', 'HEAD'], {
      cwd: repoRoot,
      encoding: 'utf8',
    }).trim();
  } catch {
    return null;
  }
}

function defaultArtifactPath(timestamp) {
  const safe = timestamp.replace(/[^0-9]/g, '').slice(0, 14);
  return `/tmp/prashna-migration-dry-run/migration-dry-run-${safe}.json`;
}

async function writeArtifact(report, outputPath) {
  const target = resolve(outputPath);
  await mkdir(dirname(target), { recursive: true });
  await writeFile(target, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
  return target;
}

function printSummary(report, artifactPath) {
  console.log('READ-ONLY DRY RUN');
  console.log(`Project: ${report.metadata.projectId}`);
  console.log(`Database: ${report.metadata.databaseId}`);
  console.log('');
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
  console.log(`Artifact: ${artifactPath}`);
}

async function loadFixture(fixturePath) {
  const raw = JSON.parse(await readFile(resolve(fixturePath), 'utf8'));
  return normalizeFixture(raw);
}

async function loadProduction() {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error(
      'Refusing production mode while FIRESTORE_EMULATOR_HOST is set; use --fixture.',
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
  return readProductionData(getFirestore());
}

export async function main(argv = process.argv) {
  const options = parseCliArgs(argv);
  const timestamp = new Date().toISOString();
  const catalog = await loadCatalog();
  const data = options.fixturePath
    ? await loadFixture(options.fixturePath)
    : await loadProduction();
  const report = buildDryRunReport({
    projectId: options.projectId,
    ...data,
    timestamp,
    gitCommit: readGitCommit(),
    catalog,
  });
  const artifactPath = await writeArtifact(
    report,
    options.outputPath || defaultArtifactPath(timestamp),
  );
  printSummary(report, artifactPath);
  return { report, artifactPath };
}

const invokedPath = process.argv[1] ? pathToFileURL(resolve(process.argv[1])).href : null;
if (invokedPath && import.meta.url === invokedPath) {
  main().catch((error) => {
    console.error(`M1 dry-run refused: ${error.message}`);
    process.exitCode = 1;
  });
}
