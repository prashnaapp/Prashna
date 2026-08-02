import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class ResultStatTile extends StatelessWidget {
  const ResultStatTile({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium(context)),
          ),
          Text(value, style: AppTextStyles.titleMedium(context)),
        ],
      ),
    );
  }
}
