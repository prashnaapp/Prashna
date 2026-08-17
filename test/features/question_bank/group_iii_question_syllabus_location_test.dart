import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_question_form.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  Question groupIiiQuestion({
    String paperId = 'group-iii-paper-ii',
    String? partId = 'group-iii-paper-ii-part-i',
    String? syllabusUnitId = 'group-iii-paper-ii-part-i-unit-02',
    String? topicId,
    String? lessonId,
  }) {
    return Question(
      id: 'q-giii-kakatiya-01',
      courseId: 'group-iii',
      paperId: paperId,
      correctOption: 'A',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: QuestionPublicationStatus.draft,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Who founded the Kakatiya kingdom?',
          options: [
            QuestionOption(text: 'Prola I'),
            QuestionOption(text: 'Rudrama Devi'),
            QuestionOption(text: 'Prataparudra'),
            QuestionOption(text: 'Ganapati Deva'),
          ],
          explanation: 'Prola I is associated with early Kakatiya rule.',
        ),
        te: QuestionLocalizedContent(
          question: 'కాకతీయ రాజ్యాన్ని ఎవరు స్థాపించారు?',
          options: [
            QuestionOption(text: 'ప్రోల I'),
            QuestionOption(text: 'రుద్రమదేవి'),
            QuestionOption(text: 'ప్రతాపరుద్ర'),
            QuestionOption(text: 'గణపతి దేవ'),
          ],
          explanation: 'ప్రారంభ కాకతీయ పాలన ప్రోల I తో ముడిపడి ఉంది.',
        ),
      ),
      syllabus: QuestionSyllabusAttribution(
        courseId: 'group-iii',
        paperId: paperId,
        partId: partId,
        topicId: topicId,
        lessonId: lessonId,
        syllabusUnitId: syllabusUnitId,
      ),
    );
  }

  Question groupIiQuestion() {
    return Question(
      id: 'q-gii-001',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-iii',
      correctOption: 'B',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const ['group-ii'],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: QuestionPublicationStatus.draft,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'What is the capital of Telangana?',
          options: [
            QuestionOption(text: 'Warangal'),
            QuestionOption(text: 'Hyderabad'),
            QuestionOption(text: 'Nizamabad'),
            QuestionOption(text: 'Karimnagar'),
          ],
          explanation: 'Hyderabad is the capital.',
        ),
        te: QuestionLocalizedContent(
          question: 'తెలంగాణ రాజధాని ఏది?',
          options: [
            QuestionOption(text: 'వరంగల్'),
            QuestionOption(text: 'హైదరాబాద్'),
            QuestionOption(text: 'నిజామాబాద్'),
            QuestionOption(text: 'కరీంనగర్'),
          ],
          explanation: 'హైదరాబాద్ రాజధాని.',
        ),
      ),
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-iii',
        partId: 'group-ii-paper-iii-part-01',
        topicId: 'group-ii-paper-iii-part-01-topic-01',
        lessonId: 'group-ii-paper-iii-part-01-topic-01-lesson-01',
      ),
    );
  }

  const courses = [
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
    Course(
      courseId: 'group-iii',
      title: 'Group-III',
      shortTitle: 'G-III',
      description: '',
      thumbnail: null,
      icon: null,
      color: null,
      isFree: false,
      isPublished: true,
      price: 0,
      sortOrder: 2,
      createdAt: null,
      updatedAt: null,
    ),
  ];

  test('1/2: Group-III question serializes partId and syllabusUnitId', () {
    final data = QuestionCloudMapper.toFirestore(
      groupIiiQuestion(),
      documentId: 'q-giii-kakatiya-01',
    );

    expect(data['courseId'], 'group-iii');
    expect(data['paperId'], 'group-iii-paper-ii');
    expect(data['partId'], 'group-iii-paper-ii-part-i');
    expect(data['syllabusUnitId'], 'group-iii-paper-ii-part-i-unit-02');
    expect(data.containsKey('lessonId'), isFalse);
    expect(data.containsKey('majorStudyAreaId'), isFalse);
  });

  test('3: Group-III question deserializes partId and syllabusUnitId', () {
    final data = QuestionCloudMapper.toFirestore(
      groupIiiQuestion(),
      documentId: 'q-giii-kakatiya-01',
    );
    final restored = QuestionCloudMapper.fromFirestore(
      'q-giii-kakatiya-01',
      data..remove('updatedAt'),
    );

    expect(restored, isNotNull);
    expect(restored!.partId, 'group-iii-paper-ii-part-i');
    expect(restored.syllabusUnitId, 'group-iii-paper-ii-part-i-unit-02');
  });

  test('4: empty optional Group-III fields are omitted', () {
    final data = QuestionCloudMapper.toFirestore(
      groupIiiQuestion(partId: null, syllabusUnitId: null),
      documentId: 'q-giii-kakatiya-01',
    );

    expect(data.containsKey('partId'), isFalse);
    expect(data.containsKey('syllabusUnitId'), isFalse);
  });

  test('5: Group-II question serialization remains unchanged', () {
    final data = QuestionCloudMapper.toFirestore(
      groupIiQuestion(),
      documentId: 'q-gii-001',
    );

    expect(data['courseId'], 'group-ii');
    expect(data['partId'], 'group-ii-paper-iii-part-01');
    expect(data['topicId'], 'group-ii-paper-iii-part-01-topic-01');
    expect(data['lessonId'], 'group-ii-paper-iii-part-01-topic-01-lesson-01');
    expect(data.containsKey('syllabusUnitId'), isFalse);
  });

  test('6: Group-II question deserialization remains unchanged', () {
    final data = QuestionCloudMapper.toFirestore(
      groupIiQuestion(),
      documentId: 'q-gii-001',
    );
    final restored = QuestionCloudMapper.fromFirestore(
      'q-gii-001',
      data..remove('updatedAt'),
    );

    expect(restored!.partId, 'group-ii-paper-iii-part-01');
    expect(restored.syllabus!.topicId, 'group-ii-paper-iii-part-01-topic-01');
    expect(restored.lessonId, 'group-ii-paper-iii-part-01-topic-01-lesson-01');
    expect(restored.syllabusUnitId, isNull);
  });

  test('7: Group-III Paper-II requires Part', () {
    final errors = AdminQuestionService().validate(
      groupIiiQuestion(partId: null),
      documentId: 'q-giii-kakatiya-01',
    );

    expect(
      errors.any((error) => error.contains('Part is required')),
      isTrue,
    );
  });

  test('8: Group-III Paper-I does not require Part', () {
    final errors = AdminQuestionService().validate(
      groupIiiQuestion(
        paperId: 'group-iii-paper-i',
        partId: null,
        syllabusUnitId: 'group-iii-paper-i-unit-01',
      ),
      documentId: 'q-giii-kakatiya-01',
    );

    expect(errors, isEmpty);
  });

  testWidgets(
    '9: Admin form displays canonical Group-III units for Kakatiya location',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminQuestionForm(
              courses: courses,
              initialQuestion: groupIiiQuestion(),
              onSubmit: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('group-iii-question-syllabus')),
        findsOneWidget,
      );
      expect(find.text('Group-III syllabus location'), findsOneWidget);
      expect(find.text('Syllabus Unit *'), findsOneWidget);
      expect(find.text('Part *'), findsOneWidget);
      expect(find.text('Kakatiyas and Medieval Telangana'), findsOneWidget);
    },
  );

  testWidgets('10: Group-III form has no Topic/Lesson levels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminQuestionForm(
            courses: courses,
            initialQuestion: groupIiiQuestion(),
            onSubmit: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Topic *'), findsNothing);
    expect(find.text('Lesson'), findsNothing);
    expect(find.text('Major Study Area *'), findsNothing);
    expect(find.text('Content Topic *'), findsNothing);
    expect(find.byKey(const ValueKey('group-ii-question-syllabus')), findsNothing);
  });
}
