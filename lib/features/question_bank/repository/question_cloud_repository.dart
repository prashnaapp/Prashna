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
      _getByIdsForTest = null;

  /// Unit-test constructor — does not touch Firestore.
  @visibleForTesting
  QuestionCloudRepository.withHandlers({
    Future<List<Question>> Function(QuestionFilter? filter)? loadQuestions,
    Future<Question?> Function(String id)? getById,
    Future<List<Question>> Function(List<String> ids)? getByIds,
  }) : _firestore = null,
       _loadQuestionsForTest = loadQuestions,
       _getByIdForTest = getById,
       _getByIdsForTest = getByIds;

  static const String collectionName = 'questions';

  final FirebaseFirestore? _firestore;
  final Future<List<Question>> Function(QuestionFilter? filter)?
      _loadQuestionsForTest;
  final Future<Question?> Function(String id)? _getByIdForTest;
  final Future<List<Question>> Function(List<String> ids)? _getByIdsForTest;

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

    final hasCourseScope = courseId != null && courseId.isNotEmpty;
    final hasHierarchyScope =
        (paperId != null && paperId.isNotEmpty) ||
        (sectionId != null && sectionId.isNotEmpty) ||
        (topicId != null && topicId.isNotEmpty);

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
      if (filter?.difficulty != null) {
        query = query.where(
          'difficulty',
          isEqualTo: filter!.difficulty!.name,
        );
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
