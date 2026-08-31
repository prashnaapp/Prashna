import 'package:flutter/material.dart';

/// Horizontal-only swipe over syllabus content.
///
/// Vertical scrolling is left to the ancestor [Scrollable]. A destination
/// change requires a clear horizontal drag that dominates vertical movement.
class SyllabusSwipeSurface extends StatefulWidget {
  const SyllabusSwipeSurface({
    super.key,
    required this.child,
    required this.onSwipeForward,
    required this.onSwipeBack,
  });

  final Widget child;
  final VoidCallback onSwipeForward;
  final VoidCallback onSwipeBack;

  static const double minDistance = 60;
  static const double dominance = 1.5;

  @override
  State<SyllabusSwipeSurface> createState() => _SyllabusSwipeSurfaceState();
}

class _SyllabusSwipeSurfaceState extends State<SyllabusSwipeSurface> {
  Offset _delta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _delta = Offset.zero,
      onHorizontalDragUpdate: (details) => _delta += details.delta,
      onHorizontalDragEnd: (_) {
        final dx = _delta.dx;
        final dy = _delta.dy;
        _delta = Offset.zero;
        if (dx.abs() < SyllabusSwipeSurface.minDistance) return;
        if (dx.abs() <= dy.abs() * SyllabusSwipeSurface.dominance) return;
        if (dx < 0) {
          widget.onSwipeForward();
        } else {
          widget.onSwipeBack();
        }
      },
      onHorizontalDragCancel: () => _delta = Offset.zero,
      child: widget.child,
    );
  }
}
