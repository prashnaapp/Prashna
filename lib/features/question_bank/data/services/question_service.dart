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

  Future<List<Question>> getByPart(String partId) =>
      _repository.getQuestionsByPart(partId);

  Future<List<Question>> getByLesson(String lessonId) =>
      _repository.getQuestionsByLesson(lessonId);

  Future<List<Question>> getBySyllabusUnit(String syllabusUnitId) =>
      _repository.getQuestionsBySyllabusUnit(syllabusUnitId);

  Future<List<Question>> getByMajorStudyArea(String areaId) =>
      _repository.getQuestionsByMajorStudyArea(areaId);

  Future<List<Question>> getByContentTopic(String topicId) =>
      _repository.getQuestionsByContentTopic(topicId);

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
    const labels = ['A', 'B', 'C', 'D', 'E'];
    final englishOptions = question.options.isNotEmpty
        ? question.options
        : question.content?.en.options.map((option) => option.text).toList() ??
              const <String>[];
    if (englishOptions.length < 2) return question;

    final correctIndex = labels.indexOf(question.correctOption);
    final correctText =
        correctIndex >= 0 && correctIndex < englishOptions.length
        ? englishOptions[correctIndex]
        : question.correctOption;
    final order = List<int>.generate(englishOptions.length, (index) => index)
      ..shuffle(_random);
    final texts = [for (final index in order) englishOptions[index]];
    final newIndex = texts.indexOf(correctText);
    final correctLabel = newIndex >= 0 && newIndex < labels.length
        ? labels[newIndex]
        : question.correctOption;

    QuestionContent? content;
    final originalContent = question.content;
    if (originalContent != null) {
      List<QuestionOption> reorder(List<QuestionOption> options) => [
        for (final index in order) options[index],
      ];

      content = QuestionContent(
        en: QuestionLocalizedContent(
          question: originalContent.en.question,
          options: reorder(originalContent.en.options),
          explanation: originalContent.en.explanation,
        ),
        te:
            originalContent.te == null ||
                originalContent.te!.options.length != order.length
            ? null
            : QuestionLocalizedContent(
                question: originalContent.te!.question,
                options: reorder(originalContent.te!.options),
                explanation: originalContent.te!.explanation,
              ),
      );
    }

    return Question(
      id: question.id,
      courseId: question.courseId,
      paperId: question.paperId,
      sectionId: question.sectionId,
      topicId: question.topicId,
      question: question.question.isNotEmpty
          ? question.question
          : question.content?.en.question ?? '',
      options: texts,
      correctOption: correctLabel,
      explanation: question.explanation.isNotEmpty
          ? question.explanation
          : question.content?.en.explanation ?? '',
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
      content: content,
      syllabus: question.syllabus,
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
          (a, b) => difficultyRank(
            a.difficulty,
          ).compareTo(difficultyRank(b.difficulty)),
        );
        break;
      case QuestionSort.difficultyDesc:
        copy.sort(
          (a, b) => difficultyRank(
            b.difficulty,
          ).compareTo(difficultyRank(a.difficulty)),
        );
        break;
      case QuestionSort.yearDesc:
        copy.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
        break;
    }
    return copy;
  }

  /// Primary entry for Test Engine — filter, randomize, optionally shuffle.
  ///
  /// Syllabus-linked selection (paper / part / unit / topic / section) is
  /// exact-scope. It never broadens to another unit, part, paper, or the
  /// whole course. An undersized pool fails instead of silently filling.
  ///
  /// Tests without location metadata keep course-scoped legacy selection.
  Future<List<Question>> getQuestionsForTest({
    required int count,
    String? courseId,
    String? paperId,
    String? sectionId,
    String? topicId,
    String? partId,
    String? lessonId,
    String? syllabusUnitId,
    String? majorStudyAreaId,
    String? contentTopicId,
    QuestionType? questionType,
    QuestionDifficulty? difficulty,
    String? language,
    int? year,
    bool randomizeOrder = true,
    bool shuffleOptionOrder = false,
  }) async {
    final exactScope = _hasLocationScope(
      paperId: paperId,
      sectionId: sectionId,
      topicId: topicId,
      partId: partId,
      lessonId: lessonId,
      syllabusUnitId: syllabusUnitId,
      majorStudyAreaId: majorStudyAreaId,
      contentTopicId: contentTopicId,
    );

    if (exactScope) {
      var questions = await fetchQuestions(
        filter: QuestionFilter(
          courseId: courseId,
          paperId: paperId,
          sectionId: sectionId,
          topicId: topicId,
          partId: partId,
          lessonId: lessonId,
          majorStudyAreaId: majorStudyAreaId,
          contentTopicId: contentTopicId,
        ),
      );
      final unit = syllabusUnitId?.trim();
      if (unit != null && unit.isNotEmpty) {
        questions = [
          for (final question in questions)
            if (matchesSyllabusUnit(question, unit)) question,
        ];
      }
      if (questions.length < count) {
        throw StateError(
          'Not enough questions in the selected syllabus scope.',
        );
      }
      final selected = randomizeOrder
          ? randomize(questions, count: count)
          : questions.take(count).toList();
      if (!shuffleOptionOrder) return selected;
      return [for (final question in selected) shuffleOptions(question)];
    }

    var questions = await fetchQuestions(
      filter: QuestionFilter(
        courseId: courseId,
        questionType: questionType,
        difficulty: difficulty,
        language: language,
        year: year,
      ),
    );

    // Legacy unscoped path: broaden within the same course only.
    if (questions.length < count &&
        courseId != null &&
        courseId.isNotEmpty &&
        (difficulty != null || language != null || year != null)) {
      questions = await fetchQuestions(
        filter: QuestionFilter(courseId: courseId, questionType: questionType),
      );
    }

    if (questions.length < count && courseId != null && courseId.isNotEmpty) {
      questions = await fetchQuestions(
        filter: QuestionFilter(courseId: courseId),
      );
    }

    final selected = randomizeOrder
        ? randomize(questions, count: count)
        : questions.take(count).toList();

    if (!shuffleOptionOrder) return selected;
    return [for (final question in selected) shuffleOptions(question)];
  }

  static bool _nonEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;

  static bool _hasLocationScope({
    String? paperId,
    String? sectionId,
    String? topicId,
    String? partId,
    String? lessonId,
    String? syllabusUnitId,
    String? majorStudyAreaId,
    String? contentTopicId,
  }) {
    return _nonEmpty(paperId) ||
        _nonEmpty(sectionId) ||
        _nonEmpty(topicId) ||
        _nonEmpty(partId) ||
        _nonEmpty(lessonId) ||
        _nonEmpty(syllabusUnitId) ||
        _nonEmpty(majorStudyAreaId) ||
        _nonEmpty(contentTopicId);
  }

  /// Group-III stores the unit on [Question.syllabusUnitId]; Group-II stores
  /// the same canonical id on topicId or majorStudyAreaId.
  static bool matchesSyllabusUnit(Question question, String syllabusUnitId) {
    final unit = syllabusUnitId.trim();
    if (unit.isEmpty) return false;
    if (question.syllabusUnitId == unit) return true;
    if (question.topicId == unit) return true;
    if (question.majorStudyAreaId == unit) return true;
    return false;
  }

  Future<List<Question>> getByIds(List<String> ids) {
    return _repository.getByIds(ids);
  }

  Future<List<Question>> getBookmarked() {
    return fetchQuestions(filter: const QuestionFilter(bookmarked: true));
  }

  Future<List<Question>> getUnattempted({String? courseId}) {
    return fetchQuestions(
      filter: QuestionFilter(courseId: courseId, attempted: false),
    );
  }

  Future<void> setBookmarked(String questionId, {required bool value}) {
    return _repository.markBookmarked(questionId, value: value);
  }

  Future<void> markAttempted(String questionId) {
    return _repository.markAttempted(questionId);
  }
}
