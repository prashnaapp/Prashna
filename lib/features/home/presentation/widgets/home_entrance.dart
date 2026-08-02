import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Staggered entrance that does **not** reserve layout space while hidden.
///
/// Before the delayed reveal, this collapses to zero height so later sections
/// are not separated by invisible placeholders.
class HomeEntrance extends StatefulWidget {
  const HomeEntrance({
    super.key,
    required this.index,
    required this.child,
    this.topSpacing = 0,
  });

  final int index;
  final Widget child;

  /// Spacing above this section; omitted entirely while the section is hidden.
  final double topSpacing;

  @override
  State<HomeEntrance> createState() => _HomeEntranceState();
}

class _HomeEntranceState extends State<HomeEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveStandard,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.curveStandard,
      ),
    );
    Future<void>.delayed(AppAnimations.fast * widget.index, () {
      if (!mounted) return;
      setState(() => _revealed = true);
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_revealed) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.topSpacing > 0) SizedBox(height: widget.topSpacing),
        FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
