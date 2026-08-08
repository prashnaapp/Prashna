import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/models/test_models.dart';
import '../data/test_cloud_mapper.dart';

/// Firestore boundary for published Test Series definitions (`tests` collection).
///
/// Does not load questions, attempts, or unpublished tests.
class TestCloudRepository {
  TestCloudRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _loadPublishedTestsForTest = null;

  /// Unit-test constructor — does not touch Firestore.
  @visibleForTesting
  TestCloudRepository.withLoader(
    Future<List<TestModel>> Function(String courseId)
        this._loadPublishedTestsForTest,
  ) : _firestore = null;

  static const String collectionName = 'tests';

  final FirebaseFirestore? _firestore;

  /// Optional override for unit tests — never used in production.
  final Future<List<TestModel>> Function(String courseId)?
      _loadPublishedTestsForTest;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tests =>
      _db.collection(collectionName);

  /// Published tests for exactly [courseId] (`group-ii` / `group-iii`).
  ///
  /// Query constraints (required by security rules):
  /// - `courseId == courseId`
  /// - `isPublished == true`
  ///
  /// Intentionally **no** `orderBy`. The schema uses `title`, not `name`.
  /// Firestore may still show an internal `order by __name__` (doc id) in
  /// error logs — that is not an application `orderBy('name')`.
  /// UI list order is not required to be server-sorted.
  Future<List<TestModel>> loadPublishedTests(String courseId) async {
    final testLoader = _loadPublishedTestsForTest;
    if (testLoader != null) {
      return testLoader(courseId);
    }

    try {
      final snapshot = await _tests
          .where('courseId', isEqualTo: courseId)
          .where('isPublished', isEqualTo: true)
          .get();

      final tests = <TestModel>[];
      for (final doc in snapshot.docs) {
        final mapped = TestCloudMapper.fromFirestore(doc.id, doc.data());
        if (mapped == null) continue;
        // Defense in depth: never surface another course's document.
        if (mapped.examId != courseId) continue;
        tests.add(mapped);
      }
      return tests;
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestCloudRepository.loadPublishedTests: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('TestCloudRepository.loadPublishedTests: $error\n$stack');
      rethrow;
    }
  }
}
