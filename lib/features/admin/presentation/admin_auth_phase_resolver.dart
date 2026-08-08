import '../../authentication/models/auth_user.dart';
import 'admin_auth_phase.dart';

/// Resolves Admin Web shell phase from auth + custom-claim admin check.
///
/// Pure / injectable — unit-tested without Firebase.
abstract final class AdminAuthPhaseResolver {
  /// [isAdmin] must verify Firebase ID token claims (`admin == true`).
  /// Never pass a value derived from Firestore `users/{uid}.role`.
  static Future<AdminAuthPhase> resolve({
    required AuthUser? user,
    required Future<bool> Function({bool forceRefresh}) isAdmin,
    bool forceRefreshClaim = true,
  }) async {
    if (user == null) return AdminAuthPhase.login;

    final admin = await isAdmin(forceRefresh: forceRefreshClaim);
    if (!admin) return AdminAuthPhase.accessDenied;
    return AdminAuthPhase.dashboard;
  }
}
