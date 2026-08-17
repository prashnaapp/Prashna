import 'package:flutter/material.dart';

import '../model/course_access_decision.dart';
import '../presentation/subscription_navigation.dart';
import 'subscription_access_service.dart';

/// Guards course navigation with the authoritative [SubscriptionAccessService]
/// / [CourseAccessService] gate.
///
/// Returns a [CourseAccessDecision]. Navigates only when access is allowed.
/// Denied / expired / revoked access opens the course subscription paywall.
abstract final class CourseOpenGuard {
  /// Calls access evaluation for [courseId].
  ///
  /// - Allowed → runs [onAllowed] (existing navigation).
  /// - Denied / expired / revoked → opens [CourseSubscriptionScreen].
  /// - Context unavailable → SnackBar; no navigation.
  static Future<CourseAccessDecision> attemptOpen({
    required BuildContext context,
    required String courseId,
    required VoidCallback onAllowed,
    SubscriptionAccessService? accessService,
  }) async {
    final access = accessService ?? SubscriptionAccessService.instance;

    // Single authoritative gate — do not duplicate in feature screens.
    final decision = await access.evaluateCourseAccess(courseId);

    if (decision.allowed) {
      onAllowed();
      return decision;
    }

    if (!context.mounted) return decision;

    if (decision.reason == CourseAccessReason.denied ||
        decision.reason == CourseAccessReason.expiredEntitlement ||
        decision.reason == CourseAccessReason.revokedEntitlement) {
      await SubscriptionNavigation.openCourseSubscription(
        context,
        courseId: courseId,
      );
      return decision;
    }

    if (decision.reason == CourseAccessReason.contextUnavailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(decision))));
    }

    return decision;
  }

  static String _messageFor(CourseAccessDecision decision) {
    switch (decision.reason) {
      case CourseAccessReason.contextUnavailable:
        return 'Course access is unavailable right now. Please try again.';
      case CourseAccessReason.denied:
      case CourseAccessReason.expiredEntitlement:
      case CourseAccessReason.revokedEntitlement:
      case CourseAccessReason.freeCourse:
      case CourseAccessReason.activeEnrollment:
        return 'This course requires an active subscription.';
    }
  }
}
