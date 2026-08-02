import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/bookmark_models.dart';
import '../bookmark_navigation.dart';

class BookmarkQuestionCard extends StatelessWidget {
  const BookmarkQuestionCard({
    super.key,
    required this.bookmark,
    this.onChanged,
  });

  final Bookmark bookmark;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () async {
        await openBookmarkedQuestion(context, bookmark.questionId);
        onChanged?.call();
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bookmark.questionTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${bookmark.paperName} · ${bookmark.chapterName}',
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatDate(bookmark.createdAt),
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return 'Bookmarked $d/$m/${date.year}';
  }
}
