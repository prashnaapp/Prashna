/// Pure helpers for Firebase Auth custom-claim admin checks.
///
/// Authorization must NEVER use Firestore `users/{uid}.role` or similar
/// client-writable fields. Prefer [AdminAuthService] at runtime.
bool hasAdminClaim(Map<String, dynamic>? claims) {
  if (claims == null) return false;
  return claims['admin'] == true;
}
