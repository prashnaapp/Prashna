import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../../question_bank/data/services/question_service.dart';
import '../../../test_engine/presentation/widgets/attempt_option_tile.dart';
import '../../data/services/bookmark_service.dart';

/// Reuses Test Engine option tiles to show a bookmarked Question Bank item.
class BookmarkQuestionViewerScreen extends StatefulWidget {
  const BookmarkQuestionViewerScreen({
    super.key,
    required this.questionId,
    this.title = 'Bookmarked Question',
  });

  final String questionId;
  final String title;

  @override
  State<BookmarkQuestionViewerScreen> createState() =>
      _BookmarkQuestionViewerScreenState();
}

class _BookmarkQuestionViewerScreenState
    extends State<BookmarkQuestionViewerScreen> {
  late Future<Question?> _future;

  @override
  void initState() {
    super.initState();
    _future = QuestionService.instance.getById(widget.questionId);
  }

  @override
  Widget build(BuildContext context) {
    final bookmarked = BookmarkService.instance.isBookmarked(widget.questionId);

    return FutureBuilder<Question?>(
      future: _future,
      builder: (context, snapshot) {
        final question = snapshot.data;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                tooltip: 'Bookmark',
                onPressed: question == null
                    ? null
                    : () async {
                        await BookmarkService.instance.toggleBookmark(
                          questionId: question.id,
                          courseId: question.courseId,
                          paperId: question.paperId,
                          partId: question.sectionId,
                          chapterId: question.topicId,
                          questionType: question.questionType.name,
                          questionTitle: question.question,
                        );
                        if (mounted) setState(() {});
                      },
                icon: Icon(
                  bookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                  color: bookmarked
                      ? AppColors.accentWarm
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: AppCircularProgress())
              : question == null
              ? Center(
                  child: Text(
                    'Question unavailable.',
                    style: AppTextStyles.bodyMedium(context),
                  ),
                )
              : SafeArea(
                  bottom: false,
                  child: AppResponsivePadding(
                    child: TabScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl,
                      ),
                      children: [
                        AppCard(
                          showShadow: false,
                          child: Text(
                            question.content?.en.question.isNotEmpty == true
                                ? question.content!.en.question
                                : question.question,
                            style: AppTextStyles.bodyLarge(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (question.content?.te != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            question.content!.te!.question,
                            style: AppTextStyles.bodyMedium(context),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        for (var i = 0; i < question.options.length; i++) ...[
                          AttemptOptionTile(
                            label: String.fromCharCode(65 + i),
                            optionText:
                                question.content?.te == null ||
                                    i >= question.content!.te!.options.length
                                ? question.options[i]
                                : '${question.options[i]}\n'
                                      '${question.content!.te!.options[i].text}',
                            selected:
                                String.fromCharCode(65 + i) ==
                                question.correctOption,
                            onTap: () {},
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          backgroundColor: AppColors.successSurface,
                          showShadow: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Correct Answer: ${question.correctOption}',
                                style: AppTextStyles.titleMedium(context),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                question.explanation,
                                style: AppTextStyles.bodyMedium(context),
                              ),
                              if (question.content?.te != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  question.content!.te!.explanation,
                                  style: AppTextStyles.bodyMedium(context),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
