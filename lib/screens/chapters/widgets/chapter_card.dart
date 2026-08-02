import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

/// Row card for chapter list (number only).
class ChapterCard extends StatelessWidget {
  const ChapterCard({
    super.key,
    required this.label,
    required this.onTap,
    this.heroTag,
  });

  final String label;
  final VoidCallback onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final card = AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.titleMedium(context)),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );

    if (heroTag == null) return card;

    return Hero(
      tag: heroTag!,
      child: Material(
        color: Colors.transparent,
        child: card,
      ),
    );
  }
}
