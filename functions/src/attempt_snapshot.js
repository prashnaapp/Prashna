/**
 * Immutable attempt snapshot helpers.
 *
 * Grading answer keys live in a server-only collection.
 * Student-facing attempt docs never include correctOption before submit.
 */

import {
  buildSnapshotAttribution,
  tryResolveCanonicalScope,
} from './canonical_scope.js';

export const SNAPSHOT_SCHEMA_VERSION = 1;
export const GRADING_SNAPSHOT_COLLECTION = 'test_attempt_grading_snapshots';

const OPTION_LABELS = ['A', 'B', 'C', 'D', 'E'];

function trimString(value) {
  if (value == null) return '';
  return String(value).trim();
}

function optionalString(value) {
  const trimmed = trimString(value);
  return trimmed || null;
}

function asNumber(value, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

/**
 * Normalize Firestore question options into { label, text }[].
 */
export function normalizeSnapshotOptions(data) {
  const raw = data?.options;
  const contentEn = data?.content?.en?.options;
  const out = [];

  if (Array.isArray(raw) && raw.length > 0) {
    for (let i = 0; i < raw.length; i += 1) {
      const option = raw[i];
      if (typeof option === 'string') {
        const text = trimString(option);
        if (!text) continue;
        out.push({
          label: OPTION_LABELS[i] || String(i + 1),
          text,
        });
        continue;
      }
      if (option && typeof option === 'object') {
        const label =
          trimString(option.label).toUpperCase() ||
          OPTION_LABELS[i] ||
          String(i + 1);
        const text = trimString(option.text ?? option.value);
        if (!text) continue;
        out.push({ label, text });
      }
    }
  }

  if (out.length === 0 && Array.isArray(contentEn)) {
    for (let i = 0; i < contentEn.length; i += 1) {
      const option = contentEn[i];
      const text =
        typeof option === 'string'
          ? trimString(option)
          : trimString(option?.text);
      if (!text) continue;
      out.push({
        label: OPTION_LABELS[i] || String(i + 1),
        text,
      });
    }
  }

  return out;
}

export function extractQuestionText(data) {
  const direct = trimString(data?.question);
  if (direct) return direct;
  return trimString(data?.content?.en?.question);
}

export function extractExplanation(data) {
  const direct = trimString(data?.explanation);
  if (direct) return direct;
  return trimString(data?.content?.en?.explanation);
}

function extractStatements(block) {
  if (!block || !Array.isArray(block.statements)) return [];
  const statements = [];
  for (const item of block.statements) {
    const text = trimString(item);
    if (text) statements.push(text);
  }
  return statements;
}

/**
 * One language block: { question, options:[{text}], explanation, statements? }.
 * Accepts Firestore string options or { text } objects.
 */
function extractLocalizedContentBlock(block) {
  if (!block || typeof block !== 'object') return null;
  const question = trimString(block.question);
  const explanation = trimString(block.explanation);
  const options = [];
  if (Array.isArray(block.options)) {
    for (const option of block.options) {
      const text =
        typeof option === 'string'
          ? trimString(option)
          : trimString(option?.text);
      if (!text) continue;
      options.push({ text });
    }
  }
  const statements = extractStatements(block);
  if (!question && options.length === 0 && !explanation && statements.length === 0) {
    return null;
  }
  const out = { question, options, explanation };
  if (statements.length > 0) out.statements = statements;
  return out;
}

/**
 * Preserve bilingual student content from the live question document.
 * English falls back to top-level question/options/explanation when needed.
 */
export function buildSnapshotContent(data, {
  englishText,
  englishOptions,
  englishExplanation,
} = {}) {
  const enFromContent = extractLocalizedContentBlock(data?.content?.en);
  const teFromContent = extractLocalizedContentBlock(data?.content?.te);

  const enOptions =
    enFromContent?.options?.length > 0
      ? enFromContent.options
      : (englishOptions || [])
          .map((option) => ({ text: trimString(option?.text) }))
          .filter((option) => option.text);

  const en = {
    question: enFromContent?.question || trimString(englishText),
    options: enOptions,
    explanation:
      enFromContent?.explanation || trimString(englishExplanation) || '',
  };
  if (enFromContent?.statements?.length) {
    en.statements = enFromContent.statements;
  }
  if (!en.question) return null;

  const content = { en };
  if (teFromContent?.question) {
    content.te = teFromContent;
  }
  return content;
}

function attachTeluguOptionText(options, teBlock) {
  const teOptions = teBlock?.options;
  if (!Array.isArray(teOptions) || teOptions.length === 0) return options;
  return options.map((option, index) => {
    const teluguText = trimString(teOptions[index]?.text);
    if (!teluguText) return option;
    return { ...option, teluguText };
  });
}

/** Student-safe content: keep en/te question+options+statements; never expose explanations. */
function toStudentSafeContent(content) {
  if (!content?.en?.question) return null;
  const en = {
    question: content.en.question,
    options: (content.en.options || []).map((option) => ({
      text: option.text,
    })),
  };
  if (Array.isArray(content.en.statements) && content.en.statements.length > 0) {
    en.statements = content.en.statements;
  }
  const out = { en };
  if (content.te?.question) {
    const te = {
      question: content.te.question,
      options: (content.te.options || []).map((option) => ({
        text: option.text,
      })),
    };
    if (Array.isArray(content.te.statements) && content.te.statements.length > 0) {
      te.statements = content.te.statements;
    }
    out.te = te;
  }
  return out;
}

function compactAttribution(attribution) {
  const out = {};
  for (const [key, value] of Object.entries(attribution || {})) {
    if (value != null && value !== '') out[key] = value;
  }
  return out;
}

export function buildTestSnapshot(testData, {
  questionCount,
  totalMarks,
  durationSeconds,
  negativeMarks,
  scoringVersion,
}) {
  const instructions = Array.isArray(testData.instructions)
    ? testData.instructions
        .map((item) => trimString(item))
        .filter(Boolean)
    : [];

  const attribution = buildSnapshotAttribution(
    {
      courseId: testData.courseId,
      paperId: testData.paperId,
      partId: testData.partId,
      syllabusUnitId: testData.syllabusUnitId,
      majorStudyAreaId:
        testData.majorStudyAreaId ||
        (testData.paperId === 'group-ii-paper-i'
          ? testData.syllabusUnitId
          : null),
      contentTopicId: testData.contentTopicId,
      topicId:
        testData.canonicalTopicId ||
        (testData.courseId === 'group-ii' &&
        testData.paperId !== 'group-ii-paper-i'
          ? testData.syllabusUnitId
          : null),
      lessonId: testData.lessonId,
      scopeShape: testData.scopeShape || testData.shape,
    },
    testData.courseId,
  );

  return {
    testId: trimString(testData.id || testData.testId),
    title: trimString(testData.title) || trimString(testData.id),
    description: trimString(testData.description),
    category: trimString(testData.category),
    questionCount,
    totalMarks,
    durationSeconds,
    negativeMarks,
    instructions,
    scoringVersion,
    ...compactAttribution(attribution),
  };
}

/**
 * Build one authoritative question snapshot from a live question document.
 */
export function buildQuestionSnapshot(questionId, data, position, courseId) {
  const options = normalizeSnapshotOptions(data);
  const text = extractQuestionText(data);
  const correctOption = trimString(data?.correctOption).toUpperCase();
  const explanation = extractExplanation(data);

  if (!text) {
    const error = new Error(`Question missing text: ${questionId}`);
    error.code = 'failed-precondition';
    throw error;
  }
  if (options.length < 2) {
    const error = new Error(`Question missing options: ${questionId}`);
    error.code = 'failed-precondition';
    throw error;
  }
  if (!correctOption) {
    const error = new Error(`Question missing correctOption: ${questionId}`);
    error.code = 'failed-precondition';
    throw error;
  }

  const validLabels = new Set(options.map((option) => option.label));
  if (!validLabels.has(correctOption)) {
    // Still allow common A-D keys when options were stored as bare strings.
    if (!OPTION_LABELS.includes(correctOption)) {
      const error = new Error(
        `Question correctOption not in options: ${questionId}`,
      );
      error.code = 'failed-precondition';
      throw error;
    }
  }

  const attribution = buildSnapshotAttribution(data, courseId);
  const content = buildSnapshotContent(data, {
    englishText: text,
    englishOptions: options,
    englishExplanation: explanation,
  });
  const optionsWithTelugu = attachTeluguOptionText(options, content?.te);

  return {
    questionId: String(questionId),
    position,
    text,
    options: optionsWithTelugu,
    correctOption,
    explanation,
    ...(content ? { content } : {}),
    marks: asNumber(data?.marks, 1),
    ...compactAttribution({
      questionType: optionalString(data?.questionType),
      itemFormat: optionalString(data?.itemFormat),
      difficulty: optionalString(data?.difficulty),
    }),
    ...compactAttribution(attribution),
  };
}

/** Strip answer-key fields for in-progress student reads / start response. */
export function toStudentSafeQuestion(snapshot) {
  // Omit null/undefined/empty optional fields so Firestore never sees undefined
  // (Paper-I has no partId / canonicalTopicId / lessonId).
  const safeContent = toStudentSafeContent(snapshot.content);
  return {
    questionId: snapshot.questionId,
    position: snapshot.position,
    text: snapshot.text,
    options: (snapshot.options || []).map((option) =>
      compactAttribution({
        label: option.label,
        text: option.text,
        teluguText: option.teluguText,
      }),
    ),
    ...(safeContent ? { content: safeContent } : {}),
    ...compactAttribution({
      questionType: snapshot.questionType,
      itemFormat: snapshot.itemFormat,
      marks: snapshot.marks,
      difficulty: snapshot.difficulty,
      courseId: snapshot.courseId,
      paperId: snapshot.paperId,
      partId: snapshot.partId,
      syllabusUnitId: snapshot.syllabusUnitId,
      majorStudyAreaId: snapshot.majorStudyAreaId,
      contentTopicId: snapshot.contentTopicId,
      canonicalTopicId: snapshot.canonicalTopicId,
      lessonId: snapshot.lessonId,
      scopeShape: snapshot.scopeShape,
      scopeKey: snapshot.scopeKey,
    }),
  };
}

export function gradingMapsFromSnapshots(questionSnapshots) {
  const correctByQuestionId = {};
  const optionLabelsByQuestionId = {};
  for (const snapshot of questionSnapshots) {
    correctByQuestionId[snapshot.questionId] = snapshot.correctOption;
    optionLabelsByQuestionId[snapshot.questionId] = new Set(
      (snapshot.options || []).map((option) =>
        String(option.label || '').trim().toUpperCase(),
      ),
    );
  }
  return { correctByQuestionId, optionLabelsByQuestionId };
}

export function isSnapshotEnabledAttempt(attempt) {
  const version = Number(attempt?.snapshotSchemaVersion);
  return Number.isFinite(version) && version >= 1;
}

export { tryResolveCanonicalScope };
