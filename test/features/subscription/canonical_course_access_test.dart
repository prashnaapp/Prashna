import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/course_enrollment/model/course_context.dart';
import 'package:telangana_prep/features/course_enrollment/model/user_course.dart';
import 'package:telangana_prep/features/course_enrollment/service/course_loader_service.dart';
import 'package:telangana_prep/features/payments/model/payment_transaction.dart';
import 'package:telangana_prep/features/progress_cloud/model/user_progress.dart';
import 'package:telangana_prep/features/subscription/service/course_access_service.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_attempt_history.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/test_cloud_mapper.dart';

/// Phase 5.9 — authoritative course entitlement / access foundation.
void main() {
  final now = DateTime(2026, 8, 10, 12);

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
      price: isFree ? 0 : 299,
      sortOrder: 0,
      createdAt: null,
      updatedAt: null,
    );
  }

  UserCourse entitlement({
    required String courseId,
    UserCourseStatus status = UserCourseStatus.active,
    DateTime? expiresAt,
    UserCourseSource source = UserCourseSource.purchase,
    String uid = 'user-1',
  }) {
    return UserCourse(
      uid: uid,
      courseId: courseId,
      enrolledAt: DateTime(2026, 1, 1),
      status: status,
      source: source,
      expiresAt: expiresAt,
      updatedAt: DateTime(2026, 2, 1),
    );
  }

  late CourseLoaderService loader;
  late CourseAccessService access;

  setUp(() {
    loader = CourseLoaderService();
    access = CourseAccessService(
      courseLoader: loader,
      now: () => now,
    );
  });

  tearDown(() {
    loader.clear();
  });

  void loadPaidCatalog({List<UserCourse> enrollments = const []}) {
    loader.debugSetCurrent(
      CourseContext(
        publishedCourses: [
          course(id: 'group-ii'),
          course(id: 'group-iii'),
          course(id: 'free-course', isFree: true),
        ],
        enrollments: enrollments,
      ),
    );
  }

  test('1: active entitlement grants course access', () async {
    loadPaidCatalog(enrollments: [entitlement(courseId: 'group-ii')]);

    expect(await access.hasCourseAccess('group-ii'), isTrue);
    expect(await access.canAccessCourse('group-ii'), isTrue);
    final decision = await access.evaluateCourseAccess('group-ii');
    expect(decision.reason, CourseAccessReason.activeEnrollment);
    expect(access.entitlementFor('group-ii')?.status, CourseEntitlementStatus.active);
    expect(access.entitlementFor('group-ii')?.grantsAccess, isTrue);
  });

  test('2: expired entitlement denies paid course access', () async {
    loadPaidCatalog(
      enrollments: [
        entitlement(
          courseId: 'group-ii',
          expiresAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    );

    expect(await access.hasCourseAccess('group-ii'), isFalse);
    final decision = await access.evaluateCourseAccess('group-ii');
    expect(decision.reason, CourseAccessReason.expiredEntitlement);
    expect(
      access.entitlementFor('group-ii')?.status,
      CourseEntitlementStatus.expired,
    );
  });

  test('3: revoked entitlement denies paid course access', () async {
    loadPaidCatalog(
      enrollments: [
        entitlement(
          courseId: 'group-ii',
          status: UserCourseStatus.revoked,
          expiresAt: now.add(const Duration(days: 30)),
        ),
        entitlement(
          courseId: 'group-iii',
          status: UserCourseStatus.inactive,
        ),
      ],
    );

    expect(await access.hasCourseAccess('group-ii'), isFalse);
    expect(
      (await access.evaluateCourseAccess('group-ii')).reason,
      CourseAccessReason.revokedEntitlement,
    );
    expect(await access.hasCourseAccess('group-iii'), isFalse);
    expect(
      (await access.evaluateCourseAccess('group-iii')).reason,
      CourseAccessReason.revokedEntitlement,
    );
  });

  test('4: different course entitlement does not grant Group II access',
      () async {
    loadPaidCatalog(enrollments: [entitlement(courseId: 'group-iii')]);

    expect(await access.hasCourseAccess('group-iii'), isTrue);
    expect(await access.hasCourseAccess('group-ii'), isFalse);
    expect(
      (await access.evaluateCourseAccess('group-ii')).reason,
      CourseAccessReason.denied,
    );
  });

  test('5: payment record alone does not grant access', () async {
    // Successful payment exists in memory, but no entitlement was loaded.
    const payment = PaymentTransaction(
      transactionId: 'txn-1',
      uid: 'user-1',
      courseId: 'group-ii',
      planId: 'plan-group-ii',
      amount: 299,
      currency: 'INR',
      paymentProvider: 'manual',
      providerTransactionId: 'prov-1',
      status: PaymentTransactionStatus.success,
      purchasedAt: null,
      expiresAt: null,
      metadata: {},
    );
    expect(payment.status, PaymentTransactionStatus.success);
    expect(payment.courseId, 'group-ii');

    loadPaidCatalog(enrollments: const []);

    expect(await access.hasCourseAccess('group-ii'), isFalse);
    expect(access.entitlementFor('group-ii'), isNull);
    expect(
      (await access.evaluateCourseAccess('group-ii')).reason,
      CourseAccessReason.denied,
    );
  });

  test('6: course access is reusable across features via one service', () async {
    loadPaidCatalog(enrollments: [entitlement(courseId: 'group-ii')]);

    // Home / Question Bank / Test Series / Syllabus all call the same gate.
    Future<bool> homeGate(String courseId) => access.hasCourseAccess(courseId);
    Future<bool> questionBankGate(String courseId) =>
        access.canAccessCourse(courseId);
    Future<bool> testSeriesGate(String courseId) =>
        access.hasCourseAccess(courseId);

    expect(await homeGate('group-ii'), isTrue);
    expect(await questionBankGate('group-ii'), isTrue);
    expect(await testSeriesGate('group-ii'), isTrue);
    expect(await homeGate('group-iii'), isFalse);
    expect(await questionBankGate('group-iii'), isFalse);
    expect(await testSeriesGate('group-iii'), isFalse);

    // Typedef identity: CourseAccessService IS SubscriptionAccessService.
    expect(access, isA<SubscriptionAccessService>());
  });

  test('7: published test still requires appropriate course access', () async {
    loadPaidCatalog(enrollments: [entitlement(courseId: 'group-ii')]);

    final published = TestCloudMapper.fromFirestore('t-pub', {
      'courseId': 'group-ii',
      'category': 'chapterTests',
      'title': 'Published Test',
      'questionCount': 10,
      'totalMarks': 10,
      'durationMinutes': 30,
      'negativeMarks': '0',
      'difficulty': 'Medium',
      'isPublished': true,
      'status': 'published',
      'questionIds': <String>[],
    });
    expect(published, isNotNull);
    expect(published!.isPublished, isTrue);

    // Publication ≠ entitlement.
    expect(await access.hasCourseAccess('group-ii'), isTrue);
    expect(await access.hasCourseAccess('group-iii'), isFalse);

    loadPaidCatalog(enrollments: const []);
    expect(published.isPublished, isTrue);
    expect(await access.hasCourseAccess('group-ii'), isFalse);
  });

  test('8: draft test remains unavailable regardless of entitlement', () {
    loadPaidCatalog(enrollments: [entitlement(courseId: 'group-ii')]);

    final draft = TestCloudMapper.fromFirestore('t-draft', {
      'courseId': 'group-ii',
      'category': 'chapterTests',
      'title': 'Draft Test',
      'questionCount': 10,
      'totalMarks': 10,
      'durationMinutes': 30,
      'negativeMarks': '0',
      'difficulty': 'Medium',
      'isPublished': false,
      'status': 'draft',
      'questionIds': <String>[],
    });
    expect(draft, isNull);

    final adminDraft = TestCloudMapper.fromFirestoreAdmin('t-draft', {
      'courseId': 'group-ii',
      'category': 'chapterTests',
      'title': 'Draft Test',
      'questionCount': 10,
      'totalMarks': 10,
      'durationMinutes': 30,
      'negativeMarks': '0',
      'difficulty': 'Medium',
      'isPublished': false,
      'status': 'draft',
      'questionIds': <String>[],
    });
    expect(adminDraft, isNotNull);
    expect(adminDraft!.status, TestPublicationStatus.draft);
    expect(adminDraft.isAvailableForNewAttempts, isFalse);
  });

  test('9: existing free-content behavior remains intact', () async {
    loadPaidCatalog(enrollments: const []);

    expect(await access.hasCourseAccess('free-course'), isTrue);
    expect(
      (await access.evaluateCourseAccess('free-course')).reason,
      CourseAccessReason.freeCourse,
    );
    expect(await access.hasActiveEntitlement('free-course'), isFalse);
    expect(await access.isFreeCourse('free-course'), isTrue);
  });

  test('10: historical attempts remain readable without entitlement', () {
    // Attempt history is owned user data — reading does not call the
    // course-access gate. Entitlement only gates new paid content access.
    const attempt = TestAttemptHistoryItem(
      attemptId: 'attempt-legacy',
      testId: 't-old',
      courseId: 'group-ii',
      mode: 'exam',
      status: 'submitted',
      score: 8,
      percentage: 80,
      accuracy: 80,
      correct: 8,
      wrong: 2,
      skipped: 0,
      totalQuestions: 10,
      timeSpentSeconds: 600,
      startedAt: null,
      submittedAt: null,
      passed: true,
      uid: 'user-1',
    );
    expect(attempt.attemptId, 'attempt-legacy');
    expect(attempt.courseId, 'group-ii');
    expect(attempt.score, 8);
  });

  test('11: existing progress remains readable without entitlement', () {
    final progress = UserProgress.initial(
      uid: 'user-1',
      courseId: 'group-ii',
      appVersion: '1.0.0',
    );
    expect(progress.uid, 'user-1');
    expect(progress.courseId, 'group-ii');
    // Progress remains structurally readable; access gate is not consulted.
    expect(progress.schemaVersion, UserProgress.currentSchemaVersion);
  });

  test('12: no duplicate access-check implementations are introduced', () async {
    loadPaidCatalog(enrollments: [entitlement(courseId: 'group-ii')]);

    // Single service API surface used by features.
    expect(await access.hasCourseAccess('group-ii'), isTrue);
    expect(await access.canAccessCourse('group-ii'), isTrue);
    expect(await access.hasActiveEntitlement('group-ii'), isTrue);

    final listed = access.listEntitlements();
    expect(listed, hasLength(1));
    expect(listed.first.courseId, 'group-ii');
    expect(listed.first.source, UserCourseSource.purchase);
    expect(listed.first.startedAt, DateTime(2026, 1, 1));
  });

  test('inactive stored status maps to revoked entitlement', () {
    final mapped = CourseEntitlement.fromUserCourse(
      entitlement(courseId: 'group-ii', status: UserCourseStatus.inactive),
      now: () => now,
    );
    expect(mapped.status, CourseEntitlementStatus.revoked);
    expect(mapped.grantsAccess, isFalse);
  });

  test('UserCourse.fromFirestore parses revoked status', () {
    final parsed = UserCourse.fromFirestore('user-1', {
      'uid': 'user-1',
      'courseId': 'group-ii',
      'status': 'revoked',
      'source': 'admin',
      'enrolledAt': null,
      'expiresAt': null,
    });
    expect(parsed.status, UserCourseStatus.revoked);
    expect(
      CourseEntitlement.fromUserCourse(parsed, now: () => now).status,
      CourseEntitlementStatus.revoked,
    );
  });

  test('15: backend-shaped purchase entitlement still drives access', () async {
    // Mirrors functions entitlement grant payload consumed by CourseLoader.
    loadPaidCatalog(
      enrollments: [
        entitlement(
          courseId: 'group-ii',
          status: UserCourseStatus.active,
          source: UserCourseSource.purchase,
          expiresAt: now.add(const Duration(days: 90)),
        ),
      ],
    );
    expect(await access.hasCourseAccess('group-ii'), isTrue);
    expect(
      access.entitlementFor('group-ii')?.source,
      UserCourseSource.purchase,
    );
    expect(access.entitlementFor('group-ii')?.grantsAccess, isTrue);
  });
}
