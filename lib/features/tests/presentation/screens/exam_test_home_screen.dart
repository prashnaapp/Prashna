import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../progress/data/progress_dummy_data.dart';
import '../../services/test_service.dart';
import '../paper_wise_navigation.dart';
import '../widgets/test_category_card.dart';
import '../widgets/tests_scroll_body.dart';

class ExamTestHomeScreen extends StatelessWidget {
  const ExamTestHomeScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  final String examId;
  final String examTitle;

  @override
  Widget build(BuildContext context) {
    final categories = TestService.instance.getCategories(examId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(examTitle)),
      body: TestsScrollBody(
        bottomInset: false,
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            TestCategoryCard(
              title: categories[i].title,
              subtitle: categories[i].subtitle,
              onTap: () => openTestCategory(
                context: context,
                examId: examId,
                category: categories[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GroupIITestHomeScreen extends StatelessWidget {
  const GroupIITestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExamTestHomeScreen(
      examId: ProgressDummyData.groupII,
      examTitle: 'Group-II',
    );
  }
}

class GroupIIITestHomeScreen extends StatelessWidget {
  const GroupIIITestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExamTestHomeScreen(
      examId: ProgressDummyData.groupIII,
      examTitle: 'Group-III',
    );
  }
}
