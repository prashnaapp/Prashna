import '../../../question_activity/data/models/question_activity_models.dart';
import '../../../question_bank/data/models/question_models.dart';

enum TestMode { practice, topic, section, paper, mock, previousYear, grand }

enum QuestionStatus { notVisited, notAnswered, answered, markedForReview }

/// Catalog attempt submission lifecycle for the student UI.
enum TestSubmissionPhase { idle, submitting, submitted, submissionFailed }

class TestOption {
  const TestOption({required this.label, required this.text, this.teluguText});

  final String label;
  final String text;
  final String? teluguText;
}

class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOption,
    required this.explanation,
    this.paperId,
    this.sectionId,
    this.topicId,
    this.content,
    this.syllabus,
  });

  final String id;
  final String text;
  final List<TestOption> options;
  final String correctOption;
  final String explanation;
  final String? paperId;
  final String? sectionId;
  final String? topicId;
  final QuestionContent? content;
  final QuestionSyllabusAttribution? syllabus;

  String? get teluguText => content?.te?.question;
  String? get majorStudyAreaId => syllabus?.majorStudyAreaId;
  String? get contentTopicId => syllabus?.contentTopicId;
  String? get partId => syllabus?.partId;
  String? get lessonId => syllabus?.lessonId;

  /// Numbered statements from the snapshot. Empty for Standard MCQ.
  List<String> get englishStatements => content?.en.statements ?? const [];

  /// Telugu statements paired by index with [englishStatements].
  List<String> get teluguStatements => content?.te?.statements ?? const [];

  bool get hasNumberedStatements => englishStatements.isNotEmpty;

  String get correctAnswerText {
    for (final option in options) {
      if (option.label == correctOption) return option.text;
    }
    return correctOption;
  }
}

/// Configurable test definition. Different exam types only change this model.
class Test {
  const Test({
    required this.id,
    required this.title,
    required this.courseId,
    required this.duration,
    required this.totalQuestions,
    required this.totalMarks,
    required this.negativeMarks,
    required this.instructions,
    required this.mode,
    required this.questions,
    this.paperId,
    this.sectionId,
    this.topicId,
    this.partId,
    this.lessonId,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.syllabusUnitId,
    this.seriesId,
    this.year,
    this.currentAffairsSetId,
    this.activitySourceModule,
    this.activitySourceType,
  });

  final String id;
  final String title;
  final String courseId;
  final String? paperId;
  final String? sectionId;
  final String? topicId;
  final String? partId;
  final String? lessonId;
  final String? majorStudyAreaId;
  final String? contentTopicId;

  /// Optional catalog / CA encounter hints for question activity reporting.
  final String? syllabusUnitId;
  final String? seriesId;
  final int? year;
  final String? currentAffairsSetId;
  final QuestionActivitySourceModule? activitySourceModule;
  final QuestionActivitySourceType? activitySourceType;

  final Duration duration;
  final int totalQuestions;
  final int totalMarks;
  final double negativeMarks;
  final List<String> instructions;
  final TestMode mode;
  final List<TestQuestion> questions;

  Test copyWith({
    String? id,
    String? title,
    String? courseId,
    String? paperId,
    String? sectionId,
    String? topicId,
    String? partId,
    String? lessonId,
    String? majorStudyAreaId,
    String? contentTopicId,
    String? syllabusUnitId,
    String? seriesId,
    int? year,
    String? currentAffairsSetId,
    QuestionActivitySourceModule? activitySourceModule,
    QuestionActivitySourceType? activitySourceType,
    Duration? duration,
    int? totalQuestions,
    int? totalMarks,
    double? negativeMarks,
    List<String>? instructions,
    TestMode? mode,
    List<TestQuestion>? questions,
  }) {
    return Test(
      id: id ?? this.id,
      title: title ?? this.title,
      courseId: courseId ?? this.courseId,
      paperId: paperId ?? this.paperId,
      sectionId: sectionId ?? this.sectionId,
      topicId: topicId ?? this.topicId,
      partId: partId ?? this.partId,
      lessonId: lessonId ?? this.lessonId,
      majorStudyAreaId: majorStudyAreaId ?? this.majorStudyAreaId,
      contentTopicId: contentTopicId ?? this.contentTopicId,
      syllabusUnitId: syllabusUnitId ?? this.syllabusUnitId,
      seriesId: seriesId ?? this.seriesId,
      year: year ?? this.year,
      currentAffairsSetId: currentAffairsSetId ?? this.currentAffairsSetId,
      activitySourceModule: activitySourceModule ?? this.activitySourceModule,
      activitySourceType: activitySourceType ?? this.activitySourceType,
      duration: duration ?? this.duration,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalMarks: totalMarks ?? this.totalMarks,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      instructions: instructions ?? this.instructions,
      mode: mode ?? this.mode,
      questions: questions ?? this.questions,
    );
  }
}

class QuestionAttempt {
  QuestionAttempt({required this.questionId});

  final String questionId;
  String? selectedOption;
  bool answered = false;
  bool visited = false;
  bool bookmarked = false;
  bool markedForReview = false;
  int timeSpent = 0;

  QuestionStatus get status {
    if (!visited) return QuestionStatus.notVisited;
    if (markedForReview) return QuestionStatus.markedForReview;
    if (answered && selectedOption != null) return QuestionStatus.answered;
    return QuestionStatus.notAnswered;
  }

  QuestionAttempt copy() {
    return QuestionAttempt(questionId: questionId)
      ..selectedOption = selectedOption
      ..answered = answered
      ..visited = visited
      ..bookmarked = bookmarked
      ..markedForReview = markedForReview
      ..timeSpent = timeSpent;
  }
}

class TestResult {
  const TestResult({
    required this.totalQuestions,
    required this.attempted,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.score,
    required this.accuracy,
    required this.percentage,
    required this.timeTaken,
    required this.passed,
    this.authority,
    this.attemptId,
  });

  final int totalQuestions;
  final int attempted;
  final int correct;
  final int wrong;
  final int skipped;
  final double score;
  final double accuracy;
  final double percentage;
  final Duration timeTaken;
  final bool passed;

  /// `server_verified` for callable-scored attempts; null/local for practice.
  final String? authority;

  /// Server attempt id when submitted via [submitTestAttempt].
  final String? attemptId;

  bool get isServerVerified => authority == 'server_verified';
}

class AreaPerformance {
  const AreaPerformance({
    required this.id,
    required this.label,
    required this.correct,
    required this.total,
  });

  final String id;
  final String label;
  final int correct;
  final int total;

  double get accuracy => total == 0 ? 0 : (correct / total) * 100;
}

class QuestionReviewItem {
  const QuestionReviewItem({
    required this.question,
    required this.attempt,
    required this.isCorrect,
  });

  final TestQuestion question;
  final QuestionAttempt attempt;
  final bool isCorrect;
}

class TestAnalysis {
  const TestAnalysis({
    required this.byPaper,
    required this.bySection,
    required this.byTopic,
    required this.weakAreas,
    required this.strongAreas,
    required this.reviews,
  });

  final List<AreaPerformance> byPaper;
  final List<AreaPerformance> bySection;
  final List<AreaPerformance> byTopic;
  final List<AreaPerformance> weakAreas;
  final List<AreaPerformance> strongAreas;
  final List<QuestionReviewItem> reviews;
}
