import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/course_enrollment/model/course_context.dart';
import 'package:telangana_prep/features/course_enrollment/model/user_course.dart';
import 'package:telangana_prep/features/course_enrollment/service/course_loader_service.dart';
import 'package:telangana_prep/features/subscription/model/course_access_decision.dart';
import 'package:telangana_prep/features/subscription/service/subscription_access_service.dart';

void main() {
  Course course({
    required String id,
    bool isFree = false,
  }) {
    return Course(
      courseId: id,
      title: id,
      shortTitle: id,
      description: '',
      thumbnail: null,
      icon: null,
      color: null,
      isFree: isFree,
      isPublished: true,
      price: 0,
      sortOrder: 0,
      createdAt: null,
      updatedAt: null,
    );
  }

  UserCourse enrollment({
    required String courseId,
    UserCourseStatus status = UserCourseStatus.active,
    DateTime? expiresAt,
  }) {
    return UserCourse(
      uid: 'user-1',
      courseId: courseId,
      enrolledAt: DateTime(2026, 1, 1),
      status: status,
      source: UserCourseSource.purchase,
      expiresAt: expiresAt,
    );
  }

  group('CourseContext.enrollmentFor', () {
    test('returns matching enrollment without affecting others', () {
      final context = CourseContext(
        publishedCourses: [course(id: 'group-ii'), course(id: 'group-iii')],
        enrollments: [
          enrollment(courseId: 'group-ii'),
          enrollment(courseId: 'group-iii'),
        ],
      );

      expect(context.enrollmentFor('group-ii')?.courseId, 'group-ii');
      expect(context.enrollmentFor('group-iii')?.courseId, 'group-iii');
      expect(context.enrollmentFor('missing'), isNull);
      expect(context.enrollments, hasLength(2));
    });
  });

  group('SubscriptionAccessService multi-course', () {
    late CourseLoaderService loader;
    late SubscriptionAccessService access;
    final now = DateTime(2026, 8, 8);

    setUp(() {
      loader = CourseLoaderService();
      access = SubscriptionAccessService(
        courseLoader: loader,
        now: () => now,
      );
    });

    tearDown(() {
      loader.clear();
    });

    test('A/D/E: both Group-II and Group-III active open independently',
        () async {
      loader.debugSetCurrent(
        CourseContext(
          publishedCourses: [
            course(id: 'group-ii'),
            course(id: 'group-iii'),
          ],
          enrollments: [
            enrollment(courseId: 'group-ii'),
            enrollment(courseId: 'group-iii'),
          ],
        ),
      );

      expect(await access.canAccessCourse('group-ii'), isTrue);
      expect(await access.canAccessCourse('group-iii'), isTrue);

      final ii = await access.evaluateCourseAccess('group-ii');
      final iii = await access.evaluateCourseAccess('group-iii');
      expect(ii.reason, CourseAccessReason.activeEnrollment);
      expect(iii.reason, CourseAccessReason.activeEnrollment);
    });

    test('F: expired Group-II denied while active Group-III allowed', () async {
      loader.debugSetCurrent(
        CourseContext(
          publishedCourses: [
            course(id: 'group-ii'),
            course(id: 'group-iii'),
          ],
          enrollments: [
            enrollment(
              courseId: 'group-ii',
              expiresAt: now.subtract(const Duration(days: 1)),
            ),
            enrollment(
              courseId: 'group-iii',
              expiresAt: now.add(const Duration(days: 30)),
            ),
          ],
        ),
      );

      expect(await access.canAccessCourse('group-ii'), isFalse);
      expect(await access.canAccessCourse('group-iii'), isTrue);
      expect(
        (await access.evaluateCourseAccess('group-ii')).reason,
        CourseAccessReason.expiredEntitlement,
      );
    });

    test('G: free course accessible without enrollment', () async {
      loader.debugSetCurrent(
        CourseContext(
          publishedCourses: [course(id: 'free-course', isFree: true)],
          enrollments: const [],
        ),
      );

      final decision = await access.evaluateCourseAccess('free-course');
      expect(decision.allowed, isTrue);
      expect(decision.reason, CourseAccessReason.freeCourse);
    });

    test('B/C: access uses enrollmentFor — missing course denied', () async {
      loader.debugSetCurrent(
        CourseContext(
          publishedCourses: [
            course(id: 'group-ii'),
            course(id: 'group-iii'),
          ],
          enrollments: [enrollment(courseId: 'group-ii')],
        ),
      );

      expect(await access.canAccessCourse('group-ii'), isTrue);
      expect(await access.canAccessCourse('group-iii'), isFalse);
    });
  });
}
