import '../../../question_bank/data/models/question_models.dart';
import '../../../question_bank/data/services/question_service.dart';
import '../../../syllabus/data/models/canonical_scope.dart';
import '../models/canonical_planner_models.dart';

/// Counts active questions for an exact canonical syllabus scope.
///
/// This is deliberately separate from the legacy planner's question counts.
/// It does not broaden to a parent paper, part, course, topic, or lesson.
class CanonicalQuestionInventoryService {
  CanonicalQuestionInventoryService({QuestionService? questionService})
    : _questionService = questionService ?? QuestionService.instance;

  final QuestionService _questionService;

  /// Returns the active question count for [scope].
  ///
  /// Group-II Paper-I accepts the canonical major-study-area attribution,
  /// because that is the existing representation of its final unit. For
  /// Group-II Part/Unit and all Group-III scopes, an explicit
  /// [Question.syllabusUnitId] is required. A topicId or lessonId never
  /// becomes a canonical unit here.
  Future<int> getCanonicalQuestionCount(CanonicalScope scope) async {
    scope.validate();
    final questions = await _questionService.fetchQuestions(
      filter: QuestionFilter(courseId: scope.courseId),
    );

    return questions.where((question) {
      if (!question.isActive) return false;
      return _matchesExactScope(question, scope);
    }).length;
  }

  Future<int> getCanonicalQuestionCountForItem(
    CanonicalPlannerItem item,
  ) {
    return getCanonicalQuestionCount(item.scope);
  }

  bool _matchesExactScope(Question question, CanonicalScope scope) {
    if (question.courseId != scope.courseId ||
        question.paperId != scope.paperId ||
        _normalize(question.partId) != _normalize(scope.partId)) {
      return false;
    }

    final questionScope = _questionScope(question, scope);
    return questionScope?.scopeKey == scope.scopeKey;
  }

  CanonicalScope? _questionScope(
    Question question,
    CanonicalScope requested,
  ) {
    final requestedUnit = requested.syllabusUnitId;

    switch (requested.shape) {
      case CanonicalScopeShape.groupIiPaperI:
        // Paper-I's final unit is the major study area. An explicit
        // syllabusUnitId is also accepted when a newer document stores it.
        final areaMatches = question.majorStudyAreaId == requestedUnit;
        final unitMatches = question.syllabusUnitId == requestedUnit;
        if (!areaMatches && !unitMatches) return null;
        return CanonicalScope.tryFromSyllabusUnit(
          courseId: question.courseId,
          paperId: question.paperId,
          syllabusUnitId: requestedUnit,
        );
      case CanonicalScopeShape.groupIiPartUnit:
      case CanonicalScopeShape.groupIiiPaperUnit:
      case CanonicalScopeShape.groupIiiPartUnit:
        // No topicId or lessonId fallback. Legacy Group-II part questions
        // without syllabusUnitId therefore remain unavailable canonically.
        if (question.syllabusUnitId != requestedUnit) return null;
        return CanonicalScope.tryFromSyllabusUnit(
          courseId: question.courseId,
          paperId: question.paperId,
          partId: question.partId,
          syllabusUnitId: question.syllabusUnitId!,
        );
    }
  }

  String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
