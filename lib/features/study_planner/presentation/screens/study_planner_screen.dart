import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../data/models/study_planner_models.dart';
import '../../data/services/study_planner_service.dart';
import '../widgets/course_complete_banner.dart';
import '../widgets/monthly_progress_section.dart';
import '../widgets/study_progress_section.dart';
import '../widgets/study_streak_section.dart';
import '../widgets/today_goal_section.dart';
import '../widgets/upcoming_tasks_section.dart';
import '../widgets/weekly_plan_section.dart';

/// Smart Study Planner — Progress-backed plan (Phase 2).
class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({
    super.key,
    this.courseId = 'group-ii',
  });

  final String courseId;

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  late Future<StudyPlannerData> _future;

  @override
  void initState() {
    super.initState();
    _future = StudyPlannerService.instance.getPlan(courseId: widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudyPlannerData>(
      future: _future,
      builder: (context, snapshot) {
        final plan = snapshot.data;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Study Planner'),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                icon: const Icon(Icons.notifications_rounded),
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: AppCircularProgress())
              : SafeArea(
                  bottom: false,
                  child: AppResponsivePadding(
                    child: TabScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl,
                      ),
                      children: [
                        if (plan!.isCourseComplete) ...[
                          CourseCompleteBanner(courseTitle: plan.courseTitle),
                          const SizedBox(height: AppSpacing.xxxl),
                        ] else ...[
                          TodayGoalSection(goal: plan.todayGoal),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],
                        StudyProgressSection(progress: plan.studyProgress),
                        const SizedBox(height: AppSpacing.xxxl),
                        WeeklyPlanSection(days: plan.weeklyPlan),
                        const SizedBox(height: AppSpacing.xxxl),
                        MonthlyProgressSection(
                          progress: plan.monthlyProgress,
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        StudyStreakSection(streak: plan.streak),
                        if (!plan.isCourseComplete) ...[
                          const SizedBox(height: AppSpacing.xxxl),
                          UpcomingTasksSection(tasks: plan.upcomingTasks),
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
