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

  Question statementCanonical() {
    final now = DateTime(2026, 8, 10);
    return Question(
      id: 'q-statement',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: 'Consider the following statements.',
      options: const [
        '1 and 3 only',
        '2 and 3 only',
        '1 and 2 only',
        '1, 2 and 3',
      ],
      correctOption: 'B',
      explanation: 'Statements 2 and 3 are correct.',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      isActive: false,
      status: QuestionPublicationStatus.draft,
      itemFormat: QuestionItemFormat.statementMcq,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Consider the following statements.',
          options: [
            QuestionOption(text: '1 and 3 only'),
            QuestionOption(text: '2 and 3 only'),
            QuestionOption(text: '1 and 2 only'),
            QuestionOption(text: '1, 2 and 3'),
          ],
          explanation: 'Statements 2 and 3 are correct.',
          statements: [
            'Inserted by the 32nd Amendment.',
            'The tribunal is excluded from Article 226.',
            'The President may provide equitable opportunities.',
          ],
        ),
        te: QuestionLocalizedContent(
          question: 'కింది ప్రకటనలను పరిశీలించండి.',
          options: [],
          explanation: 'ప్రకటనలు 2 మరియు 3 సరైనవి.',
          statements: [
            '32వ సవరణ ద్వారా చేర్చారు.',
            'ట్రిబ్యునల్ అధికరణ 226 నుండి మినహాయించబడింది.',
            'రాష్ట్రపతి సమాన అవకాశాలు కల్పించవచ్చు.',
          ],
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

  test('missing itemFormat still requires bilingual Telugu options', () {
    final question = canonical().copyWithForTest(
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
          options: [],
          explanation: 'హైదరాబాద్ రాజధాని.',
        ),
      ),
    );

    expect(question.itemFormat, isNull);
    expect(question.resolvedItemFormat, QuestionItemFormat.standardMcq);
    expect(
      AdminQuestionService().validate(question, documentId: 'generated-id'),
      contains('Exactly four Telugu options are required.'),
    );
  });

  test('statement_mcq validates without Telugu options', () {
    final question = statementCanonical();
    final errors = AdminQuestionService().validate(
      question,
      documentId: question.id,
    );

    expect(errors, isEmpty);
    expect(question.content!.te!.options, isEmpty);

    final firestore = QuestionCloudMapper.toFirestore(
      question,
      documentId: 'q-statement',
    );
    final te = (firestore['content'] as Map)['te'] as Map;
    expect(te.containsKey('options'), isFalse);
  });

  test(
    'statement_mcq requires bilingual statements and four English options',
    () {
      final question = statementCanonical().copyWithForTest(
        itemFormat: QuestionItemFormat.statementMcq,
        content: const QuestionContent(
          en: QuestionLocalizedContent(
            question: 'Consider the following statements.',
            options: [
              QuestionOption(text: '1 only'),
              QuestionOption(text: '2 only'),
              QuestionOption(text: 'Both'),
              QuestionOption(text: 'Neither'),
            ],
            explanation: 'Statement 1 is correct.',
            statements: ['', 'Second'],
          ),
          te: QuestionLocalizedContent(
            question: 'కింది ప్రకటనలను పరిశీలించండి.',
            options: [],
            explanation: 'ప్రకటన 1 సరైనది.',
            statements: ['మొదటి'],
          ),
        ),
      );
      final errors = AdminQuestionService().validate(
        question,
        documentId: 'generated-id',
      );

      expect(errors, contains('English text is required for every statement.'));
      expect(
        errors,
        contains('English and Telugu statement counts must match.'),
      );
      expect(
        errors,
        isNot(contains('Exactly four Telugu options are required.')),
      );
    },
  );

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
  Question copyWithForTest({
    QuestionContent? content,
    QuestionItemFormat? itemFormat,
  }) {
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
      content: content ?? this.content,
      syllabus: syllabus,
      status: status,
      isActive: isActive,
      itemFormat: itemFormat ?? this.itemFormat,
    );
  }
}
