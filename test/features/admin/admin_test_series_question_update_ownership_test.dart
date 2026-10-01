import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/tests/data/grand_test_series.dart';

void main() {
  const bilingualContent = QuestionContent(
    en: QuestionLocalizedContent(
      question: 'Stem',
      options: [
        QuestionOption(text: 'A'),
        QuestionOption(text: 'B'),
        QuestionOption(text: 'C'),
        QuestionOption(text: 'D'),
      ],
      explanation: 'Because',
    ),
    te: QuestionLocalizedContent(
      question: 'ప్రశ్న',
      options: [
        QuestionOption(text: 'ఎ'),
        QuestionOption(text: 'బి'),
        QuestionOption(text: 'సి'),
        QuestionOption(text: 'డి'),
      ],
      explanation: 'ఎందుకంటే',
    ),
  );

  Question base({
    required String id,
    String courseId = 'group-ii',
    String paperId = 'group-ii-paper-i',
    String? contentArea,
    String? testSeriesCategory,
    String? seriesId,
    int? year,
    QuestionSyllabusAttribution? syllabus,
  }) {
    final now = DateTime(2026, 10, 1);
    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      question: 'Stem',
      options: const ['A', 'B', 'C', 'D'],
      correctOption: 'A',
      explanation: 'Because',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: QuestionPublicationStatus.draft,
      content: bilingualContent,
      syllabus: syllabus,
      contentArea: contentArea,
      testSeriesCategory: testSeriesCategory,
      seriesId: seriesId,
      year: year,
    );
  }

  test('grand test series update preserves mock ownership', () async {
    Map<String, dynamic>? written;
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        update: ({required questionId, required data}) async {
          written = data;
        },
      ),
    );
    await service.updateQuestion(
      base(
        id: 'q-grand',
        paperId: '',
        contentArea: AdminQuestionScope.contentAreaTestSeries,
        testSeriesCategory: AdminQuestionScope.categoryMock,
        seriesId: GrandTestSeries.grandTestII,
      ),
    );
    expect(written?['contentArea'], 'testSeries');
    expect(written?['testSeriesCategory'], 'mock');
    expect(written?['seriesId'], GrandTestSeries.grandTestII);
    expect(written?.containsKey('paperId'), isFalse);
  });

  test('previous papers update preserves year ownership', () async {
    Map<String, dynamic>? written;
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        update: ({required questionId, required data}) async {
          written = data;
        },
      ),
    );
    await service.updateQuestion(
      Question(
        id: 'q-prev',
        courseId: 'group-ii',
        paperId: '',
        question: 'Stem',
        options: const ['A', 'B', 'C', 'D'],
        correctOption: 'A',
        explanation: 'Because',
        difficulty: QuestionDifficulty.easy,
        questionType: QuestionType.previousYear,
        marks: 1,
        negativeMarks: 0,
        tags: const [],
        estimatedTime: const Duration(seconds: 60),
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
        status: QuestionPublicationStatus.draft,
        content: bilingualContent,
        contentArea: AdminQuestionScope.contentAreaTestSeries,
        testSeriesCategory: AdminQuestionScope.categoryPreviousYear,
        year: 2024,
      ),
    );
    expect(written?['contentArea'], 'testSeries');
    expect(written?['testSeriesCategory'], 'previousyear');
    expect(written?['year'], 2024);
    expect(written?.containsKey('paperId'), isFalse);
  });

  test('chapter update does not inject test series ownership', () async {
    Map<String, dynamic>? written;
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        update: ({required questionId, required data}) async {
          written = data;
        },
      ),
    );
    await service.updateQuestion(
      base(
        id: 'q-chapter',
        syllabus: const QuestionSyllabusAttribution(
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
          majorStudyAreaId: 'group-ii-paper-i-area-1',
          contentTopicId: 'group-ii-paper-i-area-1-topic-1',
        ),
      ),
    );
    expect(written?['contentArea'], 'chapter');
    expect(written?.containsKey('testSeriesCategory'), isFalse);
    expect(written?['majorStudyAreaId'], 'group-ii-paper-i-area-1');
  });

  test('legacy question without ownership is not auto-classified', () async {
    Map<String, dynamic>? written;
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        update: ({required questionId, required data}) async {
          written = data;
        },
      ),
    );
    await service.updateQuestion(
      base(
        id: 'q-legacy',
        syllabus: const QuestionSyllabusAttribution(
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
          majorStudyAreaId: 'group-ii-paper-i-area-1',
          contentTopicId: 'group-ii-paper-i-area-1-topic-1',
        ),
      ),
    );
    expect(written?['contentArea'], 'chapter');
    expect(written?.containsKey('testSeriesCategory'), isFalse);
  });

  test('test series without valid bank scope does not invent category', () async {
    Map<String, dynamic>? written;
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        update: ({required questionId, required data}) async {
          written = data;
        },
      ),
    );
    expect(
      () => service.updateQuestion(
        base(
          id: 'q-incomplete',
          contentArea: AdminQuestionScope.contentAreaTestSeries,
        ),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(written, isNull);
  });
}
