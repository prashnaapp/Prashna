import 'package:flutter/material.dart';

import '../../core/utils/auth_validators.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/auth_message_banner.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({
    super.key,
    AuthService? authService,
  }) : authService = authService ?? AuthServiceRegistry.instance;

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();

  bool isValidMobile = false;
  bool _isLoading = false;
  String? _errorMessage;

  void validateMobile(String value) {
    setState(() {
      isValidMobile = AuthValidators.validateIndianMobile(value) == null;
      _errorMessage = null;
    });
  }

  Future<void> _continueToOtp() async {
    final validationError =
        AuthValidators.validateIndianMobile(mobileController.text);
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.authService.sendOtp(mobileController.text);

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            result.errorMessage ?? 'Unable to send OTP. Please try again.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          mobileNumber: mobileController.text,
          authService: widget.authService,
        ),
      ),
    );
  }

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.school,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 25),
              const Text(
                "Welcome Back!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter your mobile number",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              if (_errorMessage != null) ...[
                AuthMessageBanner(message: _errorMessage!),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: !_isLoading,
                onChanged: validateMobile,
                decoration: const InputDecoration(
                  prefixText: "+91 ",
                  labelText: "Mobile Number",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isValidMobile && !_isLoading ? _continueToOtp : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Continue",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const Spacer(),
              const Text(
                "By continuing, you agree to our\nTerms & Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
