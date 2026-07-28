import 'auth_result.dart';
import 'auth_service.dart';

class FakeAuthService implements AuthService {
  const FakeAuthService();

  @override
  Future<AuthResult> sendOtp(String mobileNumber) async {
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> resendOtp(String mobileNumber) async {
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> saveProfile({
    required String mobileNumber,
    required String name,
    required String targetExam,
  }) async {
    return const AuthResult.success();
  }

  @override
  Future<bool> isLoggedIn() async => false;
}
