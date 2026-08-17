import 'package:flutter/material.dart';

import '../../../../navigation/app_nav_metrics.dart';

/// Scroll host for syllabus flows. Content-sized — no AlwaysScrollable stretch.
class SyllabusScrollBody extends StatelessWidget {
  const SyllabusScrollBody({
    super.key,
    required this.slivers,
    this.bottomInset = true,
  });

  final List<Widget> slivers;
  final bool bottomInset;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        ...slivers,
        if (bottomInset)
          SliverToBoxAdapter(
            child: SizedBox(height: AppNavMetrics.contentBottomInset(context)),
          ),
      ],
    );
  }
}
