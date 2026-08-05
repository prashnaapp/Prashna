import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../model/bookmark_cloud.dart';

/// Firestore boundary for the top-level `user_bookmarks` collection.
///
/// Document ID equals Firebase Authentication UID.
class BookmarkCloudRepository {
  BookmarkCloudRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'user_bookmarks';

  final FirebaseFirestore _firestore;
  String? _cachedAppVersion;

  CollectionReference<Map<String, dynamic>> get _bookmarks =>
      _firestore.collection(collectionName);

  DocumentReference<Map<String, dynamic>> docRef(String uid) =>
      _bookmarks.doc(uid);

  Future<BookmarkCloud?> load(String uid) async {
    try {
      final snapshot = await docRef(uid).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return BookmarkCloud.fromFirestore(uid, snapshot.data()!);
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 19.1)
      debugPrint(
        'FirebaseException in BookmarkCloudRepository.load: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('BookmarkCloudRepository.load: $error\n$stack');
      rethrow;
    }
  }

  /// Creates `user_bookmarks/{uid}` with empty questionIds when missing.
  Future<void> createIfMissing(String uid) async {
    // TEMP DEBUG (Milestone 19.1)
    debugPrint('createIfMissing collection=$collectionName');
    debugPrint('createIfMissing documentId=$uid');
    try {
      final snapshot = await docRef(uid).get();
      // TEMP DEBUG (Milestone 19.1)
      debugPrint('createIfMissing document exists=${snapshot.exists}');
      if (snapshot.exists) return;

      final appVersion = await _resolveAppVersion();
      final initial = BookmarkCloud.initial(uid: uid, appVersion: appVersion);
      await docRef(uid).set(initial.toCreateMap(appVersion: appVersion));
      // TEMP DEBUG (Milestone 19.1)
      debugPrint('createIfMissing success');
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 19.1)
      debugPrint(
        'FirebaseException in BookmarkCloudRepository.createIfMissing: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('BookmarkCloudRepository.createIfMissing: $error\n$stack');
      rethrow;
    }
  }

  /// Replaces the bookmarks document with [bookmarks] (sets server timestamp).
  Future<void> update(BookmarkCloud bookmarks) async {
    try {
      final appVersion =
          bookmarks.appVersion ?? await _resolveAppVersion();
      await docRef(bookmarks.uid).set(
        bookmarks.toUpdateMap(appVersion: appVersion),
        SetOptions(merge: false),
      );
      // TEMP DEBUG (Milestone 19.1)
      debugPrint('update success');
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 19.1)
      debugPrint(
        'FirebaseException in BookmarkCloudRepository.update: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('BookmarkCloudRepository.update: $error\n$stack');
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
