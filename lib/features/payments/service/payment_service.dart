import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../course_enrollment/service/course_enrollment_service.dart';
import '../model/payment_plan.dart';
import '../model/payment_transaction.dart';
import '../repository/payment_repository.dart';

/// App-facing API for payment plans and transactions.
///
/// Thin wrapper around [PaymentRepository] — same layering as
/// ProgressCloudService / BookmarkCloudService / RevisionCloudService.
///
/// Simulated purchases write a transaction then activate enrollment via
/// [CourseEnrollmentService] (which reloads CourseContext). No Razorpay,
/// Play Billing, or UI.
class PaymentService {
  PaymentService({
    PaymentRepository? repository,
    CourseEnrollmentService? enrollmentService,
  })  : _repository = repository ?? PaymentRepository(),
        _enrollment = enrollmentService ?? CourseEnrollmentService.instance;

  static final PaymentService instance = PaymentService();

  final PaymentRepository _repository;
  final CourseEnrollmentService _enrollment;

  Future<List<PaymentPlan>> loadActivePlans() =>
      _repository.loadActivePlans();

  Future<void> createTransaction(PaymentTransaction transaction) =>
      _repository.createTransaction(transaction);

  Future<PaymentTransaction?> loadTransaction(String transactionId) =>
      _repository.loadTransaction(transactionId);

  /// Simulated successful purchase pipeline (infrastructure only).
  ///
  /// 1. Creates `payment_transactions/{transactionId}`
  /// 2. Activates enrollment via [CourseEnrollmentService]
  /// 3. CourseContext reloads inside activateEnrollment
  Future<void> purchaseCourse({
    required String uid,
    required String courseId,
    required PaymentPlan plan,
  }) async {
    try {
      debugPrint('Purchase started');

      final now = DateTime.now();
      final transactionId =
          'txn_${now.microsecondsSinceEpoch}_${uid.hashCode.abs()}';
      final expiresAt = plan.durationDays == null
          ? null
          : now.add(Duration(days: plan.durationDays!));

      final transaction = PaymentTransaction(
        transactionId: transactionId,
        uid: uid,
        courseId: courseId,
        planId: plan.planId,
        amount: plan.amount,
        currency: plan.currency,
        paymentProvider: 'debug',
        providerTransactionId: transactionId,
        status: PaymentTransactionStatus.success,
        purchasedAt: now,
        expiresAt: expiresAt,
        metadata: const <String, dynamic>{},
      );

      await _repository.createTransaction(transaction);
      debugPrint('Transaction created');

      await _enrollment.activateEnrollment(
        uid: uid,
        courseId: courseId,
        source: 'purchase',
        expiresAt: expiresAt,
      );
      debugPrint('Enrollment activated');

      debugPrint('Purchase complete');
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in PaymentService.purchaseCourse: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('PaymentService.purchaseCourse failed: $error\n$stack');
      rethrow;
    }
  }
}
