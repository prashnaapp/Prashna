import 'dart:math';

import '../models/question_models.dart';
import '../repositories/question_repository.dart';

/// Business logic for fetching and preparing questions for consumers
/// (Test Engine, practice, etc.).
class QuestionService {
  QuestionService({QuestionRepository? repository})
      : _repository = repository ?? QuestionRepository.instance;

  static final QuestionService instance = QuestionService();

  final QuestionRepository _repository;
  final Random _random = Random();

  Future<List<Question>> fetchQuestions({QuestionFilter? filter}) {
    return _repository.loadQuestions(filter: filter);
  }

  Future<Question?> getById(String id) => _repository.getQuestionById(id);

  Future<List<Question>> getByTopic(String topicId) =>
      _repository.getQuestionsByTopic(topicId);

  Future<List<Question>> getBySection(String sectionId) =>
      _repository.getQuestionsBySection(sectionId);

  Future<List<Question>> getByPaper(String paperId) =>
      _repository.getQuestionsByPaper(paperId);

  Future<List<Question>> search(String query) =>
      _repository.searchQuestions(query);

  Future<List<Question>> filter(QuestionFilter filter) =>
      _repository.filterQuestions(filter);

  List<Question> randomize(List<Question> questions, {int? count}) {
    final copy = List<Question>.from(questions)..shuffle(_random);
    if (count == null || count >= copy.length) return copy;
    return copy.take(count).toList(growable: false);
  }

  /// Optionally shuffles option order while remapping [Question.correctOption].
  Question shuffleOptions(Question question) {
    if (question.options.length < 2) return question;

    const labels = ['A', 'B', 'C', 'D', 'E'];
    final correctText = question.correctAnswerText;
    final texts = List<String>.from(question.options)..shuffle(_random);
    final newIndex = texts.indexOf(correctText);
    final correctLabel = newIndex >= 0 && newIndex < labels.length
        ? labels[newIndex]
        : question.correctOption;

    return Question(
      id: question.id,
      courseId: question.courseId,
      paperId: question.paperId,
      sectionId: question.sectionId,
      topicId: question.topicId,
      question: question.question,
      options: texts,
      correctOption: correctLabel,
      explanation: question.explanation,
      difficulty: question.difficulty,
      questionType: question.questionType,
      language: question.language,
      marks: question.marks,
      negativeMarks: question.negativeMarks,
      year: question.year,
      examName: question.examName,
      tags: question.tags,
      estimatedTime: question.estimatedTime,
      hint: question.hint,
      aiExplanation: question.aiExplanation,
      createdAt: question.createdAt,
      updatedAt: question.updatedAt,
      isActive: question.isActive,
    );
  }

  List<Question> sort(
    List<Question> questions, {
    QuestionSort sortBy = QuestionSort.newest,
  }) {
    final copy = List<Question>.from(questions);
    int difficultyRank(QuestionDifficulty d) => d.index;

    switch (sortBy) {
      case QuestionSort.newest:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case QuestionSort.oldest:
        copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case QuestionSort.difficultyAsc:
        copy.sort(
          (a, b) => difficultyRank(a.difficulty)
              .compareTo(difficultyRank(b.difficulty)),
        );
        break;
      case QuestionSort.difficultyDesc:
        copy.sort(
          (a, b) => difficultyRank(b.difficulty)
              .compareTo(difficultyRank(a.difficulty)),
        );
        break;
      case QuestionSort.yearDesc:
        copy.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
        break;
    }
    return copy;
  }

  /// Primary entry for Test Engine — filter, randomize, optionally shuffle.
  Future<List<Question>> getQuestionsForTest({
    required int count,
    String? courseId,
    String? paperId,
    String? sectionId,
    String? topicId,
    QuestionType? questionType,
    QuestionDifficulty? difficulty,
    String? language,
    int? year,
    bool randomizeOrder = true,
    bool shuffleOptionOrder = false,
  }) async {
    var questions = await fetchQuestions(
      filter: QuestionFilter(
        courseId: courseId,
        paperId: paperId,
        sectionId: sectionId,
        topicId: topicId,
        questionType: questionType,
        difficulty: difficulty,
        language: language,
        year: year,
      ),
    );

    // Broaden if scoped filters yield too few items (dummy corpus gaps).
    if (questions.length < count) {
      questions = await fetchQuestions(
        filter: QuestionFilter(
          courseId: courseId,
          questionType: questionType,
        ),
      );
    }
    if (questions.length < count) {
      questions = await fetchQuestions();
    }

    final selected = randomizeOrder
        ? randomize(questions, count: count)
        : questions.take(count).toList();

    if (!shuffleOptionOrder) return selected;
    return [
      for (final question in selected) shuffleOptions(question),
    ];
  }

  Future<List<Question>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final unique = ids.toSet();
    final results = <Question>[];
    for (final id in unique) {
      final question = await getById(id);
      if (question != null) results.add(question);
    }
    // Preserve requested order.
    final byId = {for (final q in results) q.id: q};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<List<Question>> getBookmarked() {
    return fetchQuestions(
      filter: const QuestionFilter(bookmarked: true),
    );
  }

  Future<List<Question>> getUnattempted({String? courseId}) {
    return fetchQuestions(
      filter: QuestionFilter(
        courseId: courseId,
        attempted: false,
      ),
    );
  }

  Future<void> setBookmarked(String questionId, {required bool value}) {
    return _repository.markBookmarked(questionId, value: value);
  }

  Future<void> markAttempted(String questionId) {
    return _repository.markAttempted(questionId);
  }
}
