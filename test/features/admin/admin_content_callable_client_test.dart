import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/data/admin_content_callable_client.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  test('encodeCallableWriteData converts deletes and drops timestamps', () {
    final encoded = encodeCallableWriteData({
      'topicId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'courseId': 'group-ii',
    });
    expect(encoded['topicId'], const {'_fieldDelete': true});
    expect(encoded.containsKey('updatedAt'), isFalse);
    expect(encoded['courseId'], 'group-ii');
  });

  test(
    'question repository production writes go through admin callables',
    () async {
      final calls = <String, Map<String, dynamic>>{};
      final repo = QuestionCloudRepository(
        contentCallables: AdminContentCallableClient(
          callOverride: (name, data) async {
            calls[name] = data;
            return {'questionId': data['questionId'] ?? 'q-stale'};
          },
        ),
      );

      final now = DateTime(2026, 8, 9);
      final question = Question(
        id: 'q-stale',
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        question: 'What is the capital of Telangana?',
        options: const ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
        correctOption: 'A',
        explanation: 'Hyderabad is the capital.',
        difficulty: QuestionDifficulty.easy,
        questionType: QuestionType.practice,
        marks: 1,
        negativeMarks: 0,
        tags: const [],
        estimatedTime: const Duration(seconds: 60),
        createdAt: now,
        updatedAt: now,
      );

      await repo.updateQuestion(question);
      expect(calls.containsKey('adminUpdateQuestion'), isTrue);
      final data = Map<String, dynamic>.from(
        calls['adminUpdateQuestion']!['data'] as Map,
      );
      expect(data['courseId'], 'group-ii');
      expect(data['topicId'], const {'_fieldDelete': true});
      expect(
        QuestionCloudMapper.toFirestore(
          question,
          documentId: 'q-stale',
          forUpdate: true,
        )['updatedAt'],
        isA<FieldValue>(),
      );
    },
  );

  test(
    'test repository production writes go through admin callables',
    () async {
      final names = <String>[];
      final repo = TestCloudRepository(
        contentCallables: AdminContentCallableClient(
          callOverride: (name, data) async {
            names.add(name);
            return {'testId': data['testId'] ?? 't-1'};
          },
        ),
      );

      await repo.setTestStatus('t-1', TestPublicationStatus.published);
      await repo.setTestStatus('t-1', TestPublicationStatus.draft);
      expect(names, ['adminSetTestStatus', 'adminSetTestStatus']);
    },
  );
}
