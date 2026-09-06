import '../../../authentication/services/user_session_state_coordinator.dart';
import '../../../revision_cloud/model/revision_cloud.dart';
import '../../../revision_cloud/service/revision_cloud_service.dart';
import '../models/revision_models.dart';

/// Lifecycle of the catalog revision session cache.
enum CatalogRevisionLoadState {
  /// No successful load for the current session (or cleared).
  notLoaded,

  /// A cloud read is in flight.
  loading,

  /// Cloud read succeeded (document may be empty).
  loaded,

  /// Last read failed; [catalogLoadError] holds the failure.
  /// Prior successful snapshot is retained when present.
  error,
}

/// Session-scoped revision storage.
///
/// Owns:
/// - recent revision-session metadata (existing)
/// - authoritative catalog revision hydrate from `user_revision/{uid}`
///
/// Firestore remains the source of truth for catalog revision. Memory is a
/// temporary cache cleared on auth session reset.
class RevisionRepository {
  RevisionRepository({
    RevisionCloudService? cloudService,
    Future<RevisionCloud?> Function(String uid)? cloudLoader,
    UserSessionStateCoordinator? sessionCoordinator,
  }) : _cloudOverride = cloudService,
       _cloudLoaderOverride = cloudLoader,
       _sessions = sessionCoordinator ?? UserSessionStateCoordinator.instance;

  static final RevisionRepository instance = RevisionRepository()
    .._registerSessionReset();

  final RevisionCloudService? _cloudOverride;
  final Future<RevisionCloud?> Function(String uid)? _cloudLoaderOverride;
  final UserSessionStateCoordinator _sessions;

  RevisionCloudService? _cloudCache;
  RevisionCloudService get _cloud =>
      _cloudCache ??= _cloudOverride ?? RevisionCloudService.instance;

  final List<RevisionCollectionType> _recentSessions = [];

  CatalogRevisionLoadState _catalogLoadState =
      CatalogRevisionLoadState.notLoaded;
  RevisionCloud? _catalogRevision;
  Object? _catalogLoadError;
  Future<CatalogRevisionLoadState>? _catalogLoadInFlight;
  int _catalogLoadGeneration = 0;

  CatalogRevisionLoadState get catalogLoadState => _catalogLoadState;

  /// Latest successfully hydrated catalog revision for the current session.
  ///
  /// Null when never loaded, cleared, or only an error occurred with no prior
  /// success. An empty Firestore document yields a non-null empty snapshot.
  RevisionCloud? get currentCatalogRevision => _catalogRevision;

  Object? get catalogLoadError => _catalogLoadError;

  bool get hasCatalogRevisionSnapshot => _catalogRevision != null;

  bool get isCatalogRevisionEmpty {
    final snap = _catalogRevision;
    if (snap == null) return true;
    return snap.wrongQuestions.isEmpty &&
        snap.frequentlyWrongQuestions.isEmpty &&
        snap.mistakeCounts.isEmpty;
  }

  Future<RevisionCloud?> Function(String uid) get _loadCloud {
    final override = _cloudLoaderOverride;
    if (override != null) return override;
    return _cloud.load;
  }

  Future<void> recordSessionStarted(RevisionCollectionType type) async {
    _recentSessions.remove(type);
    _recentSessions.insert(0, type);
    if (_recentSessions.length > 10) {
      _recentSessions.removeLast();
    }
  }

  /// Clears local revision-session metadata and catalog hydrate cache.
  void clear() {
    _recentSessions.clear();
    _catalogLoadGeneration++;
    _catalogLoadInFlight = null;
    _catalogLoadState = CatalogRevisionLoadState.notLoaded;
    _catalogRevision = null;
    _catalogLoadError = null;
  }

  void _registerSessionReset() {
    UserSessionStateCoordinator.instance.register(clear);
  }

  Future<List<RevisionCollectionType>> loadRecentSessionTypes() async {
    return List.unmodifiable(_recentSessions);
  }

  /// Loads `user_revision/{uid}` for the active authenticated user into cache.
  ///
  /// Missing documents become a valid empty snapshot. Failures set
  /// [CatalogRevisionLoadState.error] without inventing empty success.
  Future<CatalogRevisionLoadState> loadCurrentUserRevision({
    bool force = false,
  }) {
    return _hydrateCatalog(force: force);
  }

  /// Forces a fresh cloud read and replaces the session cache when successful.
  Future<CatalogRevisionLoadState> refreshCurrentUserRevision() {
    return _hydrateCatalog(force: true);
  }

  Future<CatalogRevisionLoadState> _hydrateCatalog({required bool force}) async {
    final session = _sessions.capture();
    final uid = session.uid?.trim();
    if (uid == null || uid.isEmpty) {
      _catalogLoadState = CatalogRevisionLoadState.notLoaded;
      _catalogRevision = null;
      _catalogLoadError = null;
      return CatalogRevisionLoadState.notLoaded;
    }

    if (!force &&
        _catalogLoadState == CatalogRevisionLoadState.loaded &&
        _catalogRevision != null &&
        _catalogRevision!.uid == uid) {
      return CatalogRevisionLoadState.loaded;
    }

    final inFlight = _catalogLoadInFlight;
    if (!force && inFlight != null) {
      return inFlight;
    }

    final loadGeneration = ++_catalogLoadGeneration;
    final future = _runCatalogLoad(
      uid: uid,
      session: session,
      loadGeneration: loadGeneration,
    );
    _catalogLoadInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_catalogLoadInFlight, future)) {
        _catalogLoadInFlight = null;
      }
    }
  }

  Future<CatalogRevisionLoadState> _runCatalogLoad({
    required String uid,
    required UserSessionIdentity session,
    required int loadGeneration,
  }) async {
    if (!_sessions.isCurrent(session) || loadGeneration != _catalogLoadGeneration) {
      return CatalogRevisionLoadState.notLoaded;
    }

    _catalogLoadState = CatalogRevisionLoadState.loading;
    _catalogLoadError = null;

    try {
      final loaded = await _loadCloud(uid);

      if (!_sessions.isCurrent(session) ||
          loadGeneration != _catalogLoadGeneration) {
        return CatalogRevisionLoadState.notLoaded;
      }

      final activeUid = _sessions.activeUid?.trim();
      if (activeUid == null || activeUid.isEmpty || activeUid != uid) {
        return CatalogRevisionLoadState.notLoaded;
      }

      final snapshot = loaded ?? RevisionCloud.emptyForUser(uid);
      if (snapshot.uid != uid) {
        // Never accept a payload for a different user.
        _catalogLoadState = CatalogRevisionLoadState.error;
        _catalogLoadError = StateError(
          'Revision payload uid mismatch: expected $uid got ${snapshot.uid}',
        );
        return CatalogRevisionLoadState.error;
      }

      _catalogRevision = snapshot;
      _catalogLoadError = null;
      _catalogLoadState = CatalogRevisionLoadState.loaded;
      return CatalogRevisionLoadState.loaded;
    } catch (error) {
      if (!_sessions.isCurrent(session) ||
          loadGeneration != _catalogLoadGeneration) {
        return CatalogRevisionLoadState.notLoaded;
      }
      _catalogLoadError = error;
      _catalogLoadState = CatalogRevisionLoadState.error;
      // Keep prior successful snapshot if any (do not invent empty success).
      return CatalogRevisionLoadState.error;
    }
  }
}
