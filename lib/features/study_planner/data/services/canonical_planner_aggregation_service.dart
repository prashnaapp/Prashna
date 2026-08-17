import '../../../progress/data/models/syllabus_completion.dart';
import '../../../progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import '../models/canonical_planner_entry.dart';
import '../models/canonical_planner_models.dart';
import 'canonical_planner_service.dart';
import 'canonical_question_inventory_service.dart';

/// Combines deterministic canonical items with exact question inventory and
/// explicit syllabus completion.
///
/// The completion repository currently exposes one-document reads, so this
/// service performs one completion read per item concurrently. No caching or
/// Firestore writes are introduced here. Any read failure is propagated.
class CanonicalPlannerAggregationService {
  CanonicalPlannerAggregationService({
    CanonicalPlannerService? plannerService,
    CanonicalQuestionInventoryService? questionInventoryService,
    SyllabusCompletionCloudRepository? completionRepository,
  }) : _plannerService = plannerService ?? CanonicalPlannerService(),
       _questionInventoryService =
           questionInventoryService ?? CanonicalQuestionInventoryService(),
       _completionRepository =
           completionRepository ?? SyllabusCompletionCloudRepository();

  final CanonicalPlannerService _plannerService;
  final CanonicalQuestionInventoryService _questionInventoryService;
  final SyllabusCompletionCloudRepository _completionRepository;

  Future<List<CanonicalPlannerEntry>> getCanonicalPlannerEntries(
    String courseId,
  ) {
    final items = _plannerService.getCanonicalPlannerItems(courseId);
    return _aggregate(items);
  }

  Future<List<CanonicalPlannerEntry>> getCanonicalPlannerEntriesForPaper({
    required String courseId,
    required String paperId,
  }) {
    final items = _plannerService.getCanonicalPlannerItemsForPaper(
      courseId: courseId,
      paperId: paperId,
    );
    return _aggregate(items);
  }

  Future<List<CanonicalPlannerEntry>> getCanonicalPlannerEntriesForPart({
    required String courseId,
    required String paperId,
    required String partId,
  }) {
    final items = _plannerService.getCanonicalPlannerItemsForPart(
      courseId: courseId,
      paperId: paperId,
      partId: partId,
    );
    return _aggregate(items);
  }

  Future<CanonicalPlannerEntry> getCanonicalPlannerEntryForItem(
    CanonicalPlannerItem item,
  ) async {
    final entries = await _aggregate([item]);
    return entries.single;
  }

  Future<List<CanonicalPlannerEntry>> _aggregate(
    List<CanonicalPlannerItem> items,
  ) async {
    final entries = await Future.wait([
      for (final item in items) _aggregateItem(item),
    ]);
    _validateEntries(entries);
    return List.unmodifiable(entries);
  }

  Future<CanonicalPlannerEntry> _aggregateItem(
    CanonicalPlannerItem item,
  ) async {
    item.scope.validate();
    final results = await Future.wait<Object>([
      _questionInventoryService.getCanonicalQuestionCountForItem(item),
      _completionRepository.getCompletion(scope: item.scope),
    ]);
    final questionCount = results[0] as int;
    final completion = results[1] as SyllabusCompletion;
    _validateCompletion(item, completion);

    return CanonicalPlannerEntry(
      item: item,
      questionCount: questionCount,
      completionStatus: completion.status,
    );
  }

  void _validateCompletion(
    CanonicalPlannerItem item,
    SyllabusCompletion completion,
  ) {
    if (completion.scopeKey != item.scopeKey ||
        completion.courseId != item.courseId ||
        completion.paperId != item.paperId ||
        _normalize(completion.partId) != _normalize(item.partId) ||
        completion.syllabusUnitId != item.syllabusUnitId) {
      throw FormatException(
        'Completion identity does not match planner scope ${item.scopeKey}.',
      );
    }
  }

  void _validateEntries(List<CanonicalPlannerEntry> entries) {
    final seen = <String>{};
    for (final entry in entries) {
      if (!seen.add(entry.scopeKey)) {
        throw StateError('Duplicate planner scopeKey ${entry.scopeKey}.');
      }
      if (entry.questionCount < 0) {
        throw StateError('Negative question count for ${entry.scopeKey}.');
      }
    }
  }

  String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
