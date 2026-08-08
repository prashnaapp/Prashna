import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/course_enrollment/model/course_context.dart';
import 'package:telangana_prep/features/course_enrollment/model/user_course.dart';
import 'package:telangana_prep/features/course_enrollment/service/course_loader_service.dart';
import 'package:telangana_prep/features/subscription/model/course_access_decision.dart';
import 'package:telangana_prep/features/subscription/service/subscription_access_service.dart';

/// Access rules for Test Series use the same courseId as enrollment
/// (`exam.examId` == `group-ii` / `group-iii`).
void main() {
  Course course({required String id, bool isFree = false}) {
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
      price: 299,
      sortOrder: 0,
      createdAt: null,
      updatedAt: null,
    );
  }

  UserCourse enrollment({required String courseId, DateTime? expiresAt}) {
    return UserCourse(
      uid: 'user-1',
      courseId: courseId,
      enrolledAt: DateTime(2026, 1, 1),
      status: UserCourseStatus.active,
      source: UserCourseSource.purchase,
      expiresAt: expiresAt,
    );
  }

  late CourseLoaderService loader;
  late SubscriptionAccessService access;

  setUp(() {
    loader = CourseLoaderService();
    access = SubscriptionAccessService(
      courseLoader: loader,
      now: () => DateTime(2026, 8, 8),
    );
  });

  tearDown(() {
    loader.clear();
  });

  test('1: Group-II active → Group-II Test Series allowed', () async {
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
  });

  test('2: Group-II active → Group-III Test Series denied', () async {
    loader.debugSetCurrent(
      CourseContext(
        publishedCourses: [
          course(id: 'group-ii'),
          course(id: 'group-iii'),
        ],
        enrollments: [enrollment(courseId: 'group-ii')],
      ),
    );

    final decision = await access.evaluateCourseAccess('group-iii');
    expect(decision.allowed, isFalse);
    expect(decision.reason, CourseAccessReason.denied);
    expect(decision.courseId, 'group-iii');
  });

  test('3: Group-III active → Group-III Test Series allowed', () async {
    loader.debugSetCurrent(
      CourseContext(
        publishedCourses: [
          course(id: 'group-ii'),
          course(id: 'group-iii'),
        ],
        enrollments: [enrollment(courseId: 'group-iii')],
      ),
    );

    expect(await access.canAccessCourse('group-iii'), isTrue);
  });

  test('4: Group-III active → Group-II Test Series denied', () async {
    loader.debugSetCurrent(
      CourseContext(
        publishedCourses: [
          course(id: 'group-ii'),
          course(id: 'group-iii'),
        ],
        enrollments: [enrollment(courseId: 'group-iii')],
      ),
    );

    final decision = await access.evaluateCourseAccess('group-ii');
    expect(decision.allowed, isFalse);
    expect(decision.reason, CourseAccessReason.denied);
    expect(decision.courseId, 'group-ii');
  });

  test('5: No enrollment → paid Test Series denied', () async {
    loader.debugSetCurrent(
      CourseContext(
        publishedCourses: [
          course(id: 'group-ii'),
          course(id: 'group-iii'),
        ],
        enrollments: const [],
      ),
    );

    expect(await access.canAccessCourse('group-ii'), isFalse);
    expect(await access.canAccessCourse('group-iii'), isFalse);
  });

  test(
    '8: courseId-scoped access matches dashboard Test Series entry',
    () async {
      loader.debugSetCurrent(
        CourseContext(
          publishedCourses: [
            course(id: 'group-ii'),
            course(id: 'group-iii'),
          ],
          enrollments: [enrollment(courseId: 'group-ii')],
        ),
      );

      // Dashboard passes widget.courseId into CourseOpenGuard — same check.
      expect(await access.canAccessCourse('group-ii'), isTrue);
      expect(await access.canAccessCourse('group-iii'), isFalse);
    },
  );
}
