import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../admin/data/admin_content_callable_client.dart';
import '../data/models/test_models.dart';
import '../data/test_cloud_mapper.dart';

/// Firestore boundary for published Test Series definitions (`tests` collection).
///
/// Does not load questions, attempts, or unpublished tests.
class TestCloudRepository {
  TestCloudRepository({
    FirebaseFirestore? firestore,
    AdminContentCallableClient? contentCallables,
  }) : _firestore = firestore, // ignore: prefer_initializing_formals
       _contentCallables =
           contentCallables, // ignore: prefer_initializing_formals
       _loadPublishedTestsForTest = null,
       _loadAdminTestsForTest = null,
       _getByIdForTest = null,
       _createForTest = null,
       _updateForTest = null,
       _setPublishedForTest = null,
       _idGeneratorForTest = null;

  /// Unit-test constructor — does not touch Firestore.
  @visibleForTesting
  TestCloudRepository.withLoader(
    Future<List<TestModel>> Function(String courseId)
    this._loadPublishedTestsForTest, {
    Future<List<TestModel>> Function(String courseId)? loadAdminTests,
    Future<TestModel?> Function(String testId)? getById,
    Future<void> Function({
      required String testId,
      required Map<String, dynamic> data,
    })?
    create,
    Future<void> Function({
      required String testId,
      required Map<String, dynamic> data,
    })?
    update,
    Future<void> Function({required String testId, required bool isPublished})?
    setPublished,
    String Function()? idGenerator,
  }) : _firestore = null,
       _contentCallables = null,
       _loadAdminTestsForTest = loadAdminTests,
       _getByIdForTest = getById,
       _createForTest = create,
       _updateForTest = update,
       _setPublishedForTest = setPublished,
       _idGeneratorForTest = idGenerator;

  static const String collectionName = 'tests';

  final FirebaseFirestore? _firestore;
  final AdminContentCallableClient? _contentCallables;

  /// Optional override for unit tests — never used in production.
  final Future<List<TestModel>> Function(String courseId)?
  _loadPublishedTestsForTest;
  final Future<List<TestModel>> Function(String courseId)?
  _loadAdminTestsForTest;
  final Future<TestModel?> Function(String testId)? _getByIdForTest;
  final Future<void> Function({
    required String testId,
    required Map<String, dynamic> data,
  })?
  _createForTest;
  final Future<void> Function({
    required String testId,
    required Map<String, dynamic> data,
  })?
  _updateForTest;
  final Future<void> Function({
    required String testId,
    required bool isPublished,
  })?
  _setPublishedForTest;
  final String Function()? _idGeneratorForTest;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tests =>
      _db.collection(collectionName);

  AdminContentCallableClient get _callables =>
      _contentCallables ?? AdminContentCallableClient();

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

  /// Admin-visible tests for exactly [courseId], including drafts.
  Future<List<TestModel>> loadAdminTests(String courseId) async {
    final testLoader = _loadAdminTestsForTest;
    if (testLoader != null) {
      return testLoader(courseId);
    }

    try {
      final snapshot = await _tests
          .where('courseId', isEqualTo: courseId)
          .get();

      final tests = <TestModel>[];
      for (final doc in snapshot.docs) {
        final mapped = TestCloudMapper.fromFirestoreAdmin(doc.id, doc.data());
        if (mapped == null) continue;
        if (mapped.examId != courseId) continue;
        tests.add(mapped);
      }
      return tests;
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestCloudRepository.loadAdminTests: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('TestCloudRepository.loadAdminTests: $error\n$stack');
      rethrow;
    }
  }

  /// Loads a single test for admin editing, including drafts.
  Future<TestModel?> getAdminTestById(String testId) async {
    final testGet = _getByIdForTest;
    if (testGet != null) return testGet(testId);

    final id = testId.trim();
    if (id.isEmpty) return null;

    try {
      final snapshot = await _tests.doc(id).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return TestCloudMapper.fromFirestoreAdmin(id, snapshot.data()!);
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestCloudRepository.getAdminTestById: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('TestCloudRepository.getAdminTestById: $error\n$stack');
      rethrow;
    }
  }

  /// Creates a test with a generated Firestore ID.
  ///
  /// New tests always start as drafts. Explicit question IDs are persisted when
  /// provided; empty means dynamic Question Bank selection at attempt time.
  Future<String> createTest(TestModel test) async {
    final testCreate = _createForTest;
    final testId =
        _idGeneratorForTest?.call() ??
        (testCreate != null
            ? 'admin-${DateTime.now().microsecondsSinceEpoch}'
            : _tests.doc().id);
    final data = TestCloudMapper.toFirestore(
      TestModel(
        id: testId,
        examId: test.examId,
        category: test.category,
        title: test.title,
        description: test.description,
        questionCount: test.questionCount,
        marks: test.marks,
        durationMinutes: test.durationMinutes,
        negativeMarking: test.negativeMarking,
        difficulty: test.difficulty,
        questionIds: test.questionIds,
        status: TestPublicationStatus.draft,
        paperId: test.paperId,
        partId: test.partId,
        syllabusUnitId: test.syllabusUnitId,
        majorStudyAreaId: test.majorStudyAreaId,
        contentTopicId: test.contentTopicId,
        canonicalTopicId: test.canonicalTopicId,
        lessonId: test.lessonId,
        scopeShape: test.scopeShape,
      ),
      documentId: testId,
    );
    try {
      if (testCreate != null) {
        await testCreate(testId: testId, data: data);
      } else {
        await _callables.createTest(testId: testId, data: data);
      }
      return testId;
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestCloudRepository.createTest: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('TestCloudRepository.createTest: $error\n$stack');
      rethrow;
    }
  }

  /// Updates editable metadata, including explicit [questionIds] assignment.
  Future<void> updateTest(TestModel test) async {
    final testId = test.id.trim();
    if (testId.isEmpty) {
      throw const FormatException('Test ID is required for update.');
    }
    final data = TestCloudMapper.toFirestore(
      test,
      documentId: testId,
      forUpdate: true,
    );
    try {
      if (_updateForTest != null) {
        await _updateForTest(testId: testId, data: data);
      } else {
        await _callables.updateTest(testId: testId, data: data);
      }
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestCloudRepository.updateTest: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('TestCloudRepository.updateTest: $error\n$stack');
      rethrow;
    }
  }

  /// Sets catalog visibility without changing other metadata.
  Future<void> setTestPublished(
    String testId, {
    required bool isPublished,
  }) async {
    final id = testId.trim();
    if (id.isEmpty) {
      throw const FormatException('Test ID is required.');
    }
    try {
      if (_setPublishedForTest != null) {
        await _setPublishedForTest(testId: id, isPublished: isPublished);
      } else if (isPublished) {
        await _callables.publishTest(testId: id);
      } else {
        await _callables.setTestStatus(testId: id, status: 'draft');
      }
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestCloudRepository.setTestPublished: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('TestCloudRepository.setTestPublished: $error\n$stack');
      rethrow;
    }
  }

  /// Sets draft / published / archived lifecycle.
  Future<void> setTestStatus(
    String testId,
    TestPublicationStatus status,
  ) async {
    final id = testId.trim();
    if (id.isEmpty) {
      throw const FormatException('Test ID is required.');
    }
    try {
      if (_updateForTest != null) {
        await _updateForTest(
          testId: id,
          data: TestCloudMapper.toStatusMap(status),
        );
      } else if (_setPublishedForTest != null) {
        await _setPublishedForTest(
          testId: id,
          isPublished: status == TestPublicationStatus.published,
        );
      } else {
        await _callables.setTestStatus(testId: id, status: status.name);
      }
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in TestCloudRepository.setTestStatus: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('TestCloudRepository.setTestStatus: $error\n$stack');
      rethrow;
    }
  }
}
