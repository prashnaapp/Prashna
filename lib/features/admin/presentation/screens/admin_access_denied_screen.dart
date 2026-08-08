import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../authentication/models/auth_user.dart';

/// Shown when Firebase Auth succeeds but `admin: true` claim is missing.
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Access denied',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline(context),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Signed in as $email, but this account does not have the '
                  'admin custom claim. Admin access is granted only via '
                  'Firebase Auth custom claims (not Firestore role fields).',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                OutlinedButton(
                  onPressed: () => onSignOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
