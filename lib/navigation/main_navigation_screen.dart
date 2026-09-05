import 'dart:async';

import 'package:flutter/material.dart';

import '../core/design_system/design_system.dart';
import '../features/course_enrollment/service/course_loader_service.dart';
import '../screens/chapters/chapters_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/tests/tests_screen.dart';
import '../screens/tracker/study_tracker_screen.dart';
import 'app_nav_item.dart';
import 'custom_bottom_navigation.dart';

/// Root shell after authentication. Owns the app Scaffold and tab stack.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // AppNavItems.all is the source of truth for tab → IndexedStack index.
    _currentIndex = AppNavItems.indexOf(widget.initialTab).clamp(
      0,
      AppNavItems.all.length - 1,
    );
    // Covers fresh Google Sign-In → Home when Splash did not load courses.
    if (CourseLoaderService.instance.current == null) {
      unawaited(CourseLoaderService.instance.load());
    }
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final progressIndex = AppNavItems.indexOf(AppTab.progress);
    final pages = <Widget>[
      const HomeScreen(),
      const ChaptersScreen(),
      const TestsScreen(),
      StudyTrackerScreen(isActive: _currentIndex == progressIndex),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: _currentIndex,
            sizing: StackFit.expand,
            children: [
              for (var i = 0; i < pages.length; i++)
                _TabTransition(active: i == _currentIndex, child: pages[i]),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabTransition extends StatefulWidget {
  const _TabTransition({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_TabTransition> createState() => _TabTransitionState();
}

class _TabTransitionState extends State<_TabTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.navigation,
      value: widget.active ? 1 : 0,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveStandard,
    );
    _offset = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppAnimations.curveStandard,
          ),
        );
  }

  @override
  void didUpdateWidget(covariant _TabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
