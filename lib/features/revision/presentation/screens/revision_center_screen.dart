import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../data/models/revision_models.dart';
import '../../services/revision_service.dart';
import '../revision_navigation.dart';
import '../widgets/revision_hub_card.dart';

class RevisionCenterScreen extends StatefulWidget {
  const RevisionCenterScreen({
    super.key,
    this.courseId,
  });

  final String? courseId;

  @override
  State<RevisionCenterScreen> createState() => _RevisionCenterScreenState();
}

class _RevisionCenterScreenState extends State<RevisionCenterScreen> {
  late Future<List<RevisionHubItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = RevisionService.instance.loadHubItems(courseId: widget.courseId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = RevisionService.instance.loadHubItems(courseId: widget.courseId);
    });
  }

  Future<void> _open(RevisionHubItem item) async {
    await RevisionNavigation.openHubDestination(
      context,
      type: item.type,
      courseId: widget.courseId,
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Revision Center')),
      body: FutureBuilder<List<RevisionHubItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: AppCircularProgress());
          }

          final items = snapshot.data!;

          return SafeArea(
            bottom: false,
            child: AppResponsivePadding(
              child: TabScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                children: [
                  Text(
                    'Revise everything in one place',
                    style: AppTextStyles.headline(context),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Wrong answers, weak topics, bookmarks, and repeated mistakes.',
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    RevisionHubCard(
                      item: items[i],
                      onTap: () => _open(items[i]),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
