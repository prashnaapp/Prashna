import 'package:flutter/foundation.dart';

import '../../user_profile/service/user_profile_service.dart';
import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';
import 'user_session_state_coordinator.dart';

/// App-facing authentication API.
///
/// UI should depend on this service — never on Firebase / Google SDKs directly.
class AuthService {
  AuthService({
    AuthRepository? repository,
    UserProfileService? userProfileService,
    UserSessionStateCoordinator? sessionCoordinator,
  })  : _repository = repository ?? AuthRepository(),
       _userProfileService = userProfileService ?? UserProfileService.instance,
       _sessionCoordinator =
           sessionCoordinator ?? UserSessionStateCoordinator.instance;

  static final AuthService instance = AuthService();

  final AuthRepository _repository;
  final UserProfileService _userProfileService;
  final UserSessionStateCoordinator _sessionCoordinator;
  Future<void>? _initFuture;

  /// Initializes Google Sign-In. Safe to call multiple times.
  Future<void> initialize() async {
    await (_initFuture ??= _repository.initialize());
    _sessionCoordinator.start(_repository.authStateChanges());
  }

  AuthUser? get currentUser => _repository.currentUser;

  bool get isLoggedIn => currentUser != null;

  Stream<AuthUser?> authStateChanges() => _repository.authStateChanges();

  Future<AuthActionResult> signInWithGoogle() async {
    await initialize();
    final result = await _repository.signInWithGoogle();
    if (result.isSuccess && result.user != null) {
      _sessionCoordinator.handleAuthState(result.user);
      try {
        await _userProfileService.ensureProfileAfterLogin(result.user!);
      } catch (error, stack) {
        debugPrint('Profile sync after login failed: $error\n$stack');
        return AuthActionResult.failure(
          'Signed in, but profile setup failed. Please try again.',
        );
      }
    }
    return result;
  }

  Future<void> signOut() async {
    await initialize();
    await _repository.signOut();
    _sessionCoordinator.handleAuthState(null);
  }

  void registerSessionReset(SessionResetCallback reset) {
    _sessionCoordinator.register(reset);
  }
}
