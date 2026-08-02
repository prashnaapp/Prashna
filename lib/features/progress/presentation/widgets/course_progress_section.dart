import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/progress_models.dart';
import '../screens/exam_progress_screen.dart';
import 'exam_tracker_card.dart';

/// Available + Launching Soon — same MVP catalog as Test Series.
class CourseProgressSection extends StatelessWidget {
  const CourseProgressSection({
    super.key,
    required this.enabled,
    required this.comingSoon,
  });

  final List<ExamProgressSummary> enabled;
  final List<ExamProgressSummary> comingSoon;

  @override
  Widget build(BuildContext context) {
    if (enabled.isEmpty && comingSoon.isEmpty) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (enabled.isNotEmpty) ...[
          const SectionHeader(title: 'Available'),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < enabled.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            ExamTrackerCard(
              title: enabled[i].title,
              subtitle:
                  '${_format(enabled[i].maxMarks)} Marks · ${enabled[i].paperCount} Papers',
              enabled: true,
              onTap: () => _openExam(context, enabled[i]),
            ),
          ],
        ],
        if (comingSoon.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxxl),
          const SectionHeader(title: 'Launching Soon'),
          const SizedBox(height: AppSpacing.lg),
          _LaunchingSoonGrid(
            crossAxisCount: crossAxisCount,
            children: [
              for (final exam in comingSoon)
                CourseGridCard(
                  title: exam.title,
                  locked: true,
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _openExam(BuildContext context, ExamProgressSummary exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamProgressScreen(examId: exam.examId),
      ),
    );
  }

  String _format(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

class _LaunchingSoonGrid extends StatelessWidget {
  const _LaunchingSoonGrid({
    required this.crossAxisCount,
    required this.children,
  });

  final int crossAxisCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i += crossAxisCount) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < crossAxisCount; c++) ...[
                if (c > 0) const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: i + c < children.length
                      ? children[i + c]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
