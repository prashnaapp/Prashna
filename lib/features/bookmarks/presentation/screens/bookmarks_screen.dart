import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../data/services/bookmark_service.dart';
import '../widgets/bookmark_question_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    final groups = BookmarkService.instance.getGroupedBookmarks();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bookmarks')),
      body: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: groups.isEmpty
              ? _EmptyState()
              : TabScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  children: [
                    for (var g = 0; g < groups.length; g++) ...[
                      if (g > 0) const SizedBox(height: AppSpacing.xxxl),
                      Text(
                        groups[g].courseName,
                        style: AppTextStyles.titleLarge(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${groups[g].paperName} · ${groups[g].chapterName}',
                        style: AppTextStyles.bodyMedium(context),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (var i = 0; i < groups[g].items.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        BookmarkQuestionCard(
                          bookmark: groups[g].items[i],
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No bookmarked questions.',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bookmark important questions while practicing.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context),
            ),
          ],
        ),
      ),
    );
  }
}
