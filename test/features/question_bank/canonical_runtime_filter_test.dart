import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/repositories/question_repository.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';

void main() {
  test(
    'canonical repository filters remain distinct from legacy sectionId',
    () async {
      QuestionFilter? received;
      final repository = QuestionCloudRepository.withHandlers(
        loadQuestions: (filter) async {
          received = filter;
          return const [];
        },
      );
      final service = QuestionService(
        repository: QuestionRepository(cloudRepository: repository),
      );

      await service.fetchQuestions(
        filter: const QuestionFilter(
          courseId: 'group-ii',
          paperId: 'group-ii-paper-iii',
          partId: 'group-ii-paper-iii-part-01',
          topicId: 'group-ii-paper-iii-part-01-topic-01',
          lessonId: 'group-ii-paper-iii-part-01-topic-01-lesson-01',
        ),
      );

      expect(received!.partId, 'group-ii-paper-iii-part-01');
      expect(received!.topicId, 'group-ii-paper-iii-part-01-topic-01');
      expect(
        received!.lessonId,
        'group-ii-paper-iii-part-01-topic-01-lesson-01',
      );
      expect(received!.sectionId, isNull);
    },
  );

  test('Paper I canonical filters are available independently', () async {
    QuestionFilter? received;
    final repository = QuestionCloudRepository.withHandlers(
      loadQuestions: (filter) async {
        received = filter;
        return const [];
      },
    );
    final service = QuestionService(
      repository: QuestionRepository(cloudRepository: repository),
    );

    await service.fetchQuestions(
      filter: const QuestionFilter(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      ),
    );

    expect(received!.majorStudyAreaId, 'group-ii-paper-i-area-01');
    expect(received!.contentTopicId, 'group-ii-paper-i-area-01-topic-01');
    expect(received!.partId, isNull);
  });
}
