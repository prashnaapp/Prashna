import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';

void main() {
  Question question({
    String topicId = 'topic-a',
    String? syllabusTopicId,
    String? syllabusUnitId,
    String? partId,
    QuestionContent? content,
  }) {
    final now = DateTime(2026, 8, 9);
    return Question(
      id: 'q-stale',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      sectionId: 'legacy-section',
      topicId: topicId,
      question: 'What is the capital of Telangana?',
      options: const ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
      correctOption: 'A',
      explanation: 'Hyderabad is the capital.',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      language: 'en',
      marks: 1,
      negativeMarks: 0,
      tags: const ['Telangana'],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      content: content,
      syllabus: QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-ii',
        partId: partId,
        topicId: syllabusTopicId,
        syllabusUnitId: syllabusUnitId,
      ),
    );
  }

  Map<String, dynamic> applyUpdate(
    Map<String, dynamic> existing,
    Map<String, dynamic> update,
  ) {
    final next = Map<String, dynamic>.from(existing);
    update.forEach((key, value) {
      if (_isDelete(value)) {
        next.remove(key);
      } else if (value is! FieldValue) {
        next[key] = value;
      }
    });
    return next;
  }

  test('1: existing topicId is replaced on update', () {
    final data = QuestionCloudMapper.toFirestore(
      question(syllabusTopicId: 'topic-b'),
      documentId: 'q-stale',
      forUpdate: true,
    );
    expect(data['topicId'], 'topic-b');
    expect(_isDelete(data['topicId']), isFalse);
  });

  test('2: existing topicId is deleted when explicitly cleared', () {
    final data = QuestionCloudMapper.toFirestore(
      question(topicId: '', syllabusTopicId: null),
      documentId: 'q-stale',
      forUpdate: true,
    );
    expect(_isDelete(data['topicId']), isTrue);
    expect(_isDelete(data['syllabus.topicId']), isTrue);

    final stored = applyUpdate({
      'topicId': 'topic-a',
      'syllabus.topicId': 'topic-a',
      'courseId': 'group-ii',
    }, data);
    expect(stored.containsKey('topicId'), isFalse);
    expect(stored.containsKey('syllabus.topicId'), isFalse);
    expect(stored['courseId'], 'group-ii');
  });

  test('3: existing syllabusUnitId is deleted when explicitly cleared', () {
    final data = QuestionCloudMapper.toFirestore(
      question(syllabusUnitId: null),
      documentId: 'q-stale',
      forUpdate: true,
    );
    expect(_isDelete(data['syllabusUnitId']), isTrue);
    expect(_isDelete(data['syllabus.syllabusUnitId']), isTrue);
  });

  test('4: nested syllabus field is deleted when explicitly cleared', () {
    final data = QuestionCloudMapper.toFirestore(
      question(partId: null),
      documentId: 'q-stale',
      forUpdate: true,
    );
    expect(_isDelete(data['partId']), isTrue);
    expect(_isDelete(data['syllabus.partId']), isTrue);
  });

  test('5: required fields are never deleted on update', () {
    final data = QuestionCloudMapper.toFirestore(
      question(topicId: '', syllabusTopicId: null, syllabusUnitId: null),
      documentId: 'q-stale',
      forUpdate: true,
    );
    expect(data['id'], 'q-stale');
    expect(data['courseId'], 'group-ii');
    expect(data['question'], 'What is the capital of Telangana?');
    expect(data['correctOption'], 'A');
    expect(_isDelete(data['id']), isFalse);
    expect(_isDelete(data['courseId']), isFalse);
    expect(_isDelete(data['question']), isFalse);
  });

  test('create omits empty optional fields instead of deleting them', () {
    final data = QuestionCloudMapper.toFirestore(
      question(topicId: '', syllabusTopicId: null, syllabusUnitId: null),
      documentId: 'q-stale',
    );
    expect(data.containsKey('syllabusUnitId'), isFalse);
    expect(data.containsKey('partId'), isFalse);
    expect(_isDelete(data['syllabusUnitId']), isFalse);
  });

  test('supplied content replaces nested te when Telugu is cleared', () {
    final data = QuestionCloudMapper.toFirestore(
      question(
        content: const QuestionContent(
          en: QuestionLocalizedContent(
            question: 'What is the capital of Telangana?',
            options: [
              QuestionOption(text: 'Hyderabad'),
              QuestionOption(text: 'Warangal'),
              QuestionOption(text: 'Nizamabad'),
              QuestionOption(text: 'Karimnagar'),
            ],
            explanation: 'Hyderabad is the capital.',
          ),
        ),
      ),
      documentId: 'q-stale',
      forUpdate: true,
    );
    final content = data['content'] as Map<String, dynamic>;
    expect(content.containsKey('en'), isTrue);
    expect(content.containsKey('te'), isFalse);
  });

  test('repository updateQuestion sends delete sentinels', () async {
    Map<String, dynamic>? updated;
    final repo = QuestionCloudRepository.withHandlers(
      update: ({required questionId, required data}) async {
        updated = data;
      },
    );
    await repo.updateQuestion(question(topicId: '', syllabusTopicId: null));
    expect(updated, isNotNull);
    expect(_isDelete(updated!['topicId']), isTrue);
    expect(updated!['courseId'], 'group-ii');
    expect(updated!.containsKey('createdAt'), isFalse);
  });

  test('unrelated existing fields stay outside the update payload', () {
    final data = QuestionCloudMapper.toFirestore(
      question(syllabusTopicId: 'topic-b'),
      documentId: 'q-stale',
      forUpdate: true,
    );
    expect(data.containsKey('legacyAnalytics'), isFalse);
    expect(data.containsKey('createdAt'), isFalse);
  });
}

bool _isDelete(dynamic value) =>
    value is FieldValue && value == FieldValue.delete();
