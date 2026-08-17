/// Preferred export for the authoritative course-access / entitlement API.
///
/// Features should depend on [CourseAccessService] / [SubscriptionAccessService]
/// rather than local `if paid` / `if subscribed` checks.
library;

export '../model/course_access_decision.dart';
export '../model/course_entitlement.dart';
export 'subscription_access_service.dart';
