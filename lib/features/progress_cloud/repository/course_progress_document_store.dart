import 'package:cloud_firestore/cloud_firestore.dart';

/// Persistence seam for `user_progress/{uid}/courses/{courseId}` documents.
///
/// Implementations must never write the legacy parent `user_progress/{uid}`.
abstract class CourseProgressDocumentStore {
  Future<Map<String, dynamic>?> getCourse(String uid, String courseId);

  Future<bool> courseExists(String uid, String courseId);

  /// Returns course documents for [uid], keyed by courseId.
  Future<Map<String, Map<String, dynamic>>> listCourses(String uid);

  /// Replaces a single course document. Must not touch sibling courses.
  Future<void> setCourse(
    String uid,
    String courseId,
    Map<String, dynamic> data,
  );

  /// Creates the course document only when absent.
  ///
  /// Returns `true` when a new document was written, `false` when one already
  /// existed. Must never overwrite existing progress.
  Future<bool> createCourseIfAbsent(
    String uid,
    String courseId,
    Map<String, dynamic> data,
  );
}

/// Firestore implementation of [CourseProgressDocumentStore].
class FirestoreCourseProgressDocumentStore
    implements CourseProgressDocumentStore {
  FirestoreCourseProgressDocumentStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'user_progress';
  static const String coursesSubcollectionName = 'courses';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> courseDocRef(
    String uid,
    String courseId,
  ) {
    return _firestore
        .collection(collectionName)
        .doc(uid)
        .collection(coursesSubcollectionName)
        .doc(courseId);
  }

  @override
  Future<Map<String, dynamic>?> getCourse(String uid, String courseId) async {
    final snapshot = await courseDocRef(uid, courseId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return Map<String, dynamic>.from(snapshot.data()!);
  }

  @override
  Future<bool> courseExists(String uid, String courseId) async {
    final snapshot = await courseDocRef(uid, courseId).get();
    return snapshot.exists;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> listCourses(String uid) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .doc(uid)
        .collection(coursesSubcollectionName)
        .get();
    final result = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      result[doc.id] = Map<String, dynamic>.from(doc.data());
    }
    return result;
  }

  @override
  Future<void> setCourse(
    String uid,
    String courseId,
    Map<String, dynamic> data,
  ) async {
    // merge:false replaces THIS course document only — never the parent,
    // never sibling course documents.
    await courseDocRef(uid, courseId).set(
      data,
      SetOptions(merge: false),
    );
  }

  @override
  Future<bool> createCourseIfAbsent(
    String uid,
    String courseId,
    Map<String, dynamic> data,
  ) async {
    // Flutter cloud_firestore has no DocumentReference.create(); a transaction
    // provides atomic create-only semantics (no overwrite of concurrent writes).
    final ref = courseDocRef(uid, courseId);
    return _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) return false;
      transaction.set(ref, data);
      return true;
    });
  }
}

/// In-memory store for unit tests. Never touches Firebase or parent docs.
class InMemoryCourseProgressDocumentStore
    implements CourseProgressDocumentStore {
  final Map<String, Map<String, Map<String, dynamic>>> _byUid = {};

  /// Parent-keyed writes are intentionally unsupported / tracked for tests.
  int parentWriteAttempts = 0;

  @override
  Future<Map<String, dynamic>?> getCourse(String uid, String courseId) async {
    final course = _byUid[uid]?[courseId];
    if (course == null) return null;
    return Map<String, dynamic>.from(course);
  }

  @override
  Future<bool> courseExists(String uid, String courseId) async {
    return _byUid[uid]?.containsKey(courseId) ?? false;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> listCourses(String uid) async {
    final courses = _byUid[uid];
    if (courses == null) return {};
    return {
      for (final entry in courses.entries)
        entry.key: Map<String, dynamic>.from(entry.value),
    };
  }

  @override
  Future<void> setCourse(
    String uid,
    String courseId,
    Map<String, dynamic> data,
  ) async {
    final userCourses = _byUid.putIfAbsent(uid, () => {});
    userCourses[courseId] = Map<String, dynamic>.from(data);
  }

  @override
  Future<bool> createCourseIfAbsent(
    String uid,
    String courseId,
    Map<String, dynamic> data,
  ) async {
    final userCourses = _byUid.putIfAbsent(uid, () => {});
    if (userCourses.containsKey(courseId)) return false;
    userCourses[courseId] = Map<String, dynamic>.from(data);
    return true;
  }
}
