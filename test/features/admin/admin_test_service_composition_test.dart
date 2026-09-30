import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_query.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/services/admin_test_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';

void main() {
  test(
    'production-configured AdminTestService uses the injected Chapter repository',
    () async {
      final original = AdminTestService.instance;
      final queries = <AdminChapterQuestionQuery>[];
      final repository = QuestionCloudRepository.withHandlers(
        loadQuestions: (_) async {
          fail('located Chapter loading must not use a whole-course scan');
        },
        loadChapterQuestionPage: (query) async {
          queries.add(query);
          return const QuestionBankPage(questions: [], hasMore: false);
        },
      );

      try {
        AdminTestService.configureProduction(repository);
        final service = AdminTestService.instance;
        for (final test in _locatedChapterTests) {
          await service.loadCompatibleQuestionPage(test);
        }
      } finally {
        AdminTestService.instance = original;
      }

      expect(queries, hasLength(4));
      expect(
        queries[0].equalityFilters,
        containsAll(<({String field, Object value})>[
          (field: 'majorStudyAreaId', value: 'group-ii-paper-i-area-01'),
          (field: 'contentTopicId', value: 'group-ii-paper-i-topic-01'),
        ]),
      );
      expect(
        queries[1].equalityFilters,
        containsAll(<({String field, Object value})>[
          (field: 'partId', value: 'group-ii-paper-ii-part-02'),
          (field: 'topicId', value: 'group-ii-paper-ii-part-02-topic-01'),
        ]),
      );
      expect(
        queries[2].equalityFilters,
        contains((field: 'syllabusUnitId', value: 'group-iii-paper-i-unit-01')),
      );
      expect(
        queries[3].equalityFilters,
        containsAll(<({String field, Object value})>[
          (field: 'partId', value: 'group-iii-paper-ii-part-01'),
          (
            field: 'syllabusUnitId',
            value: 'group-iii-paper-ii-part-01-unit-01',
          ),
        ]),
      );
    },
  );
}

const _locatedChapterTests = <TestModel>[
  TestModel(
    id: 'group-ii-paper-i',
    examId: 'group-ii',
    category: TestCategoryType.chapterTests,
    title: 'Paper I',
    questionCount: 1,
    marks: 1,
    durationMinutes: 1,
    negativeMarking: '0',
    difficulty: 'Medium',
    paperId: 'group-ii-paper-i',
    majorStudyAreaId: 'group-ii-paper-i-area-01',
    contentTopicId: 'group-ii-paper-i-topic-01',
  ),
  TestModel(
    id: 'group-ii-paper-ii',
    examId: 'group-ii',
    category: TestCategoryType.chapterTests,
    title: 'Paper II',
    questionCount: 1,
    marks: 1,
    durationMinutes: 1,
    negativeMarking: '0',
    difficulty: 'Medium',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-02',
    syllabusUnitId: 'group-ii-paper-ii-part-02-topic-01',
  ),
  TestModel(
    id: 'group-iii-paper-i',
    examId: 'group-iii',
    category: TestCategoryType.chapterTests,
    title: 'Paper I',
    questionCount: 1,
    marks: 1,
    durationMinutes: 1,
    negativeMarking: '0',
    difficulty: 'Medium',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: 'group-iii-paper-i-unit-01',
  ),
  TestModel(
    id: 'group-iii-paper-ii',
    examId: 'group-iii',
    category: TestCategoryType.chapterTests,
    title: 'Paper II',
    questionCount: 1,
    marks: 1,
    durationMinutes: 1,
    negativeMarking: '0',
    difficulty: 'Medium',
    paperId: 'group-iii-paper-ii',
    partId: 'group-iii-paper-ii-part-01',
    syllabusUnitId: 'group-iii-paper-ii-part-01-unit-01',
  ),
];
