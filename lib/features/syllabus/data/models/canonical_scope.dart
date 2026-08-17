/// Shared canonical syllabus analytical identity.
///
/// Analytical identity is:
/// `courseId + paperId + optional partId + syllabusUnitId`
///
/// Legacy IDs never define canonical identity and must not be inferred into
/// this object from ambiguous values such as `topic-1` / `section-1`.
enum CanonicalScopeShape {
  groupIiPaperI,
  groupIiPartUnit,
  groupIiiPaperUnit,
  groupIiiPartUnit,
}

class CanonicalScopeValidationException implements Exception {
  CanonicalScopeValidationException(this.message);

  final String message;

  @override
  String toString() => 'CanonicalScopeValidationException: $message';
}

class CanonicalScope {
  const CanonicalScope({
    required this.courseId,
    required this.paperId,
    required this.syllabusUnitId,
    required this.shape,
    this.partId,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.canonicalTopicId,
    this.lessonId,
    this.legacyPaperId,
    this.legacySectionId,
    this.legacyTopicId,
    this.legacyLessonId,
  });

  static const scopeKeySchemaVersion = 'v1';

  final String courseId;
  final String paperId;
  final String? partId;
  final String syllabusUnitId;
  final CanonicalScopeShape shape;

  final String? majorStudyAreaId;
  final String? contentTopicId;
  final String? canonicalTopicId;
  final String? lessonId;

  /// Compatibility-only. Never used for [scopeKey] or analytical identity.
  final String? legacyPaperId;
  final String? legacySectionId;
  final String? legacyTopicId;
  final String? legacyLessonId;

  /// Deterministic derived key. Never user-entered.
  ///
  /// Format: `v1|courseId|paperId|partId|syllabusUnitId`
  /// Null [partId] yields an empty part segment: `v1|course|paper||unit`
  String get scopeKey {
    final part = partId ?? '';
    return '$scopeKeySchemaVersion|$courseId|$paperId|$part|$syllabusUnitId';
  }

  /// Validates and returns a normalized scope, or throws.
  factory CanonicalScope.validated({
    required String courseId,
    required String paperId,
    required String syllabusUnitId,
    required CanonicalScopeShape shape,
    String? partId,
    String? majorStudyAreaId,
    String? contentTopicId,
    String? canonicalTopicId,
    String? lessonId,
    String? legacyPaperId,
    String? legacySectionId,
    String? legacyTopicId,
    String? legacyLessonId,
  }) {
    final normalized = CanonicalScope(
      courseId: _requireId(courseId, 'courseId'),
      paperId: _requireId(paperId, 'paperId'),
      partId: _optionalId(partId),
      syllabusUnitId: _requireId(syllabusUnitId, 'syllabusUnitId'),
      shape: shape,
      majorStudyAreaId: _optionalId(majorStudyAreaId),
      contentTopicId: _optionalId(contentTopicId),
      canonicalTopicId: _optionalId(canonicalTopicId),
      lessonId: _optionalId(lessonId),
      legacyPaperId: _optionalId(legacyPaperId),
      legacySectionId: _optionalId(legacySectionId),
      legacyTopicId: _optionalId(legacyTopicId),
      legacyLessonId: _optionalId(legacyLessonId),
    );
    normalized.validate();
    return normalized;
  }

  /// Returns null when attribution is missing or ambiguous.
  ///
  /// Never invents identity from legacy-only fields.
  static CanonicalScope? tryResolve({
    required String? courseId,
    required String? paperId,
    String? partId,
    String? syllabusUnitId,
    String? majorStudyAreaId,
    String? contentTopicId,
    String? topicId,
    String? lessonId,
    String? legacyPaperId,
    String? legacySectionId,
    String? legacyTopicId,
    String? legacyLessonId,
    CanonicalScopeShape? shapeHint,
  }) {
    final course = _optionalId(courseId);
    final paper = _optionalId(paperId);
    if (course == null || paper == null) return null;

    final part = _optionalId(partId);
    final unit = _optionalId(syllabusUnitId);
    final area = _optionalId(majorStudyAreaId);
    final content = _optionalId(contentTopicId);
    final topic = _optionalId(topicId);
    final lesson = _optionalId(lessonId);

    // Ambiguous: Paper-I area fields mixed with part/lesson tree.
    if (area != null && (part != null || lesson != null || topic != null)) {
      return null;
    }
    if (content != null && (part != null || lesson != null || topic != null)) {
      return null;
    }

    try {
      if (course == 'group-iii') {
        return _resolveGroupIii(
          courseId: course,
          paperId: paper,
          partId: part,
          syllabusUnitId: unit,
          majorStudyAreaId: area,
          contentTopicId: content,
          topicId: topic,
          lessonId: lesson,
          legacyPaperId: legacyPaperId,
          legacySectionId: legacySectionId,
          legacyTopicId: legacyTopicId,
          legacyLessonId: legacyLessonId,
          shapeHint: shapeHint,
        );
      }

      if (course == 'group-ii') {
        return _resolveGroupIi(
          courseId: course,
          paperId: paper,
          partId: part,
          syllabusUnitId: unit,
          majorStudyAreaId: area,
          contentTopicId: content,
          topicId: topic,
          lessonId: lesson,
          legacyPaperId: legacyPaperId,
          legacySectionId: legacySectionId,
          legacyTopicId: legacyTopicId,
          legacyLessonId: legacyLessonId,
          shapeHint: shapeHint,
        );
      }
    } on CanonicalScopeValidationException {
      return null;
    }

    return null;
  }

  /// Resolves scope from syllabus-unit navigation IDs.
  ///
  /// For Group-II Paper-I, [syllabusUnitId] is the major study area ID.
  /// For Group-II Papers II–IV, [syllabusUnitId] is the canonical topic/unit ID.
  /// Never uses display names or legacy topic/section IDs.
  static CanonicalScope? tryFromSyllabusUnit({
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
  }) {
    final course = courseId.trim();
    final paper = paperId.trim();
    final unit = syllabusUnitId.trim();
    if (course.isEmpty || paper.isEmpty || unit.isEmpty) return null;

    return tryResolve(
      courseId: course,
      paperId: paper,
      partId: partId,
      syllabusUnitId: unit,
      majorStudyAreaId: paper == 'group-ii-paper-i' ? unit : null,
      topicId: course == 'group-ii' && paper != 'group-ii-paper-i'
          ? unit
          : null,
    );
  }

  void validate() {
    _requireId(courseId, 'courseId');
    _requireId(paperId, 'paperId');
    _requireId(syllabusUnitId, 'syllabusUnitId');

    switch (shape) {
      case CanonicalScopeShape.groupIiPaperI:
        if (partId != null) {
          throw CanonicalScopeValidationException(
            'groupIiPaperI requires partId to be null.',
          );
        }
        if (majorStudyAreaId == null) {
          throw CanonicalScopeValidationException(
            'groupIiPaperI requires majorStudyAreaId.',
          );
        }
        if (canonicalTopicId != null) {
          throw CanonicalScopeValidationException(
            'groupIiPaperI requires canonicalTopicId to be null.',
          );
        }
        if (lessonId != null) {
          throw CanonicalScopeValidationException(
            'groupIiPaperI requires lessonId to be null.',
          );
        }
        if (syllabusUnitId != majorStudyAreaId) {
          throw CanonicalScopeValidationException(
            'groupIiPaperI syllabusUnitId must equal majorStudyAreaId.',
          );
        }
        return;
      case CanonicalScopeShape.groupIiPartUnit:
        if (partId == null) {
          throw CanonicalScopeValidationException(
            'groupIiPartUnit requires partId.',
          );
        }
        if (canonicalTopicId == null) {
          throw CanonicalScopeValidationException(
            'groupIiPartUnit requires canonicalTopicId.',
          );
        }
        if (majorStudyAreaId != null) {
          throw CanonicalScopeValidationException(
            'groupIiPartUnit requires majorStudyAreaId to be null.',
          );
        }
        if (contentTopicId != null) {
          throw CanonicalScopeValidationException(
            'groupIiPartUnit requires contentTopicId to be null.',
          );
        }
        if (syllabusUnitId != canonicalTopicId) {
          throw CanonicalScopeValidationException(
            'groupIiPartUnit syllabusUnitId must equal canonicalTopicId.',
          );
        }
        return;
      case CanonicalScopeShape.groupIiiPaperUnit:
        if (partId != null) {
          throw CanonicalScopeValidationException(
            'groupIiiPaperUnit requires partId to be null.',
          );
        }
        if (majorStudyAreaId != null ||
            contentTopicId != null ||
            canonicalTopicId != null ||
            lessonId != null) {
          throw CanonicalScopeValidationException(
            'groupIiiPaperUnit forbids majorStudyAreaId/contentTopicId/'
            'canonicalTopicId/lessonId.',
          );
        }
        return;
      case CanonicalScopeShape.groupIiiPartUnit:
        if (partId == null) {
          throw CanonicalScopeValidationException(
            'groupIiiPartUnit requires partId.',
          );
        }
        if (majorStudyAreaId != null ||
            contentTopicId != null ||
            canonicalTopicId != null ||
            lessonId != null) {
          throw CanonicalScopeValidationException(
            'groupIiiPartUnit forbids majorStudyAreaId/contentTopicId/'
            'canonicalTopicId/lessonId.',
          );
        }
        return;
    }
  }

  Map<String, dynamic> toMap({bool includeLegacy = false}) {
    return {
      'courseId': courseId,
      'paperId': paperId,
      if (partId != null) 'partId': partId,
      'syllabusUnitId': syllabusUnitId,
      'shape': shape.name,
      'scopeKey': scopeKey,
      if (majorStudyAreaId != null) 'majorStudyAreaId': majorStudyAreaId,
      if (contentTopicId != null) 'contentTopicId': contentTopicId,
      if (canonicalTopicId != null) 'canonicalTopicId': canonicalTopicId,
      if (lessonId != null) 'lessonId': lessonId,
      if (includeLegacy) ...{
        if (legacyPaperId != null) 'legacyPaperId': legacyPaperId,
        if (legacySectionId != null) 'legacySectionId': legacySectionId,
        if (legacyTopicId != null) 'legacyTopicId': legacyTopicId,
        if (legacyLessonId != null) 'legacyLessonId': legacyLessonId,
      },
    };
  }

  static CanonicalScope? tryFromMap(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final shapeName = raw['shape'] as String?;
    final shape = _parseShape(shapeName);
    if (shape == null) {
      return tryResolve(
        courseId: raw['courseId'] as String?,
        paperId: raw['paperId'] as String?,
        partId: raw['partId'] as String?,
        syllabusUnitId: raw['syllabusUnitId'] as String?,
        majorStudyAreaId: raw['majorStudyAreaId'] as String?,
        contentTopicId: raw['contentTopicId'] as String?,
        topicId:
            raw['canonicalTopicId'] as String? ?? raw['topicId'] as String?,
        lessonId: raw['lessonId'] as String?,
        legacyPaperId: raw['legacyPaperId'] as String?,
        legacySectionId: raw['legacySectionId'] as String?,
        legacyTopicId: raw['legacyTopicId'] as String?,
        legacyLessonId: raw['legacyLessonId'] as String?,
      );
    }

    try {
      return CanonicalScope.validated(
        courseId: raw['courseId'] as String? ?? '',
        paperId: raw['paperId'] as String? ?? '',
        partId: raw['partId'] as String?,
        syllabusUnitId: raw['syllabusUnitId'] as String? ?? '',
        shape: shape,
        majorStudyAreaId: raw['majorStudyAreaId'] as String?,
        contentTopicId: raw['contentTopicId'] as String?,
        canonicalTopicId: raw['canonicalTopicId'] as String?,
        lessonId: raw['lessonId'] as String?,
        legacyPaperId: raw['legacyPaperId'] as String?,
        legacySectionId: raw['legacySectionId'] as String?,
        legacyTopicId: raw['legacyTopicId'] as String?,
        legacyLessonId: raw['legacyLessonId'] as String?,
      );
    } on CanonicalScopeValidationException {
      return null;
    }
  }

  static CanonicalScope? _resolveGroupIii({
    required String courseId,
    required String paperId,
    required String? partId,
    required String? syllabusUnitId,
    required String? majorStudyAreaId,
    required String? contentTopicId,
    required String? topicId,
    required String? lessonId,
    required String? legacyPaperId,
    required String? legacySectionId,
    required String? legacyTopicId,
    required String? legacyLessonId,
    required CanonicalScopeShape? shapeHint,
  }) {
    if (syllabusUnitId == null) return null;
    if (majorStudyAreaId != null ||
        contentTopicId != null ||
        topicId != null ||
        lessonId != null) {
      return null;
    }

    final shape =
        shapeHint ??
        (partId == null
            ? CanonicalScopeShape.groupIiiPaperUnit
            : CanonicalScopeShape.groupIiiPartUnit);

    if (shape == CanonicalScopeShape.groupIiiPaperUnit && partId != null) {
      return null;
    }
    if (shape == CanonicalScopeShape.groupIiiPartUnit && partId == null) {
      return null;
    }
    if (shape != CanonicalScopeShape.groupIiiPaperUnit &&
        shape != CanonicalScopeShape.groupIiiPartUnit) {
      return null;
    }

    return CanonicalScope.validated(
      courseId: courseId,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: syllabusUnitId,
      shape: shape,
      legacyPaperId: legacyPaperId,
      legacySectionId: legacySectionId,
      legacyTopicId: legacyTopicId,
      legacyLessonId: legacyLessonId,
    );
  }

  static CanonicalScope? _resolveGroupIi({
    required String courseId,
    required String paperId,
    required String? partId,
    required String? syllabusUnitId,
    required String? majorStudyAreaId,
    required String? contentTopicId,
    required String? topicId,
    required String? lessonId,
    required String? legacyPaperId,
    required String? legacySectionId,
    required String? legacyTopicId,
    required String? legacyLessonId,
    required CanonicalScopeShape? shapeHint,
  }) {
    final isPaperI = paperId == 'group-ii-paper-i';

    if (isPaperI || shapeHint == CanonicalScopeShape.groupIiPaperI) {
      if (majorStudyAreaId == null) return null;
      if (partId != null || lessonId != null || topicId != null) return null;
      if (syllabusUnitId != null && syllabusUnitId != majorStudyAreaId) {
        return null;
      }

      return CanonicalScope.validated(
        courseId: courseId,
        paperId: paperId,
        syllabusUnitId: majorStudyAreaId,
        shape: CanonicalScopeShape.groupIiPaperI,
        majorStudyAreaId: majorStudyAreaId,
        contentTopicId: contentTopicId,
        legacyPaperId: legacyPaperId,
        legacySectionId: legacySectionId,
        legacyTopicId: legacyTopicId,
        legacyLessonId: legacyLessonId,
      );
    }

    // Papers II–IV: unit = canonical topic. Never use legacyTopicId.
    if (partId == null) return null;
    if (majorStudyAreaId != null || contentTopicId != null) return null;

    final canonicalTopic = syllabusUnitId ?? topicId;
    if (canonicalTopic == null) return null;
    if (syllabusUnitId != null &&
        topicId != null &&
        syllabusUnitId != topicId) {
      return null;
    }

    return CanonicalScope.validated(
      courseId: courseId,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: canonicalTopic,
      shape: CanonicalScopeShape.groupIiPartUnit,
      canonicalTopicId: canonicalTopic,
      lessonId: lessonId,
      legacyPaperId: legacyPaperId,
      legacySectionId: legacySectionId,
      legacyTopicId: legacyTopicId,
      legacyLessonId: legacyLessonId,
    );
  }

  static String _requireId(String value, String field) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw CanonicalScopeValidationException('$field is required.');
    }
    return trimmed;
  }

  static String? _optionalId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static CanonicalScopeShape? _parseShape(String? raw) {
    switch (raw?.trim()) {
      case 'groupIiPaperI':
        return CanonicalScopeShape.groupIiPaperI;
      case 'groupIiPartUnit':
        return CanonicalScopeShape.groupIiPartUnit;
      case 'groupIiiPaperUnit':
        return CanonicalScopeShape.groupIiiPaperUnit;
      case 'groupIiiPartUnit':
        return CanonicalScopeShape.groupIiiPartUnit;
      default:
        return null;
    }
  }
}
