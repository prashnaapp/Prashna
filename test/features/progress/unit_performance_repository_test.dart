import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress/data/models/unit_performance.dart';
import 'package:telangana_prep/features/progress_cloud/repository/unit_performance_cloud_repository.dart';
import 'package:telangana_prep/features/syllabus/data/models/canonical_scope.dart';

void main() {
  const uid = 'student-a';

  UnitPerformance sample({
    required String scopeKey,
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
  }) {
    return UnitPerformance(
      scopeKey: scopeKey,
      courseId: courseId,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: syllabusUnitId,
      testsAttempted: 2,
      testsCompleted: 2,
      questionsAttempted: 5,
      correct: 3,
      wrong: 1,
      skipped: 1,
      totalMarks: 5,
      marksObtained: 3,
      accuracy: 75,
      percentage: 60,
      bestMarks: 3,
      bestPercentage: 100,
      latestAttemptAt: DateTime.utc(2026, 8, 15, 10, 30),
      lastTestId: 't1',
      lastAttemptId: 'a1',
      authority: 'server_verified',
      schemaVersion: 1,
    );
  }

  group('UnitPerformanceCloudRepository', () {
    late InMemoryUnitPerformanceDocumentStore store;
    late UnitPerformanceCloudRepository repo;

    setUp(() {
      store = InMemoryUnitPerformanceDocumentStore();
      repo = UnitPerformanceCloudRepository(
        store: store,
        currentUid: () => uid,
      );
    });

    test('1/2: reads correct user path and scopeKey', () async {
      final scope = CanonicalScope.tryFromSyllabusUnit(
        courseId: 'group-iii',
        paperId: 'group-iii-paper-ii',
        partId: 'group-iii-paper-ii-part-i',
        syllabusUnitId: 'group-iii-paper-ii-part-i-unit-02',
      )!;
      store.seed(
        uid,
        scope.scopeKey,
        sample(
          scopeKey: scope.scopeKey,
          courseId: scope.courseId,
          paperId: scope.paperId,
          partId: scope.partId,
          syllabusUnitId: scope.syllabusUnitId,
        ).toMap()..['uid'] = uid,
      );

      final loaded = await repo.getUnitPerformance(scope.scopeKey);
      expect(store.lastUid, uid);
      expect(store.lastScopeKey, scope.scopeKey);
      expect(loaded, isNotNull);
      expect(loaded!.correct, 3);
      expect(loaded.bestPercentage, 100);
    });

    test('3: missing document returns null', () async {
      final loaded = await repo.getUnitPerformance(
        'v1|group-iii|group-iii-paper-i||missing-unit',
      );
      expect(loaded, isNull);
    });

    test('4: store failure is surfaced as error', () async {
      final failing = UnitPerformanceCloudRepository(
        store: _FailingStore(),
        currentUid: () => uid,
      );
      expect(
        () => failing.getUnitPerformance('v1|group-ii|group-ii-paper-i||area'),
        throwsA(isA<Exception>()),
      );
    });

    test('8: latest attempt timestamp parses safely', () async {
      final scopeKey = 'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01';
      store.seed(uid, scopeKey, {
        'uid': uid,
        'scopeKey': scopeKey,
        'courseId': 'group-ii',
        'paperId': 'group-ii-paper-i',
        'syllabusUnitId': 'group-ii-paper-i-area-01',
        'testsAttempted': 1,
        'testsCompleted': 1,
        'questionsAttempted': 1,
        'correct': 1,
        'wrong': 0,
        'skipped': 0,
        'totalMarks': 1,
        'marksObtained': 1,
        'accuracy': 100,
        'percentage': 100,
        'bestMarks': 1,
        'bestPercentage': 100,
        'latestAttemptAt': '2026-08-15T10:30:00.000Z',
      });

      final loaded = await repo.getUnitPerformance(scopeKey);
      expect(loaded!.latestAttemptAt, isNotNull);
      expect(loaded.latestAttemptAt!.toUtc().year, 2026);
    });

    test('15: signed-out state does not read another user', () async {
      final signedOut = UnitPerformanceCloudRepository(
        store: store,
        currentUid: () => null,
      );
      store.seed(
        'other-user',
        'v1|group-iii|group-iii-paper-i||unit-01',
        sample(
          scopeKey: 'v1|group-iii|group-iii-paper-i||unit-01',
          courseId: 'group-iii',
          paperId: 'group-iii-paper-i',
          syllabusUnitId: 'unit-01',
        ).toMap(),
      );

      expect(
        () => signedOut.getUnitPerformance(
          'v1|group-iii|group-iii-paper-i||unit-01',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('no authenticated user'),
          ),
        ),
      );
      expect(store.lastUid, isNull);
    });

    test('rejects uid mismatch in document body', () async {
      final scopeKey = 'v1|group-iii|group-iii-paper-i||unit-01';
      store.seed(uid, scopeKey, {
        'uid': 'other-user',
        'scopeKey': scopeKey,
        'courseId': 'group-iii',
        'paperId': 'group-iii-paper-i',
        'syllabusUnitId': 'unit-01',
        'testsAttempted': 1,
        'testsCompleted': 1,
        'questionsAttempted': 1,
        'correct': 1,
        'wrong': 0,
        'skipped': 0,
        'totalMarks': 1,
        'marksObtained': 1,
        'accuracy': 100,
        'percentage': 100,
        'bestMarks': 1,
        'bestPercentage': 100,
      });

      expect(
        () => repo.getUnitPerformance(scopeKey),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('CanonicalScope.tryFromSyllabusUnit', () {
    test('9: Group-II Paper-I scope works', () {
      final scope = CanonicalScope.tryFromSyllabusUnit(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
      );
      expect(scope, isNotNull);
      expect(scope!.shape, CanonicalScopeShape.groupIiPaperI);
      expect(scope.majorStudyAreaId, 'group-ii-paper-i-area-01');
      expect(scope.syllabusUnitId, 'group-ii-paper-i-area-01');
      expect(
        scope.scopeKey,
        'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
      );
      expect(scope.contentTopicId, isNull);
    });

    test('10: Group-II Part/Unit scope works', () {
      final scope = CanonicalScope.tryFromSyllabusUnit(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-ii',
        partId: 'group-ii-paper-ii-part-01',
        syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
      );
      expect(scope, isNotNull);
      expect(scope!.shape, CanonicalScopeShape.groupIiPartUnit);
      expect(
        scope.scopeKey,
        'v1|group-ii|group-ii-paper-ii|group-ii-paper-ii-part-01|'
        'group-ii-paper-ii-part-01-topic-04',
      );
    });

    test('11: Group-III Paper-I scope works', () {
      final scope = CanonicalScope.tryFromSyllabusUnit(
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        syllabusUnitId: 'group-iii-paper-i-unit-01',
      );
      expect(scope, isNotNull);
      expect(scope!.shape, CanonicalScopeShape.groupIiiPaperUnit);
      expect(
        scope.scopeKey,
        'v1|group-iii|group-iii-paper-i||group-iii-paper-i-unit-01',
      );
    });

    test('12: Group-III Part/Unit scope works', () {
      final scope = CanonicalScope.tryFromSyllabusUnit(
        courseId: 'group-iii',
        paperId: 'group-iii-paper-iii',
        partId: 'group-iii-paper-iii-part-i',
        syllabusUnitId: 'group-iii-paper-iii-part-i-unit-03',
      );
      expect(scope, isNotNull);
      expect(scope!.shape, CanonicalScopeShape.groupIiiPartUnit);
      expect(
        scope.scopeKey,
        'v1|group-iii|group-iii-paper-iii|group-iii-paper-iii-part-i|'
        'group-iii-paper-iii-part-i-unit-03',
      );
    });

    test('13: no topic/lesson fallback for ambiguous legacy ids', () {
      final scope = CanonicalScope.tryFromSyllabusUnit(
        courseId: 'group-ii',
        paperId: 'paper-1',
        syllabusUnitId: 'topic-1',
      );
      expect(scope, isNull);
    });
  });
}

class _FailingStore implements UnitPerformanceDocumentStore {
  @override
  Future<Map<String, dynamic>?> getUnitPerformance(
    String uid,
    String scopeKey,
  ) {
    throw Exception('network down');
  }
}
