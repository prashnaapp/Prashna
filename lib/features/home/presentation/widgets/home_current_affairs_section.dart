import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../current_affairs/presentation/current_affairs_navigation.dart';

/// Home entry — Current Affairs (below My Courses).
class HomeCurrentAffairsSection extends StatelessWidget {
  const HomeCurrentAffairsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Current Affairs'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          onTap: () => openCurrentAffairs(context),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Weekly & Monthly MCQs',
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Practice exam-focused current affairs.',
                      style: AppTextStyles.bodyMedium(context),
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
        ),
      ],
    );
  }
}
