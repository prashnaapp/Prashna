import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/user_course.dart';

/// Firestore boundary for `user_courses/{uid}/courses/{courseId}`.
///
/// Legacy flat docs at `user_courses/{uid}` are migrated into the subcollection
/// idempotently and are never deleted.
class UserCourseRepository {
  UserCourseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'user_courses';
  static const String coursesSubcollectionName = 'courses';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _userCourses =>
      _firestore.collection(collectionName);

  DocumentReference<Map<String, dynamic>> userDocRef(String uid) =>
      _userCourses.doc(uid);

  CollectionReference<Map<String, dynamic>> coursesRef(String uid) =>
      userDocRef(uid).collection(coursesSubcollectionName);

  DocumentReference<Map<String, dynamic>> courseDocRef(
    String uid,
    String courseId,
  ) => coursesRef(uid).doc(courseId);

  /// Loads all course enrollments for [uid], migrating legacy data first.
  Future<List<UserCourse>> loadEnrollments(String uid) async {
    try {
      await migrateLegacyIfNeeded(uid);
      final snapshot = await coursesRef(uid).get();
      return [
        for (final doc in snapshot.docs)
          UserCourse.fromFirestore(uid, doc.data(), courseIdFallback: doc.id),
      ];
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in UserCourseRepository.loadEnrollments: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('UserCourseRepository.loadEnrollments: $error\n$stack');
      rethrow;
    }
  }

  /// Loads a single course enrollment for [uid] / [courseId].
  Future<UserCourse?> loadEnrollment(String uid, String courseId) async {
    try {
      await migrateLegacyIfNeeded(uid);
      final snapshot = await courseDocRef(uid, courseId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserCourse.fromFirestore(
        uid,
        snapshot.data()!,
        courseIdFallback: courseId,
      );
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

  /// Creates `user_courses/{uid}/courses/{courseId}` (first activation).
  Future<void> createEnrollment(UserCourse enrollment) async {
    try {
      await courseDocRef(
        enrollment.uid,
        enrollment.courseId,
      ).set(enrollment.toCreateMap());
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

  /// Updates an existing course enrollment subdocument.
  Future<void> updateEnrollment(UserCourse enrollment) async {
    try {
      await courseDocRef(
        enrollment.uid,
        enrollment.courseId,
      ).update(enrollment.toUpdateMap());
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

  /// Best-effort legacy read helper.
  ///
  /// Client entitlement writes are disabled by Firestore rules, so this no
  /// longer copies legacy parent docs into the subcollection. Remaining
  /// legacy-only enrollments require a trusted server migration later.
  ///
  /// Never deletes the legacy parent document.
  Future<void> migrateLegacyIfNeeded(String uid) async {
    try {
      final legacySnap = await userDocRef(uid).get();
      if (!legacySnap.exists || legacySnap.data() == null) return;

      final data = legacySnap.data()!;
      final courseId = data['courseId'] as String?;
      if (courseId == null || courseId.isEmpty) return;

      // Skip if this is not a legacy enrollment-shaped parent (e.g. empty marker).
      if (!data.containsKey('status') && !data.containsKey('source')) return;

      final subRef = courseDocRef(uid, courseId);
      final existing = await subRef.get();
      if (existing.exists) return;

      debugPrint(
        'UserCourseRepository: legacy enrollment present but client '
        'migration writes are disabled (entitlement lockdown). '
        'uid=$uid courseId=$courseId — requires trusted server migration.',
      );
    } on FirebaseException catch (error, stack) {
      // Permission / network failures must not break enrollment reads.
      debugPrint(
        'FirebaseException in UserCourseRepository.migrateLegacyIfNeeded: '
        'code=${error.code} message=${error.message}\n$stack',
      );
    } catch (error, stack) {
      debugPrint('UserCourseRepository.migrateLegacyIfNeeded: $error\n$stack');
    }
  }
}
