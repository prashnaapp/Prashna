import '../../../progress/data/models/syllabus_completion.dart';
import 'canonical_planner_models.dart';

/// Tracker-ready canonical planner data for one syllabus unit.
///
/// Question inventory and completion are intentionally the only enrichment
/// fields. UnitPerformance is not part of this representation.
class CanonicalPlannerEntry {
  const CanonicalPlannerEntry({
    required this.item,
    required this.questionCount,
    required this.completionStatus,
  });

  final CanonicalPlannerItem item;
  final int questionCount;
  final SyllabusCompletionStatus completionStatus;

  String get scopeKey => item.scopeKey;
  String get displayName => item.displayName;
  String get courseId => item.courseId;
  String get paperId => item.paperId;
  String? get partId => item.partId;
  String get syllabusUnitId => item.syllabusUnitId;
}
