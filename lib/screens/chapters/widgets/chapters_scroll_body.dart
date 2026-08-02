import 'package:flutter/material.dart';

import '../../../navigation/app_nav_metrics.dart';

class ChaptersScrollBody extends StatelessWidget {
  const ChaptersScrollBody({
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
            child: SizedBox(
              height: AppNavMetrics.contentBottomInset(context),
            ),
          ),
      ],
    );
  }
}
