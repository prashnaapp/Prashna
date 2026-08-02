import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart' hide TestCard;
import '../../data/models/test_models.dart';
import '../../services/test_service.dart';
import '../widgets/test_card.dart';
import '../widgets/tests_scroll_body.dart';
import 'test_instructions_screen.dart';

class TestListScreen extends StatelessWidget {
  const TestListScreen({
    super.key,
    required this.examId,
    required this.category,
    required this.title,
  });

  final String examId;
  final TestCategoryType category;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tests = TestService.instance.getTests(
      examId: examId,
      category: category,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: TestsScrollBody(
        bottomInset: false,
        children: [
          for (var i = 0; i < tests.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            TestCard(
              test: tests[i],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestInstructionsScreen(test: tests[i]),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
