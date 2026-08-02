import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart' hide ChapterCard, ProgressCard;
import 'chapter_list_screen.dart';
import 'data/chapters_data.dart';
import 'widgets/chapters_scroll_body.dart';
import 'widgets/part_card.dart';

class PartsScreen extends StatelessWidget {
  const PartsScreen({
    super.key,
    required this.paperTitle,
  });

  final String paperTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(paperTitle)),
      body: ChaptersScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                for (var i = 0; i < ChaptersData.parts.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  PartCard(
                    title: ChaptersData.parts[i],
                    heroTag: 'g3-$paperTitle-${ChaptersData.parts[i]}',
                    onTap: () => _openChapters(context, ChaptersData.parts[i]),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openChapters(BuildContext context, String partTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterListScreen(
          paperTitle: paperTitle,
          partTitle: partTitle,
        ),
      ),
    );
  }
}
