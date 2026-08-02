import 'package:flutter/material.dart';

import '../core/design_system/design_system.dart';

/// Shared premium course card for Home, Chapters, and Test Series.
///
/// Presentation only — callers own accent, copy, and [onTap] navigation.
class CourseGridCard extends StatefulWidget {
  const CourseGridCard({
    super.key,
    required this.title,
    this.subtitle,
    this.marksValue,
    this.papersValue,
    this.accentColor = AppColors.primary,
    this.icon = Icons.school_rounded,
    this.enabled = true,
    this.locked = false,
    this.lockedLabel = 'Launching Soon',
    this.onTap,
  });

  final String title;

  /// Plain subtitle when [marksValue] / [papersValue] are not set.
  final String? subtitle;

  /// Optional premium metadata: `600 Marks • 4 Papers`.
  final String? marksValue;
  final String? papersValue;

  final Color accentColor;
  final IconData icon;

  /// When false (or [locked]), the card is non-interactive.
  final bool enabled;

  /// Locked / launching-soon visual state.
  final bool locked;

  final String lockedLabel;
  final VoidCallback? onTap;

  @override
  State<CourseGridCard> createState() => _CourseGridCardState();
}

class _CourseGridCardState extends State<CourseGridCard> {
  static const _tapDuration = Duration(milliseconds: 150);

  bool _pressed = false;

  bool get _isLocked => widget.locked || !widget.enabled;

  bool get _interactive => !_isLocked && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        _isLocked ? AppColors.textTertiary : widget.accentColor;

    final card = AppCard(
      onTap: null,
      showShadow: true,
      borderRadius: AppRadius.xlAll,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      child: Opacity(
        opacity: _isLocked ? 0.55 : 1,
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
                _isLocked ? Icons.lock_rounded : widget.icon,
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
            if (_isLocked)
              Text(
                widget.lockedLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              _buildSubtitle(context),
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

  Widget _buildSubtitle(BuildContext context) {
    final base = AppTextStyles.caption(context).copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400,
    );

    if (widget.marksValue != null || widget.papersValue != null) {
      return Text.rich(
        TextSpan(
          style: base,
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
      );
    }

    if (widget.subtitle == null || widget.subtitle!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      widget.subtitle!,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: base,
    );
  }
}
