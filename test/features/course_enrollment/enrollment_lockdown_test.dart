import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/course_enrollment/entitlement_mutation_forbidden.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/course_enrollment/model/course_context.dart';
import 'package:telangana_prep/features/course_enrollment/model/user_course.dart';
import 'package:telangana_prep/features/course_enrollment/service/course_enrollment_service.dart';
import 'package:telangana_prep/features/course_enrollment/service/course_loader_service.dart';
import 'package:telangana_prep/features/subscription/model/course_access_decision.dart';
import 'package:telangana_prep/features/subscription/service/subscription_access_service.dart';

void main() {
  group('CourseEnrollmentService lockdown', () {
    late CourseEnrollmentService service;

    setUp(() {
      service = CourseEnrollmentService();
    });

    test('activateEnrollment cannot grant paid entitlement', () async {
      await expectLater(
        service.activateEnrollment(
          uid: 'student-1',
          courseId: 'group-iii',
          source: 'purchase',
          expiresAt: DateTime(2099, 1, 1),
        ),
        throwsA(isA<EntitlementMutationForbidden>()),
      );
    });

    test('createEnrollment cannot manufacture active paid access', () async {
      await expectLater(
        service.createEnrollment(
          UserCourse(
            uid: 'student-1',
            courseId: 'group-iii',
            enrolledAt: null,
            status: UserCourseStatus.active,
            source: UserCourseSource.purchase,
            expiresAt: null,
          ),
        ),
        throwsA(isA<EntitlementMutationForbidden>()),
      );
    });

    test('updateEnrollment cannot flip inactive → active', () async {
      await expectLater(
        service.updateEnrollment(
          UserCourse(
            uid: 'student-1',
            courseId: 'group-iii',
            enrolledAt: DateTime(2026, 1, 1),
            status: UserCourseStatus.active,
            source: UserCourseSource.purchase,
            expiresAt: DateTime(2099, 1, 1),
          ),
        ),
        throwsA(isA<EntitlementMutationForbidden>()),
      );
    });

    test('updateEnrollment cannot extend or clear expiry', () async {
      await expectLater(
        service.updateEnrollment(
          UserCourse(
            uid: 'student-1',
            courseId: 'group-iii',
            enrolledAt: DateTime(2026, 1, 1),
            status: UserCourseStatus.active,
            source: UserCourseSource.purchase,
            expiresAt: null,
          ),
        ),
        throwsA(isA<EntitlementMutationForbidden>()),
      );
    });

    test('updateEnrollment cannot change source to purchase', () async {
      await expectLater(
        service.updateEnrollment(
          UserCourse(
            uid: 'student-1',
            courseId: 'group-iii',
            enrolledAt: DateTime(2026, 1, 1),
            status: UserCourseStatus.active,
            source: UserCourseSource.purchase,
            expiresAt: DateTime(2026, 12, 31),
          ),
        ),
        throwsA(isA<EntitlementMutationForbidden>()),
      );
    });
  });

  group('Home debug activation seam', () {
    test('debug enrollment activation path is blocked by service lockdown',
        () async {
      // Former HomeScreen TEMP controls called activateEnrollment against
      // production Firestore. Those UI controls are removed; the service also
      // refuses mutation so a reintroduced debug button cannot grant access.
      final service = CourseEnrollmentService();
      await expectLater(
        service.activateEnrollment(
          uid: 'student-1',
          courseId: 'group-ii',
          source: 'debug',
        ),
        throwsA(isA<EntitlementMutationForbidden>()),
      );
    });
  });

  group('Free-course access preserved without client enrollment writes', () {
    test('free course remains accessible via catalog isFree', () async {
      final loader = CourseLoaderService();
      final access = SubscriptionAccessService(courseLoader: loader);
      addTearDown(loader.clear);

      loader.debugSetCurrent(
        CourseContext(
          publishedCourses: [
            Course(
              courseId: 'free-course',
              title: 'Free',
              shortTitle: 'Free',
              description: '',
              thumbnail: null,
              icon: null,
              color: null,
              isFree: true,
              isPublished: true,
              price: 0,
              sortOrder: 0,
              createdAt: null,
              updatedAt: null,
            ),
          ],
          enrollments: const [],
        ),
      );

      final decision = await access.evaluateCourseAccess('free-course');
      expect(decision.allowed, isTrue);
      expect(decision.reason, CourseAccessReason.freeCourse);
    });

    test('paid course without enrollment remains denied', () async {
      final loader = CourseLoaderService();
      final access = SubscriptionAccessService(courseLoader: loader);
      addTearDown(loader.clear);

      loader.debugSetCurrent(
        CourseContext(
          publishedCourses: [
            Course(
              courseId: 'group-iii',
              title: 'Group-III',
              shortTitle: 'G3',
              description: '',
              thumbnail: null,
              icon: null,
              color: null,
              isFree: false,
              isPublished: true,
              price: 299,
              sortOrder: 0,
              createdAt: null,
              updatedAt: null,
            ),
          ],
          enrollments: const [],
        ),
      );

      final decision = await access.evaluateCourseAccess('group-iii');
      expect(decision.allowed, isFalse);
      expect(decision.reason, CourseAccessReason.denied);
    });
  });
}
