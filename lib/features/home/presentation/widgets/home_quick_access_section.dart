import 'package:flutter/material.dart';

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
        const SizedBox(height: 12),
        HomeSurfaceCard(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
          child: narrow
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _QuickTile(item: tiles[0])),
                        const SizedBox(width: 8),
                        Expanded(child: _QuickTile(item: tiles[1])),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickTile(item: tiles[2])),
                        const SizedBox(width: 8),
                        Expanded(child: _QuickTile(item: tiles[3])),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(child: _QuickTile(item: tiles[i])),
                    ],
                  ],
                ),
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
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(HomeVisual.tileRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: item.tint,
                  borderRadius: BorderRadius.circular(HomeVisual.tileRadius),
                ),
                child: Center(
                  child: HomeQuickGlyphIcon(glyph: item.glyph, size: 26),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: HomeVisual.ink,
                ),
              ),
            ],
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
