import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/models/question_models.dart';
import '../data/question_cloud_mapper.dart';

/// Firestore boundary for the Question Bank (`questions` collection).
///
/// All list queries are course-scoped (and typically `isActive == true`) so
/// they satisfy security rules and never mix courses.
class QuestionCloudRepository {
  QuestionCloudRepository({this._firestore})
    : _loadQuestionsForTest = null,
      _getByIdForTest = null,
      _getByIdsForTest = null,
      _createForTest = null,
      _createBatchForTest = null,
      _updateForTest = null,
      _deactivateForTest = null,
      _idGeneratorForTest = null;

  /// Unit-test constructor — does not touch Firestore.
  @visibleForTesting
  QuestionCloudRepository.withHandlers({
    Future<List<Question>> Function(QuestionFilter? filter)? loadQuestions,
    Future<Question?> Function(String id)? getById,
    Future<List<Question>> Function(List<String> ids)? getByIds,
    Future<void> Function({
      required String questionId,
      required Map<String, dynamic> data,
    })?
    create,
    Future<void> Function({
      required List<({String questionId, Map<String, dynamic> data})> items,
    })?
    createBatch,
    Future<void> Function({
      required String questionId,
      required Map<String, dynamic> data,
    })?
    update,
    Future<void> Function({required String questionId, required bool isActive})?
    deactivate,
    String Function()? idGenerator,
  }) : _firestore = null,
       _loadQuestionsForTest = loadQuestions,
       _getByIdForTest = getById,
       _getByIdsForTest = getByIds,
       _createForTest = create,
       _createBatchForTest = createBatch,
       _updateForTest = update,
       _deactivateForTest = deactivate,
       _idGeneratorForTest = idGenerator;

  static const String collectionName = 'questions';
  static const int maxBatchSize = 500;

  final FirebaseFirestore? _firestore;
  final Future<List<Question>> Function(QuestionFilter? filter)?
  _loadQuestionsForTest;
  final Future<Question?> Function(String id)? _getByIdForTest;
  final Future<List<Question>> Function(List<String> ids)? _getByIdsForTest;
  final Future<void> Function({
    required String questionId,
    required Map<String, dynamic> data,
  })?
  _createForTest;
  final Future<void> Function({
    required List<({String questionId, Map<String, dynamic> data})> items,
  })?
  _createBatchForTest;
  final Future<void> Function({
    required String questionId,
    required Map<String, dynamic> data,
  })?
  _updateForTest;
  final Future<void> Function({
    required String questionId,
    required bool isActive,
  })?
  _deactivateForTest;
  final String Function()? _idGeneratorForTest;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _questions =>
      _db.collection(collectionName);

  /// Loads questions matching [filter].
  ///
  /// Prefer [QuestionFilter.courseId] so queries stay course-isolated.
  /// Topic / section / paper-only queries are allowed for revision helpers but
  /// still always constrain `isActive` when [QuestionFilter.activeOnly] is set.
  Future<List<Question>> loadQuestions({QuestionFilter? filter}) async {
    final testLoader = _loadQuestionsForTest;
    if (testLoader != null) return testLoader(filter);

    final courseId = filter?.courseId;
    final paperId = filter?.paperId;
    final sectionId = filter?.sectionId;
    final topicId = filter?.topicId;
    final partId = filter?.partId;
    final lessonId = filter?.lessonId;
    final syllabusUnitId = filter?.syllabusUnitId;
    final majorStudyAreaId = filter?.majorStudyAreaId;
    final contentTopicId = filter?.contentTopicId;

    final hasCourseScope = courseId != null && courseId.isNotEmpty;
    final hasHierarchyScope =
        (paperId != null && paperId.isNotEmpty) ||
        (sectionId != null && sectionId.isNotEmpty) ||
        (topicId != null && topicId.isNotEmpty) ||
        (partId != null && partId.isNotEmpty) ||
        (lessonId != null && lessonId.isNotEmpty) ||
        (syllabusUnitId != null && syllabusUnitId.isNotEmpty) ||
        (majorStudyAreaId != null && majorStudyAreaId.isNotEmpty) ||
        (contentTopicId != null && contentTopicId.isNotEmpty);

    if (!hasCourseScope && !hasHierarchyScope) {
      throw StateError(
        'QuestionCloudRepository.loadQuestions requires courseId '
        '(or paperId/sectionId/topicId). Unscoped queries are not allowed.',
      );
    }

    try {
      Query<Map<String, dynamic>> query = _questions;

      if (hasCourseScope) {
        query = query.where('courseId', isEqualTo: courseId);
      }

      final activeOnly = filter?.activeOnly ?? true;
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      if (filter?.questionType != null) {
        query = query.where(
          'questionType',
          isEqualTo: _questionTypeFirestoreValue(filter!.questionType!),
        );
      }
      if (paperId != null && paperId.isNotEmpty) {
        query = query.where('paperId', isEqualTo: paperId);
      }
      if (sectionId != null && sectionId.isNotEmpty) {
        query = query.where('sectionId', isEqualTo: sectionId);
      }
      if (topicId != null && topicId.isNotEmpty) {
        query = query.where('topicId', isEqualTo: topicId);
      }
      if (partId != null && partId.isNotEmpty) {
        query = query.where('partId', isEqualTo: partId);
      }
      if (lessonId != null && lessonId.isNotEmpty) {
        query = query.where('lessonId', isEqualTo: lessonId);
      }
      if (syllabusUnitId != null && syllabusUnitId.isNotEmpty) {
        query = query.where('syllabusUnitId', isEqualTo: syllabusUnitId);
      }
      if (majorStudyAreaId != null && majorStudyAreaId.isNotEmpty) {
        query = query.where('majorStudyAreaId', isEqualTo: majorStudyAreaId);
      }
      if (contentTopicId != null && contentTopicId.isNotEmpty) {
        query = query.where('contentTopicId', isEqualTo: contentTopicId);
      }
      if (filter?.difficulty != null) {
        query = query.where('difficulty', isEqualTo: filter!.difficulty!.name);
      }
      if (filter?.language != null) {
        query = query.where('language', isEqualTo: filter!.language);
      }
      if (filter?.year != null) {
        query = query.where('year', isEqualTo: filter!.year);
      }

      final snapshot = await query.get();
      final results = <Question>[];
      for (final doc in snapshot.docs) {
        final mapped = QuestionCloudMapper.fromFirestore(doc.id, doc.data());
        if (mapped == null) continue;
        if (hasCourseScope && mapped.courseId != courseId) continue;
        if (activeOnly && !mapped.isActive) continue;
        results.add(mapped);
      }
      return results;
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in QuestionCloudRepository.loadQuestions: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('QuestionCloudRepository.loadQuestions: $error\n$stack');
      rethrow;
    }
  }

  Future<Question?> getQuestionById(String id) async {
    final testGet = _getByIdForTest;
    if (testGet != null) return testGet(id);

    try {
      final snapshot = await _questions.doc(id).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return QuestionCloudMapper.fromFirestore(id, snapshot.data()!);
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in QuestionCloudRepository.getQuestionById: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('QuestionCloudRepository.getQuestionById: $error\n$stack');
      rethrow;
    }
  }

  /// Loads questions by stable IDs, preserving [ids] order.
  Future<List<Question>> getByIds(List<String> ids) async {
    final testGet = _getByIdsForTest;
    if (testGet != null) return testGet(ids);

    if (ids.isEmpty) return const [];

    try {
      final unique = ids.toSet().toList(growable: false);
      final fetched = await Future.wait([
        for (final id in unique) getQuestionById(id),
      ]);
      final byId = <String, Question>{};
      for (final question in fetched) {
        if (question != null) byId[question.id] = question;
      }
      return [
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ];
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in QuestionCloudRepository.getByIds: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('QuestionCloudRepository.getByIds: $error\n$stack');
      rethrow;
    }
  }

  /// Creates a question with a generated Firestore ID.
  ///
  /// The generated ID is also stored in the document's `id` field.
  Future<String> createQuestion(Question question) async {
    final testCreate = _createForTest;
    final questionId =
        _idGeneratorForTest?.call() ??
        (testCreate != null
            ? 'admin-${DateTime.now().microsecondsSinceEpoch}'
            : _questions.doc().id);
    final data = QuestionCloudMapper.toFirestore(
      question,
      includeCreatedAt: true,
      documentId: questionId,
    );
    // Legacy writes retain their historical active default. Canonical admin
    // writes carry an explicit draft/published/archived status.
    if (question.status == null) data['isActive'] = true;
    try {
      if (testCreate != null) {
        await testCreate(questionId: questionId, data: data);
      } else {
        await _questions.doc(questionId).set(data);
      }
      return questionId;
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in QuestionCloudRepository.createQuestion: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('QuestionCloudRepository.createQuestion: $error\n$stack');
      rethrow;
    }
  }

  /// Atomically creates many questions in one WriteBatch.
  ///
  /// Uses a supplied question ID when non-empty; otherwise generates one with
  /// the same strategy as [createQuestion]. Fails the whole batch if any write
  /// cannot be prepared. Firestore batches are capped at [maxBatchSize].
  Future<List<String>> createQuestionsBatch(List<Question> questions) async {
    if (questions.isEmpty) return const [];
    if (questions.length > maxBatchSize) {
      throw FormatException(
        'Batch import supports at most $maxBatchSize questions per request.',
      );
    }

    final items = <({String questionId, Map<String, dynamic> data})>[];
    var generatedIndex = 0;
    for (final question in questions) {
      final supplied = question.id.trim();
      final questionId = supplied.isNotEmpty
          ? supplied
          : (_idGeneratorForTest?.call() ??
                (_createBatchForTest != null || _createForTest != null
                    ? 'admin-batch-${DateTime.now().microsecondsSinceEpoch}-'
                          '${generatedIndex++}'
                    : _questions.doc().id));
      final data = QuestionCloudMapper.toFirestore(
        question,
        includeCreatedAt: true,
        documentId: questionId,
      );
      if (question.status == null) data['isActive'] = true;
      items.add((questionId: questionId, data: data));
    }

    final testBatch = _createBatchForTest;
    if (testBatch != null) {
      await testBatch(items: items);
      return [for (final item in items) item.questionId];
    }

    // Fallback for unit tests that only stub single create.
    final testCreate = _createForTest;
    if (testCreate != null) {
      for (final item in items) {
        await testCreate(questionId: item.questionId, data: item.data);
      }
      return [for (final item in items) item.questionId];
    }

    try {
      final batch = _db.batch();
      for (final item in items) {
        batch.set(_questions.doc(item.questionId), item.data);
      }
      await batch.commit();
      return [for (final item in items) item.questionId];
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in QuestionCloudRepository.createQuestionsBatch: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint(
        'QuestionCloudRepository.createQuestionsBatch: $error\n$stack',
      );
      rethrow;
    }
  }

  /// Updates all editable fields while preserving `createdAt`.
  Future<void> updateQuestion(Question question) async {
    final questionId = question.id.trim();
    if (questionId.isEmpty) {
      throw const FormatException('Question ID is required for update.');
    }
    final data = QuestionCloudMapper.toFirestore(
      question,
      documentId: questionId,
    );
    try {
      final testUpdate = _updateForTest;
      if (testUpdate != null) {
        await testUpdate(questionId: questionId, data: data);
      } else {
        await _questions.doc(questionId).update(data);
      }
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in QuestionCloudRepository.updateQuestion: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('QuestionCloudRepository.updateQuestion: $error\n$stack');
      rethrow;
    }
  }

  /// Soft-deactivates or reactivates a question.
  Future<void> setQuestionActive(
    String questionId, {
    required bool isActive,
  }) async {
    final id = questionId.trim();
    if (id.isEmpty) {
      throw const FormatException('Question ID is required.');
    }
    final data = QuestionCloudMapper.toDeactivateMap(isActive: isActive);
    try {
      final testDeactivate = _deactivateForTest;
      if (testDeactivate != null) {
        await testDeactivate(questionId: id, isActive: isActive);
      } else {
        await _questions.doc(id).update(data);
      }
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in QuestionCloudRepository.setQuestionActive: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('QuestionCloudRepository.setQuestionActive: $error\n$stack');
      rethrow;
    }
  }

  Future<void> setQuestionStatus(
    String questionId,
    QuestionPublicationStatus status,
  ) async {
    final id = questionId.trim();
    if (id.isEmpty) {
      throw const FormatException('Question ID is required.');
    }
    final data = QuestionCloudMapper.toStatusMap(status);
    final testUpdate = _updateForTest;
    if (testUpdate != null) {
      await testUpdate(questionId: id, data: data);
    } else {
      await _questions.doc(id).update(data);
    }
  }

  static String _questionTypeFirestoreValue(QuestionType type) {
    switch (type) {
      case QuestionType.practice:
        return 'practice';
      case QuestionType.previousYear:
        return 'previousYear';
      case QuestionType.mock:
        return 'mock';
    }
  }
}
