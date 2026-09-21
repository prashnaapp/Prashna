import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../authentication/models/auth_user.dart';
import '../../admin_routes.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../shell/admin_dirty_scope.dart';
import '../widgets/admin_ui/admin_hover_lift.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Admin command-center dashboard (no Firestore metrics in Phase 1).
///
/// Phase 5A: Dashboard-only education atmosphere + glass destination cards.
/// Workspace screens must not reuse [_DashboardAtmosphere].
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
    // Prefer the nearest (nested AdminShell) navigator — never the root app
    // navigator — so Dashboard visuals dispose with the workspace route.
    Navigator.of(context, rootNavigator: false).pushNamedAndRemoveUntil(
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
        final showChrome = embeddedInShell && constraints.maxWidth >= 720;
        final cards = [
          _DestinationCard(
            key: const ValueKey('dashboard-dest-questions'),
            icon: Icons.quiz_outlined,
            title: 'Questions',
            subtitle: 'Create, edit, publish, and archive questions',
            accent: AdminDestinationAccent.questions,
            onTap: () => _goMajor(context, AdminRoutes.questions),
          ),
          _DestinationCard(
            key: const ValueKey('dashboard-dest-import'),
            icon: Icons.upload_file_outlined,
            title: 'Import Questions',
            subtitle: 'Validate bilingual JSON and import as drafts',
            accent: AdminDestinationAccent.importQuestions,
            onTap: () => _goMajor(context, AdminRoutes.questionImport),
          ),
          _DestinationCard(
            key: const ValueKey('dashboard-dest-chapters'),
            icon: Icons.account_tree_outlined,
            title: 'Chapters',
            subtitle: 'Browse the syllabus hierarchy and manage chapter tests',
            accent: AdminDestinationAccent.chapters,
            onTap: () => _goMajor(context, AdminRoutes.chapters),
          ),
          _DestinationCard(
            key: const ValueKey('dashboard-dest-test-series'),
            icon: Icons.assignment_outlined,
            title: 'Test Series',
            subtitle: 'Manage paper-wise tests, grand tests, and previous papers',
            accent: AdminDestinationAccent.testSeries,
            onTap: () => _goMajor(context, AdminRoutes.testSeries),
          ),
        ];

        // Atmosphere is owned by this route only. SizedBox.expand keeps the
        // photographic stack clipped to Dashboard bounds (not AdminShell).
        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const RepaintBoundary(
                child: _DashboardAtmosphere(
                  key: ValueKey('dashboard-atmosphere'),
                ),
              ),
              SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AdminSpacing.pagePadding,
                AdminSpacing.xl,
                AdminSpacing.pagePadding,
                AdminSpacing.section,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AdminSpacing.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showChrome) ...[
                        _DashboardChrome(user: user),
                        const SizedBox(height: AdminSpacing.xxl),
                      ],
                      Text(
                        'Welcome, $name',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AdminColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.md),
                      Text(
                        'Manage Prashna content from a single Admin workspace.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AdminColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.section),
                      Text(
                        'Content Management',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AdminColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.xl),
                      _DestinationGrid(wide: wide, cards: cards),
                    ],
                  ),
                ),
              ),
            ),
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
            onPressed: () async {
              final allowed = await AdminSignOutConfirm.show(
                context,
                isDirty: false,
              );
              if (!allowed || !context.mounted) return;
              await onSignOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: body,
    );
  }
}

/// Dashboard-only photographic workspace.
/// Local asset + one background blur + light wash. Not used by other routes.
class _DashboardAtmosphere extends StatelessWidget {
  const _DashboardAtmosphere({super.key});

  static const assetPath = 'assets/images/admin/dashboard_workspace.jpg';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AdminColors.atmosphereSoft),
          // Single blur system — background image only; foreground stays sharp.
          Positioned.fill(
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
                child: const SizedBox.expand(
                  child: Image(
                    key: ValueKey('dashboard-workspace-background'),
                    image: AssetImage(assetPath),
                    fit: BoxFit.cover,
                    alignment: Alignment(0.35, 0.05),
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
          // Light translucent wash: photo remains recognizable but subordinate.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xD9F7F1E8),
                  Color(0xB8F4F7FC),
                  Color(0xC2E8EEF8),
                  Color(0xCCE6ECF6),
                ],
                stops: [0.0, 0.38, 0.72, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardChrome extends StatelessWidget {
  const _DashboardChrome({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final initials = user?.initials ?? 'A';
    return Row(
      key: const ValueKey('dashboard-content-chrome'),
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AdminColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: Text(
            initials,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AdminColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DestinationGrid extends StatelessWidget {
  const _DestinationGrid({required this.wide, required this.cards});

  final bool wide;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: AdminSpacing.lg),
          ],
        ],
      );
    }

    Widget pair(Widget left, Widget right) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            const SizedBox(width: AdminSpacing.xl),
            Expanded(child: right),
          ],
        ),
      );
    }

    return Column(
      children: [
        pair(cards[0], cards[1]),
        const SizedBox(height: AdminSpacing.xl),
        pair(cards[2], cards[3]),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AdminDestinationAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminHoverLift(
      child: AdminSurface(
        variant: AdminSurfaceVariant.glass,
        accentColor: accent.strong,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(
          AdminSpacing.xxl,
          AdminSpacing.xxl,
          AdminSpacing.xxl,
          AdminSpacing.xxxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 168),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        accent.soft.withValues(alpha: 0.92),
                        Colors.white.withValues(alpha: 0.55),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.strong.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(icon, color: accent.strong, size: 26),
                  ),
                  const Spacer(),
                  ExcludeSemantics(
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AdminColors.atmosphereDeep.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: accent.strong,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AdminSpacing.xl),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AdminColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AdminSpacing.sm),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AdminColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
