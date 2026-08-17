import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../navigation/tab_scroll_view.dart';

/// Content-sized scroll host for Test Series — same behavior as Home [TabScrollView].
class TestsScrollBody extends StatelessWidget {
  const TestsScrollBody({
    super.key,
    required this.children,
    this.bottomInset = true,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final List<Widget> children;
  final bool bottomInset;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (!bottomInset) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      );
    }

    return TabScrollView(padding: padding, children: children);
  }
}
