import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_cloud_mapper.dart';
import 'package:telangana_prep/features/syllabus/data/models/canonical_scope.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/test_cloud_mapper.dart';

void main() {
  group('CanonicalScope validation', () {
    test('A: valid Group-II Paper-I', () {
      final scope = CanonicalScope.validated(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
        shape: CanonicalScopeShape.groupIiPaperI,
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      );

      expect(scope.partId, isNull);
      expect(scope.canonicalTopicId, isNull);
      expect(scope.lessonId, isNull);
      expect(scope.syllabusUnitId, scope.majorStudyAreaId);
      expect(
        scope.scopeKey,
        'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
      );
    });

    test('B: valid Group-II Part Unit', () {
      final scope = CanonicalScope.validated(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-ii',
        partId: 'group-ii-paper-ii-part-01',
        syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
        shape: CanonicalScopeShape.groupIiPartUnit,
        canonicalTopicId: 'group-ii-paper-ii-part-01-topic-04',
        lessonId: 'group-ii-paper-ii-part-01-topic-04-lesson-11',
      );

      expect(scope.majorStudyAreaId, isNull);
      expect(scope.contentTopicId, isNull);
      expect(
        scope.scopeKey,
        'v1|group-ii|group-ii-paper-ii|group-ii-paper-ii-part-01|'
        'group-ii-paper-ii-part-01-topic-04',
      );
    });

    test('C: valid Group-III Paper Unit', () {
      final scope = CanonicalScope.validated(
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: 'group-iii-paper-i-unit-01',
        shape: CanonicalScopeShape.groupIiiPaperUnit,
      );

      expect(scope.partId, isNull);
      expect(scope.lessonId, isNull);
      expect(
        scope.scopeKey,
        'v1|group-iii|group-iii-paper-i||group-iii-paper-i-unit-01',
      );
    });

    test('D: valid Group-III Part Unit', () {
      final scope = CanonicalScope.validated(
        courseId: 'group-iii',
        paperId: 'group-iii-paper-iii',
        partId: 'group-iii-paper-iii-part-i',
        syllabusUnitId: 'group-iii-paper-iii-part-i-unit-03',
        shape: CanonicalScopeShape.groupIiiPartUnit,
      );

      expect(scope.canonicalTopicId, isNull);
      expect(
        scope.scopeKey,
        'v1|group-iii|group-iii-paper-iii|group-iii-paper-iii-part-i|'
        'group-iii-paper-iii-part-i-unit-03',
      );
    });

    test('E: invalid shape combinations are rejected', () {
      expect(
        () => CanonicalScope.validated(
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
          syllabusUnitId: 'group-ii-paper-i-area-01',
          shape: CanonicalScopeShape.groupIiPaperI,
          majorStudyAreaId: 'group-ii-paper-i-area-01',
          partId: 'should-not-exist',
        ),
        throwsA(isA<CanonicalScopeValidationException>()),
      );

      expect(
        () => CanonicalScope.validated(
          courseId: 'group-ii',
          paperId: 'group-ii-paper-ii',
          partId: 'group-ii-paper-ii-part-01',
          syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
          shape: CanonicalScopeShape.groupIiPartUnit,
          canonicalTopicId: 'group-ii-paper-ii-part-01-topic-04',
          majorStudyAreaId: 'area',
        ),
        throwsA(isA<CanonicalScopeValidationException>()),
      );

      expect(
        () => CanonicalScope.validated(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-i',
          syllabusUnitId: 'group-iii-paper-i-unit-01',
          shape: CanonicalScopeShape.groupIiiPaperUnit,
          lessonId: 'lesson',
        ),
        throwsA(isA<CanonicalScopeValidationException>()),
      );
    });

    test('F/G/H: scopeKey is deterministic without display/legacy IDs', () {
      final a = CanonicalScope.validated(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
        shape: CanonicalScopeShape.groupIiPaperI,
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
        legacyTopicId: 'topic-1',
        legacySectionId: 'section-1',
      );
      final b = CanonicalScope.validated(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
        shape: CanonicalScopeShape.groupIiPaperI,
        majorStudyAreaId: 'group-ii-paper-i-area-01',
      );

      expect(a.scopeKey, b.scopeKey);
      expect(a.scopeKey.contains('Current Affairs'), isFalse);
      expect(a.scopeKey.contains('topic-1'), isFalse);
      expect(a.scopeKey.contains('section-1'), isFalse);
      expect(a.scopeKey.contains('legacy'), isFalse);
    });

    test('legacy-only attribution remains unmapped', () {
      final scope = CanonicalScope.tryResolve(
        courseId: 'group-ii',
        paperId: 'paper-1',
        partId: null,
        syllabusUnitId: null,
        topicId: null,
        legacySectionId: 'section-1',
        legacyTopicId: 'topic-1',
      );
      expect(scope, isNull);
    });

    test('does not treat contentTopicId as syllabusUnitId', () {
      final scope = CanonicalScope.tryResolve(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        majorStudyAreaId: 'group-ii-paper-i-area-01',
        contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      );
      expect(scope, isNotNull);
      expect(scope!.syllabusUnitId, 'group-ii-paper-i-area-01');
      expect(scope.contentTopicId, 'group-ii-paper-i-area-01-topic-01');
      expect(scope.syllabusUnitId, isNot(scope.contentTopicId));
    });
  });

  group('Question / Test integration', () {
    final now = DateTime(2026, 8, 15);

    Question groupIiPaperIQuestion() {
      return Question(
        id: 'q-gii-p1',
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        correctOption: 'A',
        difficulty: QuestionDifficulty.easy,
        questionType: QuestionType.practice,
        marks: 1,
        negativeMarks: 0,
        tags: const [],
        estimatedTime: const Duration(seconds: 30),
        createdAt: now,
        updatedAt: now,
        question: 'Paper I question?',
        options: const ['A', 'B', 'C', 'D'],
        explanation: 'Because A.',
        syllabus: const QuestionSyllabusAttribution(
          courseId: 'group-ii',
          paperId: 'group-ii-paper-i',
          majorStudyAreaId: 'group-ii-paper-i-area-01',
          contentTopicId: 'group-ii-paper-i-area-01-topic-01',
        ),
      );
    }

    test('I: Group-II existing question serialization remains compatible', () {
      final question = groupIiPaperIQuestion();
      final data = QuestionCloudMapper.toFirestore(question);

      expect(data['majorStudyAreaId'], 'group-ii-paper-i-area-01');
      expect(data['contentTopicId'], 'group-ii-paper-i-area-01-topic-01');
      expect(data.containsKey('syllabusUnitId'), isFalse);
      expect(data.containsKey('scopeKey'), isFalse);
      expect(data.containsKey('scopeShape'), isFalse);

      final restored = QuestionCloudMapper.fromFirestore('q-gii-p1', data)!;
      expect(restored.canonicalScope, isNotNull);
      expect(
        restored.canonicalScope!.syllabusUnitId,
        'group-ii-paper-i-area-01',
      );
      expect(
        restored.canonicalScope!.shape,
        CanonicalScopeShape.groupIiPaperI,
      );
    });

    test('J: Group-III question serialization works', () {
      final question = Question(
        id: 'q-giii',
        courseId: 'group-iii',
        paperId: 'group-iii-paper-iii',
        correctOption: 'B',
        difficulty: QuestionDifficulty.medium,
        questionType: QuestionType.practice,
        marks: 1,
        negativeMarks: 0,
        tags: const [],
        estimatedTime: const Duration(seconds: 30),
        createdAt: now,
        updatedAt: now,
        question: 'Group III?',
        options: const ['A', 'B', 'C', 'D'],
        explanation: 'B',
        syllabus: const QuestionSyllabusAttribution(
          courseId: 'group-iii',
          paperId: 'group-iii-paper-iii',
          partId: 'group-iii-paper-iii-part-i',
          syllabusUnitId: 'group-iii-paper-iii-part-i-unit-03',
        ),
      );

      final data = QuestionCloudMapper.toFirestore(question);
      expect(data['partId'], 'group-iii-paper-iii-part-i');
      expect(data['syllabusUnitId'], 'group-iii-paper-iii-part-i-unit-03');
      expect(data.containsKey('majorStudyAreaId'), isFalse);
      expect(data.containsKey('lessonId'), isFalse);

      final restored = QuestionCloudMapper.fromFirestore('q-giii', data)!;
      expect(
        restored.canonicalScope!.shape,
        CanonicalScopeShape.groupIiiPartUnit,
      );
      expect(
        restored.canonicalScope!.scopeKey,
        'v1|group-iii|group-iii-paper-iii|group-iii-paper-iii-part-i|'
        'group-iii-paper-iii-part-i-unit-03',
      );
    });

    test('K: Group-II TestModel compatibility without location', () {
      const test = TestModel(
        id: 'gii-legacy',
        examId: 'group-ii',
        category: TestCategoryType.mockTests,
        title: 'Legacy Group-II Mock',
        questionCount: 10,
        marks: 10,
        durationMinutes: 10,
        negativeMarking: '0',
        difficulty: 'Medium',
      );

      expect(test.canonicalScope, isNull);
      final data = TestCloudMapper.toFirestore(test, documentId: 'gii-legacy');
      expect(data.containsKey('paperId'), isFalse);
      expect(data.containsKey('syllabusUnitId'), isFalse);
      expect(data.containsKey('scopeKey'), isFalse);

      final restored = TestCloudMapper.fromFirestoreAdmin('gii-legacy', data)!;
      expect(restored.canonicalScope, isNull);
    });

    test('L: Group-III TestModel compatibility with location', () {
      const test = TestModel(
        id: 'giii-unit',
        examId: 'group-iii',
        category: TestCategoryType.chapterTests,
        title: 'Agriculture Unit Test',
        questionCount: 20,
        marks: 20,
        durationMinutes: 20,
        negativeMarking: '0',
        difficulty: 'Medium',
        paperId: 'group-iii-paper-iii',
        partId: 'group-iii-paper-iii-part-i',
        syllabusUnitId: 'group-iii-paper-iii-part-i-unit-03',
        scopeShape: CanonicalScopeShape.groupIiiPartUnit,
      );

      expect(test.canonicalScope, isNotNull);
      expect(
        test.canonicalScope!.shape,
        CanonicalScopeShape.groupIiiPartUnit,
      );

      final data = TestCloudMapper.toFirestore(test, documentId: 'giii-unit');
      expect(data['syllabusUnitId'], 'group-iii-paper-iii-part-i-unit-03');
      expect(data['scopeShape'], 'groupIiiPartUnit');
      expect(data.containsKey('scopeKey'), isFalse);

      final restored = TestCloudMapper.fromFirestore('giii-unit', {
        ...data,
        'isPublished': true,
        'status': 'published',
      })!;
      expect(restored.canonicalScope, isNotNull);
      expect(
        restored.canonicalScope!.syllabusUnitId,
        'group-iii-paper-iii-part-i-unit-03',
      );
    });

    test('O: legacy question docs still deserialize', () {
      final restored = QuestionCloudMapper.fromFirestore('legacy-q', {
        'id': 'legacy-q',
        'courseId': 'group-ii',
        'paperId': 'paper-1',
        'sectionId': 'section-1',
        'topicId': 'topic-1',
        'question': 'Old question?',
        'options': ['A', 'B', 'C', 'D'],
        'correctOption': 'A',
        'explanation': 'A',
        'difficulty': 'easy',
        'questionType': 'practice',
        'marks': 1,
        'negativeMarks': 0,
        'tags': <String>[],
        'estimatedTimeSeconds': 30,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isActive': true,
      });

      expect(restored, isNotNull);
      expect(restored!.sectionId, 'section-1');
      expect(restored.topicId, 'topic-1');
      expect(restored.canonicalScope, isNull);
    });
  });
}
