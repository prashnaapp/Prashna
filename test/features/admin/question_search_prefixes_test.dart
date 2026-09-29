import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_context.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_query.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/data/admin_test_series_question_query.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/admin/services/question_import_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_content_fingerprint.dart';
import 'package:telangana_prep/features/question_bank/data/question_search_text.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';

const _sentence =
    'On which date was the Constitution of India adopted by the Constituent Assembly?';

void main() {
  test('any-word prefixes match words that are not at the start', () {
    final prefixes = QuestionSearchPrefixes.fromQuestion(_sentence);
    expect(prefixes, containsAll(['on', 'date', 'constitution']));
    expect(prefixes, isNot(contains('o')));
    expect(QuestionSearchPrefixes.queryTerm('date'), 'date');
    expect(QuestionSearchPrefixes.queryTerm('constitution'), 'constitution');
    expect(QuestionSearchPrefixes.queryTerm('on'), 'on');
    expect(prefixes.toSet().length, prefixes.length);
    expect(prefixes, prefixes.toList()..sort());
  });

  test('hyphenated words and short prefixes are deterministic', () {
    final prefixes = QuestionSearchPrefixes.fromQuestion(
      'The Mini-Constitution is called the Drafting charter.',
    );
    expect(prefixes, containsAll(['mini', 'constitution', 'draft']));
    expect(
      QuestionSearchPrefixes.fromQuestion('Mini-Constitution'),
      QuestionSearchPrefixes.fromQuestion('mini — constitution'),
    );
  });

  test('a very long question keeps a bounded deterministic prefix list', () {
    final text = [
      for (var i = 0; i < 801; i++) 'word${i.toString().padLeft(4, '0')}',
    ].join(' ');
    final prefixes = QuestionSearchPrefixes.fromQuestion(text);
    expect(prefixes, hasLength(QuestionSearchPrefixes.maxPrefixes));
    expect(prefixes, contains('word0000'));
    expect(prefixes, isNot(contains('word0800')));
  });

  test(
    'create and edit derive prefixes and leave ownership unchanged',
    () async {
      final created = <Map<String, dynamic>>[];
      Map<String, dynamic>? updated;
      final service = AdminQuestionService(
        questionRepository: QuestionCloudRepository.withHandlers(
          create: ({required questionId, required data}) async {
            created.add(data);
          },
          update: ({required questionId, required data}) async {
            updated = data;
          },
          idGenerator: () => 'q-search',
        ),
      );
      final question = _question(_sentence);
      await service.createQuestion(question);
      expect(created.single['contentArea'], 'chapter');
      expect(created.single['questionSearchPrefixes'], contains('date'));
      expect(
        created.single['contentFingerprint'],
        QuestionContentFingerprint.fromQuestion(question),
      );

      await service.updateQuestion(
        _question(
          'The Drafting Committee prepared the Constitution.',
          id: 'q-1',
        ),
      );
      expect(updated?['contentArea'], 'chapter');
      expect(updated?['questionSearchPrefixes'], contains('draft'));
      expect(updated?['questionSearchPrefixes'], isNot(contains('date')));
    },
  );

  test('chapter and test series imports derive prefixes internally', () async {
    final created = <Map<String, dynamic>>[];
    final chapter = QuestionImportService(
      chapterContext: const AdminChapterQuestionContext(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      ),
      questionRepository: QuestionCloudRepository.withHandlers(
        createBatch: ({required items}) async {
          created.addAll([for (final item in items) item.data]);
        },
        idGenerator: () => 'q-import',
      ),
    );
    final chapterResult = await chapter.validateAndImportJson(
      jsonEncode({
        'questions': [
          _record()..['questionSearchPrefixes'] = ['not-authoritative'],
        ],
      }),
    );
    expect(chapterResult.succeeded, isTrue);
    expect(created.single['contentArea'], 'chapter');
    expect(created.single['questionSearchPrefixes'], contains('date'));
    expect(
      created.single['questionSearchPrefixes'],
      isNot(contains('not-authoritative')),
    );

    final series = QuestionImportService(
      scope: const AdminQuestionScope(
        contentArea: AdminQuestionScope.contentAreaTestSeries,
        courseId: 'group-ii',
        testSeriesCategory: AdminQuestionScope.categoryPart,
        paperId: 'group-ii-paper-i',
      ),
      questionRepository: QuestionCloudRepository.withHandlers(
        createBatch: ({required items}) async {
          created.add(items.single.data);
        },
        idGenerator: () => 'q-series-import',
      ),
    );
    final seriesResult = await series.validateAndImportJson(
      jsonEncode({
        'questions': [_record()],
      }),
    );
    expect(seriesResult.succeeded, isTrue);
    expect(created[1]['contentArea'], 'testSeries');
    expect(created[1]['questionSearchPrefixes'], contains('mini'));
  });

  test(
    'chapter and test series search stay server-side and page by document id',
    () {
      const contexts = [
        AdminChapterQuestionContext(
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
          majorStudyAreaId: 'area',
          contentTopicId: 'topic',
        ),
        AdminChapterQuestionContext(
          courseId: 'group-ii',
          paperId: 'group-ii-paper-ii',
          partId: 'part',
          topicId: 'topic',
        ),
        AdminChapterQuestionContext(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-i',
          syllabusUnitId: 'unit',
        ),
        AdminChapterQuestionContext(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-ii',
          partId: 'part',
          syllabusUnitId: 'unit',
        ),
      ];
      for (final context in contexts) {
        final query = AdminChapterQuestionQuery.fromContext(
          context,
          status: QuestionPublicationStatus.published,
          searchText: 'constitution date',
          cursorDocumentId: 'q-9',
        );
        expect(query.searchPrefix, 'date');
        expect(query.cursorPlan.arrayContains, 'date');
        expect(query.cursorPlan.orderBy, ['__name__']);
        expect(query.cursorPlan.startAfter, ['q-9']);
        expect(
          query.equalityFilters.any((filter) => filter.field == 'lessonId'),
          isFalse,
        );
        expect(
          query.equalityFilters.any(
            (filter) => filter.field == 'questionSearchText',
          ),
          isFalse,
        );
        final count = AdminChapterQuestionQuery.fromContext(
          context,
          status: QuestionPublicationStatus.published,
          searchText: 'date',
        );
        expect(count.cursorPlan.arrayContains, 'date');
        expect(count.cursorPlan.startAfter, isNull);
      }

      final series = AdminTestSeriesQuestionQuery.fromScope(
        const AdminQuestionScope(
          contentArea: AdminQuestionScope.contentAreaTestSeries,
          courseId: 'group-ii',
          testSeriesCategory: AdminQuestionScope.categoryPart,
          paperId: 'group-ii-paper-i',
        ),
        searchText: 'mini constitution',
        cursorDocumentId: 'q-4',
      );
      expect(series.searchPrefix, 'constitution');
      expect(series.cursorPlan.arrayContains, 'constitution');
      expect(series.cursorPlan.startAfter, ['q-4']);
      expect(
        series.equalityFilters.any((filter) => filter.value == 'chapter'),
        isFalse,
      );
      final cleared = AdminChapterQuestionQuery.fromContext(
        contexts.first,
        searchText: ' ',
      );
      expect(cleared.searchPrefix, isNull);
      expect(cleared.cursorPlan.arrayContains, isNull);
      expect(cleared.cursorPlan.orderBy, ['__name__']);
    },
  );
}

Question _question(String text, {String id = ''}) {
  final now = DateTime(2026, 9, 28);
  return Question(
    id: id,
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    question: text,
    options: const ['A', 'B', 'C', 'D'],
    correctOption: 'A',
    explanation: 'Because.',
    difficulty: QuestionDifficulty.medium,
    questionType: QuestionType.practice,
    marks: 1,
    negativeMarks: 0,
    tags: const [],
    estimatedTime: const Duration(seconds: 30),
    createdAt: now,
    updatedAt: now,
    isActive: false,
    status: QuestionPublicationStatus.draft,
    content: QuestionContent(
      en: QuestionLocalizedContent(
        question: text,
        options: const [
          QuestionOption(text: 'A'),
          QuestionOption(text: 'B'),
          QuestionOption(text: 'C'),
          QuestionOption(text: 'D'),
        ],
        explanation: 'Because.',
      ),
      te: const QuestionLocalizedContent(
        question: 'తెలుగు ప్రశ్న',
        options: [
          QuestionOption(text: 'ఎ'),
          QuestionOption(text: 'బి'),
          QuestionOption(text: 'సి'),
          QuestionOption(text: 'డి'),
        ],
        explanation: 'కారణం.',
      ),
    ),
    syllabus: const QuestionSyllabusAttribution(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      majorStudyAreaId: 'group-ii-paper-i-area-01',
      contentTopicId: 'group-ii-paper-i-area-01-topic-01',
    ),
  );
}

Map<String, dynamic> _record() {
  return {
    'question': {
      'en': 'The Mini-Constitution answered the date question.',
      'te': 'తెలుగు ప్రశ్న',
    },
    'options': [
      {'en': 'One', 'te': 'ఒకటి'},
      {'en': 'Two', 'te': 'రెండు'},
      {'en': 'Three', 'te': 'మూడు'},
      {'en': 'Four', 'te': 'నాలుగు'},
    ],
    'correctOption': 'A',
    'explanation': {'en': 'Because.', 'te': 'కారణం.'},
  };
}
