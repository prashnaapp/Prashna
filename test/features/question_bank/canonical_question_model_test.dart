import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/question_bank/data/services/question_service.dart';

void main() {
  final now = DateTime(2026, 8, 10);

  Question canonicalQuestion({required QuestionSyllabusAttribution syllabus}) {
    return Question(
      id: 'q-canonical-001',
      courseId: 'group-ii',
      paperId: syllabus.paperId,
      correctOption: 'B',
      difficulty: QuestionDifficulty.medium,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const ['canonical'],
      estimatedTime: const Duration(seconds: 60),
      createdAt: now,
      updatedAt: now,
      content: const QuestionContent(
        en: QuestionLocalizedContent(
          question: 'What is the capital of Telangana?',
          options: [
            QuestionOption(text: 'Warangal'),
            QuestionOption(text: 'Hyderabad'),
            QuestionOption(text: 'Nizamabad'),
            QuestionOption(text: 'Karimnagar'),
          ],
          explanation: 'Hyderabad is the capital of Telangana.',
        ),
        te: QuestionLocalizedContent(
          question: 'తెలంగాణ రాజధాని ఏది?',
          options: [
            QuestionOption(text: 'వరంగల్'),
            QuestionOption(text: 'హైదరాబాద్'),
            QuestionOption(text: 'నిజామాబాద్'),
            QuestionOption(text: 'కరీంనగర్'),
          ],
          explanation: 'హైదరాబాద్ తెలంగాణ రాజధాని.',
        ),
      ),
      syllabus: syllabus,
    );
  }

  test('one question record contains English and Telugu variants', () {
    final question = canonicalQuestion(
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      ),
    );

    expect(question.content, isNotNull);
    expect(question.content!.en.question, contains('capital'));
    expect(question.content!.te!.question, contains('రాజధాని'));
    expect(question.content!.en.options.map((option) => option.text), [
      'Warangal',
      'Hyderabad',
      'Nizamabad',
      'Karimnagar',
    ]);
    expect(question.content!.te!.options.map((option) => option.text), [
      'వరంగల్',
      'హైదరాబాద్',
      'నిజామాబాద్',
      'కరీంనగర్',
    ]);
    expect(question.correctOption, 'B');
  });

  test('Paper I attribution uses area and content topic only', () {
    final question = canonicalQuestion(
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      ),
    );

    expect(question.syllabus!.isPaperI, isTrue);
    expect(question.partId, isNull);
    expect(question.lessonId, isNull);
  });

  test('Papers II–IV attribution supports an optional lesson', () {
    final question = canonicalQuestion(
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-iii',
        partId: 'group-ii-paper-iii-part-01',
        topicId: 'group-ii-paper-iii-part-01-topic-01',
      ),
    );
    final attributedWithLesson = QuestionSyllabusAttribution(
      courseId: question.syllabus!.courseId,
      paperId: question.syllabus!.paperId,
      partId: question.syllabus!.partId,
      topicId: question.syllabus!.topicId,
      lessonId: 'group-ii-paper-iii-part-01-topic-01-lesson-01',
    );

    expect(question.syllabus!.isPartBased, isTrue);
    expect(question.lessonId, isNull);
    expect(attributedWithLesson.lessonId, isNotNull);
  });

  test('canonical bilingual documents serialize and deserialize', () {
    final original = canonicalQuestion(
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-iii',
        partId: 'group-ii-paper-iii-part-01',
        topicId: 'group-ii-paper-iii-part-01-topic-01',
        lessonId: 'group-ii-paper-iii-part-01-topic-01-lesson-01',
      ),
    );
    final firestore = QuestionCloudMapper.toFirestore(
      original,
      documentId: original.id,
    );
    final restored = QuestionCloudMapper.fromFirestore(
      original.id,
      firestore..remove('updatedAt'),
    );

    expect(firestore['content'], isA<Map<String, dynamic>>());
    expect(firestore['partId'], original.partId);
    expect(firestore['topicId'], original.syllabus!.topicId);
    expect(firestore['lessonId'], original.lessonId);
    expect(restored, isNotNull);
    expect(restored!.content!.en.question, original.content!.en.question);
    expect(restored.content!.te!.options[1].text, 'హైదరాబాద్');
    expect(restored.syllabus!.partId, original.partId);
    expect(restored.syllabus!.lessonId, original.lessonId);
  });

  test('legacy scalar documents remain readable without reinterpretation', () {
    final restored = QuestionCloudMapper.fromFirestore('q-legacy', {
      'courseId': 'group-ii',
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

    expect(restored, isNotNull);
    expect(restored!.sectionId, 'section-1');
    expect(restored.topicId, 'topic-1');
    expect(restored.syllabus!.legacySectionId, 'section-1');
    expect(restored.syllabus!.legacyTopicId, 'topic-1');
    expect(restored.syllabus!.partId, isNull);
    expect(restored.content, isNull);
  });

  test('option shuffling preserves English/Telugu pairing', () {
    final question = canonicalQuestion(
      syllabus: const QuestionSyllabusAttribution(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      ),
    );
    final shuffled = QuestionService().shuffleOptions(question);
    final translations = <String, String>{
      'Warangal': 'వరంగల్',
      'Hyderabad': 'హైదరాబాద్',
      'Nizamabad': 'నిజామాబాద్',
      'Karimnagar': 'కరీంనగర్',
    };

    for (var i = 0; i < shuffled.options.length; i++) {
      expect(
        shuffled.content!.te!.options[i].text,
        translations[shuffled.options[i]],
      );
    }
  });
}
