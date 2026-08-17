/// Centralized Google Play Billing product configuration (client display/query).
///
/// The Play Console product ID must match [groupIi12MonthProductId] exactly.
/// Access duration is NOT claimed from Google Play — the trusted backend
/// derives entitlement expiry from its own product mapping.
abstract final class PlayBillingConfig {
  /// Android application ID / package name (must match Play Console app).
  static const String packageName = 'com.prashna.app';

  /// One-time in-app product for Group II 12-month access.
  /// Create this exact product ID in Play Console before testing.
  static const String groupIi12MonthProductId = 'group2_12m';

  /// Course unlocked by [groupIi12MonthProductId] (server is authoritative).
  static const String groupIiCourseId = 'group-ii';

  /// Marketing label for the access window. Entitlement expiry is set by backend.
  static const String groupIiAccessLabel = '12-Month Access';

  static const String paymentProvider = 'google_play';

  static Set<String> get queryProductIds => {groupIi12MonthProductId};

  /// Whether this course has a Play Billing product in V1.
  static bool supportsPlayPurchase(String courseId) =>
      courseId == groupIiCourseId;

  static String? productIdForCourse(String courseId) {
    if (courseId == groupIiCourseId) return groupIi12MonthProductId;
    return null;
  }
}
