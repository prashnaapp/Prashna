import 'package:flutter/material.dart';

import '../../../authentication/models/auth_user.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../../tests/data/models/test_models.dart';
import '../../admin_routes.dart';
import '../../data/admin_test_scope.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../screens/admin_chapters_browser_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_question_form_screen.dart';
import '../screens/admin_question_import_screen.dart';
import '../screens/admin_question_list_screen.dart';
import '../screens/admin_test_form_screen.dart';
import '../screens/admin_test_series_browser_screen.dart';
import 'admin_dirty_scope.dart';
import 'admin_nav_destination.dart';

/// Authenticated Admin chrome: sidebar/drawer + nested content navigator.
class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.user,
    required this.onSignOut,
    this.embeddedChild,
  });

  final AuthUser? user;
  final Future<void> Function() onSignOut;

  /// When set (tests / legacy), show [embeddedChild] instead of nested routes.
  final Widget? embeddedChild;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  final AdminDirtyController _dirtyController = AdminDirtyController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AdminNavDestination _destination = AdminNavDestination.dashboard;

  static const _desktopBreakpoint = 1024.0;

  @override
  void dispose() {
    _dirtyController.dispose();
    super.dispose();
  }

  Future<void> _go(AdminNavDestination destination) async {
    final allowed = await _dirtyController.confirmLeaveIfNeeded(context);
    if (!allowed || !mounted) return;

    if (widget.embeddedChild != null) {
      setState(() => _destination = destination);
      await Navigator.of(context).pushNamedAndRemoveUntil(
        destination.routeName,
        (route) => false,
      );
      return;
    }

    setState(() => _destination = destination);
    _navKey.currentState?.pushNamedAndRemoveUntil(
      destination.routeName,
      (route) => false,
    );
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _requestSignOut() async {
    final allowed = await _dirtyController.confirmSignOutIfNeeded(context);
    if (!allowed || !mounted) return;
    await widget.onSignOut();
  }

  void _onNestedRoute(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    final matched = AdminNavDestinationX.fromRouteName(name);
    if (matched != null && matched != _destination) {
      setState(() => _destination = matched);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _desktopBreakpoint;
    final displayName = widget.user?.displayName?.trim().isNotEmpty == true
        ? widget.user!.displayName!.trim()
        : (widget.user?.email ?? 'Admin');

    return AdminDirtyScope(
      controller: _dirtyController,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AdminColors.workspaceGradient,
        ),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          drawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: AdminColors.sidebar,
                  child: SafeArea(
                    child: _AdminSidebar(
                      destination: _destination,
                      displayName: displayName,
                      email: widget.user?.email,
                      initials: widget.user?.initials ?? 'A',
                      onSelect: _go,
                      onSignOut: _requestSignOut,
                    ),
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: AdminSpacing.sidebarWidth,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1A2440),
                          AdminColors.sidebar,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: _AdminSidebar(
                        destination: _destination,
                        displayName: displayName,
                        email: widget.user?.email,
                        initials: widget.user?.initials ?? 'A',
                        onSelect: _go,
                        onSignOut: _requestSignOut,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (!isDesktop)
                      Material(
                        color: AdminColors.surfaceElevated.withValues(
                          alpha: 0.92,
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: SizedBox(
                            height: 56,
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Open navigation',
                                  onPressed: () =>
                                      _scaffoldKey.currentState?.openDrawer(),
                                  icon: const Icon(Icons.menu_rounded),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _destination.label,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                TextButton(
                                  key: const ValueKey('admin-mobile-sign-out'),
                                  onPressed: _requestSignOut,
                                  child: const Text('Sign out'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: widget.embeddedChild ??
                          Navigator(
                            key: _navKey,
                            initialRoute: AdminRoutes.dashboard,
                            observers: [_AdminNavObserver(onChange: _onNestedRoute)],
                            onGenerateRoute: _onGenerateNestedRoute,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Route<dynamic> _onGenerateNestedRoute(RouteSettings settings) {
    final name = settings.name;
    final Widget page = switch (name) {
      AdminRoutes.root ||
      AdminRoutes.login ||
      AdminRoutes.dashboard ||
      '/' ||
      null => AdminDashboardScreen(
        user: widget.user,
        onSignOut: widget.onSignOut,
        embeddedInShell: true,
      ),
      AdminRoutes.questions =>
        const AdminQuestionListScreen(embeddedInShell: true),
      AdminRoutes.questionCreate => const AdminQuestionFormScreen(),
      AdminRoutes.questionEdit => () {
        final question = settings.arguments;
        return question is Question
            ? AdminQuestionFormScreen(question: question)
            : const AdminQuestionListScreen(embeddedInShell: true);
      }(),
      AdminRoutes.questionImport =>
        const AdminQuestionImportScreen(embeddedInShell: true),
      AdminRoutes.chapters =>
        const AdminChaptersBrowserScreen(embeddedInShell: true),
      AdminRoutes.testSeries || AdminRoutes.tests =>
        const AdminTestSeriesBrowserScreen(embeddedInShell: true),
      AdminRoutes.testCreate => () {
        final createArgs = settings.arguments;
        return AdminTestFormScreen(
          initialCourseId: createArgs is String ? createArgs : null,
          scope: createArgs is AdminTestScope ? createArgs : null,
        );
      }(),
      AdminRoutes.testEdit => () {
        final test = settings.arguments;
        return test is TestModel
            ? AdminTestFormScreen(
                test: test,
                scope: AdminTestScope.fromTest(test),
              )
            : const AdminTestSeriesBrowserScreen(embeddedInShell: true);
      }(),
      _ => AdminDashboardScreen(
        user: widget.user,
        onSignOut: widget.onSignOut,
        embeddedInShell: true,
      ),
    };

    return _AdminWorkspaceRoute<void>(
      settings: settings,
      coverWithWorkspace: !_isDashboardRoute(name),
      builder: (_) => page,
    );
  }
}

bool _isDashboardRoute(String? name) {
  return switch (name) {
    AdminRoutes.root ||
    AdminRoutes.login ||
    AdminRoutes.dashboard ||
    '/' ||
    null => true,
    _ => false,
  };
}

/// Nested Admin workspace route.
///
/// Zero-duration and opaque so the Dashboard background cannot fade through
/// the next screen. Non-dashboard pages get an opaque workspace fill because
/// several embedded screens do not paint their own full-bleed background.
@visibleForTesting
const Duration adminWorkspaceTransitionDuration = Duration.zero;

class _AdminWorkspaceRoute<T> extends PageRoute<T> {
  _AdminWorkspaceRoute({
    required this.builder,
    required this.coverWithWorkspace,
    super.settings,
  });

  final WidgetBuilder builder;
  final bool coverWithWorkspace;

  @override
  Duration get transitionDuration => adminWorkspaceTransitionDuration;

  @override
  Duration get reverseTransitionDuration => adminWorkspaceTransitionDuration;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final child = builder(context);
    if (!coverWithWorkspace) return child;
    return ColoredBox(color: AdminColors.backgroundTop, child: child);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class _AdminNavObserver extends NavigatorObserver {
  _AdminNavObserver({required this.onChange});

  final void Function(Route<dynamic> route, Route<dynamic>? previousRoute)
  onChange;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChange(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) onChange(newRoute, oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) onChange(previousRoute, route);
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.destination,
    required this.displayName,
    required this.onSelect,
    required this.onSignOut,
    required this.initials,
    this.email,
  });

  final AdminNavDestination destination;
  final String displayName;
  final String? email;
  final String initials;
  final ValueChanged<AdminNavDestination> onSelect;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.md,
        AdminSpacing.lg,
        AdminSpacing.md,
        AdminSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.sm,
              AdminSpacing.xs,
              AdminSpacing.sm,
              AdminSpacing.xl,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AdminColors.sidebarActive,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.sidebarBorder),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 20,
                    color: AdminColors.sidebarAccent,
                  ),
                ),
                const SizedBox(width: AdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRASHNA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AdminColors.sidebarText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Admin Console',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AdminColors.sidebarTextMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('admin-sidebar-nav'),
              padding: EdgeInsets.zero,
              children: [
                for (final item in AdminNavDestination.values)
                  _NavTile(
                    destination: item,
                    selected: destination == item,
                    onTap: () => onSelect(item),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AdminSpacing.md),
          Container(
            key: const ValueKey('admin-sidebar-utility'),
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.md,
              AdminSpacing.md,
              AdminSpacing.md,
              AdminSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AdminColors.sidebarUtility,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.sidebarBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AdminColors.sidebarActive,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminColors.sidebarBorder),
                      ),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AdminColors.sidebarText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminColors.sidebarText,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              email!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AdminColors.sidebarTextMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpacing.sm),
                Text(
                  'Administrator',
                  style: TextStyle(
                    color: AdminColors.sidebarAccent.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AdminColors.sidebarBorder,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('admin-sidebar-sign-out'),
                    onPressed: () => onSignOut(),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.sidebarText,
                      side: const BorderSide(color: AdminColors.sidebarBorder),
                      backgroundColor: AdminColors.sidebarHover,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AdminSpacing.md,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AdminNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final emphasize = selected || _hovered || _focused;
    final bg = selected
        ? AdminColors.sidebarActive
        : (_hovered || _focused)
            ? AdminColors.sidebarHover
            : Colors.transparent;
    final iconColor = selected
        ? Colors.white
        : emphasize
            ? AdminColors.sidebarText
            : AdminColors.sidebarTextMuted;
    final textColor = selected
        ? Colors.white
        : AdminColors.sidebarText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: FocusableActionDetector(
          onShowFocusHighlight: (show) => setState(() => _focused = show),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              _hovered && !selected ? 2.0 : 0.0,
              0,
              0,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AdminColors.sidebarAccent.withValues(alpha: 0.35)
                    : _focused
                        ? AdminColors.sidebarAccent.withValues(alpha: 0.45)
                        : Colors.transparent,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onTap,
                hoverColor: Colors.transparent,
                splashColor: AdminColors.sidebarAccent.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.sm,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        width: 3,
                        height: 22,
                        decoration: BoxDecoration(
                          color: selected
                              ? AdminColors.sidebarAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        widget.destination.iconData,
                        size: 20,
                        color: iconColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.destination.label,
                          style: TextStyle(
                            color: textColor,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
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
