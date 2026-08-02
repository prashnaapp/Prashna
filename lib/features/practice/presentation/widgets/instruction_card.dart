import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class InstructionCard extends StatelessWidget {
  const InstructionCard({
    super.key,
    required this.instructions,
  });

  final List<String> instructions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: AppTextStyles.titleMedium(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final line in instructions) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    line,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
