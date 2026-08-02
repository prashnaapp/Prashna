import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../../test_engine/presentation/test_engine_navigation.dart';
import '../../data/models/revision_models.dart';
import '../../services/revision_service.dart';
import '../widgets/revision_empty_state.dart';
import '../widgets/revision_weak_topic_card.dart';

class WeakTopicsRevisionScreen extends StatefulWidget {
  const WeakTopicsRevisionScreen({super.key, this.courseId});

  final String? courseId;

  @override
  State<WeakTopicsRevisionScreen> createState() =>
      _WeakTopicsRevisionScreenState();
}

class _WeakTopicsRevisionScreenState extends State<WeakTopicsRevisionScreen> {
  late Future<List<RevisionWeakTopicGroup>> _future;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _future = RevisionService.instance.loadWeakTopicGroups(
      courseId: widget.courseId,
    );
  }

  Future<void> _start(WeakTopicRevision topic) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final test = await RevisionService.instance.buildTopicRevisionTest(
        topic: topic,
      );
      if (!mounted) return;
      if (test == null || test.questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions available for this topic.')),
        );
        return;
      }
      await TestEngineNavigation.openTest(context, test: test);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Weak Topics')),
      body: FutureBuilder<List<RevisionWeakTopicGroup>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: AppCircularProgress());
          }

          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return const RevisionEmptyState(
              title: 'No weak topics detected.',
              icon: Icons.insights_outlined,
            );
          }

          return SafeArea(
            bottom: false,
            child: AppResponsivePadding(
              child: TabScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                children: [
                  if (_starting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.lg),
                      child: LinearProgressIndicator(),
                    ),
                  for (var g = 0; g < groups.length; g++) ...[
                    if (g > 0) const SizedBox(height: AppSpacing.xxxl),
                    Text(
                      groups[g].paperName,
                      style: AppTextStyles.titleLarge(context),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (var i = 0; i < groups[g].topics.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      RevisionWeakTopicCard(
                        topic: groups[g].topics[i],
                        onTap: () => _start(groups[g].topics[i]),
                      ),
                    ],
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
