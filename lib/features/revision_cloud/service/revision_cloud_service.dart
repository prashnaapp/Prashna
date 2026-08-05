import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/revision_cloud.dart';
import '../repository/revision_cloud_repository.dart';

/// App-facing API for cloud revision documents.
///
/// Firestore is a synchronized copy — local revision data remains source of truth.
class RevisionCloudService {
  RevisionCloudService({
    RevisionCloudRepository? repository,
  }) : _repository = repository ?? RevisionCloudRepository();

  static final RevisionCloudService instance = RevisionCloudService();

  final RevisionCloudRepository _repository;

  Future<RevisionCloud?> load(String uid) => _repository.load(uid);

  Future<void> createIfMissing(String uid) =>
      _repository.createIfMissing(uid);

  Future<void> update(RevisionCloud revision) =>
      _repository.update(revision);

  /// Ensures the document exists, then writes the latest local snapshot.
  ///
  /// Never throws — failures are logged so callers can fire-and-forget safely.
  Future<void> syncSnapshot(RevisionCloud revision) async {
    // TEMP DEBUG (Milestone 21.1)
    debugPrint('RevisionCloudService.syncSnapshot() entered');
    debugPrint('syncSnapshot uid=${revision.uid}');
    debugPrint(
      'syncSnapshot wrongQuestions=${revision.wrongQuestions.length} '
      'weakQuestions=${revision.weakQuestions.length} '
      'frequentlyWrongQuestions=${revision.frequentlyWrongQuestions.length}',
    );
    try {
      await _repository.createIfMissing(revision.uid);
      await _repository.update(revision);
    } on FirebaseException catch (error, stack) {
      // TEMP DEBUG (Milestone 21.1)
      debugPrint(
        'FirebaseException in RevisionCloudService.syncSnapshot: '
        'code=${error.code} message=${error.message}\n$stack',
      );
    } catch (error, stack) {
      debugPrint('RevisionCloudService.syncSnapshot failed: $error\n$stack');
    }
  }
}
