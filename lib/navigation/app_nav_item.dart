import 'package:flutter/material.dart';

/// Bottom-navigation tabs.
///
/// Declaration order MUST match [AppNavItems.all] — that list is the
/// source of truth for UI indices. Prefer [AppNavItems.indexOf] when
/// mapping a tab to a bottom-nav / IndexedStack index.
enum AppTab {
  home,
  chapters,
  testSeries,
  progress,
  profile,
}

class AppNavItem {
  const AppNavItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.semanticLabel,
  });

  final AppTab tab;
  final String label;
  final IconData icon;
  final String semanticLabel;
}

abstract final class AppNavItems {
  static const List<AppNavItem> all = [
    AppNavItem(
      tab: AppTab.home,
      label: 'Home',
      icon: Icons.home_rounded,
      semanticLabel: 'Home tab',
    ),
    AppNavItem(
      tab: AppTab.chapters,
      label: 'Chapters',
      icon: Icons.menu_book_rounded,
      semanticLabel: 'Chapters tab',
    ),
    AppNavItem(
      tab: AppTab.testSeries,
      label: 'Test Series',
      icon: Icons.quiz_rounded,
      semanticLabel: 'Test Series tab',
    ),
    AppNavItem(
      tab: AppTab.progress,
      label: 'Progress',
      icon: Icons.insights_rounded,
      semanticLabel: 'Progress tab',
    ),
    AppNavItem(
      tab: AppTab.profile,
      label: 'Profile',
      icon: Icons.person_rounded,
      semanticLabel: 'Profile tab',
    ),
  ];

  /// Index of [tab] in the bottom-navigation / IndexedStack order.
  static int indexOf(AppTab tab) {
    final index = all.indexWhere((item) => item.tab == tab);
    assert(index >= 0, 'Unknown AppTab: $tab');
    return index;
  }
}
