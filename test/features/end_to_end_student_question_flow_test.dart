import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/authentication/services/user_session_state_coordinator.dart';
import 'package:telangana_prep/features/bookmarks/data/services/bookmark_service.dart';
import 'package:telangana_prep/features/progress/data/models/progress_models.dart';
import 'package:telangana_prep/features/progress/data/repositories/progress_repository.dart';
import 'package:telangana_prep/features/progress/services/progress_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/revision/services/revision_service.dart';
import 'package:telangana_prep/features/study_planner/data/services/study_planner_calculator.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';
import 'package:telangana_prep/features/test_engine/data/mappers/question_bank_mapper.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/repositories/test_repository.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_cloud_mapper.dart';
import 'package:telangana_prep/features/test_engine/presentation/controllers/test_engine_controller.dart';
import 'package:telangana_prep/features/test_engine/presentation/screens/test_question_screen.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

const _courseId = 'group-ii';
const _paperId = 'group-ii-paper-iii';
const _partId = 'group-ii-paper-iii-part-01';
const _topicId = 'group-ii-paper-iii-part-01-topic-03';
const _lessonId = 'group-ii-paper-iii-part-01-topic-03-lesson-01';

void main() {
  final now = DateTime(2026, 8, 10);

  Question buildQuestion({String id = 'e2e-q-001'}) {
    return Question(
      id: id,
      courseId: _courseId,
      paperId: _paperId,
      correctOption: 'B',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0.25,
      tags: ['e2e'],
      estimatedTime: Duration(seconds: 60),
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
      content: QuestionContent(
        en: QuestionLocalizedContent(
          question: 'Which activity belongs to agriculture and allied sectors?',
          options: [
            QuestionOption(text: 'Mining'),
            QuestionOption(text: 'Crop cultivation'),
            QuestionOption(text: 'Banking'),
            QuestionOption(text: 'Insurance'),
          ],
          explanation: 'Crop cultivation belongs to agriculture.',
        ),
        te: QuestionLocalizedContent(
          question: 'వ్యవసాయ మరియు అనుబంధ రంగాలకు చెందినది ఏది?',
          options: [
            QuestionOption(text: 'మైనింగ్'),
            QuestionOption(text: 'పంటల సాగు'),
            QuestionOption(text: 'బ్యాంకింగ్'),
            QuestionOption(text: 'బీమా'),
          ],
          explanation: 'పంటల సాగు వ్యవసాయ రంగానికి చెందుతుంది.',
        ),
      ),
      syllabus: QuestionSyllabusAttribution(
        courseId: _courseId,
        paperId: _paperId,
        partId: _partId,
        topicId: _topicId,
        lessonId: _lessonId,
      ),
    );
  }

  QuestionService serviceFor(Iterable<Question> questions) {
    final byId = {for (final question in questions) question.id: question};
    final cloud = QuestionCloudRepository.withHandlers(
      loadQuestions: (filter) async => [
        for (final question in byId.values)
          if (filter?.courseId == null || question.courseId == filter!.courseId)
            question,
      ],
      getById: (id) async => byId[id],
    );
    return QuestionService(
      repository: QuestionRepository(cloudRepository: cloud),
    );
  }

  test('resolves the locked Paper III canonical syllabus path', () {
    final syllabus = SyllabusService.instance;
    final course = syllabus.getCourseById(_courseId);
    final paper = syllabus.getPaper(courseId: _courseId, paperId: _paperId);
    final part = syllabus.getPart(
      courseId: _courseId,
      paperId: _paperId,
      partId: _partId,
    );
    final topic = syllabus.getCanonicalTopic(
      courseId: _courseId,
      paperId: _paperId,
      partId: _partId,
      topicId: _topicId,
    );
    final lesson = syllabus.getLesson(
      courseId: _courseId,
      paperId: _paperId,
      partId: _partId,
      topicId: _topicId,
      lessonId: _lessonId,
    );

    expect(course?.name, 'Group-II');
    expect(paper?.title, 'Paper III');
    expect(part?.displayName, 'Indian Economy: Issues and Challenges');
    expect(topic?.displayName, 'Primary and Secondary Sectors');
    expect(lesson?.displayName, 'Agriculture and Allied Sectors');
  });

  test(
    'real repository/service path preserves bilingual question attribution',
    () async {
      final question = buildQuestion();
      final service = serviceFor([question]);
      final resolved = await service.getByLesson(_lessonId);

      expect(resolved.single.id, question.id);
      expect(resolved.single.courseId, _courseId);
      expect(resolved.single.paperId, _paperId);
      expect(resolved.single.partId, _partId);
      expect(resolved.single.syllabus?.topicId, _topicId);
      expect(resolved.single.lessonId, _lessonId);
      expect(resolved.single.content?.en.question, contains('agriculture'));
      expect(resolved.single.content?.te?.question, contains('వ్యవసాయ'));
    },
  );

  testWidgets('student question UI displays paired bilingual content', (
    tester,
  ) async {
    final question = buildQuestion();
    final testQuestion = QuestionBankMapper.toTestQuestion(question);
    final test = Test(
      id: 'e2e-test',
      title: 'E2E Test',
      courseId: _courseId,
      duration: const Duration(minutes: 1),
      totalQuestions: 1,
      totalMarks: 1,
      negativeMarks: 0.25,
      instructions: const [],
      mode: TestMode.practice,
      questions: [testQuestion],
    );
    final controller = TestEngineController(
      test: test,
      service: TestService(repository: TestRepository()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TestQuestionScreen(
          controller: controller,
          onOpenReview: () {},
          onSubmit: () async {},
        ),
      ),
    );

    expect(find.text(testQuestion.text), findsOneWidget);
    expect(find.text(testQuestion.teluguText!), findsOneWidget);
    expect(find.textContaining('Crop cultivation'), findsOneWidget);
    expect(find.textContaining('పంటల సాగు'), findsOneWidget);
    controller.dispose();
  });

  test('answer, scoring, explanation, attempt, and progress flow', () async {
    final question = buildQuestion();
    final test = await TestService(repository: TestRepository())
        .createTestFromQuestions(
          id: 'e2e-test',
          title: 'E2E Test',
          courseId: _courseId,
          questions: [question],
        );
    final engine = TestService(repository: TestRepository());
    final correctAttempt = engine.startTest(test).single;
    engine.saveAnswer(attempt: correctAttempt, optionLabel: 'B');
    final correct = engine.calculateScore(
      test: test,
      attempts: [correctAttempt],
      timeTaken: const Duration(seconds: 10),
    );
    final wrongAttempt = engine.startTest(test).single;
    engine.saveAnswer(attempt: wrongAttempt, optionLabel: 'A');
    final wrong = engine.calculateScore(
      test: test,
      attempts: [wrongAttempt],
      timeTaken: const Duration(seconds: 10),
    );

    expect(correct.correct, 1);
    expect(correct.score, 1);
    expect(wrong.wrong, 1);
    expect(wrong.score, 0);
    expect(test.questions.single.explanation, contains('Crop cultivation'));
    expect(
      test.questions.single.content?.te?.explanation,
      contains('పంటల సాగు'),
    );

    final attemptData = TestAttemptCloudMapper.toCreateMap(
      attemptId: 'e2e-attempt',
      uid: 'test-user',
      test: test,
      result: correct,
      attempts: [correctAttempt],
      startedAt: now,
    );
    final answer = (attemptData['answers'] as List).single as Map;
    expect(answer['questionId'], question.id);
    expect(answer['selectedOption'], 'B');
    expect(answer['canonicalAttribution']['lessonId'], _lessonId);

    final progressRepository = ProgressRepository();
    final progress = ProgressService.debug(
      repository: progressRepository,
      sessionCoordinator: UserSessionStateCoordinator.debug(),
    );
    await progress.recordTestAttempt(
      test: test,
      result: correct,
      attempts: [correctAttempt],
    );
    final history = await progress.loadHistory(courseId: _courseId);
    final summary = await progress.generateSummary(courseId: _courseId);
    expect(history, hasLength(1));
    expect(history.single.courseId, _courseId);
    expect(summary.totalQuestions, 1);
  });

  test(
    'bookmark and revision resolve canonical hierarchy without migration',
    () async {
      final question = buildQuestion();
      final questionService = serviceFor([question]);
      final coordinator = UserSessionStateCoordinator.debug();
      final bookmarks = BookmarkService.debug(
        questionService: questionService,
        sessionCoordinator: coordinator,
      );

      await bookmarks.addBookmark(questionId: question.id);
      final bookmark = bookmarks.getBookmarks().single;
      expect(bookmark.questionId, question.id);
      expect(bookmark.canonicalPartId, _partId);
      expect(bookmark.canonicalTopicId, _topicId);
      expect(bookmark.lessonId, _lessonId);
      expect(bookmark.chapterName, 'Agriculture and Allied Sectors');
      await bookmarks.removeBookmark(question.id);
      expect(bookmarks.getBookmarks(), isEmpty);

      final progressRepository = ProgressRepository();
      final progress = ProgressService.debug(
        repository: progressRepository,
        sessionCoordinator: coordinator,
      );
      final test = await TestService(repository: TestRepository())
          .createTestFromQuestions(
            id: 'revision-test',
            title: 'Revision Test',
            courseId: _courseId,
            questions: [question],
          );
      final wrongAttempt = QuestionAttempt(questionId: question.id)
        ..answered = true
        ..visited = true
        ..selectedOption = 'A';
      final result = TestService(repository: TestRepository()).calculateScore(
        test: test,
        attempts: [wrongAttempt],
        timeTaken: Duration.zero,
      );
      await progress.recordTestAttempt(
        test: test,
        result: result,
        attempts: [wrongAttempt],
      );

      final revision = RevisionService(
        questionService: questionService,
        progressService: progress,
        bookmarkService: bookmarks,
        sessionCoordinator: coordinator,
      );
      final groups = await revision.loadWrongQuestionGroups(
        courseId: _courseId,
      );
      final item = groups.single.items.single;
      expect(item.questionId, question.id);
      expect(item.canonicalPartId, _partId);
      expect(item.canonicalTopicId, _topicId);
      expect(item.lessonId, _lessonId);
      expect(item.chapterName, 'Agriculture and Allied Sectors');
    },
  );

  test('Study Tracker flattening preserves canonical paper and part IDs', () {
    final overall = OverallProgress(
      examId: _courseId,
      examTitle: 'Group-II',
      maxMarks: 1,
      coveredMarks: 0,
      progressPercent: 0,
      remainingMarks: 1,
      papers: [
        PaperProgress(
          id: _paperId,
          label: 'Paper III',
          maxMarks: 1,
          coveredMarks: 0,
          progressPercent: 0,
          remainingMarks: 1,
          parts: [
            PartProgress(
              id: _partId,
              label: 'Indian Economy: Issues and Challenges',
              maxMarks: 1,
              coveredMarks: 0,
              progressPercent: 0,
              remainingMarks: 1,
              chapters: [
                ChapterProgress(
                  id: _topicId,
                  label: 'Primary and Secondary Sectors',
                  maxMarks: 1,
                  coveredMarks: 0,
                  progressPercent: 0,
                  remainingMarks: 1,
                  status: 'Not Started',
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final flattened = StudyPlannerCalculator.flattenChapters(overall);

    expect(flattened.single.paperId, _paperId);
    expect(flattened.single.partId, _partId);
    expect(flattened.single.chapter.id, _topicId);
  });

  test('legacy and Paper I regressions remain structurally distinct', () {
    final legacy = QuestionCloudMapper.fromFirestore('legacy-q', {
      'courseId': _courseId,
      'paperId': 'paper-1',
      'sectionId': 'section-1',
      'topicId': 'topic-1',
      'question': 'Legacy question',
      'options': ['A', 'B'],
      'correctOption': 'A',
      'explanation': 'Legacy explanation',
      'difficulty': 'easy',
      'questionType': 'practice',
      'language': 'en',
      'marks': 1,
      'negativeMarks': 0,
      'estimatedTimeSeconds': 60,
      'isActive': true,
    });
    final paperI = SyllabusService.instance.getPaper(
      courseId: _courseId,
      paperId: 'group-ii-paper-i',
    );

    expect(legacy?.syllabus?.legacySectionId, 'section-1');
    expect(legacy?.syllabus?.legacyTopicId, 'topic-1');
    expect(legacy?.syllabus?.partId, isNull);
    expect(paperI?.majorStudyAreas, isNotEmpty);
    expect(paperI?.parts, isEmpty);
    expect(
      paperI!.majorStudyAreas.expand((area) => area.contentTopics),
      isNotEmpty,
    );
  });
}
