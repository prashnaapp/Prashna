import 'package:flutter/material.dart';

import '../../admin_routes.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_nav_tile.dart';
import '../widgets/admin_ui/admin_page_header.dart';

/// Tests landing: Chapter Tests vs Test Series (mirrors Questions home).
class AdminTestsHomeScreen extends StatelessWidget {
  const AdminTestsHomeScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(AdminSpacing.pagePadding),
          children: [
            const AdminPageHeader(
              title: 'Tests',
              subtitle: 'Manage chapter tests and test series',
            ),
            AdminNavTile(
              key: const ValueKey('tests-choice-chapter'),
              title: 'Chapter Tests',
              subtitle: 'Browse syllabus hierarchy and manage chapter tests',
              icon: Icons.menu_book_outlined,
              onTap: () =>
                  Navigator.of(context).pushNamed(AdminRoutes.chapters),
            ),
            const SizedBox(height: AdminSpacing.md),
            AdminNavTile(
              key: const ValueKey('tests-choice-test-series'),
              title: 'Test Series',
              subtitle: 'Manage paper-wise, grand tests and previous papers',
              icon: Icons.assignment_outlined,
              onTap: () =>
                  Navigator.of(context).pushNamed(AdminRoutes.testSeries),
            ),
          ],
        ),
      ),
    );

    if (embeddedInShell) return body;

    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(title: const Text('Tests')),
      body: body,
    );
  }
}
