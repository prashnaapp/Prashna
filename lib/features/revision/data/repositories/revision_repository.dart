import '../models/revision_models.dart';
import '../../../authentication/services/user_session_state_coordinator.dart';

/// Persistence for revision session metadata (Firebase-ready).
/// Collection generation is derived from Question Bank + Progress.
class RevisionRepository {
  RevisionRepository();

  static final RevisionRepository instance = RevisionRepository()
    .._registerSessionReset();

  final List<RevisionCollectionType> _recentSessions = [];

  Future<void> recordSessionStarted(RevisionCollectionType type) async {
    _recentSessions.remove(type);
    _recentSessions.insert(0, type);
    if (_recentSessions.length > 10) {
      _recentSessions.removeLast();
    }
  }

  /// Clears only local revision-session metadata.
  void clear() {
    _recentSessions.clear();
  }

  void _registerSessionReset() {
    UserSessionStateCoordinator.instance.register(clear);
  }

  Future<List<RevisionCollectionType>> loadRecentSessionTypes() async {
    return List.unmodifiable(_recentSessions);
  }
}
