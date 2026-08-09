import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../../course_dashboard/presentation/screens/course_dashboard_screen.dart';
import '../../../subscription/service/course_open_guard.dart';
import '../../services/home_service.dart';
import '../widgets/continue_learning_card.dart';
import '../widgets/home_courses_section.dart';
import '../widgets/home_current_affairs_section.dart';
import '../widgets/home_entrance.dart';
import '../widgets/home_study_planner_section.dart';
import '../widgets/today_goal_card.dart';
import '../widgets/welcome_section.dart';

/// Productivity-focused Home dashboard (composition only).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = HomeService.instance;
    final continueLearning = home.getContinueLearning();
    final todayGoal = home.getTodayGoal();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prashna'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: TabScrollView(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            children: [
              const HomeEntrance(index: 0, child: WelcomeSection()),
              HomeEntrance(
                index: 1,
                topSpacing: AppSpacing.xxl,
                child: ContinueLearningCard(
                  data: continueLearning,
                  onContinue: () {
                    CourseOpenGuard.attemptOpen(
                      context: context,
                      courseId: continueLearning.courseId,
                      onAllowed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDashboardScreen(
                              courseId: continueLearning.courseId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const HomeEntrance(
                index: 2,
                topSpacing: AppSpacing.xxl,
                child: HomeCoursesSection(),
              ),
              const HomeEntrance(
                index: 3,
                topSpacing: AppSpacing.xxl,
                child: HomeCurrentAffairsSection(),
              ),
              const HomeEntrance(
                index: 4,
                topSpacing: AppSpacing.xxl,
                child: HomeStudyPlannerSection(),
              ),
              HomeEntrance(
                index: 5,
                topSpacing: AppSpacing.xxl,
                child: TodayGoalCard(goal: todayGoal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
