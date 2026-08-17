import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/course_enrollment/model/course_context.dart';
import 'package:telangana_prep/features/course_enrollment/model/user_course.dart';
import 'package:telangana_prep/features/course_enrollment/service/course_loader_service.dart';
import 'package:telangana_prep/features/payments/config/play_billing_config.dart';
import 'package:telangana_prep/features/payments/model/play_purchase_models.dart';
import 'package:telangana_prep/features/subscription/service/subscription_access_service.dart';

void main() {
  test('9/19: backend verification success refreshes access via CourseContext',
      () async {
    final loader = CourseLoaderService();
    final access = SubscriptionAccessService(
      courseLoader: loader,
      now: () => DateTime(2026, 8, 10),
    );

    loader.debugSetCurrent(
      const CourseContext(
        publishedCourses: [
          Course(
            courseId: 'group-ii',
            title: 'Group II',
            shortTitle: 'G-II',
            description: '',
            thumbnail: null,
            icon: null,
            color: null,
            isFree: false,
            isPublished: true,
            price: 0,
            sortOrder: 1,
            createdAt: null,
            updatedAt: null,
          ),
        ],
        enrollments: [],
      ),
    );
    expect(await access.hasCourseAccess('group-ii'), isFalse);

    // Simulate post-verify CourseLoader reload with backend-granted entitlement.
    loader.debugSetCurrent(
      CourseContext(
        publishedCourses: loader.current!.publishedCourses,
        enrollments: [
          UserCourse(
            uid: 'user-1',
            courseId: PlayBillingConfig.groupIiCourseId,
            enrolledAt: DateTime(2026, 8, 10),
            status: UserCourseStatus.active,
            source: UserCourseSource.purchase,
            expiresAt: DateTime(2027, 8, 10),
          ),
        ],
      ),
    );
    expect(await access.hasCourseAccess('group-ii'), isTrue);
  });

  test('client must not treat purchase UI success without backend', () {
    const localOnly = PlayPurchaseFlowResult(
      state: PlayPurchaseUiState.purchasing,
    );
    expect(localOnly.unlockedAccess, isFalse);
  });
}
