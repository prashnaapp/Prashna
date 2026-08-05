import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/bookmark_cloud.dart';
import '../repository/bookmark_cloud_repository.dart';

/// App-facing API for cloud bookmark documents.
///
/// Firestore is a synchronized copy — local bookmarks remain source of truth.
class BookmarkCloudService {
  BookmarkCloudService({
    BookmarkCloudRepository? repository,
  }) : _repository = repository ?? BookmarkCloudRepository();

  static final BookmarkCloudService instance = BookmarkCloudService();

  final BookmarkCloudRepository _repository;

  Future<BookmarkCloud?> load(String uid) => _repository.load(uid);

  Future<void> createIfMissing(String uid) =>
      _repository.createIfMissing(uid);

  Future<void> update(BookmarkCloud bookmarks) =>
      _repository.update(bookmarks);

  /// Ensures the document exists, then writes the latest local snapshot.
  ///
  /// Never throws — failures are logged so callers can fire-and-forget safely.
  Future<void> syncSnapshot(BookmarkCloud bookmarks) async {
    // TEMP DEBUG (Milestone 19.1)
    debugPrint('BookmarkCloudService.syncSnapshot() entered');
    debugPrint('syncSnapshot uid=${bookmarks.uid}');
    debugPrint('syncSnapshot bookmark count=${bookmarks.questionIds.length}');
    try {
      await _repository.createIfMissing(bookmarks.uid);
      await _repository.update(bookmarks);
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 19.1)
      debugPrint(
        'FirebaseException in BookmarkCloudService.syncSnapshot: '
        'code=${error.code} message=${error.message}\n$stack',
      );
    } catch (error, stack) {
      debugPrint('BookmarkCloudService.syncSnapshot failed: $error\n$stack');
    }
  }
}
