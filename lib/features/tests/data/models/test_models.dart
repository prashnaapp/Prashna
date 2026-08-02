enum TestCategoryType {
  chapterTests,
  partTests,
  paperTests,
  mockTests,
  previousYear,
}

class TestCategoryModel {
  const TestCategoryModel({
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final TestCategoryType type;
  final String title;
  final String subtitle;
}

class TestModel {
  const TestModel({
    required this.id,
    required this.examId,
    required this.category,
    required this.title,
    required this.questionCount,
    required this.marks,
    required this.durationMinutes,
    required this.negativeMarking,
    required this.difficulty,
  });

  final String id;
  final String examId;
  final TestCategoryType category;
  final String title;
  final int questionCount;
  final int marks;
  final int durationMinutes;
  final String negativeMarking;
  final String difficulty;
}

class InstructionModel {
  const InstructionModel({
    required this.testName,
    required this.questionCount,
    required this.marks,
    required this.durationLabel,
    required this.negativeMarking,
    required this.difficulty,
    required this.instructions,
  });

  final String testName;
  final int questionCount;
  final int marks;
  final String durationLabel;
  final String negativeMarking;
  final String difficulty;
  final List<String> instructions;
}

class TestExamSummary {
  const TestExamSummary({
    required this.examId,
    required this.title,
    required this.maxMarks,
    required this.paperCount,
    required this.isEnabled,
  });

  final String examId;
  final String title;
  final double maxMarks;
  final int paperCount;
  final bool isEnabled;
}
