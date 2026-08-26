import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  final now = DateTime(2026, 8, 26);

  Question standardQuestion({
    QuestionItemFormat? itemFormat,
    List<String> enStatements = const [],
    List<String> teStatements = const [],
  }) {
    return Question(
      id: 'q-format-001',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: 'Consider the following statements.',
      options: const ['1 only', '2 only', 'Both 1 and 2', 'Neither 1 nor 2'],
      correctOption: 'A',
      explanation: 'Statement 1 is correct.',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      itemFormat: itemFormat,
      content: QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Consider the following statements.',
          options: const [
            QuestionOption(text: '1 only'),
            QuestionOption(text: '2 only'),
            QuestionOption(text: 'Both 1 and 2'),
            QuestionOption(text: 'Neither 1 nor 2'),
          ],
          explanation: 'Statement 1 is correct.',
          statements: enStatements,
        ),
        te: QuestionLocalizedContent(
          question: 'కింది ప్రకటనలను పరిశీలించండి.',
          options: const [
            QuestionOption(text: '1 మాత్రమే'),
            QuestionOption(text: '2 మాత్రమే'),
            QuestionOption(text: '1 మరియు 2 రెండూ'),
            QuestionOption(text: '1 లేదా 2 కాదు'),
          ],
          explanation: 'ప్రకటన 1 సరైనది.',
          statements: teStatements,
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

  Map<String, dynamic> withoutServerTimestamp(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(data)..remove('updatedAt');
  }

  test('missing itemFormat is Standard MCQ and omits the field on write', () {
    final original = standardQuestion();
    expect(original.itemFormat, isNull);
    expect(original.resolvedItemFormat, QuestionItemFormat.standardMcq);
    expect(original.questionType, QuestionType.practice);

    final firestore = QuestionCloudMapper.toFirestore(
      original,
      documentId: original.id,
    );
    expect(firestore.containsKey('itemFormat'), isFalse);
    expect(firestore['questionType'], 'practice');
    expect(firestore['question'], 'Consider the following statements.');
    expect(firestore['options'], hasLength(4));
    expect(firestore['correctOption'], 'A');
    expect((firestore['content'] as Map)['en']['question'], isNotEmpty);
    expect((firestore['content'] as Map)['en'].containsKey('statements'), isFalse);

    final restored = QuestionCloudMapper.fromFirestore(
      original.id,
      withoutServerTimestamp(firestore),
    )!;
    expect(restored.itemFormat, isNull);
    expect(restored.resolvedItemFormat, QuestionItemFormat.standardMcq);
    expect(restored.questionType, QuestionType.practice);
    expect(restored.content!.en.statements, isEmpty);
    expect(restored.content!.te!.options[0].text, '1 మాత్రమే');
  });

  test('itemFormat=standard_mcq round-trips without statements', () {
    final original = standardQuestion(itemFormat: QuestionItemFormat.standardMcq);
    final firestore = QuestionCloudMapper.toFirestore(
      original,
      documentId: original.id,
    );
    expect(firestore['itemFormat'], 'standard_mcq');
    expect(firestore['questionType'], 'practice');

    final restored = QuestionCloudMapper.fromFirestore(
      original.id,
      withoutServerTimestamp(firestore),
    )!;
    expect(restored.itemFormat, QuestionItemFormat.standardMcq);
    expect(restored.resolvedItemFormat, QuestionItemFormat.standardMcq);
    expect(restored.content!.en.statements, isEmpty);
  });

  test('legacy Firestore docs without itemFormat remain Standard MCQ', () {
    final restored = QuestionCloudMapper.fromFirestore('q-legacy', {
      'courseId': 'group-ii',
      'paperId': 'paper-1',
      'question': 'Legacy question',
      'options': ['A', 'B', 'C', 'D'],
      'correctOption': 'A',
      'explanation': 'Because',
      'difficulty': 'easy',
      'questionType': 'practice',
      'language': 'en',
      'marks': 1,
      'negativeMarks': 0,
      'estimatedTimeSeconds': 60,
      'isActive': true,
    });

    expect(restored, isNotNull);
    expect(restored!.itemFormat, isNull);
    expect(restored.resolvedItemFormat, QuestionItemFormat.standardMcq);
    expect(restored.questionType, QuestionType.practice);
    expect(restored.content, isNull);
  });

  for (final count in [1, 2, 3, 5, 6]) {
    test('statement_mcq with $count bilingual statements round-trips', () {
      final en = [for (var i = 1; i <= count; i++) 'Statement $i is true.'];
      final te = [for (var i = 1; i <= count; i++) 'ప్రకటన $i సత్యం.'];
      final original = standardQuestion(
        itemFormat: QuestionItemFormat.statementMcq,
        enStatements: en,
        teStatements: te,
      );

      final firestore = QuestionCloudMapper.toFirestore(
        original,
        documentId: original.id,
      );
      expect(firestore['itemFormat'], 'statement_mcq');
      expect(firestore['questionType'], 'practice');
      expect(firestore['options'], hasLength(4));
      expect((firestore['content'] as Map)['en']['statements'], en);
      expect((firestore['content'] as Map)['te']['statements'], te);

      final restored = QuestionCloudMapper.fromFirestore(
        original.id,
        withoutServerTimestamp(firestore),
      )!;
      expect(restored.itemFormat, QuestionItemFormat.statementMcq);
      expect(restored.content!.en.statements, en);
      expect(restored.content!.te!.statements, te);
      expect(restored.content!.en.question, original.content!.en.question);
      expect(restored.content!.en.options.map((o) => o.text), original.options);
    });
  }

  test('mismatched English/Telugu statement lengths fail write validation', () {
    final question = standardQuestion(
      itemFormat: QuestionItemFormat.statementMcq,
      enStatements: const ['One', 'Two'],
      teStatements: const ['ఒకటి'],
    );
    expect(
      QuestionCloudMapper.validateForWrite(question, documentId: question.id),
      contains('English and Telugu statement counts must match.'),
    );
  });

  Question statementWithoutTeluguOptions() {
    return Question(
      id: 'q-stmt-no-te-options',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: 'Consider the following statements.',
      options: const ['1 only', '2 only', 'Both 1 and 2', 'Neither 1 nor 2'],
      correctOption: 'C',
      explanation: 'Both statements are correct.',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      itemFormat: QuestionItemFormat.statementMcq,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Consider the following statements.',
          options: [
            QuestionOption(text: '1 only'),
            QuestionOption(text: '2 only'),
            QuestionOption(text: 'Both 1 and 2'),
            QuestionOption(text: 'Neither 1 nor 2'),
          ],
          explanation: 'Both statements are correct.',
          statements: [
            'Article 371-D applies to Andhra Pradesh.',
            'It created a local cadre.',
          ],
        ),
        te: QuestionLocalizedContent(
          question: 'కింది ప్రకటనలను పరిశీలించండి.',
          options: [],
          explanation: 'రెండు ప్రకటనలు సరైనవి.',
          statements: [
            'ఆర్టికల్ 371-D ఆంధ్రప్రదేశ్‌కు వర్తిస్తుంది.',
            'ఇది స్థానిక కేడర్‌ను సృష్టించింది.',
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

  test('Standard MCQ with 4 EN + 4 TE options writes successfully', () {
    final original = standardQuestion(itemFormat: QuestionItemFormat.standardMcq);
    expect(
      QuestionCloudMapper.validateForWrite(original, documentId: original.id),
      isEmpty,
    );
    final firestore = QuestionCloudMapper.toFirestore(
      original,
      documentId: original.id,
    );
    expect((firestore['content'] as Map)['en']['options'], hasLength(4));
    expect((firestore['content'] as Map)['te']['options'], hasLength(4));
  });

  test('Standard MCQ missing Telugu options fails write validation', () {
    final base = standardQuestion();
    final question = Question(
      id: base.id,
      courseId: base.courseId,
      paperId: base.paperId,
      question: base.question,
      options: base.options,
      correctOption: base.correctOption,
      explanation: base.explanation,
      difficulty: base.difficulty,
      questionType: base.questionType,
      marks: base.marks,
      negativeMarks: base.negativeMarks,
      tags: base.tags,
      estimatedTime: base.estimatedTime,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      itemFormat: QuestionItemFormat.standardMcq,
      content: QuestionContent(
        en: base.content!.en,
        te: QuestionLocalizedContent(
          question: base.content!.te!.question,
          options: const [],
          explanation: base.content!.te!.explanation,
        ),
      ),
      syllabus: base.syllabus,
    );
    expect(
      QuestionCloudMapper.validateForWrite(question, documentId: question.id),
      contains('English and Telugu option counts must match.'),
    );
  });

  test('statement_mcq with 4 EN options and no TE options writes without empty te.options', () {
    final original = statementWithoutTeluguOptions();
    expect(
      QuestionCloudMapper.validateForWrite(original, documentId: original.id),
      isEmpty,
    );

    final firestore = QuestionCloudMapper.toFirestore(
      original,
      documentId: original.id,
    );
    final te = (firestore['content'] as Map)['te'] as Map;
    expect(firestore['itemFormat'], 'statement_mcq');
    expect((firestore['content'] as Map)['en']['options'], hasLength(4));
    expect(te.containsKey('options'), isFalse);
    expect(te['question'], 'కింది ప్రకటనలను పరిశీలించండి.');
    expect(te['statements'], hasLength(2));
    expect(te['explanation'], 'రెండు ప్రకటనలు సరైనవి.');
    expect(te['options'], isNull);

    final restored = QuestionCloudMapper.fromFirestore(
      original.id,
      withoutServerTimestamp(firestore),
    )!;
    expect(restored.content!.en.question, original.content!.en.question);
    expect(restored.content!.te!.question, original.content!.te!.question);
    expect(restored.content!.en.statements, original.content!.en.statements);
    expect(restored.content!.te!.statements, original.content!.te!.statements);
    expect(restored.content!.en.explanation, original.content!.en.explanation);
    expect(restored.content!.te!.explanation, original.content!.te!.explanation);
    expect(restored.content!.te!.options, isEmpty);
    expect(
      restored.content!.en.options.map((o) => o.text),
      isNot(equals(restored.content!.te!.options.map((o) => o.text))),
    );
  });

  test('statement_mcq shuffle keeps Telugu stem/statements/explanation without inventing TE options', () {
    final original = statementWithoutTeluguOptions();
    final shuffled = QuestionService().shuffleOptions(original);
    expect(shuffled.itemFormat, QuestionItemFormat.statementMcq);
    expect(shuffled.content!.te, isNotNull);
    expect(shuffled.content!.te!.question, original.content!.te!.question);
    expect(shuffled.content!.te!.statements, original.content!.te!.statements);
    expect(shuffled.content!.te!.explanation, original.content!.te!.explanation);
    expect(shuffled.content!.te!.options, isEmpty);
    expect(shuffled.options, unorderedEquals(original.options));
  });

  test('Standard MCQ shuffle still preserves English/Telugu option pairing', () {
    final original = standardQuestion(itemFormat: QuestionItemFormat.standardMcq);
    final shuffled = QuestionService().shuffleOptions(original);
    final translations = <String, String>{
      '1 only': '1 మాత్రమే',
      '2 only': '2 మాత్రమే',
      'Both 1 and 2': '1 మరియు 2 రెండూ',
      'Neither 1 nor 2': '1 లేదా 2 కాదు',
    };
    for (var i = 0; i < shuffled.options.length; i++) {
      expect(
        shuffled.content!.te!.options[i].text,
        translations[shuffled.options[i]],
      );
    }
  });

  test('student-safe mapping preserves bilingual statements and options', () async {
    final service = TestService();
    final test = await service.createTestFromStudentSafeQuestions(
      id: 'stmt-test',
      title: 'Home',
      courseId: 'group-ii',
      studentQuestions: [
        <String, dynamic>{
          'questionId': 'stmt-q',
          'position': 0,
          'text': 'Consider the following statements.',
          'options': [
            <String, dynamic>{
              'label': 'A',
              'text': '1 only',
              'teluguText': '1 మాత్రమే',
            },
            <String, dynamic>{
              'label': 'B',
              'text': '2 only',
              'teluguText': '2 మాత్రమే',
            },
            <String, dynamic>{
              'label': 'C',
              'text': 'Both 1 and 2',
              'teluguText': '1 మరియు 2 రెండూ',
            },
            <String, dynamic>{
              'label': 'D',
              'text': 'Neither 1 nor 2',
              'teluguText': '1 లేదా 2 కాదు',
            },
          ],
          'content': <String, dynamic>{
            'en': <String, dynamic>{
              'question': 'Consider the following statements.',
              'statements': ['Article 371-D applies to Andhra Pradesh.', 'It created a local cadre.'],
              'options': [
                <String, dynamic>{'text': '1 only'},
                <String, dynamic>{'text': '2 only'},
                <String, dynamic>{'text': 'Both 1 and 2'},
                <String, dynamic>{'text': 'Neither 1 nor 2'},
              ],
            },
            'te': <String, dynamic>{
              'question': 'కింది ప్రకటనలను పరిశీలించండి.',
              'statements': ['ఆర్టికల్ 371-D ఆంధ్రప్రదేశ్‌కు వర్తిస్తుంది.', 'ఇది స్థానిక కేడర్‌ను సృష్టించింది.'],
              'options': [
                <String, dynamic>{'text': '1 మాత్రమే'},
                <String, dynamic>{'text': '2 మాత్రమే'},
                <String, dynamic>{'text': '1 మరియు 2 రెండూ'},
                <String, dynamic>{'text': '1 లేదా 2 కాదు'},
              ],
            },
          },
        },
      ],
    );

    final question = test.questions.single;
    expect(question.options[0].teluguText, '1 మాత్రమే');
    expect(question.content!.en.statements, hasLength(2));
    expect(question.content!.te!.statements, hasLength(2));
    expect(question.correctOption, isEmpty);
  });
}
