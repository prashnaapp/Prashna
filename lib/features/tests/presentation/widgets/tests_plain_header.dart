import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';

/// Lavender-page header: back + title. No gradient, bell, or illustration.
class TestsPlainHeader extends StatelessWidget {
  const TestsPlainHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SyllabusVisual.pagePadding,
            8,
            SyllabusVisual.pagePadding,
            8,
          ),
          child: Row(
            children: [
              Material(
                color: SyllabusVisual.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.smAll,
                ),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: SyllabusVisual.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge(context).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: SyllabusVisual.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
