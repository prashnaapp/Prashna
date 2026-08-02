import 'package:flutter/material.dart';

import 'app_nav_metrics.dart';

/// Content-sized scroll body for bottom-nav tabs.
/// Height equals children only — no artificial full-screen stretch.
class TabScrollView extends StatelessWidget {
  const TabScrollView({
    super.key,
    required this.children,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final base = padding ?? EdgeInsets.zero;
    final resolved = base.resolve(Directionality.of(context));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: resolved.copyWith(
        bottom: resolved.bottom + AppNavMetrics.contentBottomInset(context),
      ),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
