import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_form_screen.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/admin/services/question_import_parser.dart';
import 'package:telangana_prep/features/admin/services/question_import_validator.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/tests/data/grand_test_series.dart';
import 'dart:convert';

void main() {
  const paperScope = AdminQuestionScope(
    contentArea: AdminQuestionScope.contentAreaTestSeries,
    courseId: 'group-ii',
    testSeriesCategory: AdminQuestionScope.categoryPart,
    paperId: 'group-ii-paper-iv',
  );

  Question paperWiseQuestion() {
    final now = DateTime(2026, 10, 1);
    return Question(
      id: 'q-paper-iv',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-iv',
      question: 'Paper IV stem',
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
      isActive: false,
      contentArea: AdminQuestionScope.contentAreaTestSeries,
      testSeriesCategory: AdminQuestionScope.categoryPart,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Paper IV stem',
          options: [
            QuestionOption(text: 'A'),
            QuestionOption(text: 'B'),
            QuestionOption(text: 'C'),
            QuestionOption(text: 'D'),
          ],
          explanation: 'Because',
        ),
        te: QuestionLocalizedContent(
          question: 'పేపర్ IV',
          options: [
            QuestionOption(text: 'ఎ'),
            QuestionOption(text: 'బి'),
            QuestionOption(text: 'సి'),
            QuestionOption(text: 'డి'),
          ],
          explanation: 'ఎందుకంటే',
        ),
      ),
    );
  }

  testWidgets('paper-wise edit hides Part Topic and Lesson', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AdminQuestionFormScreen(
          question: paperWiseQuestion(),
          service: _CoursesOnly(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Part *'), findsNothing);
    expect(find.text('Topic *'), findsNothing);
    expect(find.text('Lesson *'), findsNothing);
    expect(find.text('Paper-wise'), findsWidgets);
  });

  test('paper-wise question passes client validation without syllabus', () {
    final service = AdminQuestionService();
    final question = paperWiseQuestion();

    expect(question.syllabus, isNull);
    expect(question.partId, isNull);
    expect(question.topicId, isEmpty);
    expect(
      service.validate(question, documentId: question.id),
      isEmpty,
    );
  });

  test('paper-wise question missing paperId is rejected', () {
    final service = AdminQuestionService();
    final question = paperWiseQuestion();
    final missingPaper = Question(
      id: question.id,
      courseId: question.courseId,
      paperId: '',
      question: question.question,
      options: question.options,
      correctOption: question.correctOption,
      explanation: question.explanation,
      difficulty: question.difficulty,
      questionType: question.questionType,
      marks: question.marks,
      negativeMarks: question.negativeMarks,
      tags: question.tags,
      estimatedTime: question.estimatedTime,
      createdAt: question.createdAt,
      updatedAt: question.updatedAt,
      status: question.status,
      isActive: question.isActive,
      contentArea: question.contentArea,
      testSeriesCategory: question.testSeriesCategory,
      content: question.content,
    );

    expect(
      service.validate(missingPaper, documentId: missingPaper.id),
      contains('Paper is required for Paper-wise Test Series questions.'),
    );
  });

  test('paper-wise question rejects chapter hierarchy attribution', () {
    final service = AdminQuestionService();
    final question = paperWiseQuestion();
    final withPart = Question(
      id: question.id,
      courseId: question.courseId,
      paperId: question.paperId,
      question: question.question,
      options: question.options,
      correctOption: question.correctOption,
      explanation: question.explanation,
      difficulty: question.difficulty,
      questionType: question.questionType,
      marks: question.marks,
      negativeMarks: question.negativeMarks,
      tags: question.tags,
      estimatedTime: question.estimatedTime,
      createdAt: question.createdAt,
      updatedAt: question.updatedAt,
      status: question.status,
      isActive: question.isActive,
      contentArea: question.contentArea,
      testSeriesCategory: question.testSeriesCategory,
      content: question.content,
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-iv',
        partId: 'group-ii-paper-iv-part-01',
        topicId: 'topic',
      ),
    );

    expect(
      service.validate(withPart, documentId: withPart.id).any(
        (error) => error.contains('partId'),
      ),
      isTrue,
    );
  });

  test('paper-wise edit update succeeds through the service', () async {
    var updated = false;
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        update: ({required questionId, required data}) async {
          updated = true;
          expect(questionId, 'q-paper-iv');
          expect(data['contentArea'], 'testSeries');
          expect(data['testSeriesCategory'], 'part');
          expect(data['courseId'], 'group-ii');
          expect(data['paperId'], 'group-ii-paper-iv');
          for (final field in const [
            'partId',
            'topicId',
            'lessonId',
            'majorStudyAreaId',
            'contentTopicId',
            'syllabusUnitId',
          ]) {
            expect(data.containsKey(field), isFalse);
          }
        },
      ),
    );

    await service.updateQuestion(paperWiseQuestion());
    expect(updated, isTrue);
  });

  test('published paper-wise question does not require canonical syllabus', () {
    final service = AdminQuestionService();
    final published = paperWiseQuestion().copyWithStatus(
      QuestionPublicationStatus.published,
    );
    expect(
      service.validate(published, documentId: published.id),
      isEmpty,
    );
  });

  test('grand and previous test series questions skip chapter syllabus', () {
    final service = AdminQuestionService();
    final now = DateTime(2026, 10, 1);
    const content = QuestionContent(
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
    final grand = Question(
      id: 'q-grand',
      courseId: 'group-ii',
      paperId: '',
      question: 'Stem',
      options: const ['A', 'B', 'C', 'D'],
      correctOption: 'A',
      explanation: 'Because',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.mock,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: QuestionPublicationStatus.draft,
      contentArea: AdminQuestionScope.contentAreaTestSeries,
      testSeriesCategory: AdminQuestionScope.categoryMock,
      seriesId: GrandTestSeries.grandTestII,
      content: content,
    );
    final previous = Question(
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
      createdAt: now,
      updatedAt: now,
      status: QuestionPublicationStatus.draft,
      contentArea: AdminQuestionScope.contentAreaTestSeries,
      testSeriesCategory: AdminQuestionScope.categoryPreviousYear,
      year: 2024,
      content: content,
    );

    expect(service.validate(grand, documentId: grand.id), isEmpty);
    expect(service.validate(previous, documentId: previous.id), isEmpty);
  });

  test('legacy chapter question still requires canonical syllabus', () {
    final service = AdminQuestionService();
    final now = DateTime(2026, 10, 1);
    final legacy = Question(
      id: 'q-legacy',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
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
      content: paperWiseQuestion().content,
    );

    expect(
      service.validate(legacy, documentId: legacy.id),
      contains('Canonical syllabus attribution is required.'),
    );
  });

  test('paper-wise import rejects chapter hierarchy fields', () async {
    final record = {
      'partId': 'group-ii-paper-iv-part-01',
      'topicId': 'topic',
      'question': {'en': 'Stem', 'te': 'ప్రశ్న'},
      'options': [
        {'en': 'A', 'te': 'ఎ'},
        {'en': 'B', 'te': 'బి'},
        {'en': 'C', 'te': 'సి'},
        {'en': 'D', 'te': 'డి'},
      ],
      'correctOption': 'A',
      'explanation': {'en': 'Because', 'te': 'ఎందుకంటే'},
    };
    final result = await QuestionImportValidator(scope: paperScope).validate(
      QuestionImportParser.parseJson(jsonEncode({'questions': [record]})),
    );
    expect(result.canImport, isFalse);
    expect(
      result.errors.map((issue) => issue.field),
      containsAll(['partId', 'topicId']),
    );
  });
}

extension on Question {
  Question copyWithStatus(QuestionPublicationStatus status) {
    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      question: question,
      options: options,
      correctOption: correctOption,
      explanation: explanation,
      difficulty: difficulty,
      questionType: questionType,
      marks: marks,
      negativeMarks: negativeMarks,
      tags: tags,
      estimatedTime: estimatedTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      isActive: status == QuestionPublicationStatus.published,
      contentArea: contentArea,
      testSeriesCategory: testSeriesCategory,
      seriesId: seriesId,
      year: year,
      content: content,
    );
  }
}

class _CoursesOnly extends AdminQuestionService {
  _CoursesOnly() : super();

  @override
  Future<List<Course>> loadCourses() async => const [
    Course(
      courseId: 'group-ii',
      title: 'Group-II',
      shortTitle: 'G-II',
      description: '',
      thumbnail: null,
      icon: null,
      color: null,
      isFree: false,
      isPublished: true,
      price: 0,
      sortOrder: 1,
      createdAt: null,
      updatedAt: null,
    ),
  ];
}
