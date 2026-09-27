import 'package:flutter/material.dart';

import '../../admin_routes.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_nav_tile.dart';
import '../widgets/admin_ui/admin_page_header.dart';

/// Content → Questions landing: Chapter vs Test Series.
class AdminQuestionsHomeScreen extends StatelessWidget {
  const AdminQuestionsHomeScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(AdminSpacing.pagePadding),
          children: [
            const AdminPageHeader(title: 'Questions'),
            AdminNavTile(
              key: const ValueKey('questions-choice-chapter'),
              title: 'Chapter Questions',
              icon: Icons.menu_book_outlined,
              onTap: () =>
                  Navigator.of(context).pushNamed(AdminRoutes.chapterQuestions),
            ),
            const SizedBox(height: AdminSpacing.md),
            AdminNavTile(
              key: const ValueKey('questions-choice-test-series'),
              title: 'Test Series Questions',
              icon: Icons.assignment_outlined,
              onTap: () => Navigator.of(
                context,
              ).pushNamed(AdminRoutes.testSeriesQuestions),
            ),
          ],
        ),
      ),
    );

    if (embeddedInShell) return body;

    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(title: const Text('Questions')),
      body: body,
    );
  }
}
