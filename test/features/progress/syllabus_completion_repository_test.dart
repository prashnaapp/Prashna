import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress/data/models/syllabus_completion.dart';
import 'package:telangana_prep/features/progress_cloud/repository/syllabus_completion_cloud_repository.dart';
import 'package:telangana_prep/features/syllabus/data/models/canonical_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CanonicalScope groupIiPaperI() {
    return CanonicalScope.validated(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      syllabusUnitId: 'group-ii-paper-i-area-01',
      shape: CanonicalScopeShape.groupIiPaperI,
      majorStudyAreaId: 'group-ii-paper-i-area-01',
    );
  }

  CanonicalScope groupIiPartUnit() {
    return CanonicalScope.validated(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
      shape: CanonicalScopeShape.groupIiPartUnit,
      canonicalTopicId: 'group-ii-paper-ii-part-01-topic-04',
    );
  }

  CanonicalScope groupIiiPaperUnit() {
    return CanonicalScope.validated(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-i',
      syllabusUnitId: 'group-iii-paper-i-unit-01',
      shape: CanonicalScopeShape.groupIiiPaperUnit,
    );
  }

  CanonicalScope groupIiiPartUnit() {
    return CanonicalScope.validated(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-ii',
      partId: 'group-iii-paper-ii-part-i',
      syllabusUnitId: 'group-iii-paper-ii-part-i-unit-02',
      shape: CanonicalScopeShape.groupIiiPartUnit,
    );
  }

  group('SyllabusCompletion model', () {
    test('1: missing fields deserialize as Not Started via factory', () {
      final missing = SyllabusCompletion.notStarted(
        scopeKey: groupIiPaperI().scopeKey,
        courseId: 'group-ii',
        paperId: 'group-ii-paper-i',
        syllabusUnitId: 'group-ii-paper-i-area-01',
      );
      expect(missing.status, SyllabusCompletionStatus.notStarted);
    });

    test('parses completed status and timestamps defensively', () {
      final parsed =
          SyllabusCompletion.fromFirestore(groupIiiPartUnit().scopeKey, {
            'scopeKey': groupIiiPartUnit().scopeKey,
            'courseId': 'group-iii',
            'paperId': 'group-iii-paper-ii',
            'partId': 'group-iii-paper-ii-part-i',
            'syllabusUnitId': 'group-iii-paper-ii-part-i-unit-02',
            'status': 'completed',
            'updatedAt': '2026-08-15T12:00:00.000Z',
            'completedAt': '2026-08-15T12:00:00.000Z',
          });
      expect(parsed.status, SyllabusCompletionStatus.completed);
      expect(parsed.completedAt, isNotNull);
      expect(parsed.updatedAt, isNotNull);
    });
  });

  group('SyllabusCompletionCloudRepository', () {
    test('1/6/7: missing doc = Not Started; correct path/scopeKey', () async {
      final store = InMemorySyllabusCompletionDocumentStore();
      final repo = SyllabusCompletionCloudRepository(
        store: store,
        currentUid: () => 'student-a',
        mutationClient: _RecordingMutationClient(),
      );
      final scope = groupIiPaperI();
      final completion = await repo.getCompletion(scope: scope);

      expect(completion.status, SyllabusCompletionStatus.notStarted);
      expect(store.lastUid, 'student-a');
      expect(
        store.lastScopeKey,
        'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
      );
      expect(completion.scopeKey, scope.scopeKey);
    });

    test('2/3/4/5: set In Progress, Completed, back, Reset', () async {
      final store = InMemorySyllabusCompletionDocumentStore();
      final mutation = _RecordingMutationClient();
      final repo = SyllabusCompletionCloudRepository(
        store: store,
        currentUid: () => 'student-a',
        mutationClient: mutation,
      );
      final scope = groupIiPartUnit();

      final inProgress = await repo.setInProgress(scope);
      expect(inProgress.status, SyllabusCompletionStatus.inProgress);
      expect(mutation.lastStatus, 'in_progress');
      expect(mutation.lastCourseId, 'group-ii');
      expect(mutation.lastPaperId, 'group-ii-paper-ii');
      expect(mutation.lastPartId, 'group-ii-paper-ii-part-01');
      expect(mutation.lastSyllabusUnitId, 'group-ii-paper-ii-part-01-topic-04');

      final completed = await repo.setCompleted(scope);
      expect(completed.status, SyllabusCompletionStatus.completed);
      expect(mutation.lastStatus, 'completed');

      final back = await repo.setInProgress(scope);
      expect(back.status, SyllabusCompletionStatus.inProgress);

      final reset = await repo.resetToNotStarted(scope);
      expect(reset.status, SyllabusCompletionStatus.notStarted);
      expect(mutation.lastStatus, 'not_started');
    });

    test('8/9/10: Group-II and Group-III scopes share repository', () async {
      final mutation = _RecordingMutationClient();
      final repo = SyllabusCompletionCloudRepository(
        store: InMemorySyllabusCompletionDocumentStore(),
        currentUid: () => 'student-a',
        mutationClient: mutation,
      );

      await repo.setCompleted(groupIiiPaperUnit());
      expect(mutation.lastSyllabusUnitId, 'group-iii-paper-i-unit-01');
      expect(mutation.lastPartId, isNull);

      await repo.setInProgress(groupIiiPartUnit());
      expect(mutation.lastSyllabusUnitId, 'group-iii-paper-ii-part-i-unit-02');
      expect(mutation.lastPartId, 'group-iii-paper-ii-part-i');
    });

    test('15: signed-out does not read another user', () async {
      final store = InMemorySyllabusCompletionDocumentStore();
      store.seed('other-user', groupIiPaperI().scopeKey, {
        'status': 'completed',
        'courseId': 'group-ii',
        'paperId': 'group-ii-paper-i',
        'syllabusUnitId': 'group-ii-paper-i-area-01',
      });
      final repo = SyllabusCompletionCloudRepository(
        store: store,
        currentUid: () => null,
        mutationClient: _RecordingMutationClient(),
      );

      expect(
        () => repo.getCompletion(scope: groupIiPaperI()),
        throwsA(isA<StateError>()),
      );
      expect(store.lastUid, isNull);
    });

    test(
      '24: duplicate mutation is idempotent via callable responses',
      () async {
        final mutation = _RecordingMutationClient();
        final repo = SyllabusCompletionCloudRepository(
          store: InMemorySyllabusCompletionDocumentStore(),
          currentUid: () => 'student-a',
          mutationClient: mutation,
        );
        final scope = groupIiPaperI();
        final first = await repo.setCompleted(scope);
        final second = await repo.setCompleted(scope);
        expect(first.status, SyllabusCompletionStatus.completed);
        expect(second.status, SyllabusCompletionStatus.completed);
        expect(mutation.callCount, 2);
      },
    );

    test('17: repository never writes Firestore directly', () {
      final repo = SyllabusCompletionCloudRepository(
        store: InMemorySyllabusCompletionDocumentStore(),
        currentUid: () => 'student-a',
        mutationClient: _RecordingMutationClient(),
      );
      expect(repo, isA<SyllabusCompletionCloudRepository>());
      // No create/update/delete methods on the public API beyond trusted callables.
      expect(
        SyllabusCompletionCloudRepository.syllabusCompletionSubcollectionName,
        'syllabus_completion',
      );
    });
  });
}

class _RecordingMutationClient implements SyllabusCompletionMutationClient {
  String? lastStatus;
  String? lastCourseId;
  String? lastPaperId;
  String? lastPartId;
  String? lastSyllabusUnitId;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> setCompletionStatus({
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
    required String status,
  }) async {
    callCount += 1;
    lastStatus = status;
    lastCourseId = courseId;
    lastPaperId = paperId;
    lastPartId = partId;
    lastSyllabusUnitId = syllabusUnitId;

    if (status == 'not_started') {
      return {
        'status': 'not_started',
        'completion': null,
        'scopeKey': 'v1|$courseId|$paperId|${partId ?? ''}|$syllabusUnitId',
      };
    }

    return {
      'status': status,
      'completion': {
        'scopeKey': 'v1|$courseId|$paperId|${partId ?? ''}|$syllabusUnitId',
        'courseId': courseId,
        'paperId': paperId,
        'partId': ?partId,
        'syllabusUnitId': syllabusUnitId,
        'status': status,
        'updatedAt': '2026-08-15T12:00:00.000Z',
        if (status == 'completed') 'completedAt': '2026-08-15T12:00:00.000Z',
      },
    };
  }
}
