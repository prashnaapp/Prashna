import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

class ExamCard extends StatelessWidget {
  const ExamCard({
    super.key,
    required this.title,
    required this.onTap,
    this.heroTag,
  });

  final String title;
  final VoidCallback onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final card = AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppTextStyles.titleMedium(context)),
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
