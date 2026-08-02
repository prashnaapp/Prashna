import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class PracticeEntrance extends StatefulWidget {
  const PracticeEntrance({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<PracticeEntrance> createState() => _PracticeEntranceState();
}

class _PracticeEntranceState extends State<PracticeEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

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
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}
