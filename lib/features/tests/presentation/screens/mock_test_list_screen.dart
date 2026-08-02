import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/test_service.dart';
import '../mock_test_navigation.dart';
import '../widgets/test_category_card.dart';
import '../widgets/tests_scroll_body.dart';

/// Mock Tests → list of mock test sets.
class MockTestListScreen extends StatelessWidget {
  const MockTestListScreen({
    super.key,
    required this.examId,
    required this.title,
  });

  final String examId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final mocks = TestService.instance.getMockTests(examId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: TestsScrollBody(
        bottomInset: false,
        children: [
          for (var i = 0; i < mocks.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            TestCategoryCard(
              title: mocks[i].title,
              subtitle: 'Select a paper to begin',
              onTap: () => openMockPapers(
                context: context,
                examId: examId,
                mock: mocks[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
