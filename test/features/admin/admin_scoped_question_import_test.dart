import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_chapter_question_context.dart';
import 'package:telangana_prep/features/admin/data/admin_question_scope.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_import_screen.dart';
import 'package:telangana_prep/features/admin/services/question_import_parser.dart';
import 'package:telangana_prep/features/admin/services/question_import_validator.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';
import 'package:telangana_prep/features/tests/data/grand_test_series.dart';

void main() {
  final syllabus = SyllabusService.instance;

  Map<String, dynamic> contentOnly({String? courseId, String? lessonId}) {
    return {
      'courseId': ?courseId,
      'lessonId': ?lessonId,
      'question': {'en': 'Scoped import question', 'te': 'స్కోప్ ప్రశ్న'},
      'options': [
        {'en': 'One', 'te': 'ఒకటి'},
        {'en': 'Two', 'te': 'రెండు'},
        {'en': 'Three', 'te': 'మూడు'},
        {'en': 'Four', 'te': 'నాలుగు'},
      ],
      'correctOption': 'A',
      'explanation': {'en': 'Because', 'te': 'ఎందుకంటే'},
    };
  }

  String wrap(Map<String, dynamic> record) => jsonEncode({
    'questions': [record],
  });

  AdminChapterQuestionContext paperI() {
    final paper = syllabus
        .getCourseById('group-ii')!
        .papers
        .firstWhere((item) => item.hasCanonicalPaperIContent);
    final area = paper.majorStudyAreas.first;
    return AdminChapterQuestionContext(
      courseId: 'group-ii',
      paperId: paper.id,
      majorStudyAreaId: area.id,
      contentTopicId: area.contentTopics.first.id,
    );
  }

  AdminChapterQuestionContext paperII({bool withLesson = false}) {
    final paper = syllabus
        .getCourseById('group-ii')!
        .papers
        .firstWhere((item) => item.id == 'group-ii-paper-ii');
    final part = paper.parts.firstWhere(
      (item) => item.topics.any((topic) => topic.lessons.isNotEmpty),
    );
    final topic = part.topics.firstWhere((item) => item.lessons.isNotEmpty);
    return AdminChapterQuestionContext(
      courseId: 'group-ii',
      paperId: paper.id,
      partId: part.id,
      topicId: topic.id,
      lessonId: withLesson ? topic.lessons.first.id : null,
    );
  }

  AdminChapterQuestionContext groupIiiPaperI() {
    final paper = syllabus
        .getCourseById('group-iii')!
        .papers
        .firstWhere((item) => item.hasDirectSyllabusUnits);
    return AdminChapterQuestionContext(
      courseId: 'group-iii',
      paperId: paper.id,
      syllabusUnitId: paper.syllabusUnits.first.id,
    );
  }

  AdminChapterQuestionContext groupIiiPart() {
    final paper = syllabus
        .getCourseById('group-iii')!
        .papers
        .firstWhere((item) => item.hasPartSyllabusUnits);
    final part = paper.parts.firstWhere(
      (item) => item.syllabusUnits.isNotEmpty,
    );
    return AdminChapterQuestionContext(
      courseId: 'group-iii',
      paperId: paper.id,
      partId: part.id,
      syllabusUnitId: part.syllabusUnits.first.id,
    );
  }

  test('scoped Group-II Paper I content-only JSON validates', () async {
    final context = paperI();
    final result = await QuestionImportValidator(
      chapterContext: context,
    ).validate(QuestionImportParser.parseJson(wrap(contentOnly())));
    expect(result.canImport, isTrue);
    final question = result.validatedQuestions.single;
    expect(question.courseId, context.courseId);
    expect(question.paperId, context.paperId);
    expect(question.syllabus?.majorStudyAreaId, context.majorStudyAreaId);
    expect(question.syllabus?.contentTopicId, context.contentTopicId);
    expect(question.status, QuestionPublicationStatus.draft);
    expect(question.isActive, isFalse);
  });

  test('scoped Group-II Paper II content-only JSON validates', () async {
    final context = paperII();
    final result = await QuestionImportValidator(
      chapterContext: context,
    ).validate(QuestionImportParser.parseJson(wrap(contentOnly())));
    expect(result.canImport, isTrue);
    final question = result.validatedQuestions.single;
    expect(question.partId, context.partId);
    expect(question.syllabus?.topicId, context.topicId);
    expect(question.lessonId, isNull);
  });

  test('lesson context is inherited when the endpoint selected one', () async {
    final context = paperII(withLesson: true);
    final result = await QuestionImportValidator(
      chapterContext: context,
    ).validate(QuestionImportParser.parseJson(wrap(contentOnly())));
    expect(result.canImport, isTrue);
    expect(result.validatedQuestions.single.lessonId, context.lessonId);
  });

  test('scoped Group-III Paper I content-only JSON validates', () async {
    final context = groupIiiPaperI();
    final result = await QuestionImportValidator(
      chapterContext: context,
    ).validate(QuestionImportParser.parseJson(wrap(contentOnly())));
    expect(result.canImport, isTrue);
    expect(
      result.validatedQuestions.single.syllabus?.syllabusUnitId,
      context.syllabusUnitId,
    );
    expect(result.validatedQuestions.single.partId, isNull);
  });

  test('scoped Group-III part paper content-only JSON validates', () async {
    final context = groupIiiPart();
    final result = await QuestionImportValidator(
      chapterContext: context,
    ).validate(QuestionImportParser.parseJson(wrap(contentOnly())));
    expect(result.canImport, isTrue);
    final question = result.validatedQuestions.single;
    expect(question.partId, context.partId);
    expect(question.syllabus?.syllabusUnitId, context.syllabusUnitId);
  });

  test('explicit matching hierarchy IDs stay accepted', () async {
    final context = paperI();
    final record = contentOnly()
      ..['courseId'] = context.courseId
      ..['paperId'] = context.paperId
      ..['majorStudyAreaId'] = context.majorStudyAreaId
      ..['contentTopicId'] = context.contentTopicId;
    final result = await QuestionImportValidator(
      chapterContext: context,
    ).validate(QuestionImportParser.parseJson(wrap(record)));
    expect(result.canImport, isTrue);
  });

  test('explicit conflicting hierarchy IDs are rejected', () async {
    final context = paperII(withLesson: true);
    final record = contentOnly(courseId: 'group-iii', lessonId: 'other-lesson');
    final result = await QuestionImportValidator(
      chapterContext: context,
    ).validate(QuestionImportParser.parseJson(wrap(record)));
    expect(result.canImport, isFalse);
    expect(
      result.errors.map((issue) => issue.field),
      containsAll(['courseId', 'lessonId']),
    );
    expect(
      result.errors.every(
        (issue) =>
            issue.message.contains('cannot override the selected chapter'),
      ),
      isTrue,
    );
  });

  test('content-only JSON without a selected scope is rejected', () async {
    final result = await QuestionImportValidator().validate(
      QuestionImportParser.parseJson(wrap(contentOnly())),
    );
    expect(result.canImport, isFalse);
    expect(result.errors.single.field, 'courseId');
  });

  test('Test Series scoped import inherits the selected bank', () async {
    const scope = AdminQuestionScope(
      contentArea: AdminQuestionScope.contentAreaTestSeries,
      courseId: 'group-ii',
      testSeriesCategory: AdminQuestionScope.categoryMock,
      seriesId: GrandTestSeries.grandTestII,
    );
    final result = await QuestionImportValidator(
      scope: scope,
    ).validate(QuestionImportParser.parseJson(wrap(contentOnly())));
    expect(result.canImport, isTrue);
    expect(result.validatedQuestions.single.courseId, 'group-ii');
    expect(
      result.validatedQuestions.single.status,
      QuestionPublicationStatus.draft,
    );
    expect(result.validatedQuestions.single.isActive, isFalse);

    final conflict = await QuestionImportValidator(scope: scope).validate(
      QuestionImportParser.parseJson(
        wrap(contentOnly()..['courseId'] = 'group-iii'),
      ),
    );
    expect(conflict.canImport, isFalse);
    expect(conflict.errors.single.field, 'courseId');
  });

  testWidgets('scoped import guidance says hierarchy IDs are inherited', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: AdminQuestionImportScreen(chapterContext: paperI())),
    );
    await tester.pumpAndSettle();
    final guidance = find.byKey(const ValueKey('import-format-guidance'));
    expect(guidance, findsOneWidget);
    expect(
      tester.widget<Text>(guidance).data,
      contains('inherited from the selected chapter'),
    );
    expect(
      tester.widget<Text>(guidance).data,
      contains('Do not paste courseId'),
    );
  });
}
