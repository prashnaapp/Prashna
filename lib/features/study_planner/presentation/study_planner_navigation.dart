import 'package:flutter/material.dart';

import 'screens/study_planner_screen.dart';

void openStudyPlanner(
  BuildContext context, {
  String courseId = 'group-ii',
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StudyPlannerScreen(courseId: courseId),
    ),
  );
}
