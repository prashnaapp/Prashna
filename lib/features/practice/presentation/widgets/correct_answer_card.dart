import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class CorrectAnswerCard extends StatelessWidget {
  const CorrectAnswerCard({
    super.key,
    required this.answerText,
  });

  final String answerText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.successSurface,
      showBorder: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Answer',
                  style: AppTextStyles.titleMedium(context).copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  answerText,
                  style: AppTextStyles.bodyLarge(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
