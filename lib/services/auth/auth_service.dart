import 'auth_result.dart';

abstract class AuthService {
  Future<AuthResult> sendOtp(String mobileNumber);

  Future<AuthResult> verifyOtp({
    required String mobileNumber,
    required String otp,
  });

  Future<AuthResult> resendOtp(String mobileNumber);

  Future<AuthResult> saveProfile({
    required String mobileNumber,
    required String name,
    required String targetExam,
  });

  Future<bool> isLoggedIn();
}

/// Swap [instance] to [FirebaseAuthService] when integrating Firebase.
class AuthServiceRegistry {
  AuthServiceRegistry._();

  static AuthService instance = throw UnimplementedError(
    'AuthServiceRegistry.instance must be set before use.',
  );
}
