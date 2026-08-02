import 'models/test_models.dart';

abstract final class TestsDummyData {
  static const instructions = [
    'Read every question carefully.',
    'Complete before time expires.',
    'Result shown immediately after completion.',
    'Progress updates automatically.',
  ];

  static final Map<TestCategoryType, String> categoryTitles = {
    TestCategoryType.chapterTests: 'Chapter Tests',
    TestCategoryType.partTests: 'Part Tests',
    TestCategoryType.paperTests: 'Paper Tests',
    TestCategoryType.mockTests: 'Mock Tests',
    TestCategoryType.previousYear: 'Previous Year Papers',
  };

  static List<TestCategoryModel> categoriesFor(String examId) {
    return TestCategoryType.values
        .map(
          (type) => TestCategoryModel(
            type: type,
            title: categoryTitles[type]!,
            subtitle: 'View available tests',
          ),
        )
        .toList();
  }

  static List<TestModel> testsFor({
    required String examId,
    required TestCategoryType category,
  }) {
    return switch (category) {
      TestCategoryType.chapterTests => _chapterTests(examId),
      TestCategoryType.partTests => _partTests(examId),
      TestCategoryType.paperTests => _paperTests(examId),
      TestCategoryType.mockTests => _mockTests(examId),
      TestCategoryType.previousYear => _previousYear(examId),
    };
  }

  static List<TestModel> _chapterTests(String examId) => [
        _test(examId, 'chapter-1', TestCategoryType.chapterTests, 'Chapter Test 1', 20, 20, 30),
        _test(examId, 'chapter-2', TestCategoryType.chapterTests, 'Chapter Test 2', 20, 20, 30),
        _test(examId, 'chapter-3', TestCategoryType.chapterTests, 'Chapter Test 3', 20, 20, 30),
      ];

  static List<TestModel> _partTests(String examId) => [
        _test(examId, 'part-1', TestCategoryType.partTests, 'Part I Test', 50, 50, 60),
        _test(examId, 'part-2', TestCategoryType.partTests, 'Part II Test', 50, 50, 60),
        _test(examId, 'part-3', TestCategoryType.partTests, 'Part III Test', 50, 50, 60),
      ];

  static List<TestModel> _paperTests(String examId) => [
        _test(examId, 'paper-2', TestCategoryType.paperTests, 'Paper II Test', 150, 150, 180),
        _test(examId, 'paper-3', TestCategoryType.paperTests, 'Paper III Test', 150, 150, 180),
        _test(examId, 'paper-4', TestCategoryType.paperTests, 'Paper IV Test', 150, 150, 180),
      ];

  static List<TestModel> _mockTests(String examId) => [
        _test(examId, 'mock-1', TestCategoryType.mockTests, 'Mock Test 1', 150, 150, 120),
        _test(examId, 'mock-2', TestCategoryType.mockTests, 'Mock Test 2', 150, 150, 120),
        _test(examId, 'mock-3', TestCategoryType.mockTests, 'Mock Test 3', 150, 150, 120),
      ];

  static List<TestModel> _previousYear(String examId) => [
        _test(examId, 'py-2024', TestCategoryType.previousYear, '2024 Paper', 150, 150, 180),
        _test(examId, 'py-2023', TestCategoryType.previousYear, '2023 Paper', 150, 150, 180),
        _test(examId, 'py-2022', TestCategoryType.previousYear, '2022 Paper', 150, 150, 180),
        _test(examId, 'py-2021', TestCategoryType.previousYear, '2021 Paper', 150, 150, 180),
      ];

  static TestModel _test(
    String examId,
    String id,
    TestCategoryType category,
    String title,
    int questions,
    int marks,
    int minutes,
  ) {
    return TestModel(
      id: '$examId-$id',
      examId: examId,
      category: category,
      title: title,
      questionCount: questions,
      marks: marks,
      durationMinutes: minutes,
      negativeMarking: 'No',
      difficulty: 'Medium',
    );
  }
}
