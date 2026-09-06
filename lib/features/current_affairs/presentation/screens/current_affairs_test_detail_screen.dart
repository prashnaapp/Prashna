import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../../practice/presentation/widgets/primary_action_button.dart';
import '../../../question_activity/data/models/question_activity_models.dart';
import '../../../test_engine/data/models/test_engine_models.dart';
import '../../../test_engine/presentation/test_engine_navigation.dart';
import '../../data/models/current_affairs_models.dart';
import '../../data/services/current_affairs_service.dart';

/// Set detail — Start Test launches the existing Test Engine.
class CurrentAffairsTestDetailScreen extends StatelessWidget {
  const CurrentAffairsTestDetailScreen({
    super.key,
    required this.set,
  });

  final CurrentAffairsSet set;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(set.title)),
      body: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: TabScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            children: [
              Text(set.title, style: AppTextStyles.headline(context)),
              const SizedBox(height: AppSpacing.xxl),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MetaRow(
                      label: 'Questions',
                      value: '${set.questionCount}',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MetaRow(label: 'Marks', value: '${set.marks}'),
                    const SizedBox(height: AppSpacing.md),
                    _MetaRow(
                      label: 'Minutes',
                      value: '${set.durationMinutes}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              PrimaryActionButton(
                label: 'Start Test',
                onPressed: () => _startTest(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTest(BuildContext context) {
    final service = CurrentAffairsService.instance;
    final isWeekly = set.mode == CurrentAffairsMode.weekly;
    return TestEngineNavigation.openConfigured(
      context: context,
      id: set.id,
      title: set.title,
      courseId: service.courseId,
      mode: TestMode.practice,
      questionCount: set.questionCount,
      totalMarks: set.marks,
      durationMinutes: set.durationMinutes,
      negativeMarks: 0,
      instructions: service.instructions,
      activitySourceModule: QuestionActivitySourceModule.currentAffairs,
      activitySourceType: isWeekly
          ? QuestionActivitySourceType.currentAffairsWeekly
          : QuestionActivitySourceType.currentAffairsMonthly,
      currentAffairsSetId: set.id,
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium(context)),
        ),
        Text(value, style: AppTextStyles.titleMedium(context)),
      ],
    );
  }
}
