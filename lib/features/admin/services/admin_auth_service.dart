import 'package:firebase_auth/firebase_auth.dart';

import 'admin_claim.dart';

/// Client-side admin claim verification for a future Admin Web surface.
///
/// Does not create UI. Does not change student authentication.
/// Does not read Firestore `users/{uid}.role`.
class AdminAuthService {
  AdminAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static final AdminAuthService instance = AdminAuthService();

  final FirebaseAuth _firebaseAuth;

  /// Returns true when the signed-in user's ID token has `admin: true`.
  ///
  /// Returns false when there is no signed-in user, the claim is missing,
  /// or the claim is not strictly `true`.
  Future<bool> isAdmin({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    final token = await user.getIdTokenResult(forceRefresh);
    return hasAdminClaim(token.claims);
  }

  /// Forces a fresh ID token so newly granted/revoked claims take effect.
  ///
  /// Call after ops run `scripts/set_admin_claim.mjs` and the admin signs in
  /// (or is already signed in). No-op when signed out.
  Future<void> refreshIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await user.getIdToken(true);
  }
}
