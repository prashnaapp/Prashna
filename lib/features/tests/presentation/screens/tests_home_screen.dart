import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../data/models/test_models.dart';
import '../../services/test_service.dart';
import '../widgets/test_exam_card.dart';
import 'exam_test_home_screen.dart';

/// Test Series tab body — Available + Launching Soon exam grids.
class TestsHomeScreen extends StatelessWidget {
  const TestsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exams = TestService.instance.getExamSummaries();
    final available = exams.where((e) => e.isEnabled).toList();
    final launchingSoon = exams.where((e) => !e.isEnabled).toList();

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 3 : 2;

    return TabScrollView(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      children: [
        Text(
          'Select an exam to start practicing with full-length mock tests.',
          style: AppTextStyles.bodyMedium(context),
        ),
        if (available.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxxl),
          const SectionHeader(title: 'Available'),
          const SizedBox(height: AppSpacing.lg),
          _ExamGrid(
            crossAxisCount: crossAxisCount,
            children: [
              for (final exam in available)
                TestExamCard(
                  title: exam.title,
                  enabled: true,
                  accent: _accentFor(exam.examId),
                  marksValue: exam.maxMarks.toStringAsFixed(0),
                  papersValue: '${exam.paperCount}',
                  onTap: () => _openExam(context, exam),
                ),
            ],
          ),
        ],
        if (launchingSoon.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxxl),
          const SectionHeader(title: 'Launching Soon'),
          const SizedBox(height: AppSpacing.lg),
          _ExamGrid(
            crossAxisCount: crossAxisCount,
            children: [
              for (final exam in launchingSoon)
                TestExamCard(
                  title: exam.title,
                  enabled: false,
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _openExam(BuildContext context, TestExamSummary exam) {
    final Widget screen = switch (exam.examId) {
      'group-ii' => const GroupIITestHomeScreen(),
      'group-iii' => const GroupIIITestHomeScreen(),
      _ => ExamTestHomeScreen(examId: exam.examId, examTitle: exam.title),
    };

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Color _accentFor(String examId) {
    return switch (examId) {
      'group-iii' => AppColors.success,
      _ => AppColors.primary,
    };
  }
}

class _ExamGrid extends StatelessWidget {
  const _ExamGrid({
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
