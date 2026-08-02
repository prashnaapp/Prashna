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
    TestCategoryType.partTests: 'Paper-wise Tests',
    TestCategoryType.paperTests: 'Paper Tests',
    TestCategoryType.mockTests: 'Mock Tests',
    TestCategoryType.previousYear: 'Previous Papers',
  };

  /// Phase 1 Group dashboard — three entry cards only.
  static const dashboardCategories = <TestCategoryType>[
    TestCategoryType.partTests,
    TestCategoryType.mockTests,
    TestCategoryType.previousYear,
  ];

  static List<TestCategoryModel> categoriesFor(String examId) {
    return dashboardCategories
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

  /// Papers shown under Paper-wise Tests for [examId].
  static List<PaperWisePaper> paperWisePapersFor(String examId) {
    return switch (examId) {
      'group-ii' => const [
          PaperWisePaper(
            id: 'paper-i',
            title: 'Paper I',
            subtitle: 'General Studies',
          ),
          PaperWisePaper(
            id: 'paper-ii',
            title: 'Paper II',
            subtitle: 'History, Polity & Social Structure',
          ),
          PaperWisePaper(
            id: 'paper-iii',
            title: 'Paper III',
            subtitle: 'Economy',
          ),
          PaperWisePaper(
            id: 'paper-iv',
            title: 'Paper IV',
            subtitle: 'Telangana Movement',
          ),
        ],
      'group-iii' => const [
          PaperWisePaper(
            id: 'paper-i',
            title: 'Paper I',
            subtitle: 'General Studies',
          ),
          PaperWisePaper(
            id: 'paper-ii',
            title: 'Paper II',
            subtitle: 'History, Polity & Social Structure',
          ),
          PaperWisePaper(
            id: 'paper-iii',
            title: 'Paper III',
            subtitle: 'Economy',
          ),
        ],
      _ => const [],
    };
  }

  /// Parts under a Paper-wise paper — each launches the existing Test Engine.
  static List<TestModel> paperWisePartsFor({
    required String examId,
    required String paperId,
  }) {
    return [
      _test(
        examId,
        '$paperId-part-i',
        TestCategoryType.partTests,
        'Part I',
        150,
        150,
        150,
      ),
      _test(
        examId,
        '$paperId-part-ii',
        TestCategoryType.partTests,
        'Part II',
        150,
        150,
        150,
      ),
      _test(
        examId,
        '$paperId-part-iii',
        TestCategoryType.partTests,
        'Part III',
        150,
        150,
        150,
      ),
    ];
  }

  /// Mock Test list entries (Phase 3).
  static List<MockTestEntry> mockTestsListFor(String examId) {
    if (examId != 'group-ii' && examId != 'group-iii') return const [];
    return const [
      MockTestEntry(id: 'mock-1', title: 'Mock Test 1'),
      MockTestEntry(id: 'mock-2', title: 'Mock Test 2'),
      MockTestEntry(id: 'mock-3', title: 'Mock Test 3'),
    ];
  }

  /// Papers under a mock — same catalog as Paper-wise for [examId].
  static List<PaperWisePaper> mockPapersFor(String examId) =>
      paperWisePapersFor(examId);

  /// Selecting a paper under a mock launches the existing Test Engine.
  static TestModel mockPaperTest({
    required String examId,
    required MockTestEntry mock,
    required PaperWisePaper paper,
  }) {
    return _test(
      examId,
      '${mock.id}-${paper.id}',
      TestCategoryType.mockTests,
      '${mock.title} · ${paper.title}',
      150,
      150,
      150,
    );
  }

  /// Exams shown under Previous Papers (Phase 4).
  static List<PreviousPaperExam> previousPaperExams() => const [
        PreviousPaperExam(examId: 'group-ii', title: 'Group-II'),
        PreviousPaperExam(examId: 'group-iii', title: 'Group-III'),
      ];

  /// Real exam years only for Previous Papers.
  static List<PreviousPaperYear> previousPaperYearsFor(String examId) {
    return switch (examId) {
      'group-ii' => const [
          PreviousPaperYear(year: 2016),
          PreviousPaperYear(year: 2024),
        ],
      'group-iii' => const [
          PreviousPaperYear(year: 2018),
          PreviousPaperYear(year: 2024),
        ],
      _ => const [],
    };
  }

  /// Papers under a previous-paper year — same catalog as Paper-wise.
  static List<PaperWisePaper> previousPapersFor(String examId) =>
      paperWisePapersFor(examId);

  /// Selecting a paper under a previous year launches the existing Test Engine.
  static TestModel previousPaperTest({
    required String examId,
    required PreviousPaperYear year,
    required PaperWisePaper paper,
  }) {
    return _test(
      examId,
      'py-${year.year}-${paper.id}',
      TestCategoryType.previousYear,
      '${year.title} · ${paper.title}',
      150,
      150,
      150,
    );
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
