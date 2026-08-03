/// App-facing authenticated user (mapped from Firebase Auth).
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  String get initials {
    final source = (displayName?.trim().isNotEmpty == true)
        ? displayName!.trim()
        : (email?.trim().isNotEmpty == true ? email!.trim() : 'P');
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// Result of an authentication attempt.
class AuthActionResult {
  const AuthActionResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.wasCancelled = false,
  });

  const AuthActionResult.success(AuthUser user)
      : this._(isSuccess: true, user: user);

  const AuthActionResult.cancelled()
      : this._(isSuccess: false, wasCancelled: true);

  const AuthActionResult.failure(String message)
      : this._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final AuthUser? user;
  final String? errorMessage;
  final bool wasCancelled;
}
