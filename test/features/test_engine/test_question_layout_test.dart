import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/repositories/test_repository.dart';
import 'package:telangana_prep/features/test_engine/presentation/controllers/test_engine_controller.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_question_screen.dart';
import 'package:telangana_prep/features/test_engine/presentation/test_engine_presentation.dart';
import 'package:telangana_prep/features/test_engine/presentation/widgets/attempt_option_tile.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  Map<String, dynamic> studentQuestion({
    required String id,
    required String text,
    String? telugu,
    List<Map<String, String>>? options,
  }) {
    final resolved =
        options ??
        [
          {'label': 'A', 'text': 'Option A', 'teluguText': 'ఎంపిక A'},
          {'label': 'B', 'text': 'Option B', 'teluguText': 'ఎంపిక B'},
          {'label': 'C', 'text': 'Option C', 'teluguText': 'ఎంపిక C'},
          {'label': 'D', 'text': 'Option D', 'teluguText': 'ఎంపిక D'},
        ];
    return <String, dynamic>{
      'questionId': id,
      'position': 0,
      'text': text,
      'options': [
        for (final option in resolved)
          <String, dynamic>{
            'label': option['label'],
            'text': option['text'],
            if (option['teluguText'] != null)
              'teluguText': option['teluguText'],
          },
      ],
      'content': <String, dynamic>{
        'en': <String, dynamic>{
          'question': text,
          'options': [
            for (final option in resolved)
              <String, dynamic>{'text': option['text']},
          ],
        },
        if (telugu != null)
          'te': <String, dynamic>{
            'question': telugu,
            'options': [
              for (final option in resolved)
                if (option['teluguText'] != null)
                  <String, dynamic>{'text': option['teluguText']},
            ],
          },
      },
      'courseId': 'group-ii',
      'paperId': 'group-ii-paper-i',
    };
  }

  Future<Test> mapTest(
    TestService service, {
    required String title,
    required List<Map<String, dynamic>> questions,
    String id = 'layout-attempt',
    Duration duration = const Duration(minutes: 10),
    int totalMarks = 1,
  }) {
    return service.createTestFromStudentSafeQuestions(
      id: id,
      title: title,
      courseId: 'group-ii',
      studentQuestions: questions,
      duration: duration,
      totalMarks: totalMarks,
      negativeMarks: 0,
    );
  }

  Future<TestEngineController> pumpQuestion(
    WidgetTester tester,
    Test test, {
    TestService? service,
    Size size = const Size(390, 844),
    VoidCallback? onOpenReview,
    Future<void> Function()? onSubmit,
    bool settle = true,
    Key? screenKey,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TestEngineController(
      test: test,
      service: service ?? TestService(repository: TestRepository()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: TestQuestionScreen(
          key: screenKey,
          controller: controller,
          onOpenReview: onOpenReview ?? () {},
          onSubmit: onSubmit ?? () async {},
        ),
      ),
    );
    await tester.pump();
    if (settle) {
      await tester.pumpAndSettle();
    }
    return controller;
  }

  Future<FlutterErrorDetails?> overflowAt(
    WidgetTester tester, {
    required Test test,
    required Size size,
    TestService? service,
  }) async {
    FlutterErrorDetails? overflow;
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflow ??= details;
        return;
      }
      old?.call(details);
    };
    try {
      await pumpQuestion(
        tester,
        test,
        service: service,
        size: size,
        settle: false,
        screenKey: const ValueKey('h26-long-question-screen'),
      );
      expect(
        find.byKey(const ValueKey('h26-long-question-screen')),
        findsOneWidget,
      );
      expect(
        find.text(test.questions.first.text, skipOffstage: false),
        findsOneWidget,
      );
      final optionD = find.byKey(
        const ValueKey('attempt-option-D'),
        skipOffstage: false,
      );
      await tester.scrollUntilVisible(optionD, 200);
      expect(optionD, findsOneWidget);
      return overflow;
    } finally {
      FlutterError.onError = old;
    }
  }

  test('progress label uses the supplied index and count', () {
    expect(
      TestEnginePresentation.questionProgressLabel(
        questionNumber: 1,
        totalQuestions: 10,
      ),
      'Question 1 of 10',
    );
    expect(
      TestEnginePresentation.questionProgressLabel(
        questionNumber: 3,
        totalQuestions: 7,
      ),
      'Question 3 of 7',
    );
  });

  testWidgets('renders fixture-driven title, timer, question, and options', (
    tester,
  ) async {
    const title = 'Ancient Telangana Drill';
    const english =
        'National Disaster Response Force (NDRF) is a specialized disaster '
        'response force under which ministry?';
    const telugu =
        'నేషనల్ డిజాస్టర్ రెస్పాన్స్ ఫోర్స్ (NDRF) అనేది ఏ మంత్రిత్వ శాఖ '
        'పరిధిలోని ప్రత్యేక విపత్తు ప్రతిస్పందన దళం?';
    final service = TestService(repository: TestRepository());
    final questions = [
      for (var i = 0; i < 10; i++)
        studentQuestion(
          id: 'q$i',
          text: i == 0 ? english : 'Question ${i + 1} text',
          telugu: i == 0 ? telugu : null,
          options: i == 0
              ? [
                  {
                    'label': 'A',
                    'text': 'Ministry of Urban Development',
                    'teluguText': 'పట్టణాభివృద్ధి మంత్రిత్వ శాఖ',
                  },
                  {
                    'label': 'B',
                    'text': 'Ministry of Home Affairs',
                    'teluguText': 'హోం వ్యవహారాల మంత్రిత్వ శాఖ',
                  },
                  {
                    'label': 'C',
                    'text': 'Ministry of Defence',
                    'teluguText': 'రక్షణ మంత్రిత్వ శాఖ',
                  },
                  {
                    'label': 'D',
                    'text':
                        'Ministry of Environment, Forest and Climate Change',
                    'teluguText':
                        'పర్యావరణ, అటవీ మరియు వాతావరణ మార్పుల మంత్రిత్వ శాఖ',
                  },
                ]
              : null,
        ),
    ];
    final test = await mapTest(
      service,
      title: title,
      questions: questions,
      duration: const Duration(minutes: 12),
      totalMarks: 10,
    );
    final controller = await pumpQuestion(tester, test, service: service);

    expect(find.text(title), findsOneWidget);
    expect(find.text(controller.formatRemaining()), findsOneWidget);
    expect(
      find.text(
        TestEnginePresentation.questionProgressLabel(
          questionNumber: controller.questionNumber,
          totalQuestions: controller.test.totalQuestions,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(english), findsOneWidget);
    expect(find.text(telugu), findsOneWidget);
    expect(find.text('Ministry of Home Affairs'), findsOneWidget);
    expect(find.text('హోం వ్యవహారాల మంత్రిత్వ శాఖ'), findsOneWidget);
    for (final letter in ['A', 'B', 'C', 'D']) {
      final option = find.byKey(ValueKey('attempt-option-$letter'));
      await tester.scrollUntilVisible(option, 120);
      expect(option, findsOneWidget);
    }
    expect(find.text('Clear Response'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Submit'), findsWidgets);
    expect(find.byKey(const ValueKey('open-review')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-palette')), findsOneWidget);
    expect(find.byKey(const ValueKey('go-next')), findsOneWidget);
    expect(find.text('Question 1 / 1'), findsNothing);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('selected state and Clear Response stay on existing controller', (
    tester,
  ) async {
    final service = TestService(repository: TestRepository());
    final test = await mapTest(
      service,
      title: 'Selection Drill',
      questions: [studentQuestion(id: 'q1', text: 'Pick one')],
    );
    final controller = await pumpQuestion(tester, test, service: service);

    await tester.tap(find.byKey(const ValueKey('attempt-option-B')));
    await tester.pump();
    expect(controller.currentAttempt.selectedOption, 'B');
    expect(
      tester
          .widget<AttemptOptionTile>(
            find.byKey(const ValueKey('attempt-option-B')),
          )
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Clear Response'));
    await tester.pump();
    expect(controller.currentAttempt.selectedOption, isNull);
    expect(
      tester
          .widget<AttemptOptionTile>(
            find.byKey(const ValueKey('attempt-option-B')),
          )
          .selected,
      isFalse,
    );
  });

  testWidgets('Previous, Next, and Submit keep existing behavior', (
    tester,
  ) async {
    var submitted = false;
    final service = TestService(repository: TestRepository());
    final test = await mapTest(
      service,
      title: 'Nav Drill',
      questions: [
        studentQuestion(id: 'q1', text: 'First question'),
        studentQuestion(id: 'q2', text: 'Second question'),
      ],
    );
    final controller = await pumpQuestion(
      tester,
      test,
      service: service,
      onSubmit: () async => submitted = true,
    );

    expect(controller.questionNumber, 1);
    await tester.tap(find.byKey(const ValueKey('go-next')));
    await tester.pump();
    expect(controller.questionNumber, 2);
    expect(find.text('Second question'), findsOneWidget);

    await tester.tap(find.text('Previous'));
    await tester.pump();
    expect(controller.questionNumber, 1);
    expect(find.text('First question'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('submit-attempt')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-submit')));
    await tester.pumpAndSettle();
    expect(submitted, isTrue);
  });

  testWidgets('long question and option D do not overflow at 360/390/430', (
    tester,
  ) async {
    const longQuestion =
        'Which of the following statements about the administrative history '
        'of medieval Telangana, including Kakatiya, Qutb Shahi, and Asaf Jahi '
        'institutions, is the most accurate description of the period?';
    const longTelugu =
        'మధ్యయుగ తెలంగాణ పరిపాలనా చరిత్ర, కాకతీయ, కుతుబ్ షాహీ మరియు ఆసఫ్ '
        'జాహీ సంస్థలతో సహా, ఆ కాలానికి సంబంధించి క్రింది వ్యాఖ్యలలో ఏది '
        'అత్యంత ఖచ్చితమైన వివరణ?';
    const longD =
        'The administrative machinery combined hereditary village offices, '
        'regional military assignments, and later revenue reforms without '
        'erasing local customary rights.';
    final service = TestService(repository: TestRepository());
    final test = await mapTest(
      service,
      id: 'layout-attempt-long',
      title: 'Group-II Paper II Part I — Medieval Telangana Practice Set',
      questions: [
        studentQuestion(
          id: 'long-q',
          text: longQuestion,
          telugu: longTelugu,
          options: [
            {'label': 'A', 'text': 'Short A'},
            {'label': 'B', 'text': 'Short B'},
            {'label': 'C', 'text': 'Short C'},
            {'label': 'D', 'text': longD, 'teluguText': longTelugu},
          ],
        ),
      ],
    );

    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      final overflow = await overflowAt(
        tester,
        test: test,
        service: service,
        size: size,
      );
      expect(
        overflow,
        isNull,
        reason: '${size.width}: ${overflow?.exceptionAsString()}',
      );
    }
  });
}
