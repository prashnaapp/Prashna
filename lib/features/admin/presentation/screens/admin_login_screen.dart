import 'package:flutter/material.dart';

import '../../../authentication/services/auth_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Premium Admin Web login — Google Sign-In via [AuthService].
///
/// Authentication behavior is unchanged; presentation uses Admin-only tokens.
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
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AdminColors.workspaceGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AdminSpacing.pagePadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AdminSurface(
                  emphasized: true,
                  padding: const EdgeInsets.all(AdminSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AdminColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_outlined,
                            color: AdminColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.lg),
                      Text(
                        'Prashna Admin',
                        textAlign: TextAlign.center,
                        key: const ValueKey('admin-login-title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.sm),
                      Text(
                        'Sign in with an account that has the admin claim.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.xxl),
                      if (_error != null) ...[
                        AdminSurface(
                          padding: const EdgeInsets.all(AdminSpacing.md),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AdminColors.danger,
                            ),
                          ),
                        ),
                        const SizedBox(height: AdminSpacing.lg),
                      ],
                      FilledButton(
                        onPressed: _loading ? null : _signIn,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                      const SizedBox(height: AdminSpacing.md),
                      Text(
                        'Admin Console · Restricted access',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AdminColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
