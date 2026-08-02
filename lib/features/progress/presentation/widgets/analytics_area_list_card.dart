import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class AnalyticsAreaListCard extends StatelessWidget {
  const AnalyticsAreaListCard({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<({String name, String detail})> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTextStyles.titleLarge(context)),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          AppCard(
            showShadow: false,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    items[i].name,
                    style: AppTextStyles.bodyLarge(context),
                  ),
                ),
                Text(items[i].detail, style: AppTextStyles.label(context)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
