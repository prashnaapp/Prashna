import 'package:flutter/material.dart';

import '../../../authentication/models/auth_user.dart';
import '../../admin_routes.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../shell/admin_dirty_scope.dart';
import '../widgets/admin_ui/admin_page_header.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Admin command-center dashboard (no Firestore metrics in Phase 1).
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.user,
    required this.onSignOut,
    this.embeddedInShell = false,
  });

  final AuthUser? user;
  final Future<void> Function() onSignOut;
  final bool embeddedInShell;

  /// Major destinations use replace-stack semantics (same as sidebar).
  Future<void> _goMajor(BuildContext context, String routeName) async {
    final dirty = AdminDirtyScope.maybeOf(context);
    if (dirty != null) {
      final allowed = await dirty.confirmLeaveIfNeeded(context);
      if (!allowed) return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email ?? 'Admin');

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final cards = [
          _DestinationCard(
            icon: Icons.quiz_outlined,
            title: 'Questions',
            subtitle: 'Create, edit, publish, and archive questions',
            onTap: () => _goMajor(context, AdminRoutes.questions),
          ),
          _DestinationCard(
            icon: Icons.upload_file_outlined,
            title: 'Import Questions',
            subtitle: 'Validate bilingual JSON and import as drafts',
            onTap: () => _goMajor(context, AdminRoutes.questionImport),
          ),
          _DestinationCard(
            icon: Icons.account_tree_outlined,
            title: 'Chapters',
            subtitle:
                'Course → Paper → Part (when applicable) → Chapter → Test',
            onTap: () => _goMajor(context, AdminRoutes.chapters),
          ),
          _DestinationCard(
            icon: Icons.assignment_outlined,
            title: 'Test Series',
            subtitle: 'Paper-wise Tests, Grand Tests, and Previous Papers',
            onTap: () => _goMajor(context, AdminRoutes.testSeries),
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AdminSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminPageHeader(
                title: 'Welcome, $name',
                subtitle:
                    'Manage Prashna content from a single Admin workspace. '
                    'Verified admin access is active.',
                actions: embeddedInShell
                    ? const []
                    : [
                        TextButton(
                          onPressed: () => onSignOut(),
                          child: const Text('Sign out'),
                        ),
                      ],
              ),
              Text(
                'Content Management',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AdminSpacing.lg),
              if (wide)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AdminSpacing.lg,
                  crossAxisSpacing: AdminSpacing.lg,
                  childAspectRatio: 2.35,
                  children: cards,
                )
              else
                ...[
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: AdminSpacing.lg),
                  ],
                ],
            ],
          ),
        );
      },
    );

    if (embeddedInShell) return body;

    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(
        title: const Text('PRASHNA ADMIN'),
        actions: [
          TextButton(
            onPressed: () => onSignOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      emphasized: true,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AdminColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AdminColors.primaryDark),
          ),
          const SizedBox(width: AdminSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: AdminColors.primary),
        ],
      ),
    );
  }
}
