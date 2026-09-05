import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../data/grand_test_series.dart';
import '../../services/test_service.dart';
import '../widgets/tests_plain_header.dart';
import 'grand_test_papers_screen.dart';

/// Fixed Grand Test containers for one exam. Cards are not TestModels.
class GrandTestsScreen extends StatelessWidget {
  const GrandTestsScreen({
    super.key,
    required this.examId,
    this.testService,
  });

  final String examId;
  final TestService? testService;

  void _openSeries(BuildContext context, String seriesId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GrandTestPapersScreen(
          examId: examId,
          seriesId: seriesId,
          testService: testService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      body: Column(
        children: [
          TestsPlainHeader(
            title: 'Grand Tests',
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                SyllabusVisual.pagePadding,
                8,
                SyllabusVisual.pagePadding,
                24,
              ),
              itemCount: GrandTestSeries.ids.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final seriesId = GrandTestSeries.ids[index];
                return _SeriesCard(
                  title: seriesId,
                  archived: seriesId == GrandTestSeries.oldGrandTests,
                  onTap: () => _openSeries(context, seriesId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.title,
    required this.onTap,
    this.archived = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool archived;

  static const Color _titleColor = Color(0xFF130F2B);

  @override
  Widget build(BuildContext context) {
    final iconColor = archived ? AppColors.textSecondary : AppColors.accentTeal;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.xlAll,
        boxShadow: SyllabusVisual.clickableCardShadow,
      ),
      child: Material(
        color: SyllabusVisual.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.xlAll,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.14),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(
                      archived
                          ? Icons.history_rounded
                          : Icons.emoji_events_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium(context).copyWith(
                      color: _titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SyllabusVisual.accent.withValues(alpha: 0.55),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
