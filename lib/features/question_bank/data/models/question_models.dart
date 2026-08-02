enum QuestionDifficulty {
  easy,
  medium,
  hard,
}

enum QuestionType {
  practice,
  previousYear,
  mock,
}

/// Canonical question entity — single source of truth for the app.
class Question {
  const Question({
    required this.id,
    required this.courseId,
    required this.paperId,
    required this.sectionId,
    required this.topicId,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.explanation,
    required this.difficulty,
    required this.questionType,
    required this.language,
    required this.marks,
    required this.negativeMarks,
    required this.tags,
    required this.estimatedTime,
    required this.createdAt,
    required this.updatedAt,
    this.year,
    this.examName,
    this.hint,
    this.aiExplanation,
    this.isActive = true,
  });

  final String id;
  final String courseId;
  final String paperId;
  final String sectionId;
  final String topicId;
  final String question;
  final List<String> options;
  final String correctOption;
  final String explanation;
  final QuestionDifficulty difficulty;
  final QuestionType questionType;
  final String language;
  final double marks;
  final double negativeMarks;
  final int? year;
  final String? examName;
  final List<String> tags;
  final Duration estimatedTime;
  final String? hint;
  final String? aiExplanation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  String get correctAnswerText {
    const labels = ['A', 'B', 'C', 'D', 'E'];
    final index = labels.indexOf(correctOption);
    if (index >= 0 && index < options.length) return options[index];
    return correctOption;
  }
}

/// Filter criteria for repository / service queries.
class QuestionFilter {
  const QuestionFilter({
    this.courseId,
    this.paperId,
    this.sectionId,
    this.topicId,
    this.difficulty,
    this.questionType,
    this.language,
    this.year,
    this.bookmarked,
    this.attempted,
    this.activeOnly = true,
  });

  final String? courseId;
  final String? paperId;
  final String? sectionId;
  final String? topicId;
  final QuestionDifficulty? difficulty;
  final QuestionType? questionType;
  final String? language;
  final int? year;
  final bool? bookmarked;
  final bool? attempted;
  final bool activeOnly;

  QuestionFilter copyWith({
    String? courseId,
    String? paperId,
    String? sectionId,
    String? topicId,
    QuestionDifficulty? difficulty,
    QuestionType? questionType,
    String? language,
    int? year,
    bool? bookmarked,
    bool? attempted,
    bool? activeOnly,
  }) {
    return QuestionFilter(
      courseId: courseId ?? this.courseId,
      paperId: paperId ?? this.paperId,
      sectionId: sectionId ?? this.sectionId,
      topicId: topicId ?? this.topicId,
      difficulty: difficulty ?? this.difficulty,
      questionType: questionType ?? this.questionType,
      language: language ?? this.language,
      year: year ?? this.year,
      bookmarked: bookmarked ?? this.bookmarked,
      attempted: attempted ?? this.attempted,
      activeOnly: activeOnly ?? this.activeOnly,
    );
  }
}

enum QuestionSort {
  newest,
  oldest,
  difficultyAsc,
  difficultyDesc,
  yearDesc,
}
