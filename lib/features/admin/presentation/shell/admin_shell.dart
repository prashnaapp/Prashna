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
                  child: Material(
                    color: AdminColors.sidebar,
                    child: SafeArea(
                      child: _AdminSidebar(
                        destination: _destination,
                        displayName: displayName,
                        email: widget.user?.email,
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

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => page,
    );
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
    this.email,
  });

  final AdminNavDestination destination;
  final String displayName;
  final String? email;
  final ValueChanged<AdminNavDestination> onSelect;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.sm,
              AdminSpacing.sm,
              AdminSpacing.sm,
              AdminSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRASHNA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                  ),
                ),
              ],
            ),
          ),
          for (final item in AdminNavDestination.values)
            _NavTile(
              destination: item,
              selected: destination == item,
              onTap: () => onSelect(item),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(AdminSpacing.md),
            decoration: BoxDecoration(
              color: AdminColors.sidebarHover,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.sidebarText,
                    fontWeight: FontWeight.w600,
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
                    ),
                  ),
                ],
                const SizedBox(height: AdminSpacing.sm),
                TextButton(
                  onPressed: () => onSignOut(),
                  style: TextButton.styleFrom(
                    foregroundColor: AdminColors.sidebarText,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AdminNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AdminColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: AdminColors.sidebarHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.md,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  destination.iconData,
                  size: 20,
                  color: selected
                      ? Colors.white
                      : AdminColors.sidebarTextMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : AdminColors.sidebarText,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
