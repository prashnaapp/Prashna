enum RevisionCollectionType {
  wrongQuestions,
  bookmarked,
  weakTopics,
  unattempted,
  frequentlyWrong,
  recentMistakes,
}

class RevisionCollection {
  const RevisionCollection({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.questionIds,
  });

  final RevisionCollectionType type;
  final String title;
  final String subtitle;
  final List<String> questionIds;

  int get count => questionIds.length;
  bool get isEmpty => questionIds.isEmpty;
  bool get isNotEmpty => questionIds.isNotEmpty;
}

class RevisionSessionConfig {
  const RevisionSessionConfig({
    required this.collection,
    required this.courseId,
    this.maxQuestions = 20,
    this.durationMinutes,
  });

  final RevisionCollection collection;
  final String courseId;
  final int maxQuestions;
  final int? durationMinutes;
}
