import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../../authentication/services/auth_service.dart';
import '../../../course_dashboard/presentation/screens/course_dashboard_screen.dart';
import '../../../course_enrollment/service/course_enrollment_service.dart';
import '../../../course_enrollment/service/course_loader_service.dart';
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

  // TEMP DEBUG (Milestone 25) — remove after verification.
  Future<void> _debugActivateEnrollment() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      debugPrint('TEMP DEBUG (M25): No Firebase UID — sign in first.');
      return;
    }

    await CourseEnrollmentService.instance.activateEnrollment(
      uid: uid,
      courseId: 'group-ii',
      source: 'debug',
    );

    final courseContext = CourseLoaderService.instance.current;
    final enrollment = courseContext?.currentEnrollment;
    final active = courseContext?.activeCourse;

    debugPrint('Enrollment activated');
    debugPrint(
      'Current CourseContext: '
      'published=${courseContext?.publishedCourses.length ?? 0} '
      'hasEnrollment=${courseContext?.hasEnrollment} '
      'hasActiveCourse=${courseContext?.hasActiveCourse}',
    );
    debugPrint(
      'Current Enrollment: '
      'uid=${enrollment?.uid} '
      'courseId=${enrollment?.courseId} '
      'status=${enrollment?.status.name} '
      'source=${enrollment?.source.name} '
      'enrolledAt=${enrollment?.enrolledAt} '
      'expiresAt=${enrollment?.expiresAt} '
      'updatedAt=${enrollment?.updatedAt}',
    );
    debugPrint(
      'Active Course: '
      'courseId=${active?.courseId} '
      'title=${active?.title} '
      'isFree=${active?.isFree} '
      'isPublished=${active?.isPublished}',
    );
  }

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
          // TEMP DEBUG (Milestone 25) — remove after verification.
          if (kDebugMode)
            IconButton(
              tooltip: 'TEMP: Activate enrollment',
              onPressed: _debugActivateEnrollment,
              icon: const Icon(Icons.bug_report_rounded),
            ),
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
              const HomeEntrance(
                index: 0,
                child: WelcomeSection(),
              ),
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
