import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../data/models/bookmark_models.dart';
import '../../data/services/bookmark_service.dart';
import '../widgets/bookmark_question_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    super.key,
    this.bookmarkService,
  });

  /// Optional override for tests; production uses [BookmarkService.instance].
  final BookmarkService? bookmarkService;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late final BookmarkService _bookmarks;
  late Future<BookmarkLoadState> _loadFuture;

  @override
  void initState() {
    super.initState();
    _bookmarks = widget.bookmarkService ?? BookmarkService.instance;
    _loadFuture = _bookmarks.loadCurrentUserBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bookmarks')),
      body: FutureBuilder<BookmarkLoadState>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppCircularProgress());
          }

          final state = snapshot.data ?? _bookmarks.bookmarkLoadState;
          if (state == BookmarkLoadState.error || snapshot.hasError) {
            return const _MessageState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load bookmarks',
              subtitle: 'Please try again.',
              iconColor: AppColors.error,
            );
          }

          final groups = _bookmarks.getGroupedBookmarks();
          return SafeArea(
            bottom: false,
            child: AppResponsivePadding(
              child: groups.isEmpty
                  ? const _MessageState(
                      icon: Icons.star_border_rounded,
                      title: 'No bookmarked questions.',
                      subtitle:
                          'Bookmark important questions while practicing.',
                    )
                  : TabScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl,
                      ),
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
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor ?? AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context),
            ),
          ],
        ),
      ),
    );
  }
}
