import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class ProgressInfoCard extends StatelessWidget {
  const ProgressInfoCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
