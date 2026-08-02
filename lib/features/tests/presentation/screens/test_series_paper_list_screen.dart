import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/test_models.dart';
import '../widgets/test_category_card.dart';
import '../widgets/tests_scroll_body.dart';

/// Shared paper list used by Paper-wise, Mock, and Previous Papers.
class TestSeriesPaperListScreen extends StatelessWidget {
  const TestSeriesPaperListScreen({
    super.key,
    required this.title,
    required this.papers,
    required this.onPaperTap,
  });

  final String title;
  final List<PaperWisePaper> papers;
  final ValueChanged<PaperWisePaper> onPaperTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: TestsScrollBody(
        bottomInset: false,
        children: [
          for (var i = 0; i < papers.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            TestCategoryCard(
              title: papers[i].title,
              subtitle: papers[i].subtitle,
              onTap: () => onPaperTap(papers[i]),
            ),
          ],
        ],
      ),
    );
  }
}
