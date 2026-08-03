import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/main_navigation_screen.dart';
import '../services/auth_service.dart';
import '../widgets/auth_branding_header.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authService,
  });

  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  AuthService get _auth => widget.authService ?? AuthService.instance;

  Future<void> _continueWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _auth.signInWithGoogle();
    if (!mounted) return;

    if (result.wasCancelled) {
      setState(() => _isLoading = false);
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            result.errorMessage ?? 'Unable to sign in. Please try again.';
      });
      return;
    }

    setState(() => _isLoading = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AppResponsivePadding(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const AuthBrandingHeader(),
              const Spacer(flex: 2),
              if (_errorMessage != null) ...[
                AppCard(
                  backgroundColor: AppColors.errorSurface,
                  showShadow: false,
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              GoogleSignInButton(
                isLoading: _isLoading,
                onPressed: _continueWithGoogle,
              ),
              const Spacer(),
              Text(
                'By continuing, you agree to our\nTerms & Privacy Policy',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textTertiary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
