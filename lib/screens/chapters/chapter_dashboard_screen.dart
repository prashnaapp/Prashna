import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart' hide ChapterCard, ProgressCard;
import 'practice_navigation.dart';
import 'widgets/chapters_scroll_body.dart';
import 'widgets/progress_card.dart';

class ChapterDashboardScreen extends StatelessWidget {
  const ChapterDashboardScreen({
    super.key,
    required this.paperTitle,
    required this.partTitle,
    required this.chapterNumber,
  });

  final String paperTitle;
  final String partTitle;
  final int chapterNumber;

  @override
  Widget build(BuildContext context) {
    final chapterLabel = 'Chapter $chapterNumber';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$paperTitle · $partTitle'),
      ),
      body: ChaptersScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Hero(
                    tag: '$paperTitle-$partTitle-$chapterLabel',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        chapterLabel,
                        style: AppTextStyles.headline(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Hero(
                    tag: practiceSessionHeroTag(
                      paperTitle: paperTitle,
                      partTitle: partTitle,
                      chapterNumber: chapterNumber,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: const ProgressCard(
                        weightage: '8%',
                        marksCovered: '12 / 40',
                        remaining: '28 marks',
                        progressPercent: '30%',
                        status: 'In progress',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppPrimaryButton(
                    label: 'Start Practice',
                    onPressed: () => openPracticeSession(
                      context,
                      paperTitle: paperTitle,
                      partTitle: partTitle,
                      chapterNumber: chapterNumber,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
