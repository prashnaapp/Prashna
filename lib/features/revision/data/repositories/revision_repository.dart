import '../models/revision_models.dart';

/// Persistence for revision session metadata (Firebase-ready).
/// Collection generation is derived from Question Bank + Progress.
class RevisionRepository {
  RevisionRepository._();

  static final RevisionRepository instance = RevisionRepository._();

  final List<RevisionCollectionType> _recentSessions = [];

  Future<void> recordSessionStarted(RevisionCollectionType type) async {
    _recentSessions.remove(type);
    _recentSessions.insert(0, type);
    if (_recentSessions.length > 10) {
      _recentSessions.removeLast();
    }
  }

  Future<List<RevisionCollectionType>> loadRecentSessionTypes() async {
    return List.unmodifiable(_recentSessions);
  }
}
