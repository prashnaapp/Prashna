import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart' hide ChapterCard, ProgressCard;
import 'parts_screen.dart';
import 'widgets/chapters_scroll_body.dart';
import 'widgets/paper_card.dart';

class GroupIIIPapersScreen extends StatelessWidget {
  const GroupIIIPapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Group-III')),
      body: ChaptersScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const PaperCard(
                  title: 'Paper I',
                  subtitle: 'General Studies',
                  comingSoon: true,
                ),
                const SizedBox(height: AppSpacing.md),
                PaperCard(
                  title: 'Paper II',
                  onTap: () => _openParts(context, 'Paper II'),
                ),
                const SizedBox(height: AppSpacing.md),
                PaperCard(
                  title: 'Paper III',
                  onTap: () => _openParts(context, 'Paper III'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openParts(BuildContext context, String paperTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartsScreen(paperTitle: paperTitle),
      ),
    );
  }
}
