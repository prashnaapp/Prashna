import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/course_dashboard_models.dart';

class PaperProgressSection extends StatelessWidget {
  const PaperProgressSection({
    super.key,
    required this.papers,
  });

  final List<PaperProgressItem> papers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Paper Progress'),
        const SizedBox(height: AppSpacing.lg),
        if (papers.isEmpty)
          AppCard(
            child: Text(
              'Start solving Practice Bits to track your progress.',
              style: AppTextStyles.bodyMedium(context),
            ),
          )
        else
          for (var i = 0; i < papers.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          papers[i].title,
                          style: AppTextStyles.titleMedium(context),
                        ),
                      ),
                      Text(
                        '${papers[i].progressPercent}%',
                        style: AppTextStyles.label(context).copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppLinearProgress(
                    value: papers[i].progressPercent / 100,
                    height: AppSpacing.sm,
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}
