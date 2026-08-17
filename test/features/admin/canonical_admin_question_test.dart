import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';

void main() {
  Question canonical({
    String id = '',
    QuestionPublicationStatus status = QuestionPublicationStatus.draft,
    bool paperI = true,
  }) {
    final now = DateTime(2026, 8, 10);
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: paperI ? 'group-ii-paper-i' : 'group-ii-paper-ii',
      question: 'Which city is the capital?',
      options: const ['Warangal', 'Hyderabad', 'Nizamabad', 'Karimnagar'],
      correctOption: 'B',
      explanation: 'Hyderabad is the capital.',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: status == QuestionPublicationStatus.published,
      status: status,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Which city is the capital?',
          options: [
            QuestionOption(text: 'Warangal'),
            QuestionOption(text: 'Hyderabad'),
            QuestionOption(text: 'Nizamabad'),
            QuestionOption(text: 'Karimnagar'),
          ],
          explanation: 'Hyderabad is the capital.',
        ),
        te: QuestionLocalizedContent(
          question: 'రాజధాని నగరం ఏది?',
          options: [
            QuestionOption(text: 'వరంగల్'),
            QuestionOption(text: 'హైదరాబాద్'),
            QuestionOption(text: 'నిజామాబాద్'),
            QuestionOption(text: 'కరీంనగర్'),
          ],
          explanation: 'హైదరాబాద్ రాజధాని.',
        ),
      ),
      syllabus: QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: paperI ? 'group-ii-paper-i' : 'group-ii-paper-ii',
        majorStudyAreaId: paperI ? 'group-ii-paper-i-area-1' : null,
        contentTopicId: paperI ? 'group-ii-paper-i-area-1-topic-1' : null,
        partId: paperI ? null : 'group-ii-paper-ii-part-1',
        topicId: paperI ? null : 'group-ii-paper-ii-part-1-topic-1',
        lessonId: null,
      ),
    );
  }

  test(
    'creates a bilingual question as a draft through the repository',
    () async {
      Map<String, dynamic>? created;
      final service = AdminQuestionService(
        questionRepository: QuestionCloudRepository.withHandlers(
          idGenerator: () => 'q-draft',
          create: ({required questionId, required data}) async {
            created = data;
          },
        ),
      );

      await service.createQuestion(canonical());

      expect(created?['status'], 'draft');
      expect(created?['isActive'], isFalse);
      expect(
        (created?['content'] as Map<String, dynamic>)['en'],
        isA<Map<String, dynamic>>(),
      );
    },
  );

  test('Paper I requires area and content topic, without Part or Lesson', () {
    final question = canonical();
    final errors = AdminQuestionService().validate(
      question,
      documentId: 'generated-id',
    );

    expect(errors, isEmpty);
    expect(question.syllabus!.partId, isNull);
    expect(question.syllabus!.lessonId, isNull);
  });

  test('Papers II–IV require Part and Topic and may carry a Lesson', () {
    final question = canonical(paperI: false);
    final errors = AdminQuestionService().validate(
      question,
      documentId: 'generated-id',
    );

    expect(errors, isEmpty);
    expect(question.syllabus!.partId, isNotNull);
    expect(question.syllabus!.topicId, isNotNull);
  });

  test('validation requires both languages and four paired options', () {
    final question = canonical().copyWithForTest(
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: '',
          options: [QuestionOption(text: 'Only one')],
          explanation: '',
        ),
        te: QuestionLocalizedContent(
          question: '',
          options: [],
          explanation: '',
        ),
      ),
    );
    final errors = AdminQuestionService().validate(
      question,
      documentId: 'generated-id',
    );

    expect(errors, contains('English question is required.'));
    expect(errors, contains('Exactly four English options are required.'));
    expect(errors, contains('Exactly four Telugu options are required.'));
  });

  test('draft, published, and archived status controls student visibility', () {
    final draft = canonical();
    final published = canonical(status: QuestionPublicationStatus.published);
    final archived = canonical(status: QuestionPublicationStatus.archived);

    expect(draft.isPublished, isFalse);
    expect(published.isPublished, isTrue);
    expect(archived.isPublished, isFalse);
    expect(
      QuestionCloudMapper.toFirestore(
        draft,
        includeCreatedAt: true,
        documentId: 'q-draft',
      )['isActive'],
      isFalse,
    );
  });
}

extension on Question {
  Question copyWithForTest({QuestionContent? content}) {
    return Question(
      id: id,
      courseId: courseId,
      paperId: paperId,
      correctOption: correctOption,
      difficulty: difficulty,
      questionType: questionType,
      marks: marks,
      negativeMarks: negativeMarks,
      tags: tags,
      estimatedTime: estimatedTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      content: content ?? this.content,
      syllabus: syllabus,
      status: status,
      isActive: isActive,
    );
  }
}
