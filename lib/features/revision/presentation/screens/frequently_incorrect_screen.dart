import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../data/models/revision_models.dart';
import '../../services/revision_service.dart';
import '../widgets/revision_empty_state.dart';
import '../widgets/revision_question_card.dart';

class FrequentlyIncorrectScreen extends StatefulWidget {
  const FrequentlyIncorrectScreen({super.key, this.courseId});

  final String? courseId;

  @override
  State<FrequentlyIncorrectScreen> createState() =>
      _FrequentlyIncorrectScreenState();
}

class _FrequentlyIncorrectScreenState extends State<FrequentlyIncorrectScreen> {
  late Future<List<RevisionQuestionGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future = RevisionService.instance.loadFrequentlyIncorrectGroups(
      courseId: widget.courseId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Frequently Incorrect')),
      body: FutureBuilder<List<RevisionQuestionGroup>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: AppCircularProgress());
          }

          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return const RevisionEmptyState(
              title: 'No repeated mistakes found.',
              icon: Icons.thumb_up_outlined,
            );
          }

          return SafeArea(
            bottom: false,
            child: AppResponsivePadding(
              child: TabScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                children: [
                  for (var g = 0; g < groups.length; g++) ...[
                    if (g > 0) const SizedBox(height: AppSpacing.xxxl),
                    Text(
                      groups[g].courseName,
                      style: AppTextStyles.titleLarge(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${groups[g].paperName} · ${groups[g].chapterName}',
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (var i = 0; i < groups[g].items.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      RevisionQuestionCard(item: groups[g].items[i]),
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
