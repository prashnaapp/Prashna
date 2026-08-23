/**
 * Trusted server-side validation for question/test catalog writes.
 * Enforces production invariants only — not a copy of every Flutter UI rule.
 */
import { FieldValue } from 'firebase-admin/firestore';

import { CANONICAL_SYLLABUS_UNITS } from './canonical_syllabus_catalog.js';

export const SUPPORTED_COURSES = Object.freeze(['group-ii', 'group-iii']);
export const QUESTION_STATUSES = Object.freeze(['draft', 'published', 'archived']);
export const TEST_STATUSES = Object.freeze(['draft', 'published', 'archived']);
export const TEST_CATEGORIES = Object.freeze([
  'chapter',
  'part',
  'paper',
  'mock',
  'previousyear',
]);
export const OPTION_LABELS = Object.freeze(['A', 'B', 'C', 'D', 'E']);
export const MAX_QUESTION_BATCH = 500;
export const FIELD_DELETE_SENTINEL = '_fieldDelete';

const papersByCourse = new Map();
const partsByPaper = new Map();
const unitsByPart = new Map();
const paperHasParts = new Map();

for (const unit of CANONICAL_SYLLABUS_UNITS) {
  if (!papersByCourse.has(unit.courseId)) papersByCourse.set(unit.courseId, new Set());
  papersByCourse.get(unit.courseId).add(unit.paperId);

  const paperKey = `${unit.courseId}|${unit.paperId}`;
  if (!paperHasParts.has(paperKey)) paperHasParts.set(paperKey, false);
  if (unit.partId) paperHasParts.set(paperKey, true);

  if (!partsByPaper.has(paperKey)) partsByPaper.set(paperKey, new Set());
  if (unit.partId) partsByPaper.get(paperKey).add(unit.partId);

  const partKey = `${paperKey}|${unit.partId || ''}`;
  if (!unitsByPart.has(partKey)) unitsByPart.set(partKey, new Set());
  unitsByPart.get(partKey).add(unit.syllabusUnitId);
}

export function fail(code, message) {
  const error = new Error(message);
  error.code = code;
  throw error;
}

export function isDeleteSentinel(value) {
  return Boolean(
    value
    && typeof value === 'object'
    && !Array.isArray(value)
    && value[FIELD_DELETE_SENTINEL] === true,
  );
}

export function trimToNull(value) {
  if (isDeleteSentinel(value) || value == null) return null;
  const trimmed = String(value).trim();
  return trimmed === '' ? null : trimmed;
}

export function decodeWriteData(raw = {}) {
  const out = {};
  for (const [key, value] of Object.entries(raw)) {
    if (isDeleteSentinel(value)) {
      out[key] = FieldValue.delete();
    } else {
      out[key] = value;
    }
  }
  return out;
}

function asNumber(value) {
  if (typeof value === 'number') return value;
  if (typeof value === 'string' && value.trim() !== '') return Number(value);
  return Number.NaN;
}

function readStringList(value) {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item ?? ''));
}

function localizedOptions(block) {
  if (!block || typeof block !== 'object' || !Array.isArray(block.options)) {
    return [];
  }
  return block.options.map((option) => {
    if (typeof option === 'string') return option;
    if (option && typeof option === 'object') return String(option.text ?? '');
    return '';
  });
}

function resolveQuestionText(data) {
  const top = trimToNull(data.question);
  if (top) return top;
  return trimToNull(data.content?.en?.question);
}

function resolveOptions(data) {
  const top = readStringList(data.options).map((item) => item.trim()).filter(Boolean);
  if (top.length > 0) return top;
  return localizedOptions(data.content?.en).map((item) => item.trim()).filter(Boolean);
}

function paperKey(courseId, paperId) {
  return `${courseId}|${paperId}`;
}

function assertKnownCourse(courseId) {
  if (!SUPPORTED_COURSES.includes(courseId)) {
    fail('invalid-argument', `Unsupported course "${courseId}".`);
  }
}

function assertKnownPaper(courseId, paperId) {
  const papers = papersByCourse.get(courseId);
  if (!papers || !papers.has(paperId)) {
    fail(
      'invalid-argument',
      `Paper "${paperId}" does not belong to course "${courseId}".`,
    );
  }
}

function paperUsesParts(courseId, paperId) {
  return paperHasParts.get(paperKey(courseId, paperId)) === true;
}

function assertKnownPart(courseId, paperId, partId) {
  const parts = partsByPaper.get(paperKey(courseId, paperId));
  if (!parts || !parts.has(partId)) {
    fail('invalid-argument', `Part "${partId}" does not belong to paper "${paperId}".`);
  }
}

function assertKnownUnit(courseId, paperId, partId, unitId) {
  const key = `${courseId}|${paperId}|${partId || ''}`;
  const units = unitsByPart.get(key);
  if (!units || !units.has(unitId)) {
    fail(
      'invalid-argument',
      `Syllabus Unit "${unitId}" does not belong to the selected ${partId ? 'Part' : 'Paper'}.`,
    );
  }
}

function collectErrors(run) {
  const errors = [];
  try {
    run((message) => errors.push(message));
  } catch (error) {
    errors.push(error.message);
  }
  return errors;
}

function syllabusField(data, key) {
  const nested = data.syllabus && typeof data.syllabus === 'object'
    ? data.syllabus[key]
    : undefined;
  const fromNested = trimToNull(nested);
  if (fromNested) return fromNested;
  return trimToNull(data[key]);
}

function hasCanonicalLocation(data) {
  return Boolean(
    syllabusField(data, 'majorStudyAreaId')
    || syllabusField(data, 'contentTopicId')
    || syllabusField(data, 'partId')
    || syllabusField(data, 'lessonId')
    || syllabusField(data, 'syllabusUnitId'),
  );
}

function validateGroupIiQuestionSyllabus(data, addError) {
  const paperId = syllabusField(data, 'paperId');
  if (!paperId) {
    addError('Paper is required for canonical Group-II questions.');
    return;
  }
  try {
    assertKnownPaper('group-ii', paperId);
  } catch (error) {
    addError(error.message);
    return;
  }

  if (paperId === 'group-ii-paper-i') {
    const areaId = syllabusField(data, 'majorStudyAreaId');
    const contentTopicId = syllabusField(data, 'contentTopicId');
    if (!areaId || !contentTopicId) {
      addError('Paper I requires Major Study Area and Content Topic only.');
    }
    if (
      syllabusField(data, 'partId')
      || syllabusField(data, 'lessonId')
      || syllabusField(data, 'syllabusUnitId')
    ) {
      addError('Paper I requires Major Study Area and Content Topic only.');
    }
    if (areaId) {
      try {
        assertKnownUnit('group-ii', paperId, null, areaId);
      } catch (error) {
        addError(error.message);
      }
    }
    if (areaId && contentTopicId && !contentTopicId.startsWith(`${areaId}-topic-`)) {
      addError(`Unknown Content Topic "${contentTopicId}".`);
    }
    return;
  }

  const partId = syllabusField(data, 'partId');
  const topicId = syllabusField(data, 'topicId');
  const lessonId = syllabusField(data, 'lessonId');
  if (!partId || !topicId) {
    addError('Papers II–IV require Part and Topic attribution.');
  }
  if (
    syllabusField(data, 'majorStudyAreaId')
    || syllabusField(data, 'contentTopicId')
    || syllabusField(data, 'syllabusUnitId')
  ) {
    addError('Group-II questions must not use syllabusUnitId.');
  }
  if (partId) {
    try {
      assertKnownPart('group-ii', paperId, partId);
    } catch (error) {
      addError(error.message);
    }
  }
  if (partId && topicId) {
    try {
      assertKnownUnit('group-ii', paperId, partId, topicId);
    } catch (error) {
      addError(error.message);
    }
  }
  if (lessonId && topicId && !lessonId.startsWith(`${topicId}-lesson-`)) {
    addError(`Unknown Lesson "${lessonId}".`);
  }
}

function validateGroupIiiQuestionSyllabus(data, addError) {
  const paperId = syllabusField(data, 'paperId');
  if (!paperId) {
    addError('Paper is required.');
    return;
  }
  try {
    assertKnownPaper('group-iii', paperId);
  } catch (error) {
    addError(error.message);
    return;
  }
  if (
    syllabusField(data, 'majorStudyAreaId')
    || syllabusField(data, 'contentTopicId')
    || syllabusField(data, 'topicId')
    || syllabusField(data, 'lessonId')
  ) {
    addError(
      'Group-III questions use Paper / Part / Syllabus Unit only (no Topic or Lesson).',
    );
  }

  const unitId = syllabusField(data, 'syllabusUnitId');
  if (!unitId) {
    addError('Syllabus Unit is required for Group-III.');
    return;
  }
  const usesParts = paperUsesParts('group-iii', paperId);
  const partId = syllabusField(data, 'partId');
  if (!usesParts) {
    if (partId) addError('Group-III Paper-I must not include partId.');
    try {
      assertKnownUnit('group-iii', paperId, null, unitId);
    } catch (error) {
      addError(error.message);
    }
    return;
  }
  if (!partId) {
    addError('Part is required for this Group-III paper.');
    return;
  }
  try {
    assertKnownPart('group-iii', paperId, partId);
    assertKnownUnit('group-iii', paperId, partId, unitId);
  } catch (error) {
    addError(error.message);
  }
}

function validateQuestionSyllabus(data, { requireCanonical }) {
  const courseId = trimToNull(data.courseId);
  const paperId = syllabusField(data, 'paperId');
  if (paperId && courseId) {
    const papers = papersByCourse.get(courseId);
    if (papers && !papers.has(paperId)) {
      fail(
        'invalid-argument',
        `Paper "${paperId}" is incompatible with course "${courseId}".`,
      );
    }
  }

  const needsCanonical = requireCanonical || hasCanonicalLocation(data);
  if (!needsCanonical) return;

  const errors = collectErrors((addError) => {
    if (courseId === 'group-iii') validateGroupIiiQuestionSyllabus(data, addError);
    else if (courseId === 'group-ii') validateGroupIiQuestionSyllabus(data, addError);
  });
  if (errors.length > 0) {
    fail('invalid-argument', errors.join(' '));
  }
}

function validatePublishedBilingualContent(data) {
  const content = data.content;
  if (!content || typeof content !== 'object') {
    fail('invalid-argument', 'Bilingual content is required.');
  }
  const en = content.en;
  const te = content.te;
  if (!en || typeof en !== 'object' || !trimToNull(en.question)) {
    fail('invalid-argument', 'English question is required.');
  }
  if (!te || typeof te !== 'object' || !trimToNull(te.question)) {
    fail('invalid-argument', 'Telugu question is required.');
  }
  const enOptions = localizedOptions(en);
  const teOptions = localizedOptions(te);
  if (enOptions.length !== teOptions.length) {
    fail('invalid-argument', 'English and Telugu option counts must match.');
  }
  if (enOptions.length < 2 || enOptions.some((option) => !option.trim())) {
    fail('invalid-argument', 'English options cannot be empty.');
  }
  if (teOptions.some((option) => !option.trim())) {
    fail('invalid-argument', 'Telugu options cannot be empty.');
  }
  if (!trimToNull(en.explanation) || !trimToNull(te.explanation)) {
    fail('invalid-argument', 'English and Telugu explanations are required.');
  }
}

export function validateQuestionPayload(data = {}, { documentId } = {}) {
  const id = trimToNull(data.id) || trimToNull(documentId);
  const expectedId = trimToNull(documentId);
  if (!id) fail('invalid-argument', 'Question ID is required.');
  if (expectedId && id !== expectedId) {
    fail('invalid-argument', 'Question ID must match the Firestore document ID.');
  }

  const courseId = trimToNull(data.courseId);
  if (!courseId) fail('invalid-argument', 'Course is required.');
  assertKnownCourse(courseId);

  const questionText = resolveQuestionText(data);
  if (!questionText) fail('invalid-argument', 'Question text is required.');

  const options = resolveOptions(data);
  if (options.length < 2 || options.length > 5) {
    fail('invalid-argument', 'Provide between 2 and 5 answer options.');
  }
  if (options.some((option) => !option)) {
    fail('invalid-argument', 'Answer options cannot be empty.');
  }

  const correctOption = String(data.correctOption || '').trim().toUpperCase();
  const correctIndex = OPTION_LABELS.indexOf(correctOption);
  if (correctIndex < 0 || correctIndex >= options.length) {
    fail('invalid-argument', 'Correct option must match one of the provided options.');
  }

  const marks = asNumber(data.marks);
  if (!Number.isFinite(marks) || marks <= 0) {
    fail('invalid-argument', 'Marks must be greater than zero.');
  }
  const negativeMarks = asNumber(data.negativeMarks ?? 0);
  if (!Number.isFinite(negativeMarks) || negativeMarks < 0) {
    fail('invalid-argument', 'Negative marks must be zero or greater.');
  }
  const estimated = asNumber(data.estimatedTimeSeconds);
  if (!Number.isFinite(estimated) || estimated <= 0) {
    fail('invalid-argument', 'Estimated time must be greater than zero.');
  }

  const status = trimToNull(data.status);
  if (status && !QUESTION_STATUSES.includes(status)) {
    fail('invalid-argument', `Invalid question status "${status}".`);
  }
  if (typeof data.isActive !== 'boolean') {
    fail('invalid-argument', 'isActive must be a boolean.');
  }
  if (status === 'published' && data.isActive !== true) {
    fail('invalid-argument', 'Published questions must be active.');
  }
  if (status && status !== 'published' && data.isActive === true) {
    fail('invalid-argument', 'Active state must match publication status.');
  }

  const content = data.content && typeof data.content === 'object' ? data.content : null;
  if (content?.te && localizedOptions(content.en).length !== localizedOptions(content.te).length) {
    fail('invalid-argument', 'English and Telugu option counts must match.');
  }

  const isPublishedCanonical = status === 'published' && content != null;
  if (isPublishedCanonical) {
    validatePublishedBilingualContent(data);
  }
  validateQuestionSyllabus(data, { requireCanonical: isPublishedCanonical });

  return {
    id,
    courseId,
    status,
    isActive: data.isActive,
  };
}

export function validateTestPayload(data = {}, { documentId, requireExistingId = false } = {}) {
  const id = trimToNull(data.id) || trimToNull(documentId);
  const expectedId = trimToNull(documentId);
  if (!id) fail('invalid-argument', 'Test ID is required.');
  if (requireExistingId && !trimToNull(documentId)) {
    fail('invalid-argument', 'Test ID is required.');
  }
  if (expectedId && id !== expectedId) {
    fail('invalid-argument', 'Test ID must match the Firestore document ID.');
  }

  const courseId = trimToNull(data.courseId);
  if (!courseId) fail('invalid-argument', 'Course is required.');
  assertKnownCourse(courseId);
  if (!trimToNull(data.title)) fail('invalid-argument', 'Title is required.');

  const category = trimToNull(data.category);
  if (!category || !TEST_CATEGORIES.includes(category)) {
    fail('invalid-argument', 'Category is not supported.');
  }

  const questionCount = asNumber(data.questionCount);
  if (!Number.isFinite(questionCount) || questionCount <= 0) {
    fail('invalid-argument', 'Question count must be greater than zero.');
  }
  const totalMarks = asNumber(data.totalMarks ?? data.marks ?? 0);
  if (!Number.isFinite(totalMarks) || totalMarks < 0) {
    fail('invalid-argument', 'Total marks must be zero or greater.');
  }
  const durationMinutes = asNumber(data.durationMinutes);
  if (!Number.isFinite(durationMinutes) || durationMinutes <= 0) {
    fail('invalid-argument', 'Duration must be greater than zero.');
  }
  const negativeMarks = asNumber(data.negativeMarks ?? 0);
  if (!Number.isFinite(negativeMarks) || negativeMarks < 0) {
    fail('invalid-argument', 'Negative marking must be a valid non-negative number.');
  }
  if (!trimToNull(data.difficulty)) {
    fail('invalid-argument', 'Difficulty is required.');
  }

  const status = trimToNull(data.status) || 'draft';
  if (!TEST_STATUSES.includes(status)) {
    fail('invalid-argument', `Invalid test status "${status}".`);
  }
  const isPublished = data.isPublished === true;
  if (isPublished !== (status === 'published')) {
    fail('invalid-argument', 'status and isPublished must stay consistent.');
  }

  const questionIds = [
    ...new Set(
      readStringList(data.questionIds)
        .map((item) => item.trim())
        .filter(Boolean),
    ),
  ];
  if (readStringList(data.questionIds).filter((item) => item.trim()).length !== questionIds.length) {
    fail('invalid-argument', 'Fixed question IDs must be unique.');
  }
  if (questionIds.length > 0 && questionIds.length !== questionCount) {
    fail('invalid-argument', 'Question count must match assigned question IDs.');
  }

  validateTestSyllabusLocation(data, courseId);

  return {
    id,
    courseId,
    status,
    isPublished,
    questionIds,
    questionCount,
  };
}

export function validateTestSyllabusLocation(data, courseId) {
  const paperId = trimToNull(data.paperId);
  const partId = trimToNull(data.partId);
  const unitId = trimToNull(data.syllabusUnitId);
  const hasLocation = Boolean(paperId || partId || unitId);
  if (!hasLocation) return;

  if (!paperId) {
    fail('invalid-argument', 'Paper is required when a syllabus location is specified.');
  }
  assertKnownPaper(courseId, paperId);
  const usesParts = paperUsesParts(courseId, paperId);
  if (usesParts && !partId) {
    fail('invalid-argument', `Part is required for paper "${paperId}".`);
  }
  if (!usesParts && partId) {
    fail('invalid-argument', `Paper "${paperId}" does not have Parts.`);
  }
  if (partId) assertKnownPart(courseId, paperId, partId);
  if (!unitId) {
    fail('invalid-argument', 'Syllabus Unit is required when a location is specified.');
  }
  assertKnownUnit(courseId, paperId, partId, unitId);
}

export function assertQuestionCompatibleWithTest(questionData, testData, questionId) {
  if (!questionData) {
    fail('failed-precondition', `Question "${questionId}" does not exist.`);
  }
  if (questionData.isActive !== true) {
    fail('failed-precondition', `Question "${questionId}" is inactive.`);
  }
  const questionCourse = trimToNull(questionData.courseId);
  const testCourse = trimToNull(testData.courseId);
  if (questionCourse !== testCourse) {
    fail('failed-precondition', `Question "${questionId}" belongs to another course.`);
  }
  const testPaper = trimToNull(testData.paperId);
  const questionPaper = trimToNull(questionData.paperId);
  if (testPaper && questionPaper !== testPaper) {
    fail('failed-precondition', `Question "${questionId}" does not match the test paper.`);
  }
  const testPart = trimToNull(testData.partId);
  const questionPart = trimToNull(questionData.partId);
  if (testPart && questionPart !== testPart) {
    fail('failed-precondition', `Question "${questionId}" does not match the test part.`);
  }
  const testUnit = trimToNull(testData.syllabusUnitId);
  if (testUnit) {
    const questionUnit = trimToNull(questionData.syllabusUnitId);
    const topicId = trimToNull(questionData.topicId);
    const areaId = trimToNull(questionData.majorStudyAreaId);
    if (questionUnit !== testUnit && topicId !== testUnit && areaId !== testUnit) {
      fail(
        'failed-precondition',
        `Question "${questionId}" does not match the test syllabus unit.`,
      );
    }
  }
}

export function prepareQuestionWrite(data, { documentId, forUpdate = false } = {}) {
  validateQuestionPayload(data, { documentId });
  const decoded = decodeWriteData(data);
  decoded.id = trimToNull(documentId) || trimToNull(data.id);
  decoded.updatedAt = FieldValue.serverTimestamp();
  if (!forUpdate) {
    decoded.createdAt = FieldValue.serverTimestamp();
  } else {
    delete decoded.createdAt;
  }
  return decoded;
}

export function prepareTestWrite(data, { documentId, forUpdate = false } = {}) {
  validateTestPayload(data, { documentId, requireExistingId: forUpdate });
  const decoded = decodeWriteData(data);
  decoded.id = trimToNull(documentId) || trimToNull(data.id);
  return decoded;
}
