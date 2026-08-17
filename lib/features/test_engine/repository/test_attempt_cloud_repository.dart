import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../authentication/services/auth_service.dart';
import '../../syllabus/services/syllabus_service.dart';
import '../data/models/test_attempt_history.dart';
import '../data/models/test_attempt_history_detail.dart';
import '../data/models/test_engine_models.dart';
import '../data/test_attempt_cloud_mapper.dart';

/// Firestore boundary for completed test attempts (`test_attempts` collection).
///
/// Write path does not own scoring — callers pass an existing [TestResult].
/// Read path returns stored results only (never recalculates).
class TestAttemptCloudRepository {
  TestAttemptCloudRepository({
    this._firestore,
    String? Function()? currentUid,
  }) : _currentUid = currentUid ?? _defaultUid,
       _saveForTest = null,
       _loadForTest = null,
       _loadDetailForTest = null;

  /// Unit-test constructor — does not touch Firestore.
  @visibleForTesting
  TestAttemptCloudRepository.withHandlers({
    Future<void> Function({
      required String attemptId,
      required Map<String, dynamic> data,
    })? saver,
    Future<List<TestAttemptHistoryItem>> Function({String? courseId})? loader,
    Future<TestAttemptHistoryDetail?> Function(String attemptId)? detailLoader,
    String? Function()? currentUid,
  }) : _firestore = null,
       _currentUid = currentUid ?? _defaultUid,
       _saveForTest = saver,
       _loadForTest = loader,
       _loadDetailForTest = detailLoader;

  /// Backward-compatible alias used by Milestone 30.2.4 tests.
  @visibleForTesting
  factory TestAttemptCloudRepository.withSaver({
    required Future<void> Function({
      required String attemptId,
      required Map<String, dynamic> data,
    }) saver,
    String? Function()? currentUid,
  }) {
    return TestAttemptCloudRepository.withHandlers(
      saver: saver,
      currentUid: currentUid,
    );
  }

  static const String collectionName = 'test_attempts';

  final FirebaseFirestore? _firestore;
  final String? Function() _currentUid;
  final Future<void> Function({
    required String attemptId,
    required Map<String, dynamic> data,
  })? _saveForTest;
  final Future<List<TestAttemptHistoryItem>> Function({String? courseId})?
      _loadForTest;
  final Future<TestAttemptHistoryDetail?> Function(String attemptId)?
      _loadDetailForTest;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attempts =>
      _db.collection(collectionName);

  static String? _defaultUid() => AuthService.instance.currentUser?.uid;

  /// Persists a completed attempt. Never throws to callers — returns failure.
  ///
  /// UID is always taken from auth ([_currentUid]), never from UI arguments.
  Future<TestAttemptSaveResult> saveCompletedAttempt({
    required Test test,
    required TestResult result,
    required List<QuestionAttempt> attempts,
    required Duration timeTaken,
    String? attemptId,
  }) async {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      final error = StateError(
        'Cannot save test attempt: no authenticated user.',
      );
      debugPrint('TestAttemptCloudRepository: $error');
      return TestAttemptSaveResult.failed(error);
    }

    final id = (attemptId != null && attemptId.isNotEmpty)
        ? attemptId
        : '${uid}_${test.id}_${DateTime.now().microsecondsSinceEpoch}';

    final submittedAt = DateTime.now();
    final startedAt = submittedAt.subtract(
      timeTaken.isNegative ? Duration.zero : timeTaken,
    );

    final courseTitle =
        SyllabusService.instance.getCourseById(test.courseId)?.name;

    final data = TestAttemptCloudMapper.toCreateMap(
      attemptId: id,
      uid: uid,
      test: test,
      result: result,
      attempts: attempts,
      startedAt: startedAt,
      courseTitle: courseTitle,
    );

    try {
      final testSaver = _saveForTest;
      if (testSaver != null) {
        await testSaver(attemptId: id, data: data);
      } else {
        await _attempts.doc(id).set(data);
      }
      return TestAttemptSaveResult.ok(id);
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestAttemptCloudRepository.saveCompletedAttempt: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      return TestAttemptSaveResult.failed(error, attemptId: id);
    } catch (error, stack) {
      debugPrint(
        'TestAttemptCloudRepository.saveCompletedAttempt failed: '
        '$error\n$stack',
      );
      return TestAttemptSaveResult.failed(error, attemptId: id);
    }
  }

  /// Loads the signed-in user's completed attempts, newest [startedAt] first.
  ///
  /// Query is always scoped to `uid == currentUser` — never loads other users.
  /// Optional [courseId] filters within that user-scoped result set.
  Future<List<TestAttemptHistoryItem>> getMyCompletedAttempts({
    String? courseId,
  }) async {
    final testLoader = _loadForTest;
    if (testLoader != null) {
      return testLoader(courseId: courseId);
    }

    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      debugPrint(
        'TestAttemptCloudRepository.getMyCompletedAttempts: no authenticated user',
      );
      return const [];
    }

    try {
      final snapshot = await _attempts
          .where('uid', isEqualTo: uid)
          .orderBy('startedAt', descending: true)
          .get();

      final items = <TestAttemptHistoryItem>[];
      for (final doc in snapshot.docs) {
        final mapped = TestAttemptCloudMapper.historyFromFirestore(
          doc.id,
          doc.data(),
        );
        if (mapped == null) continue;
        // Defense in depth: never surface another user's attempt.
        if (mapped.uid != null && mapped.uid != uid) continue;
        if (courseId != null &&
            courseId.isNotEmpty &&
            mapped.courseId != courseId) {
          continue;
        }
        items.add(mapped);
      }
      return items;
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestAttemptCloudRepository.getMyCompletedAttempts: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint(
        'TestAttemptCloudRepository.getMyCompletedAttempts: $error\n$stack',
      );
      rethrow;
    }
  }

  /// Loads one owned attempt including immutable question snapshots.
  ///
  /// Never reloads current Question documents. Returns null when missing or
  /// not owned by the signed-in user.
  Future<TestAttemptHistoryDetail?> getMyAttemptDetail(String attemptId) async {
    final cleanId = attemptId.trim();
    if (cleanId.isEmpty) return null;

    final testLoader = _loadDetailForTest;
    if (testLoader != null) {
      return testLoader(cleanId);
    }

    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      debugPrint(
        'TestAttemptCloudRepository.getMyAttemptDetail: no authenticated user',
      );
      return null;
    }

    try {
      final doc = await _attempts.doc(cleanId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final detail = TestAttemptCloudMapper.detailFromFirestore(doc.id, data);
      if (detail == null) return null;
      if (detail.summary.uid != null && detail.summary.uid != uid) {
        return null;
      }
      return detail;
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestAttemptCloudRepository.getMyAttemptDetail: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint(
        'TestAttemptCloudRepository.getMyAttemptDetail: $error\n$stack',
      );
      rethrow;
    }
  }
}
