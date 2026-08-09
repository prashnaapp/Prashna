import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../authentication/services/user_session_state_coordinator.dart';
import '../model/user_progress.dart';
import 'course_progress_document_store.dart';

/// Firestore boundary for per-course progress:
/// `user_progress/{uid}/courses/{courseId}`.
///
/// Never writes the legacy parent `user_progress/{uid}`.
/// A write for Course A never touches Course B.
class CourseProgressCloudRepository {
  CourseProgressCloudRepository({
    CourseProgressDocumentStore? store,
    FirebaseFirestore? firestore,
    UserSessionStateCoordinator? sessionCoordinator,
    this._appVersionResolver,
  })  : _store = store ??
            FirestoreCourseProgressDocumentStore(firestore: firestore),
        _sessions = sessionCoordinator;

  static const String collectionName =
      FirestoreCourseProgressDocumentStore.collectionName;
  static const String coursesSubcollectionName =
      FirestoreCourseProgressDocumentStore.coursesSubcollectionName;

  final CourseProgressDocumentStore _store;
  final UserSessionStateCoordinator? _sessions;
  final Future<String> Function()? _appVersionResolver;
  String? _cachedAppVersion;

  /// Loads one course document, or null when missing.
  Future<UserProgress?> loadCourse(
    String uid,
    String courseId, {
    UserSessionIdentity? session,
  }) async {
    _validateOwnership(uid: uid, courseId: courseId);
    try {
      final data = await _store.getCourse(uid, courseId);
      if (!_isSessionCurrent(session)) return null;
      if (data == null) return null;
      return UserProgress.fromCourseFirestore(
        uid: uid,
        courseId: courseId,
        data: data,
      );
    } on FormatException catch (error, stack) {
      debugPrint(
        'CourseProgressCloudRepository.loadCourse malformed: $error\n$stack',
      );
      rethrow;
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in CourseProgressCloudRepository.loadCourse: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint(
        'CourseProgressCloudRepository.loadCourse: $error\n$stack',
      );
      rethrow;
    }
  }

  /// Loads all course documents under `user_progress/{uid}/courses`.
  ///
  /// Malformed sibling documents are skipped (logged) so one bad course
  /// does not block others.
  Future<List<UserProgress>> loadAllCourses(
    String uid, {
    UserSessionIdentity? session,
  }) async {
    _validateUid(uid);
    try {
      final raw = await _store.listCourses(uid);
      if (!_isSessionCurrent(session)) return const [];

      final results = <UserProgress>[];
      for (final entry in raw.entries) {
        try {
          results.add(
            UserProgress.fromCourseFirestore(
              uid: uid,
              courseId: entry.key,
              data: entry.value,
            ),
          );
        } on FormatException catch (error, stack) {
          debugPrint(
            'CourseProgressCloudRepository.loadAllCourses skip '
            'uid=$uid courseId=${entry.key}: $error\n$stack',
          );
        }
      }
      return results;
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in CourseProgressCloudRepository.loadAllCourses: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint(
        'CourseProgressCloudRepository.loadAllCourses: $error\n$stack',
      );
      rethrow;
    }
  }

  /// Creates a zeroed course document when missing. Never overwrites existing.
  Future<void> createCourseIfMissing(
    String uid,
    String courseId, {
    UserSessionIdentity? session,
  }) async {
    _validateOwnership(uid: uid, courseId: courseId);
    try {
      final exists = await _store.courseExists(uid, courseId);
      if (!_isSessionCurrent(session)) return;
      if (exists) return;

      final appVersion = await _resolveAppVersion();
      if (!_isSessionCurrent(session)) return;

      final initial = UserProgress.initial(
        uid: uid,
        courseId: courseId,
        appVersion: appVersion,
      );
      await _store.setCourse(
        uid,
        courseId,
        initial.toCourseCreateMap(appVersion: appVersion),
      );
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in '
        'CourseProgressCloudRepository.createCourseIfMissing: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint(
        'CourseProgressCloudRepository.createCourseIfMissing: $error\n$stack',
      );
      rethrow;
    }
  }

  /// Replaces a single course document with [snapshot].
  ///
  /// [snapshot.uid] and [snapshot.courseId] must match [uid]/[courseId].
  Future<void> updateCourse(
    String uid,
    String courseId,
    UserProgress snapshot, {
    UserSessionIdentity? session,
  }) async {
    _validateOwnership(uid: uid, courseId: courseId);
    if (snapshot.uid != uid) {
      throw ArgumentError(
        'Snapshot uid "${snapshot.uid}" does not match path uid "$uid"',
      );
    }
    if (snapshot.courseId != courseId) {
      throw ArgumentError(
        'Snapshot courseId "${snapshot.courseId}" does not match '
        'path courseId "$courseId"',
      );
    }

    try {
      if (!_isSessionCurrent(session)) return;

      final appVersion =
          snapshot.appVersion ?? await _resolveAppVersion();
      if (!_isSessionCurrent(session)) return;

      final payload = snapshot.toCourseUpdateMap(appVersion: appVersion);
      if (!_isSessionCurrent(session)) return;

      await _store.setCourse(uid, courseId, payload);
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in CourseProgressCloudRepository.updateCourse: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint(
        'CourseProgressCloudRepository.updateCourse: $error\n$stack',
      );
      rethrow;
    }
  }

  void _validateOwnership({
    required String uid,
    required String courseId,
  }) {
    _validateUid(uid);
    _validateCourseId(courseId);
  }

  void _validateUid(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError('uid must be a non-empty string');
    }
  }

  void _validateCourseId(String courseId) {
    final trimmed = courseId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('courseId must be a non-empty string');
    }
    if (trimmed.contains('/') || trimmed.contains('..')) {
      throw ArgumentError('courseId contains illegal path characters');
    }
  }

  bool _isSessionCurrent(UserSessionIdentity? session) {
    if (session == null || _sessions == null) return true;
    return _sessions.isCurrent(session);
  }

  Future<String> _resolveAppVersion() async {
    if (_appVersionResolver != null) {
      return _appVersionResolver();
    }
    if (_cachedAppVersion != null) return _cachedAppVersion!;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedAppVersion = info.version;
    } catch (error, stack) {
      debugPrint('PackageInfo failed: $error\n$stack');
      _cachedAppVersion = '1.0.0';
    }
    return _cachedAppVersion!;
  }
}
