import 'package:flutter/material.dart';

import '../../../authentication/models/auth_user.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Shown when Firebase Auth succeeds but `admin: true` claim is missing.
///
/// Claim checks and sign-out behavior are unchanged; presentation uses
/// Admin-only tokens.
class AdminAccessDeniedScreen extends StatelessWidget {
  const AdminAccessDeniedScreen({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  final AuthUser? user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? user?.uid ?? 'Unknown user';
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
                constraints: const BoxConstraints(maxWidth: 480),
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
                            color: AdminColors.dangerSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: AdminColors.danger,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.lg),
                      Text(
                        'Access denied',
                        textAlign: TextAlign.center,
                        key: const ValueKey('admin-access-denied-title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.md),
                      Text(
                        'Signed in as $email, but this account does not have the '
                        'admin custom claim. Admin access is granted only via '
                        'Firebase Auth custom claims (not Firestore role fields).',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.xxl),
                      OutlinedButton(
                        onPressed: () => onSignOut(),
                        child: const Text('Sign out'),
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
