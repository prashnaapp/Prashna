import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../model/user_progress.dart';

/// Firestore boundary for the top-level `user_progress` collection.
///
/// Document ID equals Firebase Authentication UID.
class ProgressCloudRepository {
  ProgressCloudRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'user_progress';

  final FirebaseFirestore _firestore;
  String? _cachedAppVersion;

  CollectionReference<Map<String, dynamic>> get _progress =>
      _firestore.collection(collectionName);

  DocumentReference<Map<String, dynamic>> docRef(String uid) =>
      _progress.doc(uid);

  Future<UserProgress?> load(String uid) async {
    try {
      final snapshot = await docRef(uid).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProgress.fromFirestore(uid, snapshot.data()!);
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 15.3)
      debugPrint(
        'FirebaseException in load: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('ProgressCloudRepository.load: $error\n$stack');
      rethrow;
    }
  }

  /// Creates `user_progress/{uid}` with zeroed defaults when missing.
  Future<void> createIfMissing(String uid) async {
    // TEMP DEBUG (Milestone 15.3)
    debugPrint('createIfMissing collection=$collectionName');
    debugPrint('createIfMissing documentId=$uid');
    try {
      final snapshot = await docRef(uid).get();
      if (snapshot.exists) return;

      final appVersion = await _resolveAppVersion();
      final initial = UserProgress.initial(uid: uid, appVersion: appVersion);
      await docRef(uid).set(initial.toCreateMap(appVersion: appVersion));
      // TEMP DEBUG (Milestone 15.3)
      debugPrint('createIfMissing success');
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 15.3)
      debugPrint(
        'FirebaseException in createIfMissing: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('ProgressCloudRepository.createIfMissing: $error\n$stack');
      rethrow;
    }
  }

  /// Replaces the progress document with [progress] (sets server timestamp).
  Future<void> update(UserProgress progress) async {
    try {
      final appVersion =
          progress.appVersion ?? await _resolveAppVersion();
      await docRef(progress.uid).set(
        progress.toUpdateMap(appVersion: appVersion),
        SetOptions(merge: false),
      );
      // TEMP DEBUG (Milestone 15.3)
      debugPrint('update success');
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 15.3)
      debugPrint(
        'FirebaseException in update: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('ProgressCloudRepository.update: $error\n$stack');
      rethrow;
    }
  }

  Future<String> _resolveAppVersion() async {
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
