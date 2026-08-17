import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/test_engine/data/mappers/question_bank_mapper.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/data/test_attempt_cloud_mapper.dart';
import 'package:telangana_prep/features/test_engine/data/repositories/test_repository.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  Question question({
    required String id,
    required String paperId,
    required String partId,
    required String topicId,
    required String lessonId,
  }) {
    return Question(
      id: id,
      courseId: 'group-ii',
      paperId: paperId,
      correctOption: 'A',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'English question',
          options: [QuestionOption(text: 'English option')],
          explanation: 'English explanation',
        ),
        te: QuestionLocalizedContent(
          question: 'తెలుగు ప్రశ్న',
          options: [QuestionOption(text: 'తెలుగు ఎంపిక')],
          explanation: 'తెలుగు వివరణ',
        ),
      ),
      syllabus: QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: paperId,
        partId: partId,
        topicId: topicId,
        lessonId: lessonId,
      ),
    );
  }

  test(
    'test questions preserve bilingual content and canonical attribution',
    () {
      final source = question(
        id: 'q-1',
        paperId: 'group-ii-paper-iii',
        partId: 'group-ii-paper-iii-part-01',
        topicId: 'group-ii-paper-iii-part-01-topic-01',
        lessonId: 'group-ii-paper-iii-part-01-topic-01-lesson-01',
      );
      final mapped = QuestionBankMapper.toTestQuestion(source);

      expect(mapped.text, 'English question');
      expect(mapped.teluguText, 'తెలుగు ప్రశ్న');
      expect(mapped.options.single.text, 'English option');
      expect(mapped.options.single.teluguText, 'తెలుగు ఎంపిక');
      expect(mapped.partId, source.partId);
      expect(mapped.lessonId, source.lessonId);
    },
  );

  test(
    'mixed tests do not derive canonical metadata from first question',
    () async {
      final first = question(
        id: 'q-1',
        paperId: 'group-ii-paper-ii',
        partId: 'group-ii-paper-ii-part-01',
        topicId: 'group-ii-paper-ii-part-01-topic-01',
        lessonId: 'group-ii-paper-ii-part-01-topic-01-lesson-01',
      );
      final second = question(
        id: 'q-2',
        paperId: 'group-ii-paper-iv',
        partId: 'group-ii-paper-iv-part-01',
        topicId: 'group-ii-paper-iv-part-01-topic-01',
        lessonId: 'group-ii-paper-iv-part-01-topic-01-lesson-01',
      );
      final test = await TestService(repository: TestRepository())
          .createTestFromQuestions(
            id: 'mixed-test',
            title: 'Mixed',
            courseId: 'group-ii',
            questions: [first, second],
          );

      expect(test.paperId, isNull);
      expect(test.partId, isNull);
      expect(test.questions[0].partId, first.partId);
      expect(test.questions[1].partId, second.partId);
    },
  );

  test('new attempts snapshot per-question canonical attribution', () {
    final source = question(
      id: 'q-1',
      paperId: 'group-ii-paper-iii',
      partId: 'group-ii-paper-iii-part-01',
      topicId: 'group-ii-paper-iii-part-01-topic-01',
      lessonId: 'group-ii-paper-iii-part-01-topic-01-lesson-01',
    );
    final testQuestion = QuestionBankMapper.toTestQuestion(source);
    final attempt = QuestionAttempt(questionId: source.id);
    final data = TestAttemptCloudMapper.toCreateMap(
      attemptId: 'attempt-1',
      uid: 'user-1',
      test: Test(
        id: 'test-1',
        title: 'Test',
        courseId: 'group-ii',
        duration: const Duration(minutes: 1),
        totalQuestions: 1,
        totalMarks: 1,
        negativeMarks: 0,
        instructions: const [],
        mode: TestMode.practice,
        questions: [testQuestion],
      ),
      result: const TestResult(
        totalQuestions: 1,
        attempted: 0,
        correct: 0,
        wrong: 0,
        skipped: 1,
        score: 0,
        accuracy: 0,
        percentage: 0,
        timeTaken: Duration.zero,
        passed: false,
      ),
      attempts: [attempt],
      startedAt: DateTime(2026, 8, 10),
    );

    final answer = (data['answers'] as List).single as Map;
    expect(answer['canonicalAttribution']['partId'], source.partId);
    expect(answer['canonicalAttribution']['lessonId'], source.lessonId);
  });
}
