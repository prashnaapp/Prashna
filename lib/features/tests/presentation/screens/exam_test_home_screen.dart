import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../progress/data/progress_dummy_data.dart';
import '../../../syllabus/presentation/syllabus_visual.dart';
import '../../../syllabus/presentation/widgets/landing_sheet.dart';
import '../../data/models/test_models.dart';
import '../../services/test_service.dart';
import '../paper_wise_navigation.dart';
import '../widgets/exam_category_hero.dart';
import '../widgets/exam_category_tile.dart';

/// Test Series → Group-II / Group-III category dashboard.
class ExamTestHomeScreen extends StatelessWidget {
  const ExamTestHomeScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    this.testService,
  });

  final String examId;
  final String examTitle;

  /// Optional catalog override for widget tests. Production uses the singleton.
  final TestService? testService;

  /// User-facing order on this screen. Other categories from
  /// [TestService.getCategories] stay available to other callers.
  static const _visibleTypes = <TestCategoryType>[
    TestCategoryType.partTests,
    TestCategoryType.mockTests,
    TestCategoryType.previousYear,
  ];

  @override
  Widget build(BuildContext context) {
    final catalog = testService ?? TestService.instance;
    final byType = <TestCategoryType, TestCategoryModel>{
      for (final category in catalog.getCategories(examId))
        category.type: category,
    };
    final categories = [
      for (final type in _visibleTypes)
        if (byType[type] != null) byType[type]!,
    ];

    return Scaffold(
      backgroundColor: SyllabusVisual.page,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final heroHeight = (h * 0.26).clamp(188.0, 232.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: ExamCategoryHero(
                  title: examTitle,
                  height: heroHeight,
                  onBack: () => Navigator.maybePop(context),
                ),
              ),
              Positioned(
                top: heroHeight - LandingSheet.heroOverlap,
                left: 0,
                right: 0,
                bottom: 0,
                child: _CategoryBody(
                  examId: examId,
                  categories: categories,
                  testService: catalog,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryBody extends StatelessWidget {
  const _CategoryBody({
    required this.examId,
    required this.categories,
    required this.testService,
  });

  final String examId;
  final List<TestCategoryModel> categories;
  final TestService testService;

  static const double _cardGap = 12;
  static const double _bottomBreathBase = 20;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyH = constraints.maxHeight;
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        final n = categories.length;
        final gaps = n > 1 ? _cardGap * (n - 1) : 0.0;
        final reserved =
            LandingSheet.topPad + _bottomBreathBase + safeBottom + gaps;
        final availableForCards = (bodyH - reserved).clamp(0.0, bodyH);
        // Previous envelope filled leftover space up to 160px. Cards are now
        // half that height so the stack stays compact against the reference.
        final fullH = n == 0 ? 0.0 : (availableForCards / n).clamp(88.0, 160.0);
        final cardH = (fullH * 0.50).clamp(76.0, 80.0);

        return LandingSheet(
          expand: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(height: _cardGap),
                ExamCategoryTile(
                  title: _displayTitle(categories[i]),
                  subtitle: categories[i].subtitle,
                  icon: _iconFor(categories[i].type),
                  accent: _accentFor(categories[i].type),
                  height: cardH,
                  onTap: () => openTestCategory(
                    context: context,
                    examId: examId,
                    category: categories[i],
                    testService: testService,
                  ),
                ),
              ],
              SizedBox(height: _bottomBreathBase + safeBottom),
            ],
          ),
        );
      },
    );
  }

  /// User-facing labels for this screen only. Destinations keep the original
  /// [TestCategoryModel] (including "Mock Tests" internally).
  String _displayTitle(TestCategoryModel category) {
    return switch (category.type) {
      TestCategoryType.mockTests => 'Grand Tests',
      _ => category.title,
    };
  }

  Color _accentFor(TestCategoryType type) {
    return switch (type) {
      TestCategoryType.partTests => AppColors.accent,
      TestCategoryType.mockTests => AppColors.accentTeal,
      TestCategoryType.previousYear => AppColors.accentWarm,
      _ => SyllabusVisual.accent,
    };
  }

  IconData _iconFor(TestCategoryType type) {
    return switch (type) {
      TestCategoryType.partTests => Icons.description_rounded,
      TestCategoryType.mockTests => Icons.emoji_events_rounded,
      TestCategoryType.previousYear => Icons.history_edu_rounded,
      _ => Icons.quiz_rounded,
    };
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
