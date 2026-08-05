import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/course.dart';

/// Firestore boundary for the top-level `courses` collection.
class CourseRepository {
  CourseRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'courses';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection(collectionName);

  DocumentReference<Map<String, dynamic>> docRef(String courseId) =>
      _courses.doc(courseId);

  /// Loads catalog documents where `isPublished == true`.
  ///
  /// Sorting by `sortOrder` is intentionally left to [CourseCatalogService].
  Future<List<Course>> loadPublishedCourses() async {
    try {
      final snapshot = await _courses
          .where('isPublished', isEqualTo: true)
          .get();
      return [
        for (final doc in snapshot.docs)
          Course.fromFirestore(doc.id, doc.data()),
      ];
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in CourseRepository.loadPublishedCourses: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('CourseRepository.loadPublishedCourses: $error\n$stack');
      rethrow;
    }
  }

  Future<Course?> loadCourse(String courseId) async {
    try {
      final snapshot = await docRef(courseId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Course.fromFirestore(courseId, snapshot.data()!);
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in CourseRepository.loadCourse: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('CourseRepository.loadCourse: $error\n$stack');
      rethrow;
    }
  }
}
