import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../current_affairs/presentation/current_affairs_navigation.dart';
import '../../../syllabus/presentation/screens/syllabus_home_screen.dart';
import '../../../tests/presentation/screens/previous_exam_selection_screen.dart';
import '../../../tests/presentation/screens/tests_home_screen.dart';
import '../home_visual.dart';
import 'home_decorations.dart';

class HomeQuickAccessSection extends StatelessWidget {
  const HomeQuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <_QuickItem>[
      _QuickItem(
        title: 'Chapter Wise',
        glyph: HomeQuickGlyph.books,
        tint: HomeVisual.tileChapter,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const _HomePushedPage(
              removeTopPadding: true,
              child: SyllabusHomeScreen(),
            ),
          ),
        ),
      ),
      _QuickItem(
        title: 'Test Series',
        glyph: HomeQuickGlyph.clipboard,
        tint: HomeVisual.tileTests,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const _HomePushedPage(
              title: 'Test Series',
              child: TestsHomeScreen(),
            ),
          ),
        ),
      ),
      _QuickItem(
        title: 'Current Affairs',
        glyph: HomeQuickGlyph.globe,
        tint: HomeVisual.tileAffairs,
        onTap: () => openCurrentAffairs(context),
      ),
      _QuickItem(
        title: 'Previous Papers',
        glyph: HomeQuickGlyph.document,
        tint: HomeVisual.tilePapers,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                const PreviousExamSelectionScreen(title: 'Previous Papers'),
          ),
        ),
      ),
    ];

    final narrow = MediaQuery.sizeOf(context).width < 340;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle('Quick Access'),
        const SizedBox(height: AppSpacing.md),
        narrow
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _QuickTile(item: tiles[0])),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _QuickTile(item: tiles[1])),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _QuickTile(item: tiles[2])),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _QuickTile(item: tiles[3])),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _QuickTile(item: tiles[i])),
                  ],
                ],
              ),
      ],
    );
  }
}

class _QuickItem {
  const _QuickItem({
    required this.title,
    required this.glyph,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final HomeQuickGlyph glyph;
  final Color tint;
  final VoidCallback onTap;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.item});

  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(HomeVisual.tileRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: HomeQuickGlyphIcon(glyph: item.glyph, size: 22),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: HomeVisual.ink,
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

/// Home-only wrapper so Quick Access can push existing screens without
/// restyling them or changing tab architecture.
class _HomePushedPage extends StatelessWidget {
  const _HomePushedPage({
    this.title,
    this.removeTopPadding = false,
    required this.child,
  });

  final String? title;
  final Widget child;
  final bool removeTopPadding;

  @override
  Widget build(BuildContext context) {
    Widget body = child;
    if (removeTopPadding) {
      body = MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: child,
      );
    }

    return Scaffold(
      backgroundColor: HomeVisual.page,
      appBar: AppBar(title: title == null ? null : Text(title!)),
      body: body,
    );
  }
}
