import '../../../syllabus/data/models/canonical_scope.dart';

/// One final student-facing canonical syllabus unit in planner order.
///
/// Identity is exclusively [scopeKey]. Completion and UnitPerformance are
/// intentionally loaded by separate layers.
class CanonicalPlannerItem {
  const CanonicalPlannerItem({
    required this.scope,
    required this.displayName,
  });

  final CanonicalScope scope;
  final String displayName;

  String get scopeKey => scope.scopeKey;
  String get courseId => scope.courseId;
  String get paperId => scope.paperId;
  String? get partId => scope.partId;
  String get syllabusUnitId => scope.syllabusUnitId;
}
