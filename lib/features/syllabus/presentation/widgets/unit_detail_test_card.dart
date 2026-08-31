import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../tests/data/models/test_models.dart';
import '../syllabus_visual.dart';
import 'unit_detail_surface.dart';

/// Compact published-test row for the Unit Detail screen.
///
/// Presentation-only. [onOpen] is the existing catalog-instructions callback.
class UnitDetailTestCard extends StatelessWidget {
  const UnitDetailTestCard({
    super.key,
    required this.test,
    required this.onOpen,
  });

  final TestModel test;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final meta = test.category == TestCategoryType.previousYear
        ? null
        : '${test.questionCount} Questions • ${test.marks} Marks';

    return UnitDetailSurface(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: SyllabusVisual.tileLavender,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            clipBehavior: Clip.antiAlias,
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.description_rounded,
                color: SyllabusVisual.accent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium(context).copyWith(
                    color: SyllabusVisual.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: SyllabusVisual.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const IgnorePointer(child: _StartButton()),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppRadius.sm));
    return Material(
      key: const ValueKey('unit-detail-start-button'),
      color: SyllabusVisual.accent,
      shape: const RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Center(
            child: Text(
              'Start',
              style: AppTextStyles.label(context).copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
