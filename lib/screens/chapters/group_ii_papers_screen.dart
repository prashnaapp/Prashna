import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart' hide ChapterCard, ProgressCard;
import 'paper_ii_parts_screen.dart';
import 'paper_iii_parts_screen.dart';
import 'paper_iv_parts_screen.dart';
import 'widgets/chapters_scroll_body.dart';
import 'widgets/paper_card.dart';

class GroupIIPapersScreen extends StatelessWidget {
  const GroupIIPapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Group-II')),
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
                  heroTag: 'paper-ii',
                  onTap: () => _open(context, const PaperIIPartsScreen()),
                ),
                const SizedBox(height: AppSpacing.md),
                PaperCard(
                  title: 'Paper III',
                  heroTag: 'paper-iii',
                  onTap: () => _open(context, const PaperIIIPartsScreen()),
                ),
                const SizedBox(height: AppSpacing.md),
                PaperCard(
                  title: 'Paper IV',
                  heroTag: 'paper-iv',
                  onTap: () => _open(context, const PaperIVPartsScreen()),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
