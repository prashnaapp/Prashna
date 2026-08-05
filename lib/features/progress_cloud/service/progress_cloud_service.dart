import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/user_progress.dart';
import '../repository/progress_cloud_repository.dart';

/// App-facing API for cloud progress documents.
///
/// Firestore is a synchronized copy — local [ProgressService] remains source of truth.
class ProgressCloudService {
  ProgressCloudService({
    ProgressCloudRepository? repository,
  }) : _repository = repository ?? ProgressCloudRepository();

  static final ProgressCloudService instance = ProgressCloudService();

  final ProgressCloudRepository _repository;

  Future<UserProgress?> load(String uid) => _repository.load(uid);

  Future<void> createIfMissing(String uid) =>
      _repository.createIfMissing(uid);

  Future<void> update(UserProgress progress) =>
      _repository.update(progress);

  /// Ensures the document exists, then writes the latest local snapshot.
  ///
  /// Never throws — failures are logged so callers can fire-and-forget safely.
  Future<void> syncSnapshot(UserProgress progress) async {
    // TEMP DEBUG (Milestone 15.3)
    debugPrint('syncSnapshot entered');
    try {
      await _repository.createIfMissing(progress.uid);
      await _repository.update(progress);
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 15.3)
      debugPrint(
        'FirebaseException in syncSnapshot: '
        'code=${error.code} message=${error.message}\n$stack',
      );
    } catch (error, stack) {
      debugPrint('ProgressCloudService.syncSnapshot failed: $error\n$stack');
    }
  }
}
