import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_form_screen.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_dirty_scope.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_shell.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_question_form.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_test_form.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';

void main() {
  const groupIi = Course(
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

  const groupIii = Course(
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
  );

  const user = AuthUser(
    uid: 'uid-1',
    email: 'admin@example.com',
    displayName: 'Admin User',
  );

  Question buildQuestion({
    String id = 'q-existing',
    QuestionPublicationStatus status = QuestionPublicationStatus.draft,
    QuestionDifficulty difficulty = QuestionDifficulty.easy,
  }) {
    final now = DateTime(2026, 8, 9);
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      sectionId: 'section-1',
      topicId: 'topic-1',
      question: 'What is the capital of Telangana?',
      options: const ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
      correctOption: 'A',
      explanation: 'Explanation',
      difficulty: difficulty,
      questionType: QuestionType.practice,
      language: 'en',
      marks: 1,
      negativeMarks: 0,
      tags: const ['Telangana'],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      status: status,
      isActive: true,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'What is the capital of Telangana?',
          options: [
            QuestionOption(text: 'Hyderabad'),
            QuestionOption(text: 'Warangal'),
            QuestionOption(text: 'Nizamabad'),
            QuestionOption(text: 'Karimnagar'),
          ],
          explanation: 'Explanation',
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

  TestModel buildTest({
    String id = 'test-edit',
    TestPublicationStatus status = TestPublicationStatus.draft,
    TestCategoryType category = TestCategoryType.chapterTests,
    String? paperId = 'group-ii-paper-i',
    String? syllabusUnitId = 'group-ii-paper-i-area-01',
    List<String> questionIds = const [],
  }) {
    return TestModel(
      id: id,
      examId: 'group-ii',
      category: category,
      title: 'Group-II Practice Test 1',
      questionCount: questionIds.isEmpty ? 10 : questionIds.length,
      marks: 10,
      durationMinutes: 30,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: status,
      paperId: paperId,
      syllabusUnitId: syllabusUnitId,
      questionIds: questionIds,
    );
  }

  Future<void> settleDirtyTracking(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> openDropdownAndSelect(
    WidgetTester tester, {
    required Key fieldKey,
    required String optionText,
  }) async {
    final field = find.byKey(fieldKey);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    final option = find.text(optionText).last;
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pumpAndSettle();
  }

  group('Question form dirty coverage', () {
    testWidgets('edit load stays clean after defaults populate', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminQuestionForm(
              courses: const [groupIi, groupIii],
              initialQuestion: buildQuestion(),
              onSubmit: (_) async {},
              onDirtyChanged: (value) => dirty = value,
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);
    });

    testWidgets('create load stays clean after defaults populate', (
      tester,
    ) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminQuestionForm(
              courses: const [groupIi, groupIii],
              onSubmit: (_) async {},
              onDirtyChanged: (value) => dirty = value,
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);
    });

    testWidgets('status dropdown marks dirty', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminQuestionForm(
                courses: const [groupIi, groupIii],
                initialQuestion: buildQuestion(),
                onSubmit: (_) async {},
                onDirtyChanged: (value) => dirty = value,
              ),
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-status'),
        optionText: 'published',
      );
      expect(dirty, isTrue);
    });

    testWidgets('difficulty dropdown marks dirty', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminQuestionForm(
                courses: const [groupIi, groupIii],
                initialQuestion: buildQuestion(),
                onSubmit: (_) async {},
                onDirtyChanged: (value) => dirty = value,
              ),
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-difficulty'),
        optionText: 'hard',
      );
      expect(dirty, isTrue);
    });

    testWidgets('syllabus paper dropdown marks dirty', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminQuestionForm(
                courses: const [groupIi, groupIii],
                initialQuestion: buildQuestion(),
                onSubmit: (_) async {},
                onDirtyChanged: (value) => dirty = value,
              ),
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-syllabus-Paper *'),
        optionText: 'Paper II',
      );
      expect(dirty, isTrue);
    });

    testWidgets('correct option dropdown marks dirty', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminQuestionForm(
                courses: const [groupIi, groupIii],
                initialQuestion: buildQuestion(),
                onSubmit: (_) async {},
                onDirtyChanged: (value) => dirty = value,
              ),
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('correct-option'),
        optionText: 'B',
      );
      expect(dirty, isTrue);
    });
  });

  group('Test form dirty coverage', () {
    testWidgets('edit load stays clean after defaults populate', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTestForm(
              courses: const [groupIi, groupIii],
              initialTest: buildTest(),
              initialCourseId: 'group-ii',
              onSubmit: (_) async {},
              onDirtyChanged: (value) => dirty = value,
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);
    });

    testWidgets('create load stays clean after defaults populate', (
      tester,
    ) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTestForm(
              courses: const [groupIi, groupIii],
              initialCourseId: 'group-ii',
              onSubmit: (_) async {},
              onDirtyChanged: (value) => dirty = value,
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);
    });

    testWidgets('status dropdown marks dirty', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminTestForm(
                courses: const [groupIi, groupIii],
                initialTest: buildTest(),
                initialCourseId: 'group-ii',
                onSubmit: (_) async {},
                onDirtyChanged: (value) => dirty = value,
              ),
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('test-status'),
        optionText: 'Published',
      );
      expect(dirty, isTrue);
    });

    testWidgets('category dropdown marks dirty', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminTestForm(
                courses: const [groupIi, groupIii],
                initialTest: buildTest(),
                initialCourseId: 'group-ii',
                onSubmit: (_) async {},
                onDirtyChanged: (value) => dirty = value,
              ),
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('test-category'),
        optionText: 'Paper-wise Tests',
      );
      expect(dirty, isTrue);
    });

    testWidgets('scope paper dropdown marks dirty', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminTestForm(
                courses: const [groupIi, groupIii],
                initialTest: buildTest(),
                initialCourseId: 'group-ii',
                onSubmit: (_) async {},
                onDirtyChanged: (value) => dirty = value,
              ),
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('test-paper'),
        optionText: 'Paper II',
      );
      expect(dirty, isTrue);
    });

    testWidgets('question assignment text marks dirty', (tester) async {
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminTestForm(
                courses: const [groupIi, groupIii],
                initialTest: buildTest(),
                initialCourseId: 'group-ii',
                onSubmit: (_) async {},
                onDirtyChanged: (value) => dirty = value,
              ),
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
      expect(dirty, isFalse);

      final idsField = find.byKey(const ValueKey('question-ids'));
      await tester.ensureVisible(idsField);
      await tester.enterText(idsField, 'q-1\nq-2');
      await tester.pump();
      expect(dirty, isTrue);
    });
  });

  group('Shell navigation respects dropdown dirty', () {
    testWidgets(
      'dropdown-only edit prompts confirmation on sidebar destination',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: AdminShell(
              user: user,
              onSignOut: () async {},
              embeddedChild: _ShellDirtyQuestionHost(
                question: buildQuestion(),
                courses: const [groupIi, groupIii],
              ),
            ),
          ),
        );
        await settleDirtyTracking(tester);

        final hostState = tester.state<_ShellDirtyQuestionHostState>(
          find.byType(_ShellDirtyQuestionHost),
        );
        expect(hostState.isDirty, isFalse);

        await openDropdownAndSelect(
          tester,
          fieldKey: const ValueKey('question-status'),
          optionText: 'published',
        );
        expect(hostState.isDirty, isTrue);

        await tester.tap(find.text('Dashboard').first);
        await tester.pumpAndSettle();
        expect(find.text('Discard unsaved changes?'), findsOneWidget);

        await tester.tap(find.text('Stay'));
        await tester.pumpAndSettle();
        expect(find.text('Discard unsaved changes?'), findsNothing);
        expect(hostState.isDirty, isTrue);
      },
    );
  });

  group('Question form premium sections', () {
    testWidgets('create form exposes editor sections and save action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminQuestionForm(
              courses: const [groupIi, groupIii],
              onSubmit: (_) async {},
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);

      expect(find.byKey(const ValueKey('question-form-create-title')), findsOneWidget);
      expect(find.text('Classification & Syllabus'), findsOneWidget);
      expect(find.text('Question Content'), findsOneWidget);
      expect(find.text('Answer Configuration'), findsOneWidget);
      expect(find.text('Explanation & Learning Content'), findsOneWidget);
      expect(find.text('Exam & Question Metadata'), findsOneWidget);
      expect(find.text('Publication'), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-question')), findsOneWidget);
      expect(find.text('Create question'), findsWidgets);
      expect(find.byKey(const ValueKey('question-course')), findsOneWidget);
      expect(find.byKey(const ValueKey('correct-option')), findsOneWidget);
    });

    testWidgets('edit form loads title, status badge, and save action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminQuestionForm(
              courses: const [groupIi, groupIii],
              initialQuestion: buildQuestion(
                status: QuestionPublicationStatus.published,
              ),
              onSubmit: (_) async {},
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);

      expect(find.byKey(const ValueKey('question-form-edit-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('question-form-status-badge')), findsOneWidget);
      expect(find.text('Published'), findsWidgets);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-question')), findsOneWidget);
    });
  });

  group('Test form premium sections', () {
    testWidgets('create form exposes editor sections and create draft', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTestForm(
              courses: const [groupIi],
              onSubmit: (_) async {},
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);

      expect(find.byKey(const ValueKey('test-form-create-title')), findsOneWidget);
      expect(find.text('Test Classification & Scope'), findsOneWidget);
      expect(find.text('Test Details'), findsOneWidget);
      expect(find.text('Exam Configuration'), findsOneWidget);
      expect(find.text('Question Assignment'), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-test')), findsOneWidget);
      expect(find.text('Create draft'), findsOneWidget);
      expect(find.byKey(const ValueKey('test-course')), findsOneWidget);
      expect(find.byKey(const ValueKey('question-ids')), findsOneWidget);
      expect(find.text('Publication'), findsNothing);
    });

    testWidgets('edit form loads title, status badge, and save action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTestForm(
              courses: const [groupIi],
              initialTest: TestModel(
                id: 'test-edit',
                examId: 'group-ii',
                category: TestCategoryType.chapterTests,
                title: 'Scoped Chapter Test',
                questionCount: 10,
                marks: 10,
                durationMinutes: 30,
                negativeMarking: '0',
                difficulty: 'Medium',
                status: TestPublicationStatus.published,
              ),
              onSubmit: (_) async {},
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);

      expect(find.byKey(const ValueKey('test-form-edit-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('test-form-status-badge')), findsOneWidget);
      expect(find.text('Published'), findsWidgets);
      expect(find.text('Publication'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-test')), findsOneWidget);
      expect(find.byKey(const ValueKey('test-status')), findsOneWidget);
    });
  });

  group('Sign-out dirty protection (Phase 4C)', () {
    Future<void> pumpShellWithQuestion(
      WidgetTester tester, {
      required Future<void> Function() onSignOut,
    }) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(
            user: user,
            onSignOut: onSignOut,
            embeddedChild: _ShellDirtyQuestionHost(
              question: buildQuestion(),
              courses: const [groupIi, groupIii],
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
    }

    Future<void> pumpShellWithTest(
      WidgetTester tester, {
      required Future<void> Function() onSignOut,
    }) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(
            user: user,
            onSignOut: onSignOut,
            embeddedChild: _ShellDirtyTestHost(
              testModel: buildTest(),
              courses: const [groupIi, groupIii],
            ),
          ),
        ),
      );
      await settleDirtyTracking(tester);
    }

    testWidgets('clean Question form Sign Out skips dirty confirmation', (
      tester,
    ) async {
      var signedOut = false;
      await pumpShellWithQuestion(tester, onSignOut: () async {
        signedOut = true;
      });

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();

      expect(find.text('You have unsaved changes'), findsNothing);
      expect(signedOut, isTrue);
    });

    testWidgets('dirty Question Sign Out shows confirmation', (tester) async {
      var signedOut = false;
      await pumpShellWithQuestion(tester, onSignOut: () async {
        signedOut = true;
      });

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-status'),
        optionText: 'published',
      );

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();

      expect(find.text('You have unsaved changes'), findsOneWidget);
      expect(find.byKey(const ValueKey('dirty-sign-out-stay')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dirty-sign-out-discard')),
        findsOneWidget,
      );
      expect(signedOut, isFalse);
    });

    testWidgets('dirty Question Stay keeps form and does not sign out', (
      tester,
    ) async {
      var signedOut = false;
      await pumpShellWithQuestion(tester, onSignOut: () async {
        signedOut = true;
      });

      final questionField = find.widgetWithText(
        TextFormField,
        'What is the capital of Telangana?',
      );
      await tester.ensureVisible(questionField.first);
      await tester.enterText(questionField.first, 'Stay preserves this stem');
      await tester.pump();

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();
      expect(find.text('You have unsaved changes'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('dirty-sign-out-stay')));
      await tester.pumpAndSettle();

      expect(find.text('You have unsaved changes'), findsNothing);
      expect(signedOut, isFalse);
      expect(find.text('Stay preserves this stem'), findsWidgets);
      expect(find.byType(AdminQuestionForm), findsOneWidget);
    });

    testWidgets('dirty Question Discard & Sign Out calls onSignOut', (
      tester,
    ) async {
      var signedOut = false;
      await pumpShellWithQuestion(tester, onSignOut: () async {
        signedOut = true;
      });

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('question-status'),
        optionText: 'published',
      );

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();
      expect(find.text('You have unsaved changes'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('dirty-sign-out-discard')));
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
      expect(find.text('You have unsaved changes'), findsNothing);
    });

    testWidgets('clean Test form Sign Out skips dirty confirmation', (
      tester,
    ) async {
      var signedOut = false;
      await pumpShellWithTest(tester, onSignOut: () async {
        signedOut = true;
      });

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();

      expect(find.text('You have unsaved changes'), findsNothing);
      expect(signedOut, isTrue);
    });

    testWidgets('dirty Test Sign Out shows confirmation', (tester) async {
      var signedOut = false;
      await pumpShellWithTest(tester, onSignOut: () async {
        signedOut = true;
      });

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('test-status'),
        optionText: 'Published',
      );

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();

      expect(find.text('You have unsaved changes'), findsOneWidget);
      expect(signedOut, isFalse);
    });

    testWidgets('dirty Test Stay preserves form', (tester) async {
      var signedOut = false;
      await pumpShellWithTest(tester, onSignOut: () async {
        signedOut = true;
      });

      final titleField = find.widgetWithText(
        TextFormField,
        'Group-II Practice Test 1',
      );
      await tester.ensureVisible(titleField.first);
      await tester.enterText(titleField.first, 'Stay keeps test title');
      await tester.pump();

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dirty-sign-out-stay')));
      await tester.pumpAndSettle();

      expect(signedOut, isFalse);
      expect(find.text('Stay keeps test title'), findsWidgets);
      expect(find.byType(AdminTestForm), findsOneWidget);
    });

    testWidgets('dirty Test Discard & Sign Out calls onSignOut', (
      tester,
    ) async {
      var signedOut = false;
      await pumpShellWithTest(tester, onSignOut: () async {
        signedOut = true;
      });

      await openDropdownAndSelect(
        tester,
        fieldKey: const ValueKey('test-status'),
        optionText: 'Published',
      );

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dirty-sign-out-discard')));
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
    });
  });

  group('Question form Cancel dirty protection (F1)', () {
    Future<void> openQuestionScreen(
      WidgetTester tester, {
      Question? question,
    }) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('Host')),
        ),
      );
      await tester.pumpAndSettle();

      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => AdminQuestionFormScreen(
            question: question,
            service: _FakeQuestionFormService(
              courses: const [groupIi, groupIii],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await settleDirtyTracking(tester);
    }

    testWidgets('clean Cancel leaves without confirmation', (tester) async {
      await openQuestionScreen(tester, question: buildQuestion());

      expect(find.byType(AdminQuestionForm), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(find.byType(AdminQuestionForm), findsNothing);
      expect(find.text('Host'), findsOneWidget);
    });

    testWidgets('dirty Cancel Stay then Discard', (tester) async {
      await openQuestionScreen(tester, question: buildQuestion());

      final questionField = find.widgetWithText(
        TextFormField,
        'What is the capital of Telangana?',
      );
      await tester.ensureVisible(questionField.first);
      await tester.enterText(questionField.first, 'Edited capital question');
      await tester.pump();
      expect(find.text('Unsaved changes'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);

      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(find.byType(AdminQuestionForm), findsOneWidget);
      expect(find.text('Edited capital question'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);

      await tester.tap(find.text('Discard & Leave'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminQuestionForm), findsNothing);
      expect(find.text('Host'), findsOneWidget);
    });

    testWidgets('create dirty Cancel prompts confirmation', (tester) async {
      await openQuestionScreen(tester);

      final fields = find.byType(TextFormField);
      expect(fields, findsWidgets);
      await tester.ensureVisible(fields.first);
      await tester.enterText(fields.first, 'Brand new exam question stem');
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);

      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminQuestionForm), findsOneWidget);
      expect(find.text('Brand new exam question stem'), findsWidgets);
    });
  });
}

class _FakeQuestionFormService extends AdminQuestionService {
  _FakeQuestionFormService({required this.courses}) : super();

  final List<Course> courses;

  @override
  Future<List<Course>> loadCourses() async => courses;

  @override
  Future<String> createQuestion(Question question) async => 'created-id';

  @override
  Future<void> updateQuestion(Question question) async {}
}

class _ShellDirtyQuestionHost extends StatefulWidget {
  const _ShellDirtyQuestionHost({
    required this.question,
    required this.courses,
  });

  final Question question;
  final List<Course> courses;

  @override
  State<_ShellDirtyQuestionHost> createState() => _ShellDirtyQuestionHostState();
}

class _ShellDirtyQuestionHostState extends State<_ShellDirtyQuestionHost> {
  bool _dirty = false;
  AdminDirtyController? _controller;

  bool get isDirty => _dirty;

  bool _isDirtyChecker() => _dirty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AdminDirtyScope.maybeOf(context);
    if (!identical(_controller, next)) {
      _controller?.unbind(_isDirtyChecker);
      _controller = next;
      _controller?.bind(_isDirtyChecker);
    }
  }

  @override
  void dispose() {
    _controller?.unbind(_isDirtyChecker);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AdminQuestionForm(
        courses: widget.courses,
        initialQuestion: widget.question,
        onSubmit: (_) async {},
        onDirtyChanged: (value) {
          if (_dirty == value) return;
          setState(() => _dirty = value);
        },
      ),
    );
  }
}

class _ShellDirtyTestHost extends StatefulWidget {
  const _ShellDirtyTestHost({
    required this.testModel,
    required this.courses,
  });

  final TestModel testModel;
  final List<Course> courses;

  @override
  State<_ShellDirtyTestHost> createState() => _ShellDirtyTestHostState();
}

class _ShellDirtyTestHostState extends State<_ShellDirtyTestHost> {
  bool _dirty = false;
  AdminDirtyController? _controller;

  bool _isDirtyChecker() => _dirty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AdminDirtyScope.maybeOf(context);
    if (!identical(_controller, next)) {
      _controller?.unbind(_isDirtyChecker);
      _controller = next;
      _controller?.bind(_isDirtyChecker);
    }
  }

  @override
  void dispose() {
    _controller?.unbind(_isDirtyChecker);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AdminTestForm(
        courses: widget.courses,
        initialTest: widget.testModel,
        initialCourseId: widget.testModel.examId,
        onSubmit: (_) async {},
        onDirtyChanged: (value) {
          if (_dirty == value) return;
          setState(() => _dirty = value);
        },
      ),
    );
  }
}
