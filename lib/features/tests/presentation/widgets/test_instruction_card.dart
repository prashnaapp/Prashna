import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class TestInstructionCard extends StatelessWidget {
  const TestInstructionCard({
    super.key,
    required this.instructions,
  });

  final List<String> instructions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Instructions', style: AppTextStyles.titleMedium(context)),
          if (instructions.isNotEmpty) const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < instructions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•', style: AppTextStyles.bodyLarge(context)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    instructions[i],
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
