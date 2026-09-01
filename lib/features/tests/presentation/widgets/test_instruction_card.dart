import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';

class TestInstructionCard extends StatelessWidget {
  const TestInstructionCard({super.key, required this.instructions});

  final List<String> instructions;

  static const _itemIcons = <IconData>[
    Icons.menu_book_outlined,
    Icons.schedule_outlined,
    Icons.emoji_events_outlined,
    Icons.sync_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SyllabusVisual.surface,
        borderRadius: BorderRadius.circular(SyllabusVisual.cardRadius),
        boxShadow: SyllabusVisual.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: SyllabusVisual.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Instructions',
                  style: AppTextStyles.titleMedium(context).copyWith(
                    color: SyllabusVisual.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            if (instructions.isNotEmpty) const SizedBox(height: 14),
            for (var i = 0; i < instructions.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _itemIcons[i % _itemIcons.length],
                    size: 20,
                    color: SyllabusVisual.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      instructions[i],
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: SyllabusVisual.ink,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
