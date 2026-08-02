import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart' hide ChapterCard, ProgressCard;
import 'chapter_dashboard_screen.dart';
import 'data/chapters_data.dart';
import 'widgets/chapter_card.dart';
import 'widgets/chapters_scroll_body.dart';

class ChapterListScreen extends StatelessWidget {
  const ChapterListScreen({
    super.key,
    required this.paperTitle,
    required this.partTitle,
  });

  final String paperTitle;
  final String partTitle;

  @override
  Widget build(BuildContext context) {
    final chapters = ChaptersData.chapterLabels(ChaptersData.chaptersPerPart);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('$paperTitle · $partTitle')),
      body: ChaptersScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                for (var i = 0; i < chapters.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  ChapterCard(
                    label: chapters[i],
                    heroTag: '$paperTitle-$partTitle-${chapters[i]}',
                    onTap: () => _openDashboard(context, i + 1),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openDashboard(BuildContext context, int chapterNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterDashboardScreen(
          paperTitle: paperTitle,
          partTitle: partTitle,
          chapterNumber: chapterNumber,
        ),
      ),
    );
  }
}
