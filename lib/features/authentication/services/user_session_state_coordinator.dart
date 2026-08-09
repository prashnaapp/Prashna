import 'dart:async';

import '../models/auth_user.dart';

typedef SessionResetCallback = void Function();

class UserSessionIdentity {
  const UserSessionIdentity({required this.uid, required this.generation});

  final String? uid;
  final int generation;
}

/// Central boundary for mutable state that belongs to the authenticated user.
///
/// State owners register one local reset callback. Authenticated UID changes
/// and authenticated/unauthenticated transitions invoke every callback before
/// the new session becomes active.
class UserSessionStateCoordinator {
  UserSessionStateCoordinator._();

  UserSessionStateCoordinator.debug() : this._();

  static final UserSessionStateCoordinator instance =
      UserSessionStateCoordinator._();

  final Set<SessionResetCallback> _resetCallbacks = {};
  StreamSubscription<AuthUser?>? _authSubscription;
  String? _activeUid;
  int _generation = 0;

  String? get activeUid => _activeUid;
  int get generation => _generation;

  UserSessionIdentity capture() {
    return UserSessionIdentity(uid: _activeUid, generation: _generation);
  }

  bool isCurrent(UserSessionIdentity identity) {
    return identity.generation == _generation && identity.uid == _activeUid;
  }

  void register(SessionResetCallback reset) {
    _resetCallbacks.add(reset);
  }

  void start(Stream<AuthUser?> authStates) {
    if (_authSubscription != null) return;
    _authSubscription = authStates.listen(handleAuthState);
  }

  void handleAuthState(AuthUser? user) {
    final nextUid = user?.uid;
    if (_activeUid == nextUid) return;

    _generation++;
    for (final reset in List<SessionResetCallback>.of(_resetCallbacks)) {
      try {
        reset();
      } catch (error, stack) {
        Zone.current.handleUncaughtError(error, stack);
      }
    }
    _activeUid = nextUid;
  }

  @override
  String toString() =>
      'UserSessionStateCoordinator(activeUid=$_activeUid, '
      'registered=${_resetCallbacks.length})';
}
