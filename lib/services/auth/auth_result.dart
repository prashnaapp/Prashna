class AuthResult {
  const AuthResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  const AuthResult.success() : this._(isSuccess: true);

  const AuthResult.failure(String message)
      : this._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final String? errorMessage;
}
