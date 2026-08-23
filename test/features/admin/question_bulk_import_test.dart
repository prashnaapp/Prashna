import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/services/question_import_service.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/repository/question_cloud_repository.dart';

void main() {
  const paperIArea = 'group-ii-paper-i-area-01';
  const paperITopic = 'group-ii-paper-i-area-01-topic-01';
  const paperIIPart = 'group-ii-paper-ii-part-01';
  const paperIITopic = 'group-ii-paper-ii-part-01-topic-01';
  const paperIILesson = 'group-ii-paper-ii-part-01-topic-01-lesson-01';

  Map<String, dynamic> validPaperIRecord({
    String? id,
    String questionEn = 'Which city is the capital of Telangana?',
    String questionTe = 'తెలంగాణ రాజధాని ఏది?',
    List<Map<String, String>>? options,
    String correctOption = 'B',
    String explanationEn = 'Hyderabad is the capital.',
    String explanationTe = 'హైదరాబాద్ రాజధాని.',
    String? majorStudyAreaId = paperIArea,
    String? contentTopicId = paperITopic,
    String? partId,
    String? topicId,
    String? lessonId,
  }) {
    return {
      'id': ?id,
      'courseId': 'group-ii',
      'paperId': 'group-ii-paper-i',
      'majorStudyAreaId': ?majorStudyAreaId,
      'contentTopicId': ?contentTopicId,
      'partId': ?partId,
      'topicId': ?topicId,
      'lessonId': ?lessonId,
      'question': {'en': questionEn, 'te': questionTe},
      'options':
          options ??
          [
            {'en': 'Warangal', 'te': 'వరంగల్'},
            {'en': 'Hyderabad', 'te': 'హైదరాబాద్'},
            {'en': 'Nizamabad', 'te': 'నిజామాబాద్'},
            {'en': 'Karimnagar', 'te': 'కరీంనగర్'},
          ],
      'correctOption': correctOption,
      'explanation': {'en': explanationEn, 'te': explanationTe},
    };
  }

  Map<String, dynamic> validPaperIIRecord({String? id}) {
    return {
      'id': ?id,
      'courseId': 'group-ii',
      'paperId': 'group-ii-paper-ii',
      'partId': paperIIPart,
      'topicId': paperIITopic,
      'lessonId': paperIILesson,
      'question': {
        'en': 'Who designed the Indian national flag?',
        'te': 'భారత జాతీయ పతాకాన్ని ఎవరు రూపొందించారు?',
      },
      'options': [
        {'en': 'Pingali Venkayya', 'te': 'పింగళి వెంకయ్య'},
        {'en': 'Mahatma Gandhi', 'te': 'మహాత్మా గాంధీ'},
        {'en': 'Nehru', 'te': 'నెహ్రూ'},
        {'en': 'Ambedkar', 'te': 'అంబేద్కర్'},
      ],
      'correctOption': 'A',
      'explanation': {
        'en': 'Pingali Venkayya designed the national flag.',
        'te': 'పింగళి వెంకయ్య జాతీయ పతాకాన్ని రూపొందించారు.',
      },
    };
  }

  String wrap(List<Map<String, dynamic>> questions) {
    return jsonEncode({'questions': questions});
  }

  QuestionImportService service({
    List<Question> existing = const [],
    List<Map<String, dynamic>>? created,
    bool Function()? onWrite,
  }) {
    return QuestionImportService(
      questionRepository: QuestionCloudRepository.withHandlers(
        getByIds: (ids) async => [
          for (final question in existing)
            if (ids.contains(question.id)) question,
        ],
        createBatch: ({required items}) async {
          if (onWrite != null && !onWrite()) {
            fail('Unexpected write during validation');
          }
          created?.addAll([for (final item in items) item.data]);
        },
        idGenerator: () => 'generated-import-id',
      ),
    );
  }

  test('1: valid bilingual Paper I record', () async {
    final result = await service().validateJson(wrap([validPaperIRecord()]));
    expect(result.canImport, isTrue);
    expect(result.validRecords, 1);
    expect(
      result.validatedQuestions.single.status,
      QuestionPublicationStatus.draft,
    );
    expect(result.validatedQuestions.single.isActive, isFalse);
  });

  test('2: missing English question', () async {
    final result = await service().validateJson(
      wrap([validPaperIRecord(questionEn: ' ')]),
    );
    expect(result.canImport, isFalse);
    expect(result.errors.any((e) => e.field == 'question.en'), isTrue);
  });

  test('3: missing Telugu question', () async {
    final result = await service().validateJson(
      wrap([validPaperIRecord(questionTe: '')]),
    );
    expect(result.errors.any((e) => e.field == 'question.te'), isTrue);
  });

  test('4: wrong option count', () async {
    final result = await service().validateJson(
      wrap([
        validPaperIRecord(
          options: [
            {'en': 'A', 'te': 'ఎ'},
            {'en': 'B', 'te': 'బి'},
          ],
        ),
      ]),
    );
    expect(result.errors.any((e) => e.field == 'options'), isTrue);
  });

  test('5: missing Telugu option', () async {
    final result = await service().validateJson(
      wrap([
        validPaperIRecord(
          options: [
            {'en': 'Warangal', 'te': 'వరంగల్'},
            {'en': 'Hyderabad', 'te': ''},
            {'en': 'Nizamabad', 'te': 'నిజామాబాద్'},
            {'en': 'Karimnagar', 'te': 'కరీంనగర్'},
          ],
        ),
      ]),
    );
    expect(result.errors.any((e) => e.field == 'options[1].te'), isTrue);
  });

  test('6: invalid correct answer', () async {
    final result = await service().validateJson(
      wrap([validPaperIRecord(correctOption: 'E')]),
    );
    expect(result.errors.any((e) => e.field == 'correctOption'), isTrue);
  });

  test('7: missing explanation', () async {
    final result = await service().validateJson(
      wrap([validPaperIRecord(explanationEn: '', explanationTe: '')]),
    );
    expect(result.errors.any((e) => e.field == 'explanation.en'), isTrue);
    expect(result.errors.any((e) => e.field == 'explanation.te'), isTrue);
  });

  test('8: invalid Paper I hierarchy', () async {
    final withPart = await service().validateJson(
      wrap([validPaperIRecord(partId: 'legacy-section')]),
    );
    expect(withPart.errors.any((e) => e.field == 'partId'), isTrue);

    final missingArea = await service().validateJson(
      wrap([
        validPaperIRecord(majorStudyAreaId: null, contentTopicId: paperITopic),
      ]),
    );
    expect(
      missingArea.errors.any((e) => e.field == 'majorStudyAreaId'),
      isTrue,
    );
  });

  test('9: invalid Papers II–IV hierarchy', () async {
    final missingLessonRecord = validPaperIIRecord()..remove('lessonId');
    final missingLesson = await service().validateJson(
      wrap([missingLessonRecord]),
    );
    expect(missingLesson.errors.any((e) => e.field == 'lessonId'), isTrue);

    final missingPart = await service().validateJson(
      wrap([
        {
          'courseId': 'group-ii',
          'paperId': 'group-ii-paper-ii',
          'topicId': paperIITopic,
          'lessonId': paperIILesson,
          'question': {'en': 'Q', 'te': 'ప్ర'},
          'options': [
            {'en': 'A', 'te': 'ఎ'},
            {'en': 'B', 'te': 'బి'},
            {'en': 'C', 'te': 'సి'},
            {'en': 'D', 'te': 'డి'},
          ],
          'correctOption': 'A',
          'explanation': {'en': 'E', 'te': 'వి'},
        },
      ]),
    );
    expect(missingPart.errors.any((e) => e.field == 'partId'), isTrue);
  });

  test('10: duplicate records inside import', () async {
    final result = await service().validateJson(
      wrap([validPaperIRecord(id: 'q-dup'), validPaperIRecord(id: 'q-dup')]),
    );
    expect(result.canImport, isFalse);
    expect(result.duplicateOrCollisionRecords, containsAll([0, 1]));
  });

  test('11: existing ID collision', () async {
    final existing = Question(
      id: 'q-existing',
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      correctOption: 'A',
      difficulty: QuestionDifficulty.easy,
      questionType: QuestionType.practice,
      marks: 1,
      negativeMarks: 0,
      tags: const [],
      estimatedTime: const Duration(seconds: 60),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      question: 'Legacy',
      options: const ['A', 'B', 'C', 'D'],
      explanation: 'Legacy',
    );
    final result = await service(
      existing: [existing],
    ).validateJson(wrap([validPaperIRecord(id: 'q-existing')]));
    expect(result.canImport, isFalse);
    expect(result.errors.any((e) => e.field == 'id'), isTrue);
  });

  test('12: validation performs no writes', () async {
    var writes = 0;
    final created = <Map<String, dynamic>>[];
    final svc = service(
      created: created,
      onWrite: () {
        writes += 1;
        return true;
      },
    );
    await svc.validateJson(wrap([validPaperIRecord()]));
    expect(writes, 0);
    expect(created, isEmpty);
  });

  test('13: valid batch imports as drafts', () async {
    final created = <Map<String, dynamic>>[];
    final svc = service(created: created);
    final validation = await svc.validateJson(
      wrap([validPaperIRecord(), validPaperIIRecord()]),
    );
    final report = await svc.importValidatedBatch(validation);
    expect(report.succeeded, isTrue);
    expect(report.recordsImported, 2);
    expect(created, hasLength(2));
    expect(created.every((row) => row['status'] == 'draft'), isTrue);
    expect(created.every((row) => row['isActive'] == false), isTrue);
  });

  test('14: invalid batch imports nothing', () async {
    final created = <Map<String, dynamic>>[];
    final svc = service(created: created);
    final validation = await svc.validateJson(
      wrap([validPaperIRecord(), validPaperIRecord(questionEn: '')]),
    );
    final report = await svc.importValidatedBatch(validation);
    expect(report.succeeded, isFalse);
    expect(report.recordsImported, 0);
    expect(created, isEmpty);
  });

  test('15: imported question is inactive/draft', () async {
    final created = <Map<String, dynamic>>[];
    final svc = service(created: created);
    final validation = await svc.validateJson(wrap([validPaperIRecord()]));
    await svc.importValidatedBatch(validation);
    expect(created.single['status'], 'draft');
    expect(created.single['isActive'], isFalse);
  });

  test('16: English/Telugu option pairing survives import', () async {
    final created = <Map<String, dynamic>>[];
    final svc = service(created: created);
    final validation = await svc.validateJson(wrap([validPaperIRecord()]));
    await svc.importValidatedBatch(validation);
    final content = created.single['content'] as Map<String, dynamic>;
    final en = content['en'] as Map<String, dynamic>;
    final te = content['te'] as Map<String, dynamic>;
    expect(en['options'], ['Warangal', 'Hyderabad', 'Nizamabad', 'Karimnagar']);
    expect(te['options'], ['వరంగల్', 'హైదరాబాద్', 'నిజామాబాద్', 'కరీంనగర్']);
  });

  test('17: canonical IDs survive import', () async {
    final created = <Map<String, dynamic>>[];
    final svc = service(created: created);
    final validation = await svc.validateJson(
      wrap([validPaperIRecord(), validPaperIIRecord()]),
    );
    await svc.importValidatedBatch(validation);
    expect(created[0]['majorStudyAreaId'], paperIArea);
    expect(created[0]['contentTopicId'], paperITopic);
    expect(created[0].containsKey('partId'), isFalse);
    expect(created[1]['partId'], paperIIPart);
    expect(created[1]['topicId'], paperIITopic);
    expect(created[1]['lessonId'], paperIILesson);
  });

  test('content duplicate is a warning, not a silent delete', () async {
    final result = await service().validateJson(
      wrap([validPaperIRecord(), validPaperIRecord()]),
    );
    expect(result.warnings, isNotEmpty);
    expect(result.errors.where((e) => e.field == 'question'), isEmpty);
    expect(result.canImport, isTrue);
  });

  test(
    'write-time ID collision fails the batch and does not overwrite',
    () async {
      final store = <String, Map<String, dynamic>>{
        'q-race': {'id': 'q-race', 'question': 'Original'},
      };
      final svc = QuestionImportService(
        questionRepository: QuestionCloudRepository.withHandlers(
          getByIds: (ids) async => const [],
          createBatch: ({required items}) async {
            for (final item in items) {
              if (store.containsKey(item.questionId)) {
                throw FirebaseException(
                  plugin: 'cloud_firestore',
                  code: 'already-exists',
                  message: 'Document already exists: ${item.questionId}',
                );
              }
              store[item.questionId] = item.data;
            }
          },
        ),
      );

      final validation = await svc.validateJson(
        wrap([validPaperIRecord(id: 'q-race')]),
      );
      expect(validation.canImport, isTrue);

      final report = await svc.importValidatedBatch(validation);
      expect(report.succeeded, isFalse);
      expect(report.recordsImported, 0);
      expect(store['q-race']?['question'], 'Original');
    },
  );
}
