import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_user.dart';

/// Low-level auth boundary over Firebase Auth + Google Sign-In.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    Stream<AuthUser?>? authStateChangesOverride,
    bool skipInitialization = false,
  }) : _firebaseAuthOverride = firebaseAuth,
       _googleSignInOverride = googleSignIn,
       // ignore: prefer_initializing_formals
       _authStateChangesOverride = authStateChangesOverride,
       // ignore: prefer_initializing_formals
       _skipInitialization = skipInitialization;

  @visibleForTesting
  AuthRepository.debug({required Stream<AuthUser?> authStateChanges})
    : this(
        authStateChangesOverride: authStateChanges,
        skipInitialization: true,
      );

  final FirebaseAuth? _firebaseAuthOverride;
  final GoogleSignIn? _googleSignInOverride;
  final Stream<AuthUser?>? _authStateChangesOverride;
  final bool _skipInitialization;
  bool _googleInitialized = false;
  Future<void>? _googleInitFuture;

  FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? FirebaseAuth.instance;

  GoogleSignIn get _googleSignIn =>
      _googleSignInOverride ?? GoogleSignIn.instance;

  Future<void> initialize() {
    return _ensureGoogleInitialized();
  }

  Future<void> _ensureGoogleInitialized() {
    if (_googleInitialized) return Future.value();
    if (_skipInitialization) {
      _googleInitialized = true;
      return Future.value();
    }
    // Web admin uses Firebase Auth popup — GoogleSignIn plugin init not required.
    if (kIsWeb) {
      _googleInitialized = true;
      return Future.value();
    }
    return _googleInitFuture ??= () async {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }();
  }

  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  Stream<AuthUser?> authStateChanges() {
    return _authStateChangesOverride ??
        _firebaseAuth.authStateChanges().map(_mapUser);
  }

  Future<AuthActionResult> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      if (kIsWeb) {
        return _signInWithGooglePopup();
      }

      if (!_googleSignIn.supportsAuthenticate()) {
        return const AuthActionResult.failure(
          'Google Sign-In is not supported on this platform.',
        );
      }

      final googleUser = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const AuthActionResult.failure(
          'Unable to retrieve Google ID token. Check Firebase Google Sign-In setup.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = _mapUser(userCredential.user);
      if (user == null) {
        return const AuthActionResult.failure(
          'Google Sign-In succeeded but no user was returned.',
        );
      }
      return AuthActionResult.success(user);
    } on GoogleSignInException catch (error, stack) {
      debugPrint('GoogleSignInException: $error\n$stack');
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const AuthActionResult.cancelled();
      }
      return AuthActionResult.failure(
        error.description?.isNotEmpty == true
            ? error.description!
            : 'Google Sign-In failed. Please try again.',
      );
    } on FirebaseAuthException catch (error, stack) {
      debugPrint('FirebaseAuthException: ${error.code}\n$stack');
      return AuthActionResult.failure(_mapFirebaseError(error));
    } catch (error, stack) {
      debugPrint('signInWithGoogle error: $error\n$stack');
      return const AuthActionResult.failure(
        'Something went wrong during Google Sign-In. Please try again.',
      );
    }
  }

  /// Firebase Auth popup flow for Flutter Web (Admin shell).
  Future<AuthActionResult> _signInWithGooglePopup() async {
    try {
      final provider = GoogleAuthProvider();
      final userCredential = await _firebaseAuth.signInWithPopup(provider);
      final user = _mapUser(userCredential.user);
      if (user == null) {
        return const AuthActionResult.failure(
          'Google Sign-In succeeded but no user was returned.',
        );
      }
      return AuthActionResult.success(user);
    } on FirebaseAuthException catch (error, stack) {
      debugPrint('FirebaseAuthException (web popup): ${error.code}\n$stack');
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request') {
        return const AuthActionResult.cancelled();
      }
      return AuthActionResult.failure(_mapFirebaseError(error));
    }
  }

  Future<void> signOut() async {
    await _ensureGoogleInitialized();
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (error, stack) {
        debugPrint('Google signOut error: $error\n$stack');
      }
    }
    await _firebaseAuth.signOut();
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'Invalid Google credentials. Please try again.';
      default:
        return error.message?.isNotEmpty == true
            ? error.message!
            : 'Authentication failed. Please try again.';
    }
  }
}
