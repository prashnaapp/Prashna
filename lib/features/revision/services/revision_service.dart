import '../../progress/services/progress_service.dart';
import '../../question_bank/data/services/question_service.dart';
import '../../test_engine/data/models/test_engine_models.dart';
import '../../test_engine/services/test_service.dart';
import '../data/models/revision_models.dart';
import '../data/repositories/revision_repository.dart';

/// Builds revision collections from Question Bank + Progress data
/// and launches sessions through the shared Test Engine.
class RevisionService {
  RevisionService({
    QuestionService? questionService,
    ProgressService? progressService,
    TestService? testService,
    RevisionRepository? repository,
  })  : _questions = questionService ?? QuestionService.instance,
        _progress = progressService ?? ProgressService.instance,
        _tests = testService ?? TestService(),
        _repository = repository ?? RevisionRepository.instance;

  static final RevisionService instance = RevisionService();

  final QuestionService _questions;
  final ProgressService _progress;
  final TestService _tests;
  final RevisionRepository _repository;

  Future<List<RevisionCollection>> generateCollections({
    String? courseId,
  }) async {
    final wrongIds = await _progress.loadWrongQuestionIds();
    final bookmarked = await _questions.getBookmarked();
    final unattempted = await _questions.getUnattempted(courseId: courseId);
    final frequentIds = await _progress.loadFrequentlyWrongIds();
    final recentIds = await _progress.loadRecentMistakeIds();
    final weakTopics = await _progress.calculateWeakAreas(courseId: courseId);

    final weakQuestionIds = <String>[];
    for (final topic in weakTopics) {
      final topicQuestions = await _questions.getByTopic(topic.topicId);
      for (final question in topicQuestions) {
        if (courseId != null && question.courseId != courseId) continue;
        weakQuestionIds.add(question.id);
      }
    }

    return [
      RevisionCollection(
        type: RevisionCollectionType.wrongQuestions,
        title: 'Wrong Questions',
        subtitle: 'Questions you answered incorrectly',
        questionIds: _unique(wrongIds),
      ),
      RevisionCollection(
        type: RevisionCollectionType.bookmarked,
        title: 'Bookmarked Questions',
        subtitle: 'Saved for later revision',
        questionIds: _unique([for (final q in bookmarked) q.id]),
      ),
      RevisionCollection(
        type: RevisionCollectionType.weakTopics,
        title: 'Weak Topics',
        subtitle: 'Practice from low-accuracy topics',
        questionIds: _unique(weakQuestionIds),
      ),
      RevisionCollection(
        type: RevisionCollectionType.unattempted,
        title: 'Unattempted Questions',
        subtitle: 'Questions you have not tried yet',
        questionIds: _unique([for (final q in unattempted) q.id]),
      ),
      RevisionCollection(
        type: RevisionCollectionType.frequentlyWrong,
        title: 'Frequently Wrong',
        subtitle: 'Missed more than once',
        questionIds: _unique(frequentIds),
      ),
      RevisionCollection(
        type: RevisionCollectionType.recentMistakes,
        title: 'Recent Mistakes',
        subtitle: 'Errors from the last 7 days',
        questionIds: _unique(recentIds),
      ),
    ];
  }

  Future<RevisionCollection?> getCollection(
    RevisionCollectionType type, {
    String? courseId,
  }) async {
    final all = await generateCollections(courseId: courseId);
    for (final item in all) {
      if (item.type == type) return item;
    }
    return null;
  }

  /// Builds a Test Engine [Test] for the given revision collection.
  Future<Test?> buildRevisionTest({
    required RevisionCollection collection,
    String courseId = 'group-ii',
    int maxQuestions = 20,
    int? durationMinutes,
  }) async {
    if (collection.isEmpty) return null;

    final ids = collection.questionIds.take(maxQuestions).toList();
    final questions = await _questions.getByIds(ids);
    if (questions.isEmpty) return null;

    await _repository.recordSessionStarted(collection.type);

    return _tests.createTestFromQuestions(
      id: 'revision-${collection.type.name}-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Revision · ${collection.title}',
      courseId: courseId,
      questions: questions,
      mode: TestMode.practice,
      duration: durationMinutes == null
          ? null
          : Duration(minutes: durationMinutes),
      instructions: const [
        'This is a revision session generated from your Progress and Question Bank.',
        'Focus on understanding explanations after each attempt.',
        'Your results will update Progress analytics automatically.',
      ],
    );
  }

  List<String> _unique(List<String> ids) {
    final seen = <String>{};
    final result = <String>[];
    for (final id in ids) {
      if (seen.add(id)) result.add(id);
    }
    return result;
  }
}
