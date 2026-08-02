import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Exam card for the Test Series grid — premium minimal layout.
class TestExamCard extends StatefulWidget {
  const TestExamCard({
    super.key,
    required this.title,
    required this.enabled,
    this.accent = AppColors.primary,
    this.marksValue,
    this.papersValue,
    this.onTap,
  });

  final String title;
  final bool enabled;
  final Color accent;
  final String? marksValue;
  final String? papersValue;
  final VoidCallback? onTap;

  @override
  State<TestExamCard> createState() => _TestExamCardState();
}

class _TestExamCardState extends State<TestExamCard> {
  static const _tapDuration = Duration(milliseconds: 150);

  bool _pressed = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.enabled ? widget.accent : AppColors.textTertiary;

    final card = AppCard(
      onTap: null,
      showShadow: true,
      borderRadius: AppRadius.xlAll,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.enabled
                    ? Icons.school_rounded
                    : Icons.lock_rounded,
                color: accent,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium(context),
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.enabled)
              Text.rich(
                TextSpan(
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(
                      text: widget.marksValue ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' Marks • '),
                    TextSpan(
                      text: widget.papersValue ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' Papers'),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                'Launching Soon',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );

    if (!_interactive) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: _tapDuration,
        curve: AppAnimations.curveStandard,
        child: card,
      ),
    );
  }
}
