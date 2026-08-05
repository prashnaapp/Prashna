import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../model/revision_cloud.dart';

/// Firestore boundary for the top-level `user_revision` collection.
///
/// Document ID equals Firebase Authentication UID.
class RevisionCloudRepository {
  RevisionCloudRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'user_revision';

  final FirebaseFirestore _firestore;
  String? _cachedAppVersion;

  CollectionReference<Map<String, dynamic>> get _revision =>
      _firestore.collection(collectionName);

  DocumentReference<Map<String, dynamic>> docRef(String uid) =>
      _revision.doc(uid);

  Future<RevisionCloud?> load(String uid) async {
    try {
      final snapshot = await docRef(uid).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return RevisionCloud.fromFirestore(uid, snapshot.data()!);
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 21.1)
      debugPrint(
        'FirebaseException in RevisionCloudRepository.load: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('RevisionCloudRepository.load: $error\n$stack');
      rethrow;
    }
  }

  /// Creates `user_revision/{uid}` with empty question lists when missing.
  Future<void> createIfMissing(String uid) async {
    // TEMP DEBUG (Milestone 21.1)
    debugPrint('createIfMissing collection=$collectionName');
    debugPrint('createIfMissing documentId=$uid');
    try {
      final snapshot = await docRef(uid).get();
      // TEMP DEBUG (Milestone 21.1)
      debugPrint('createIfMissing document exists=${snapshot.exists}');
      if (snapshot.exists) return;

      final appVersion = await _resolveAppVersion();
      final initial = RevisionCloud.initial(uid: uid, appVersion: appVersion);
      await docRef(uid).set(initial.toCreateMap(appVersion: appVersion));
      // TEMP DEBUG (Milestone 21.1)
      debugPrint('createIfMissing success');
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 21.1)
      debugPrint(
        'FirebaseException in RevisionCloudRepository.createIfMissing: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('RevisionCloudRepository.createIfMissing: $error\n$stack');
      rethrow;
    }
  }

  /// Replaces the revision document with [revision] (sets server timestamp).
  Future<void> update(RevisionCloud revision) async {
    try {
      final appVersion =
          revision.appVersion ?? await _resolveAppVersion();
      await docRef(revision.uid).set(
        revision.toUpdateMap(appVersion: appVersion),
        SetOptions(merge: false),
      );
      // TEMP DEBUG (Milestone 21.1)
      debugPrint('update success');
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 21.1)
      debugPrint(
        'FirebaseException in RevisionCloudRepository.update: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('RevisionCloudRepository.update: $error\n$stack');
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
