import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/user_course.dart';

/// Firestore boundary for the top-level `user_courses` collection.
///
/// Document ID equals Firebase Authentication UID.
class UserCourseRepository {
  UserCourseRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'user_courses';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _userCourses =>
      _firestore.collection(collectionName);

  DocumentReference<Map<String, dynamic>> docRef(String uid) =>
      _userCourses.doc(uid);

  Future<UserCourse?> loadEnrollment(String uid) async {
    try {
      final snapshot = await docRef(uid).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserCourse.fromFirestore(uid, snapshot.data()!);
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in UserCourseRepository.loadEnrollment: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('UserCourseRepository.loadEnrollment: $error\n$stack');
      rethrow;
    }
  }

  Future<void> createEnrollment(UserCourse enrollment) async {
    try {
      await docRef(enrollment.uid).set(enrollment.toCreateMap());
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in UserCourseRepository.createEnrollment: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('UserCourseRepository.createEnrollment: $error\n$stack');
      rethrow;
    }
  }

  Future<void> updateEnrollment(UserCourse enrollment) async {
    try {
      await docRef(enrollment.uid).update(enrollment.toUpdateMap());
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in UserCourseRepository.updateEnrollment: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('UserCourseRepository.updateEnrollment: $error\n$stack');
      rethrow;
    }
  }
}
