import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/auth_validators.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/auth_message_banner.dart';
import 'profile_setup_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  OtpVerificationScreen({
    super.key,
    required this.mobileNumber,
    AuthService? authService,
  }) : authService = authService ?? AuthServiceRegistry.instance;

  final String mobileNumber;
  final AuthService authService;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _canResend = false;
  int _resendSeconds = 30;
  String? _errorMessage;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _canResend = false;
      _resendSeconds = 30;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() {
          _canResend = true;
          _resendSeconds = 0;
        });
        return;
      }

      setState(() {
        _resendSeconds--;
      });
    });
  }

  Future<void> _verifyOtp() async {
    final validationError = AuthValidators.validateOtp(_otpController.text);
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

    final result = await widget.authService.verifyOtp(
      mobileNumber: widget.mobileNumber,
      otp: _otpController.text,
    );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            result.errorMessage ?? 'Invalid OTP. Please try again.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupScreen(
          mobileNumber: widget.mobileNumber,
          authService: widget.authService,
        ),
      ),
    );
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.authService.resendOtp(widget.mobileNumber);

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            result.errorMessage ?? 'Unable to resend OTP. Please try again.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP resent to +91 ${widget.mobileNumber}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOtpComplete = _otpController.text.length == 4;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.verified_user_outlined,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 25),
              const Text(
                'Verify OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the 4-digit code sent to\n+91 ${widget.mobileNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                enabled: !_isLoading,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isOtpComplete && !_isLoading ? _verifyOtp : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _canResend && !_isLoading ? _resendOtp : null,
                  child: Text(
                    _canResend
                        ? 'Resend OTP'
                        : 'Resend OTP in ${_resendSeconds}s',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'By continuing, you agree to our\nTerms & Privacy Policy',
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
