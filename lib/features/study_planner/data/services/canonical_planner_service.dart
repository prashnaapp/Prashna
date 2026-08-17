import '../../../syllabus/data/models/canonical_scope.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../models/canonical_planner_models.dart';

/// Raised when the canonical syllabus cannot produce a valid planner item.
class CanonicalPlannerValidationException implements Exception {
  CanonicalPlannerValidationException(this.message);

  final String message;

  @override
  String toString() => 'CanonicalPlannerValidationException: $message';
}

/// Deterministically builds one planner item per final [SyllabusUnit].
///
/// This service reads only [SyllabusPaper.syllabusUnits] and
/// [SyllabusPart.syllabusUnits]. It does not read or infer from
/// major-study-area, content-topic, topic, lesson, or legacy progress data.
class CanonicalPlannerService {
  CanonicalPlannerService({
    SyllabusService? syllabusService,
    this._courseLoader,
  }) : _syllabusService = syllabusService ?? SyllabusService.instance;

  final SyllabusService _syllabusService;
  final SyllabusCourse? Function(String courseId)? _courseLoader;

  List<CanonicalPlannerItem> getCanonicalPlannerItems(String courseId) {
    final normalizedCourseId = _requiredId(courseId, 'courseId');
    final course = _loadCourse(normalizedCourseId);
    if (course == null) {
      throw CanonicalPlannerValidationException(
        'Unknown course: $normalizedCourseId',
      );
    }

    final items = <CanonicalPlannerItem>[];
    for (final paper in course.papers) {
      items.addAll(_buildPaperItems(course, paper));
    }
    _validateUniqueScopeKeys(items, normalizedCourseId);
    return List.unmodifiable(items);
  }

  List<CanonicalPlannerItem> getCanonicalPlannerItemsForPaper({
    required String courseId,
    required String paperId,
  }) {
    final normalizedCourseId = _requiredId(courseId, 'courseId');
    final normalizedPaperId = _requiredId(paperId, 'paperId');
    final course = _loadCourse(normalizedCourseId);
    if (course == null) {
      throw CanonicalPlannerValidationException(
        'Unknown course: $normalizedCourseId',
      );
    }
    final paper = _findPaper(course, normalizedPaperId);
    if (paper == null) {
      throw CanonicalPlannerValidationException(
        'Unknown paper: $normalizedPaperId',
      );
    }
    final items = _buildPaperItems(course, paper);
    _validateUniqueScopeKeys(items, normalizedCourseId);
    return List.unmodifiable(items);
  }

  List<CanonicalPlannerItem> getCanonicalPlannerItemsForPart({
    required String courseId,
    required String paperId,
    required String partId,
  }) {
    final normalizedCourseId = _requiredId(courseId, 'courseId');
    final normalizedPaperId = _requiredId(paperId, 'paperId');
    final normalizedPartId = _requiredId(partId, 'partId');
    final course = _loadCourse(normalizedCourseId);
    if (course == null) {
      throw CanonicalPlannerValidationException(
        'Unknown course: $normalizedCourseId',
      );
    }
    final paper = _findPaper(course, normalizedPaperId);
    if (paper == null) {
      throw CanonicalPlannerValidationException(
        'Unknown paper: $normalizedPaperId',
      );
    }
    final part = _findPart(paper, normalizedPartId);
    if (part == null) {
      throw CanonicalPlannerValidationException(
        'Unknown part: $normalizedPartId',
      );
    }
    final items = _buildPartItems(course, paper, part);
    _validateUniqueScopeKeys(items, normalizedCourseId);
    return List.unmodifiable(items);
  }

  List<CanonicalPlannerItem> _buildPaperItems(
    SyllabusCourse course,
    SyllabusPaper paper,
  ) {
    _requiredId(paper.id, 'paperId');

    final hasDirectUnits = paper.syllabusUnits.isNotEmpty;
    final hasParts = paper.parts.isNotEmpty;
    if (hasDirectUnits && hasParts) {
      throw CanonicalPlannerValidationException(
        'Paper ${paper.id} cannot contain both direct syllabusUnits and parts.',
      );
    }
    if (!hasDirectUnits && !hasParts) {
      throw CanonicalPlannerValidationException(
        'Paper ${paper.id} has no canonical syllabus units or parts.',
      );
    }

    if (hasDirectUnits) {
      return [
        for (final unit in paper.syllabusUnits)
          _buildItem(
            courseId: course.id,
            paperId: paper.id,
            unit: unit,
          ),
      ];
    }

    final items = <CanonicalPlannerItem>[];
    for (final part in paper.parts) {
      items.addAll(_buildPartItems(course, paper, part));
    }
    return items;
  }

  List<CanonicalPlannerItem> _buildPartItems(
    SyllabusCourse course,
    SyllabusPaper paper,
    SyllabusPart part,
  ) {
    final partId = _requiredId(part.id, 'partId');
    if (part.syllabusUnits.isEmpty) {
      throw CanonicalPlannerValidationException(
        'Part $partId has no canonical syllabus units.',
      );
    }

    return [
      for (final unit in part.syllabusUnits)
        _buildItem(
          courseId: course.id,
          paperId: paper.id,
          partId: partId,
          unit: unit,
        ),
    ];
  }

  CanonicalPlannerItem _buildItem({
    required String courseId,
    required String paperId,
    String? partId,
    required SyllabusUnit unit,
  }) {
    final unitId = _requiredId(unit.id, 'syllabusUnitId');
    final displayName = _requiredId(unit.displayName, 'displayName');
    final scope = CanonicalScope.tryFromSyllabusUnit(
      courseId: courseId,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: unitId,
    );
    if (scope == null) {
      throw CanonicalPlannerValidationException(
        'Invalid CanonicalScope for '
        '$courseId/$paperId/${partId ?? ''}/$unitId.',
      );
    }

    return CanonicalPlannerItem(scope: scope, displayName: displayName);
  }

  SyllabusPaper? _findPaper(SyllabusCourse course, String paperId) {
    for (final paper in course.papers) {
      if (paper.id == paperId) return paper;
    }
    return null;
  }

  SyllabusPart? _findPart(SyllabusPaper paper, String partId) {
    for (final part in paper.parts) {
      if (part.id == partId) return part;
    }
    return null;
  }

  void _validateUniqueScopeKeys(
    List<CanonicalPlannerItem> items,
    String courseId,
  ) {
    final seen = <String>{};
    for (final item in items) {
      if (!seen.add(item.scopeKey)) {
        throw CanonicalPlannerValidationException(
          'Duplicate scopeKey ${item.scopeKey} in course $courseId.',
        );
      }
    }
  }

  String _requiredId(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw CanonicalPlannerValidationException('$field is required.');
    }
    return normalized;
  }

  SyllabusCourse? _loadCourse(String courseId) {
    return _courseLoader?.call(courseId) ??
        _syllabusService.getCourseById(courseId);
  }
}
