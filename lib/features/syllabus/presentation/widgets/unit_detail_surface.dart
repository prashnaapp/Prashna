import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../syllabus_visual.dart';

/// White clipped surface used by Unit Detail cards.
///
/// Shadow is painted outside [Material] so rounded corners do not leak
/// square artifacts.
class UnitDetailSurface extends StatelessWidget {
  const UnitDetailSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    const radius = AppRadius.mdAll;
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: SyllabusVisual.cardShadow,
      ),
      child: Material(
        color: SyllabusVisual.surface,
        shape: const RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                customBorder: const RoundedRectangleBorder(
                  borderRadius: radius,
                ),
                child: content,
              ),
      ),
    );
  }
}
