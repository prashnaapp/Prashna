import 'package:flutter_test/flutter_test.dart';

/// Documents the intended Firestore security policy for entitlement lockdown.
///
/// This project does not yet ship Firebase Rules unit-testing / emulator
/// infrastructure. These expectations mirror `firestore.rules` and must be
/// verified against the emulator before production rules deploy.
///
/// EMULATOR VERIFICATION REQUIRED before treating rules as production-proven.
void main() {
  group('Entitlement rules policy (documented expectations)', () {
    test('students cannot create or update enrollment documents', () {
      expect(_policy.studentCanCreateEnrollment, isFalse);
      expect(_policy.studentCanUpdateEnrollment, isFalse);
      expect(_policy.studentCanDeleteEnrollment, isFalse);
      expect(_policy.studentCanReadOwnEnrollment, isTrue);
    });

    test('students cannot manufacture paid entitlement fields', () {
      expect(_policy.studentCanSetStatusActive, isFalse);
      expect(_policy.studentCanExtendExpiresAt, isFalse);
      expect(_policy.studentCanClearExpiresAt, isFalse);
      expect(_policy.studentCanSetSourcePurchase, isFalse);
      expect(_policy.studentCanSetSourceAdmin, isFalse);
      expect(_policy.studentCanChangeEnrollmentCourseId, isFalse);
    });

    test('students cannot create payment transactions (including success)', () {
      expect(_policy.studentCanCreatePaymentTransaction, isFalse);
      expect(_policy.studentCanCreateSuccessfulPaymentTransaction, isFalse);
      expect(_policy.studentCanUpdatePaymentTransaction, isFalse);
      expect(_policy.studentCanReadOwnPaymentTransaction, isTrue);
    });

    test('free-course access does not require client enrollment writes', () {
      expect(_policy.freeCourseAccessRequiresEnrollmentDoc, isFalse);
      expect(_policy.freeCourseAccessUsesAuthoritativeIsFree, isTrue);
    });

    test('admin question/test CRUD authority remains claim-based', () {
      expect(_policy.adminQuestionCrudRequiresAdminClaim, isTrue);
      expect(_policy.adminTestCrudRequiresAdminClaim, isTrue);
    });

    test('published course catalog remains client-immutable', () {
      expect(_policy.studentCanMutateCourses, isFalse);
      expect(_policy.studentCanReadCourses, isTrue);
    });
    test('payment transactions are not the access entitlement', () {
      expect(_policy.paymentTransactionGrantsCourseAccess, isFalse);
      expect(_policy.accessRequiresFreeOrActiveEnrollment, isTrue);
    });

    test('students cannot create or update authoritative test attempts', () {
      expect(_policy.studentCanCreateTestAttempt, isFalse);
      expect(_policy.studentCanUpdateTestAttempt, isFalse);
      expect(_policy.studentCanReadOwnTestAttempt, isTrue);
      expect(_policy.studentCanWriteTestAttemptEvents, isFalse);
    });

    test('students cannot forge authoritative progress or revision', () {
      expect(_policy.studentCanCreateCourseProgress, isFalse);
      expect(_policy.studentCanUpdateCourseProgress, isFalse);
      expect(_policy.studentCanReadOwnCourseProgress, isTrue);
      expect(_policy.studentCanWriteRevision, isFalse);
      expect(_policy.studentCanReadOwnRevision, isTrue);
    });
  });
}

const _policy = _EntitlementRulesPolicy(
  studentCanCreateEnrollment: false,
  studentCanUpdateEnrollment: false,
  studentCanDeleteEnrollment: false,
  studentCanReadOwnEnrollment: true,
  studentCanSetStatusActive: false,
  studentCanExtendExpiresAt: false,
  studentCanClearExpiresAt: false,
  studentCanSetSourcePurchase: false,
  studentCanSetSourceAdmin: false,
  studentCanChangeEnrollmentCourseId: false,
  studentCanCreatePaymentTransaction: false,
  studentCanCreateSuccessfulPaymentTransaction: false,
  studentCanUpdatePaymentTransaction: false,
  studentCanReadOwnPaymentTransaction: true,
  freeCourseAccessRequiresEnrollmentDoc: false,
  freeCourseAccessUsesAuthoritativeIsFree: true,
  adminQuestionCrudRequiresAdminClaim: true,
  adminTestCrudRequiresAdminClaim: true,
  studentCanMutateCourses: false,
  studentCanReadCourses: true,
  paymentTransactionGrantsCourseAccess: false,
  accessRequiresFreeOrActiveEnrollment: true,
  studentCanCreateTestAttempt: false,
  studentCanUpdateTestAttempt: false,
  studentCanReadOwnTestAttempt: true,
  studentCanWriteTestAttemptEvents: false,
  studentCanCreateCourseProgress: false,
  studentCanUpdateCourseProgress: false,
  studentCanReadOwnCourseProgress: true,
  studentCanWriteRevision: false,
  studentCanReadOwnRevision: true,
);

class _EntitlementRulesPolicy {
  const _EntitlementRulesPolicy({
    required this.studentCanCreateEnrollment,
    required this.studentCanUpdateEnrollment,
    required this.studentCanDeleteEnrollment,
    required this.studentCanReadOwnEnrollment,
    required this.studentCanSetStatusActive,
    required this.studentCanExtendExpiresAt,
    required this.studentCanClearExpiresAt,
    required this.studentCanSetSourcePurchase,
    required this.studentCanSetSourceAdmin,
    required this.studentCanChangeEnrollmentCourseId,
    required this.studentCanCreatePaymentTransaction,
    required this.studentCanCreateSuccessfulPaymentTransaction,
    required this.studentCanUpdatePaymentTransaction,
    required this.studentCanReadOwnPaymentTransaction,
    required this.freeCourseAccessRequiresEnrollmentDoc,
    required this.freeCourseAccessUsesAuthoritativeIsFree,
    required this.adminQuestionCrudRequiresAdminClaim,
    required this.adminTestCrudRequiresAdminClaim,
    required this.studentCanMutateCourses,
    required this.studentCanReadCourses,
    required this.paymentTransactionGrantsCourseAccess,
    required this.accessRequiresFreeOrActiveEnrollment,
    required this.studentCanCreateTestAttempt,
    required this.studentCanUpdateTestAttempt,
    required this.studentCanReadOwnTestAttempt,
    required this.studentCanWriteTestAttemptEvents,
    required this.studentCanCreateCourseProgress,
    required this.studentCanUpdateCourseProgress,
    required this.studentCanReadOwnCourseProgress,
    required this.studentCanWriteRevision,
    required this.studentCanReadOwnRevision,
  });

  final bool studentCanCreateEnrollment;
  final bool studentCanUpdateEnrollment;
  final bool studentCanDeleteEnrollment;
  final bool studentCanReadOwnEnrollment;
  final bool studentCanSetStatusActive;
  final bool studentCanExtendExpiresAt;
  final bool studentCanClearExpiresAt;
  final bool studentCanSetSourcePurchase;
  final bool studentCanSetSourceAdmin;
  final bool studentCanChangeEnrollmentCourseId;
  final bool studentCanCreatePaymentTransaction;
  final bool studentCanCreateSuccessfulPaymentTransaction;
  final bool studentCanUpdatePaymentTransaction;
  final bool studentCanReadOwnPaymentTransaction;
  final bool freeCourseAccessRequiresEnrollmentDoc;
  final bool freeCourseAccessUsesAuthoritativeIsFree;
  final bool adminQuestionCrudRequiresAdminClaim;
  final bool adminTestCrudRequiresAdminClaim;
  final bool studentCanMutateCourses;
  final bool studentCanReadCourses;
  final bool paymentTransactionGrantsCourseAccess;
  final bool accessRequiresFreeOrActiveEnrollment;
  final bool studentCanCreateTestAttempt;
  final bool studentCanUpdateTestAttempt;
  final bool studentCanReadOwnTestAttempt;
  final bool studentCanWriteTestAttemptEvents;
  final bool studentCanCreateCourseProgress;
  final bool studentCanUpdateCourseProgress;
  final bool studentCanReadOwnCourseProgress;
  final bool studentCanWriteRevision;
  final bool studentCanReadOwnRevision;
}
