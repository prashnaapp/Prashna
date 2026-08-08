import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../../authentication/services/auth_service.dart';
import '../../../course_dashboard/presentation/screens/course_dashboard_screen.dart';
import '../../../course_enrollment/service/course_enrollment_service.dart';
import '../../../course_enrollment/service/course_loader_service.dart';
import '../../../payments/service/payment_service.dart';
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
    final enrollments = courseContext?.enrollments ?? const [];

    debugPrint('Enrollment activated');
    debugPrint(
      'Current CourseContext: '
      'published=${courseContext?.publishedCourses.length ?? 0} '
      'enrollments=${enrollments.length} '
      'hasEnrollment=${courseContext?.hasEnrollment}',
    );
    for (final enrollment in enrollments) {
      debugPrint(
        'Enrollment: '
        'uid=${enrollment.uid} '
        'courseId=${enrollment.courseId} '
        'status=${enrollment.status.name} '
        'source=${enrollment.source.name} '
        'enrolledAt=${enrollment.enrolledAt} '
        'expiresAt=${enrollment.expiresAt} '
        'updatedAt=${enrollment.updatedAt}',
      );
    }
  }

  // TEMP DEBUG (Milestone 27.1) — remove after verification.
  Future<void> _debugSimulatePurchase() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      debugPrint('TEMP DEBUG (M27.1): No Firebase UID — sign in first.');
      return;
    }

    final plans = await PaymentService.instance.loadActivePlans();
    if (plans.isEmpty) {
      debugPrint('No active payment plans.');
      return;
    }

    final plan = plans.first;
    await PaymentService.instance.purchaseCourse(
      uid: uid,
      courseId: plan.courseId,
      plan: plan,
    );

    final courseContext = CourseLoaderService.instance.current;
    final enrollments = courseContext?.enrollments ?? const [];

    debugPrint('Purchase simulation complete.');
    for (final enrollment in enrollments) {
      debugPrint(
        'Enrollment: '
        'uid=${enrollment.uid} '
        'courseId=${enrollment.courseId} '
        'status=${enrollment.status.name} '
        'source=${enrollment.source.name} '
        'enrolledAt=${enrollment.enrolledAt} '
        'expiresAt=${enrollment.expiresAt} '
        'updatedAt=${enrollment.updatedAt}',
      );
    }
    debugPrint(
      'Current CourseContext: '
      'published=${courseContext?.publishedCourses.length ?? 0} '
      'enrollments=${enrollments.length} '
      'hasEnrollment=${courseContext?.hasEnrollment}',
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
          // TEMP DEBUG (Milestone 27.1) — remove after verification.
          if (kDebugMode)
            IconButton(
              tooltip: 'TEMP: Simulate purchase',
              onPressed: _debugSimulatePurchase,
              icon: const Icon(Icons.shopping_cart_rounded),
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
