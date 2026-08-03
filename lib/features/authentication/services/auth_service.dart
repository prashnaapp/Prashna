import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';

/// App-facing authentication API.
///
/// UI should depend on this service — never on Firebase / Google SDKs directly.
class AuthService {
  AuthService({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  static final AuthService instance = AuthService();

  final AuthRepository _repository;
  Future<void>? _initFuture;

  /// Initializes Google Sign-In. Safe to call multiple times.
  Future<void> initialize() {
    return _initFuture ??= _repository.initialize();
  }

  AuthUser? get currentUser => _repository.currentUser;

  bool get isLoggedIn => currentUser != null;

  Stream<AuthUser?> authStateChanges() => _repository.authStateChanges();

  Future<AuthActionResult> signInWithGoogle() async {
    await initialize();
    return _repository.signInWithGoogle();
  }

  Future<void> signOut() async {
    await initialize();
    await _repository.signOut();
  }
}
