import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class ExplanationCard extends StatelessWidget {
  const ExplanationCard({
    super.key,
    required this.explanation,
  });

  final String explanation;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Explanation', style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: AppSpacing.md),
          Text(
            explanation,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
