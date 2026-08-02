import 'package:flutter/material.dart';

import '../../navigation/main_navigation_screen.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/auth_message_banner.dart';
import '../../core/utils/auth_validators.dart';

class ProfileSetupScreen extends StatefulWidget {
  ProfileSetupScreen({
    super.key,
    required this.mobileNumber,
    AuthService? authService,
  }) : authService = authService ?? AuthServiceRegistry.instance;

  final String mobileNumber;
  final AuthService authService;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continueToHome() async {
    final nameError = AuthValidators.validateName(_nameController.text);

    if (nameError != null) {
      setState(() {
        _errorMessage = nameError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.authService.saveProfile(
      mobileNumber: widget.mobileNumber,
      name: _nameController.text.trim(),
      targetExam: '',
    );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            result.errorMessage ?? 'Unable to save profile. Please try again.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid =
        AuthValidators.validateName(_nameController.text) == null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.person_outline,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 25),
              const Text(
                'Complete Your Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Complete your profile to continue.',
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
                controller: _nameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isFormValid && !_isLoading ? _continueToHome : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(fontSize: 18),
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
