import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../authentication/services/auth_service.dart';

/// Minimal Admin Web login — Google Sign-In via [AuthService].
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
    this.authService,
    this.errorMessage,
  });

  final AuthService? authService;
  final String? errorMessage;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool _loading = false;
  String? _error;

  AuthService get _auth => widget.authService ?? AuthService.instance;

  @override
  void initState() {
    super.initState();
    _error = widget.errorMessage;
  }

  @override
  void didUpdateWidget(covariant AdminLoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != oldWidget.errorMessage) {
      _error = widget.errorMessage;
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _auth.signInWithGoogle();
    if (!mounted) return;

    if (result.wasCancelled) {
      setState(() => _loading = false);
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _error = result.errorMessage ?? 'Unable to sign in. Please try again.';
      });
      return;
    }

    // Gate listens to authStateChanges and verifies admin claim.
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Prashna Admin',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign in with an account that has the admin claim.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                FilledButton(
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
