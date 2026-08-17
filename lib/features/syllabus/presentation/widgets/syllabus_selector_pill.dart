import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

class SyllabusSelectorPill extends StatelessWidget {
  const SyllabusSelectorPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SyllabusVisual.pillRadius),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.curveStandard,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? SyllabusVisual.accent : SyllabusVisual.surface,
            borderRadius: BorderRadius.circular(SyllabusVisual.pillRadius),
            boxShadow: selected
                ? SyllabusVisual.selectedShadow
                : SyllabusVisual.cardShadow,
          ),
          child: Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              color: selected ? Colors.white : SyllabusVisual.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
