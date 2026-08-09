import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';

void main() {
  Question question({
    String id = 'q-valid',
    String courseId = 'group-ii',
    String text = 'What is the capital of Telangana?',
    List<String>? options,
    String correctOption = 'A',
    double marks = 1,
    double negativeMarks = 0,
    int seconds = 60,
    bool isActive = true,
  }) {
    final now = DateTime(2026, 8, 9);
    return Question(
      id: id,
      courseId: courseId,
      paperId: 'paper-1',
      sectionId: 'section-1',
      topicId: 'topic-1',
      question: text,
      options: options ?? const ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
      correctOption: correctOption,
      explanation: 'Explanation',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      language: 'en',
      marks: marks,
      negativeMarks: negativeMarks,
      tags: const ['Telangana'],
      estimatedTime: Duration(seconds: seconds),
      createdAt: now,
      updatedAt: now,
      isActive: isActive,
    );
  }

  test('1: valid question passes validation', () {
    expect(QuestionCloudMapper.validateForWrite(question()), isEmpty);
  });

  test('2: empty question is rejected', () {
    final errors = QuestionCloudMapper.validateForWrite(question(text: ' '));
    expect(errors, contains('Question text is required.'));
  });

  test('3: empty or insufficient options are rejected', () {
    expect(
      QuestionCloudMapper.validateForWrite(
        question(options: const ['', 'Option B']),
      ),
      contains('Answer options cannot be empty.'),
    );
    expect(
      QuestionCloudMapper.validateForWrite(
        question(options: const ['Only one']),
      ),
      contains('Provide between 2 and 5 answer options.'),
    );
  });

  test('4: invalid correctOption is rejected', () {
    final errors = QuestionCloudMapper.validateForWrite(
      question(correctOption: 'E', options: const ['A', 'B']),
    );
    expect(errors, contains('Correct option must match one of the provided options.'));
  });

  test('5: unsupported enum strings are rejected by the read parser', () {
    expect(QuestionCloudMapper.parseDifficulty('impossible'), isNull);
    expect(QuestionCloudMapper.parseQuestionType('survey'), isNull);
  });

  test('6: invalid numeric values are rejected', () {
    expect(
      QuestionCloudMapper.validateForWrite(question(marks: 0)),
      contains('Marks must be greater than zero.'),
    );
    expect(
      QuestionCloudMapper.validateForWrite(question(negativeMarks: -1)),
      contains('Negative marks must be zero or greater.'),
    );
    expect(
      QuestionCloudMapper.validateForWrite(question(seconds: 0)),
      contains('Estimated time must be greater than zero.'),
    );
  });

  test('7: create mapping contains schema, server timestamps, and active=true', () {
    final data = QuestionCloudMapper.toFirestore(
      question(id: 'q-created'),
      includeCreatedAt: true,
      documentId: 'q-created',
    );
    expect(data['id'], 'q-created');
    expect(data['courseId'], 'group-ii');
    expect(data['questionType'], 'practice');
    expect(data['estimatedTimeSeconds'], 60);
    expect(data['isActive'], isTrue);
    expect(data['createdAt'], isA<FieldValue>());
    expect(data['updatedAt'], isA<FieldValue>());
  });

  test('8: update mapping preserves createdAt and updates updatedAt', () {
    final data = QuestionCloudMapper.toFirestore(
      question(id: 'q-existing'),
      documentId: 'q-existing',
    );
    expect(data.containsKey('createdAt'), isFalse);
    expect(data['updatedAt'], isA<FieldValue>());
  });

  test('9: document ID and Question.id must remain consistent', () {
    expect(
      () => QuestionCloudMapper.toFirestore(
        question(id: 'wrong-id'),
        documentId: 'q-authoritative',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('10: repository create/update/deactivate use admin handlers', () async {
    final created = <String, Map<String, dynamic>>{};
    final updated = <String, Map<String, dynamic>>{};
    final active = <String, bool>{};
    final repo = QuestionCloudRepository.withHandlers(
      idGenerator: () => 'q-generated',
      create: ({required questionId, required data}) async {
        created[questionId] = data;
      },
      update: ({required questionId, required data}) async {
        updated[questionId] = data;
      },
      deactivate: ({required questionId, required isActive}) async {
        active[questionId] = isActive;
      },
    );

    final id = await repo.createQuestion(question(id: '', isActive: false));
    await repo.updateQuestion(question(id: id));
    await repo.setQuestionActive(id, isActive: false);
    await repo.setQuestionActive(id, isActive: true);

    expect(id, 'q-generated');
    expect(created['q-generated']!['id'], 'q-generated');
    expect(created['q-generated']!['isActive'], isTrue);
    expect(updated['q-generated']!.containsKey('createdAt'), isFalse);
    expect(updated['q-generated']!['updatedAt'], isA<FieldValue>());
    expect(active['q-generated'], isTrue);
  });

  test('11: AdminQuestionService rejects invalid writes before repository', () async {
    final service = AdminQuestionService(
      questionRepository: QuestionCloudRepository.withHandlers(
        create: ({required questionId, required data}) async {
          fail('invalid question reached repository');
        },
      ),
    );

    expect(
      () => service.createQuestion(question(id: '', text: '')),
      throwsA(isA<FormatException>()),
    );
  });
}
