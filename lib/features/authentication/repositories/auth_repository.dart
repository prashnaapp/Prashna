import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_user.dart';

/// Low-level auth boundary over Firebase Auth + Google Sign-In.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;
  Future<void>? _googleInitFuture;

  Future<void> initialize() {
    return _ensureGoogleInitialized();
  }

  Future<void> _ensureGoogleInitialized() {
    if (_googleInitialized) return Future.value();
    return _googleInitFuture ??= () async {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }();
  }

  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  Future<AuthActionResult> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

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
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
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

  Future<void> signOut() async {
    await _ensureGoogleInitialized();
    try {
      await _googleSignIn.signOut();
    } catch (error, stack) {
      debugPrint('Google signOut error: $error\n$stack');
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
