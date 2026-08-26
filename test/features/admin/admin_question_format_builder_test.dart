import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_question_form.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';

void main() {
  const course = Course(
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
  );

  final now = DateTime(2026, 8, 26);

  const englishQuestion =
      'Which of the following statements regarding Article 371-D of the '
      'Indian Constitution is/are correct?';
  const teluguQuestion =
      'భారత రాజ్యాంగంలోని అధికరణ 371-D కి సంబంధించి క్రింది వ్యాఖ్యలలో '
      'ఏది/వి సరైనది/వి?';
  const englishExplanation =
      'Statement 2 is incorrect. After L. Chandra Kumar (1997), High Court '
      'writ jurisdiction under Article 226 was restored.';
  const teluguExplanation =
      'ప్రకటన 2 తప్పు. ఎల్. చంద్రకుమార్ (1997) తర్వాత అధికరణ 226 క్రింద '
      'హైకోర్టు రిట్ పరిధి పునరుద్ధరించబడింది.';

  const statementEnglish = [
    'It was inserted by the 32nd Constitutional Amendment Act, 1973.',
    "The Administrative Tribunal constituted under Article 371-D is excluded "
        "from the writ jurisdiction of the High Court under Article 226 as per "
        "the Supreme Court's ruling in L. Chandra Kumar case (1997).",
    'The President may provide for equitable opportunities in matters of '
        'public employment and education.',
  ];
  const statementTelugu = [
    'దీనిని 32వ రాజ్యాంగ సవరణ చట్టం, 1973 ద్వారా చేర్చారు.',
    'ఎల్. చంద్రకుమార్ కేసు (1997) తీర్పు ప్రకారం అధికరణ 371-D క్రింద '
        'ఏర్పాటైన పరిపాలనా ట్రిబ్యునల్ హైకోర్టు రిట్ పరిధి (అధికరణ 226) '
        'నుండి మినహాయించబడింది.',
    'ప్రభుత్వ ఉద్యోగాలు మరియు విద్యలో సమాన అవకాశాల కల్పనకు రాష్ట్రపతి '
        'ఆదేశాలు జారీ చేయవచ్చు.',
  ];

  Question standardQuestion({
    QuestionItemFormat? itemFormat,
    String id = 'q-standard',
  }) {
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: 'Which city is the capital of Telangana?',
      options: const ['Warangal', 'Hyderabad', 'Nizamabad', 'Karimnagar'],
      correctOption: 'B',
      explanation: 'Hyderabad is the capital.',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const ['Telangana'],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: QuestionPublicationStatus.draft,
      itemFormat: itemFormat,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Which city is the capital of Telangana?',
          options: [
            QuestionOption(text: 'Warangal'),
            QuestionOption(text: 'Hyderabad'),
            QuestionOption(text: 'Nizamabad'),
            QuestionOption(text: 'Karimnagar'),
          ],
          explanation: 'Hyderabad is the capital.',
        ),
        te: QuestionLocalizedContent(
          question: 'తెలంగాణ రాజధాని నగరం ఏది?',
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
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      ),
    );
  }

  Question statementQuestion({
    required int statementCount,
    String id = 'q-statement',
    String correctOption = 'B',
  }) {
    final english = [
      for (var i = 0; i < statementCount; i++) 'English statement ${i + 1}.',
    ];
    final telugu = [
      for (var i = 0; i < statementCount; i++) 'Telugu statement ${i + 1}.',
    ];
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: englishQuestion,
      options: const [
        '1 and 3 only',
        '2 and 3 only',
        '1 and 2 only',
        '1, 2 and 3',
      ],
      correctOption: correctOption,
      explanation: englishExplanation,
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const ['Polity'],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: QuestionPublicationStatus.draft,
      itemFormat: QuestionItemFormat.statementMcq,
      content: QuestionContent(
        en: QuestionLocalizedContent(
          question: englishQuestion,
          options: const [
            QuestionOption(text: '1 and 3 only'),
            QuestionOption(text: '2 and 3 only'),
            QuestionOption(text: '1 and 2 only'),
            QuestionOption(text: '1, 2 and 3'),
          ],
          explanation: englishExplanation,
          statements: english,
        ),
        te: QuestionLocalizedContent(
          question: teluguQuestion,
          options: const [],
          explanation: teluguExplanation,
          statements: telugu,
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

  Question article371dQuestion() {
    return Question(
      id: 'q-371d',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      question: englishQuestion,
      options: const [
        '1 and 3 only',
        '2 and 3 only',
        '1 and 2 only',
        '1, 2 and 3',
      ],
      correctOption: 'B',
      explanation: englishExplanation,
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const ['Polity', 'Article 371-D'],
      estimatedTime: const Duration(seconds: 90),
      createdAt: now,
      updatedAt: now,
      status: QuestionPublicationStatus.draft,
      itemFormat: QuestionItemFormat.statementMcq,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: englishQuestion,
          options: [
            QuestionOption(text: '1 and 3 only'),
            QuestionOption(text: '2 and 3 only'),
            QuestionOption(text: '1 and 2 only'),
            QuestionOption(text: '1, 2 and 3'),
          ],
          explanation: englishExplanation,
          statements: statementEnglish,
        ),
        te: QuestionLocalizedContent(
          question: teluguQuestion,
          options: [],
          explanation: teluguExplanation,
          statements: statementTelugu,
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

  Future<void> pumpForm(
    WidgetTester tester,
    Question initial, {
    Future<void> Function(Question)? onSubmit,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminQuestionForm(
            courses: const [course],
            initialQuestion: initial,
            onSubmit: onSubmit ?? (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester, Key key) {
    return tester.widget<TextFormField>(find.byKey(key)).controller!.text;
  }

  Future<Question> saveQuestion(WidgetTester tester, Question initial) async {
    Question? submitted;
    await pumpForm(
      tester,
      initial,
      onSubmit: (question) async => submitted = question,
    );
    await tester.tap(find.byKey(const ValueKey('submit-question')));
    await tester.pumpAndSettle();
    expect(submitted, isNotNull);
    return submitted!;
  }

  testWidgets('1: legacy question with no itemFormat opens as Standard MCQ', (
    tester,
  ) async {
    await pumpForm(tester, standardQuestion());

    expect(find.text('Standard MCQ'), findsOneWidget);
    expect(find.text('Statements *'), findsNothing);
    expect(find.byKey(const ValueKey('option-te-A')), findsOneWidget);
  });

  testWidgets('2: Standard MCQ shows bilingual option fields', (tester) async {
    await pumpForm(
      tester,
      standardQuestion(itemFormat: QuestionItemFormat.standardMcq),
    );

    for (final letter in ['A', 'B', 'C', 'D']) {
      expect(find.byKey(ValueKey('option-en-$letter')), findsOneWidget);
      expect(find.byKey(ValueKey('option-te-$letter')), findsOneWidget);
    }
    expect(find.text('Add option'), findsOneWidget);
  });

  testWidgets('3-4: Statement MCQ shows English-only option fields', (
    tester,
  ) async {
    await pumpForm(tester, statementQuestion(statementCount: 3));

    expect(find.text('Statement Based'), findsOneWidget);
    for (final letter in ['A', 'B', 'C', 'D']) {
      expect(find.byKey(ValueKey('option-en-$letter')), findsOneWidget);
      expect(find.byKey(ValueKey('option-te-$letter')), findsNothing);
    }
    expect(find.text('Add option'), findsNothing);
    expect(find.text('Telugu A'), findsNothing);
  });

  for (final count in [1, 2, 3, 4, 5, 6]) {
    testWidgets(
      'Statement MCQ supports $count statement${count == 1 ? '' : 's'}',
      (tester) async {
        await pumpForm(tester, statementQuestion(statementCount: count));

        for (var i = 1; i <= count; i++) {
          expect(find.byKey(ValueKey('statement-row-$i')), findsOneWidget);
          expect(find.byKey(ValueKey('statement-en-$i')), findsOneWidget);
          expect(find.byKey(ValueKey('statement-te-$i')), findsOneWidget);
          expect(
            fieldText(tester, ValueKey('statement-en-$i')),
            'English statement $i.',
          );
          expect(
            fieldText(tester, ValueKey('statement-te-$i')),
            'Telugu statement $i.',
          );
        }
        expect(
          find.byKey(ValueKey('statement-row-${count + 1}')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('add-statement')), findsOneWidget);
      },
    );
  }

  testWidgets('11: removing a middle statement renumbers sequentially', (
    tester,
  ) async {
    await pumpForm(tester, statementQuestion(statementCount: 5));

    await tester.ensureVisible(
      find.byKey(const ValueKey('remove-statement-3')),
    );
    await tester.tap(find.byKey(const ValueKey('remove-statement-3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('statement-row-5')), findsNothing);
    expect(find.text('Statement 5'), findsNothing);
    expect(
      fieldText(tester, const ValueKey('statement-en-1')),
      'English statement 1.',
    );
    expect(
      fieldText(tester, const ValueKey('statement-en-2')),
      'English statement 2.',
    );
    expect(
      fieldText(tester, const ValueKey('statement-en-3')),
      'English statement 4.',
    );
    expect(
      fieldText(tester, const ValueKey('statement-en-4')),
      'English statement 5.',
    );
    expect(
      fieldText(tester, const ValueKey('statement-te-3')),
      'Telugu statement 4.',
    );
    expect(find.text('Statement 1'), findsOneWidget);
    expect(find.text('Statement 2'), findsOneWidget);
    expect(find.text('Statement 3'), findsOneWidget);
    expect(find.text('Statement 4'), findsOneWidget);
  });

  testWidgets(
    '12-15: Statement MCQ saves without Telugu options and reopens intact',
    (tester) async {
      final submitted = await saveQuestion(tester, article371dQuestion());

      expect(submitted.itemFormat, QuestionItemFormat.statementMcq);
      expect(submitted.questionType, QuestionType.practice);
      expect(submitted.correctOption, 'B');
      expect(submitted.content!.te!.options, isEmpty);
      expect(submitted.content!.en.options.map((option) => option.text), [
        '1 and 3 only',
        '2 and 3 only',
        '1 and 2 only',
        '1, 2 and 3',
      ]);
      expect(submitted.content!.en.question, englishQuestion);
      expect(submitted.content!.te!.question, teluguQuestion);
      expect(submitted.content!.en.statements, statementEnglish);
      expect(submitted.content!.te!.statements, statementTelugu);
      expect(submitted.content!.en.explanation, englishExplanation);
      expect(submitted.content!.te!.explanation, teluguExplanation);
      expect(submitted.courseId, 'group-ii');
      expect(submitted.paperId, 'group-ii-paper-i');
      expect(submitted.syllabus!.majorStudyAreaId, 'group-ii-paper-i-area-01');
      expect(
        submitted.syllabus!.contentTopicId,
        'group-ii-paper-i-area-01-topic-01',
      );

      final firestore = QuestionCloudMapper.toFirestore(
        submitted,
        documentId: submitted.id,
      );
      final te = (firestore['content'] as Map)['te'] as Map;
      expect(firestore['itemFormat'], 'statement_mcq');
      expect(te.containsKey('options'), isFalse);
      expect(te['options'], isNull);
      expect(firestore['question'], isNot(isNull));
      expect(te['question'], isNotEmpty);
      expect(te['statements'], statementTelugu);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await pumpForm(tester, submitted);

      expect(find.text('Statement Based'), findsOneWidget);
      expect(
        fieldText(tester, const ValueKey('statement-en-1')),
        statementEnglish[0],
      );
      expect(
        fieldText(tester, const ValueKey('statement-te-1')),
        statementTelugu[0],
      );
      expect(
        fieldText(tester, const ValueKey('statement-en-2')),
        statementEnglish[1],
      );
      expect(
        fieldText(tester, const ValueKey('statement-te-2')),
        statementTelugu[1],
      );
      expect(
        fieldText(tester, const ValueKey('statement-en-3')),
        statementEnglish[2],
      );
      expect(
        fieldText(tester, const ValueKey('statement-te-3')),
        statementTelugu[2],
      );
      expect(find.byKey(const ValueKey('option-te-A')), findsNothing);
      expect(fieldText(tester, const ValueKey('option-en-A')), '1 and 3 only');
      expect(fieldText(tester, const ValueKey('option-en-B')), '2 and 3 only');
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const ValueKey('correct-option')),
            )
            .initialValue,
        'B',
      );
    },
  );

  testWidgets('16-17: Standard MCQ save/reopen preserves bilingual options', (
    tester,
  ) async {
    final submitted = await saveQuestion(
      tester,
      standardQuestion(itemFormat: QuestionItemFormat.standardMcq),
    );

    expect(submitted.itemFormat, QuestionItemFormat.standardMcq);
    expect(submitted.content!.en.statements, isEmpty);
    expect(submitted.content!.te!.statements, isEmpty);
    expect(submitted.content!.en.options.map((option) => option.text), [
      'Warangal',
      'Hyderabad',
      'Nizamabad',
      'Karimnagar',
    ]);
    expect(submitted.content!.te!.options.map((option) => option.text), [
      'వరంగల్',
      'హైదరాబాద్',
      'నిజామాబాద్',
      'కరీంనగర్',
    ]);

    final firestore = QuestionCloudMapper.toFirestore(
      submitted,
      documentId: submitted.id,
    );
    expect(((firestore['content'] as Map)['te'] as Map)['options'], [
      'వరంగల్',
      'హైదరాబాద్',
      'నిజామాబాద్',
      'కరీంనగర్',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpForm(tester, submitted);

    expect(find.text('Standard MCQ'), findsOneWidget);
    expect(find.byKey(const ValueKey('option-te-A')), findsOneWidget);
    expect(fieldText(tester, const ValueKey('option-en-B')), 'Hyderabad');
    expect(fieldText(tester, const ValueKey('option-te-B')), 'హైదరాబాద్');
    expect(find.text('Statements *'), findsNothing);
  });

  testWidgets('18: correct answer remains exactly one of A-D', (tester) async {
    Question? submitted;
    await pumpForm(
      tester,
      statementQuestion(statementCount: 3, correctOption: 'C'),
      onSubmit: (question) async => submitted = question,
    );

    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('correct-option')),
          )
          .initialValue,
      'C',
    );
    expect(find.byKey(const ValueKey('option-en-A')), findsOneWidget);
    expect(find.byKey(const ValueKey('option-en-B')), findsOneWidget);
    expect(find.byKey(const ValueKey('option-en-C')), findsOneWidget);
    expect(find.byKey(const ValueKey('option-en-D')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('submit-question')));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.correctOption, 'C');
    expect(const ['A', 'B', 'C', 'D'], contains(submitted!.correctOption));
  });

  testWidgets(
    '20: course/paper/part/chapter placement stays on the Standard form',
    (tester) async {
      await pumpForm(tester, standardQuestion());

      expect(
        find.byKey(const ValueKey('group-ii-question-syllabus')),
        findsOneWidget,
      );
      expect(find.text('Question type'), findsOneWidget);
      expect(find.text('practice'), findsOneWidget);
    },
  );

  testWidgets(
    'switching format hides Telugu options without copying English into Telugu',
    (tester) async {
      await pumpForm(
        tester,
        standardQuestion(itemFormat: QuestionItemFormat.standardMcq),
      );

      await tester.tap(find.byKey(const ValueKey('question-format')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Statement Based').last);
      await tester.pumpAndSettle();

      expect(find.text('Statements *'), findsOneWidget);
      expect(find.byKey(const ValueKey('statement-row-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('statement-row-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('option-te-A')), findsNothing);
      expect(fieldText(tester, const ValueKey('option-en-A')), 'Warangal');

      await tester.tap(find.byKey(const ValueKey('question-format')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Standard MCQ').last);
      await tester.pumpAndSettle();

      expect(find.text('Statements *'), findsNothing);
      expect(find.byKey(const ValueKey('option-te-A')), findsOneWidget);
      expect(fieldText(tester, const ValueKey('option-te-A')), 'వరంగల్');
      expect(fieldText(tester, const ValueKey('option-en-A')), 'Warangal');
    },
  );

  testWidgets('Add Statement grows the dynamic list past any fixed 3/5 size', (
    tester,
  ) async {
    await pumpForm(tester, statementQuestion(statementCount: 2));

    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(find.byKey(const ValueKey('add-statement')));
      await tester.tap(find.byKey(const ValueKey('add-statement')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('statement-row-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('statement-en-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('statement-row-7')), findsNothing);
  });
}
