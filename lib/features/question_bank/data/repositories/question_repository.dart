import '../dummy/question_bank_dummy_data.dart';
import '../models/question_models.dart';

/// Persistence boundary for questions.
/// In-memory dummy today; swap for Firebase without changing callers.
class QuestionRepository {
  QuestionRepository._() {
    _seedBookmarks();
  }

  static final QuestionRepository instance = QuestionRepository._();

  final Set<String> _bookmarkedIds = {};
  final Set<String> _attemptedIds = {};

  void _seedBookmarks() {
    _bookmarkedIds.addAll({'qb-2', 'qb-5', 'qb-10'});
    _attemptedIds.addAll({'qb-1', 'qb-2', 'qb-3', 'qb-4', 'qb-5', 'qb-6'});
  }
  Future<List<Question>> loadQuestions({QuestionFilter? filter}) async {
    return loadQuestionsSync(filter: filter);
  }

  /// Sync access for local dummy / in-memory backends.
  /// Firebase-backed implementations should prefer [loadQuestions].
  List<Question> loadQuestionsSync({QuestionFilter? filter}) {
    return _applyFilter(QuestionBankDummyData.all, filter);
  }

  Future<Question?> getQuestionById(String id) async {
    for (final question in QuestionBankDummyData.all) {
      if (question.id == id) return question;
    }
    return null;
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

  Future<List<Question>> searchQuestions(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return loadQuestions();

    return QuestionBankDummyData.all.where((question) {
      if (!question.isActive) return false;
      if (question.question.toLowerCase().contains(q)) return true;
      if (question.topicId.toLowerCase().contains(q)) return true;
      if ((question.examName ?? '').toLowerCase().contains(q)) return true;
      for (final tag in question.tags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList(growable: false);
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

  bool isBookmarked(String questionId) => _bookmarkedIds.contains(questionId);

  bool isAttempted(String questionId) => _attemptedIds.contains(questionId);

  List<Question> _applyFilter(List<Question> source, QuestionFilter? filter) {
    if (filter == null) {
      return source.where((q) => q.isActive).toList(growable: false);
    }

    return source.where((question) {
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
    }).toList(growable: false);
  }
}
