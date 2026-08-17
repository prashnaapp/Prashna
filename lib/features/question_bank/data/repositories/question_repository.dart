import '../dummy/question_bank_dummy_data.dart';
import '../models/question_models.dart';
import '../../repository/question_cloud_repository.dart';
import '../../../authentication/services/user_session_state_coordinator.dart';

/// Persistence boundary for questions.
///
/// Production list/get paths use [QuestionCloudRepository] (Firestore).
/// [loadQuestionsSync] remains dummy-backed for legacy practice adapters only.
///
/// Local bookmark / attempted sets are unchanged (not cloud-migrated here).
class QuestionRepository {
  QuestionRepository({QuestionCloudRepository? cloudRepository})
    : _cloudOverride = cloudRepository {
    _seedBookmarks();
  }

  static final QuestionRepository instance = QuestionRepository()
    .._registerSessionReset();

  final QuestionCloudRepository? _cloudOverride;
  QuestionCloudRepository? _cloudCache;
  final Set<String> _bookmarkedIds = {};
  final Set<String> _attemptedIds = {};

  QuestionCloudRepository get _cloud =>
      _cloudCache ??= _cloudOverride ?? QuestionCloudRepository();

  void _seedBookmarks() {
    // Legacy local seeds for in-memory bookmark/attempted filters only.
    _bookmarkedIds.addAll({'qb-2', 'qb-5', 'qb-10'});
    _attemptedIds.addAll({'qb-1', 'qb-2', 'qb-3', 'qb-4', 'qb-5', 'qb-6'});
  }

  /// Production source: Firestore via [QuestionCloudRepository].
  ///
  /// Does **not** fall back to [QuestionBankDummyData] on failure.
  Future<List<Question>> loadQuestions({QuestionFilter? filter}) async {
    // Bookmark / attempted-positive filters are local — resolve by ID first.
    if (filter?.bookmarked == true) {
      final ids = _bookmarkedIds.toList(growable: false);
      final questions = await _cloud.getByIds(ids);
      return _applyLocalFilters(questions, filter);
    }
    if (filter?.attempted == true) {
      final ids = _attemptedIds.toList(growable: false);
      final questions = await _cloud.getByIds(ids);
      return _applyLocalFilters(questions, filter);
    }

    final questions = await _cloud.loadQuestions(filter: filter);
    return _applyLocalFilters(questions, filter);
  }

  /// Sync access for legacy practice adapters only (dummy corpus).
  ///
  /// Prefer [loadQuestions] for Test Engine / production paths.
  List<Question> loadQuestionsSync({QuestionFilter? filter}) {
    return _applyLocalFilters(QuestionBankDummyData.all, filter);
  }

  Future<Question?> getQuestionById(String id) {
    return _cloud.getQuestionById(id);
  }

  Future<List<Question>> getByIds(List<String> ids) {
    return _cloud.getByIds(ids);
  }

  Future<List<Question>> getQuestionsByTopic(String topicId) {
    return loadQuestions(filter: QuestionFilter(topicId: topicId));
  }

  Future<List<Question>> getQuestionsBySection(String sectionId) {
    return loadQuestions(filter: QuestionFilter(sectionId: sectionId));
  }

  Future<List<Question>> getQuestionsByPaper(String paperId) {
    return loadQuestions(filter: QuestionFilter(paperId: paperId));
  }

  Future<List<Question>> getQuestionsByPart(String partId) {
    return loadQuestions(filter: QuestionFilter(partId: partId));
  }

  Future<List<Question>> getQuestionsByLesson(String lessonId) {
    return loadQuestions(filter: QuestionFilter(lessonId: lessonId));
  }

  Future<List<Question>> getQuestionsBySyllabusUnit(String syllabusUnitId) {
    return loadQuestions(
      filter: QuestionFilter(syllabusUnitId: syllabusUnitId),
    );
  }

  Future<List<Question>> getQuestionsByMajorStudyArea(String areaId) {
    return loadQuestions(filter: QuestionFilter(majorStudyAreaId: areaId));
  }

  Future<List<Question>> getQuestionsByContentTopic(String topicId) {
    return loadQuestions(filter: QuestionFilter(contentTopicId: topicId));
  }

  Future<List<Question>> searchQuestions(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    // Unscoped full-text search is incompatible with course-scoped rules.
    // Dummy-only helper — not used by Test Engine production paths.
    return QuestionBankDummyData.all
        .where((question) {
          if (!question.isActive) return false;
          if (question.question.toLowerCase().contains(q)) return true;
          if (question.topicId.toLowerCase().contains(q)) return true;
          if ((question.examName ?? '').toLowerCase().contains(q)) return true;
          for (final tag in question.tags) {
            if (tag.toLowerCase().contains(q)) return true;
          }
          return false;
        })
        .toList(growable: false);
  }

  Future<List<Question>> filterQuestions(QuestionFilter filter) {
    return loadQuestions(filter: filter);
  }

  Future<void> markBookmarked(String questionId, {required bool value}) async {
    if (value) {
      _bookmarkedIds.add(questionId);
    } else {
      _bookmarkedIds.remove(questionId);
    }
  }

  Future<void> markAttempted(String questionId) async {
    _attemptedIds.add(questionId);
  }

  /// Clears local bookmark and attempted flags for the previous session.
  void clear() {
    _bookmarkedIds.clear();
    _attemptedIds.clear();
  }

  void _registerSessionReset() {
    UserSessionStateCoordinator.instance.register(clear);
  }

  bool isBookmarked(String questionId) => _bookmarkedIds.contains(questionId);

  bool isAttempted(String questionId) => _attemptedIds.contains(questionId);

  List<Question> _applyLocalFilters(
    List<Question> source,
    QuestionFilter? filter,
  ) {
    if (filter == null) {
      return source.where((q) => q.isActive).toList(growable: false);
    }

    return source
        .where((question) {
          if (filter.activeOnly && !question.isActive) return false;
          if (filter.courseId != null && question.courseId != filter.courseId) {
            return false;
          }
          if (filter.paperId != null && question.paperId != filter.paperId) {
            return false;
          }
          if (filter.sectionId != null &&
              question.sectionId != filter.sectionId) {
            return false;
          }
          if (filter.topicId != null && question.topicId != filter.topicId) {
            return false;
          }
          if (filter.partId != null && question.partId != filter.partId) {
            return false;
          }
          if (filter.lessonId != null && question.lessonId != filter.lessonId) {
            return false;
          }
          if (filter.syllabusUnitId != null &&
              question.syllabusUnitId != filter.syllabusUnitId) {
            return false;
          }
          if (filter.majorStudyAreaId != null &&
              question.majorStudyAreaId != filter.majorStudyAreaId) {
            return false;
          }
          if (filter.contentTopicId != null &&
              question.contentTopicId != filter.contentTopicId) {
            return false;
          }
          if (filter.difficulty != null &&
              question.difficulty != filter.difficulty) {
            return false;
          }
          if (filter.questionType != null &&
              question.questionType != filter.questionType) {
            return false;
          }
          if (filter.language != null && question.language != filter.language) {
            return false;
          }
          if (filter.year != null && question.year != filter.year) return false;
          if (filter.bookmarked != null) {
            final bookmarked = _bookmarkedIds.contains(question.id);
            if (bookmarked != filter.bookmarked) return false;
          }
          if (filter.attempted != null) {
            final attempted = _attemptedIds.contains(question.id);
            if (attempted != filter.attempted) return false;
          }
          return true;
        })
        .toList(growable: false);
  }
}
