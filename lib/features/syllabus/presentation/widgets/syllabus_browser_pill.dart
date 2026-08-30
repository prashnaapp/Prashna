import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// Compact paper/part pill used only by the Syllabus Browser.
class SyllabusBrowserPill extends StatelessWidget {
  const SyllabusBrowserPill({
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
    final radius = BorderRadius.circular(SyllabusVisual.pillRadius);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: selected
                ? SyllabusVisual.selectedShadow
                : SyllabusVisual.cardShadow,
          ),
          child: Material(
            color: selected ? SyllabusVisual.accent : SyllabusVisual.surface,
            shape: RoundedRectangleBorder(borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: RoundedRectangleBorder(borderRadius: radius),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.label(context).copyWith(
                    color: selected ? Colors.white : SyllabusVisual.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: AppAnimations.fast,
          height: 3,
          width: selected ? 28 : 0,
          decoration: BoxDecoration(
            color: SyllabusVisual.accent,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }
}
