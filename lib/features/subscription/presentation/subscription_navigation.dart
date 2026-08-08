import 'package:flutter/material.dart';

import 'screens/course_subscription_screen.dart';

/// Navigation helpers for subscription / paywall screens.
abstract final class SubscriptionNavigation {
  static Future<void> openCourseSubscription(
    BuildContext context, {
    required String courseId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseSubscriptionScreen(courseId: courseId),
      ),
    );
  }
}
