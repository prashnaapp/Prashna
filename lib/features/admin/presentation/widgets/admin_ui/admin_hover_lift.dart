import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';

/// Controlled premium hover lift for Admin interactive cards.
///
/// Enhancement only — does not replace InkWell / keyboard / touch semantics.
/// Prefer Dashboard destination cards; do not wrap every list row.
class AdminHoverLift extends StatefulWidget {
  const AdminHoverLift({
    super.key,
    required this.child,
    this.enabled = true,
    this.lift = 3,
    this.scale = 1.012,
    this.duration = const Duration(milliseconds: 180),
  });

  final Widget child;
  final bool enabled;

  /// Upward translation in logical pixels (max 4).
  final double lift;

  /// Hover scale (keep ≤ 1.015).
  final double scale;

  final Duration duration;

  @override
  State<AdminHoverLift> createState() => _AdminHoverLiftState();
}

class _AdminHoverLiftState extends State<AdminHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final lift = widget.lift.clamp(0.0, 4.0);
    final scale = widget.scale.clamp(1.0, 1.015);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AdminColors.atmosphereDeep.withValues(alpha: 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ]
              : const [],
        ),
        child: AnimatedScale(
          scale: _hovered ? scale : 1.0,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              0,
              _hovered ? -lift : 0,
              0,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
