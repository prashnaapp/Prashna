/**
 * Canonical syllabus analytical identity helpers (server-side).
 *
 * Analytical identity:
 *   courseId + paperId + optional partId + syllabusUnitId
 *
 * Legacy IDs never define identity. Do not collapse topicId/majorStudyAreaId
 * into syllabusUnitId via `??` outside of validated scope resolution.
 */

export const SCOPE_KEY_SCHEMA_VERSION = 'v1';

export const CanonicalScopeShape = Object.freeze({
  groupIiPaperI: 'groupIiPaperI',
  groupIiPartUnit: 'groupIiPartUnit',
  groupIiiPaperUnit: 'groupIiiPaperUnit',
  groupIiiPartUnit: 'groupIiiPartUnit',
});

function trimString(value) {
  if (value == null) return '';
  return String(value).trim();
}

function optionalId(value) {
  const trimmed = trimString(value);
  return trimmed || null;
}

function requireId(value, field) {
  const trimmed = trimString(value);
  if (!trimmed) {
    const error = new Error(`${field} is required.`);
    error.code = 'invalid-argument';
    throw error;
  }
  return trimmed;
}

export function buildScopeKey({ courseId, paperId, partId, syllabusUnitId }) {
  const part = partId == null ? '' : String(partId);
  return `${SCOPE_KEY_SCHEMA_VERSION}|${courseId}|${paperId}|${part}|${syllabusUnitId}`;
}

export function validateCanonicalScope(scope) {
  const courseId = requireId(scope.courseId, 'courseId');
  const paperId = requireId(scope.paperId, 'paperId');
  const syllabusUnitId = requireId(scope.syllabusUnitId, 'syllabusUnitId');
  const shape = trimString(scope.shape);
  const partId = optionalId(scope.partId);
  const majorStudyAreaId = optionalId(scope.majorStudyAreaId);
  const contentTopicId = optionalId(scope.contentTopicId);
  const canonicalTopicId = optionalId(scope.canonicalTopicId);
  const lessonId = optionalId(scope.lessonId);

  switch (shape) {
    case CanonicalScopeShape.groupIiPaperI:
      if (partId != null) {
        throw Object.assign(
          new Error('groupIiPaperI requires partId to be null.'),
          { code: 'invalid-argument' },
        );
      }
      if (majorStudyAreaId == null) {
        throw Object.assign(
          new Error('groupIiPaperI requires majorStudyAreaId.'),
          { code: 'invalid-argument' },
        );
      }
      if (canonicalTopicId != null || lessonId != null) {
        throw Object.assign(
          new Error(
            'groupIiPaperI requires canonicalTopicId and lessonId to be null.',
          ),
          { code: 'invalid-argument' },
        );
      }
      if (syllabusUnitId !== majorStudyAreaId) {
        throw Object.assign(
          new Error(
            'groupIiPaperI syllabusUnitId must equal majorStudyAreaId.',
          ),
          { code: 'invalid-argument' },
        );
      }
      break;
    case CanonicalScopeShape.groupIiPartUnit:
      if (partId == null) {
        throw Object.assign(new Error('groupIiPartUnit requires partId.'), {
          code: 'invalid-argument',
        });
      }
      if (canonicalTopicId == null) {
        throw Object.assign(
          new Error('groupIiPartUnit requires canonicalTopicId.'),
          { code: 'invalid-argument' },
        );
      }
      if (majorStudyAreaId != null || contentTopicId != null) {
        throw Object.assign(
          new Error(
            'groupIiPartUnit requires majorStudyAreaId/contentTopicId null.',
          ),
          { code: 'invalid-argument' },
        );
      }
      if (syllabusUnitId !== canonicalTopicId) {
        throw Object.assign(
          new Error(
            'groupIiPartUnit syllabusUnitId must equal canonicalTopicId.',
          ),
          { code: 'invalid-argument' },
        );
      }
      break;
    case CanonicalScopeShape.groupIiiPaperUnit:
      if (partId != null) {
        throw Object.assign(
          new Error('groupIiiPaperUnit requires partId to be null.'),
          { code: 'invalid-argument' },
        );
      }
      if (
        majorStudyAreaId != null ||
        contentTopicId != null ||
        canonicalTopicId != null ||
        lessonId != null
      ) {
        throw Object.assign(
          new Error('groupIiiPaperUnit forbids topic/lesson/area fields.'),
          { code: 'invalid-argument' },
        );
      }
      break;
    case CanonicalScopeShape.groupIiiPartUnit:
      if (partId == null) {
        throw Object.assign(new Error('groupIiiPartUnit requires partId.'), {
          code: 'invalid-argument',
        });
      }
      if (
        majorStudyAreaId != null ||
        contentTopicId != null ||
        canonicalTopicId != null ||
        lessonId != null
      ) {
        throw Object.assign(
          new Error('groupIiiPartUnit forbids topic/lesson/area fields.'),
          { code: 'invalid-argument' },
        );
      }
      break;
    default:
      throw Object.assign(new Error(`Unknown CanonicalScope shape: ${shape}`), {
        code: 'invalid-argument',
      });
  }

  return {
    courseId,
    paperId,
    partId,
    syllabusUnitId,
    shape,
    majorStudyAreaId,
    contentTopicId,
    canonicalTopicId,
    lessonId,
    scopeKey: buildScopeKey({
      courseId,
      paperId,
      partId,
      syllabusUnitId,
    }),
  };
}

/**
 * Resolve canonical scope from known fields only.
 * Returns null when missing/ambiguous. Never invents from legacy-only IDs.
 */
export function tryResolveCanonicalScope(input = {}) {
  const courseId = optionalId(input.courseId);
  const paperId = optionalId(input.paperId);
  if (!courseId || !paperId) return null;

  const partId = optionalId(input.partId);
  const syllabusUnitId = optionalId(input.syllabusUnitId);
  const majorStudyAreaId = optionalId(input.majorStudyAreaId);
  const contentTopicId = optionalId(input.contentTopicId);
  const topicId = optionalId(input.topicId);
  const lessonId = optionalId(input.lessonId);
  const shapeHint = optionalId(input.shape) || optionalId(input.scopeShape);

  if (
    majorStudyAreaId &&
    (partId || lessonId || topicId)
  ) {
    return null;
  }
  if (contentTopicId && (partId || lessonId || topicId)) {
    return null;
  }

  try {
    if (courseId === 'group-iii') {
      if (!syllabusUnitId) return null;
      if (majorStudyAreaId || contentTopicId || topicId || lessonId) {
        return null;
      }
      const shape =
        shapeHint ||
        (partId
          ? CanonicalScopeShape.groupIiiPartUnit
          : CanonicalScopeShape.groupIiiPaperUnit);
      if (
        shape === CanonicalScopeShape.groupIiiPaperUnit &&
        partId != null
      ) {
        return null;
      }
      if (
        shape === CanonicalScopeShape.groupIiiPartUnit &&
        partId == null
      ) {
        return null;
      }
      return validateCanonicalScope({
        courseId,
        paperId,
        partId,
        syllabusUnitId,
        shape,
      });
    }

    if (courseId === 'group-ii') {
      const isPaperI =
        paperId === 'group-ii-paper-i' ||
        shapeHint === CanonicalScopeShape.groupIiPaperI;

      if (isPaperI) {
        if (!majorStudyAreaId) return null;
        if (partId || lessonId || topicId) return null;
        if (syllabusUnitId && syllabusUnitId !== majorStudyAreaId) {
          return null;
        }
        return validateCanonicalScope({
          courseId,
          paperId,
          syllabusUnitId: majorStudyAreaId,
          shape: CanonicalScopeShape.groupIiPaperI,
          majorStudyAreaId,
          contentTopicId,
        });
      }

      if (!partId) return null;
      if (majorStudyAreaId || contentTopicId) return null;
      const canonicalTopic = syllabusUnitId || topicId;
      if (!canonicalTopic) return null;
      if (syllabusUnitId && topicId && syllabusUnitId !== topicId) {
        return null;
      }
      return validateCanonicalScope({
        courseId,
        paperId,
        partId,
        syllabusUnitId: canonicalTopic,
        shape: CanonicalScopeShape.groupIiPartUnit,
        canonicalTopicId: canonicalTopic,
        lessonId,
      });
    }
  } catch (_) {
    return null;
  }

  return null;
}

/**
 * Snapshot attribution payload: separate fields only.
 * Never collapses topicId/majorStudyAreaId into syllabusUnitId via `??`.
 */
export function buildSnapshotAttribution(data, fallbackCourseId) {
  const courseId = optionalId(data?.courseId) || optionalId(fallbackCourseId);
  const paperId = optionalId(data?.paperId);
  const partId = optionalId(data?.partId);
  const syllabusUnitId = optionalId(data?.syllabusUnitId);
  const majorStudyAreaId = optionalId(data?.majorStudyAreaId);
  const contentTopicId = optionalId(data?.contentTopicId);
  const topicId = optionalId(data?.topicId);
  const lessonId = optionalId(data?.lessonId);

  const scope = tryResolveCanonicalScope({
    courseId,
    paperId,
    partId,
    syllabusUnitId,
    majorStudyAreaId,
    contentTopicId,
    topicId,
    lessonId,
    shape: data?.scopeShape || data?.shape,
  });

  if (scope) {
    return {
      courseId: scope.courseId,
      paperId: scope.paperId,
      partId: scope.partId,
      syllabusUnitId: scope.syllabusUnitId,
      majorStudyAreaId: scope.majorStudyAreaId,
      contentTopicId: scope.contentTopicId,
      canonicalTopicId: scope.canonicalTopicId,
      lessonId: scope.lessonId,
      scopeShape: scope.shape,
      scopeKey: scope.scopeKey,
    };
  }

  // Unmapped / incomplete: preserve only known explicit fields.
  return {
    courseId: courseId || null,
    paperId,
    partId,
    syllabusUnitId,
    majorStudyAreaId,
    contentTopicId,
    canonicalTopicId: null,
    lessonId,
    // Keep raw topicId only as non-identity metadata when scope unresolved.
    topicId,
    scopeShape: null,
    scopeKey: null,
  };
}
