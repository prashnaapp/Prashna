import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../authentication/models/auth_user.dart';
import '../../admin_routes.dart';

/// Minimal Admin dashboard shell — no Question/Test CRUD in this milestone.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  final AuthUser? user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email ?? 'Admin');
    final email = user?.email ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PRASHNA ADMIN'),
        actions: [
          TextButton(
            onPressed: () => onSignOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text('Welcome, $name', style: AppTextStyles.headline(context)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Email: $email',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Admin status: verified (custom claim admin=true)',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Content Management',
                style: AppTextStyles.titleLarge(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  title: const Text('Questions'),
                  subtitle: const Text(
                    'Create, edit, and deactivate questions',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AdminRoutes.questions),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: ListTile(
                  title: const Text('Import Questions'),
                  subtitle: const Text(
                    'Validate bilingual JSON and import as drafts',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AdminRoutes.questionImport),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: ListTile(
                  title: const Text('Tests'),
                  subtitle: const Text('Create, edit, and publish tests'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AdminRoutes.tests),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
