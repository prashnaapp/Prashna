import 'package:flutter/material.dart';

import '../model/course_access_decision.dart';
import 'subscription_access_service.dart';

/// Guards course navigation with [SubscriptionAccessService].
///
/// Returns a [CourseAccessDecision]. Navigates only when access is allowed.
/// No payment UI — denied access is reported via an existing SnackBar pattern.
abstract final class CourseOpenGuard {
  /// Calls access evaluation for [courseId].
  ///
  /// - Allowed → runs [onAllowed] (existing navigation).
  /// - Denied → does not navigate; shows a SnackBar; returns the decision.
  static Future<CourseAccessDecision> attemptOpen({
    required BuildContext context,
    required String courseId,
    required VoidCallback onAllowed,
    SubscriptionAccessService? accessService,
  }) async {
    final access = accessService ?? SubscriptionAccessService.instance;

    // Public gate API from Phase A.
    final allowed = await access.canAccessCourse(courseId);
    final decision = await access.evaluateCourseAccess(courseId);

    if (allowed && decision.allowed) {
      onAllowed();
      return decision;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFor(decision))),
      );
    }
    return decision;
  }

  static String _messageFor(CourseAccessDecision decision) {
    switch (decision.reason) {
      case CourseAccessReason.contextUnavailable:
        return 'Course access is unavailable right now. Please try again.';
      case CourseAccessReason.denied:
      case CourseAccessReason.freeCourse:
      case CourseAccessReason.activeEnrollment:
        return 'This course requires an active subscription.';
    }
  }
}
