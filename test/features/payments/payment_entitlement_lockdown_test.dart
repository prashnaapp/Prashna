import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/payments/model/payment_plan.dart';
import 'package:telangana_prep/features/payments/model/payment_transaction.dart';
import 'package:telangana_prep/features/payments/payments_unavailable_exception.dart';
import 'package:telangana_prep/features/payments/service/payment_service.dart';
import 'package:telangana_prep/features/subscription/presentation/screens/course_subscription_screen.dart';

void main() {
  PaymentPlan plan() {
    return PaymentPlan(
      planId: 'plan-90',
      courseId: 'group-iii',
      title: '90 Days',
      description: 'Quarterly',
      amount: 299,
      currency: 'INR',
      durationDays: 90,
      isActive: true,
      createdAt: null,
      updatedAt: null,
    );
  }

  group('PaymentService lockdown', () {
    test('purchaseCourse does not grant entitlement', () async {
      final service = PaymentService();

      await expectLater(
        service.purchaseCourse(
          uid: 'student-1',
          courseId: 'group-iii',
          plan: plan(),
        ),
        throwsA(isA<PaymentsUnavailableException>()),
      );
    });

    test('createTransaction cannot create successful payment state', () async {
      final service = PaymentService();
      final transaction = PaymentTransaction(
        transactionId: 'txn_spoof',
        uid: 'student-1',
        courseId: 'group-iii',
        planId: 'plan-90',
        amount: 299,
        currency: 'INR',
        paymentProvider: 'debug',
        providerTransactionId: 'txn_spoof',
        status: PaymentTransactionStatus.success,
        purchasedAt: DateTime(2026, 8, 9),
        expiresAt: DateTime(2026, 11, 9),
        metadata: const {},
      );

      await expectLater(
        service.createTransaction(transaction),
        throwsA(isA<PaymentsUnavailableException>()),
      );
    });
  });

  group('CourseSubscriptionScreen lockdown', () {
    testWidgets('does not expose a working purchase CTA', (tester) async {
      final payments = _StubPaymentService(plans: [plan()]);

      await tester.pumpWidget(
        MaterialApp(
          home: CourseSubscriptionScreen(
            courseId: 'group-iii',
            paymentService: payments,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payments coming soon'), findsWidgets);
      expect(find.text('Continue · ₹299'), findsNothing);

      final button = tester.widget<FilledButton>(
        find.byType(FilledButton).first,
      );
      expect(button.onPressed, isNull);
      expect(payments.purchaseCalls, 0);
      expect(payments.createTransactionCalls, 0);
    });
  });
}

class _StubPaymentService extends PaymentService {
  _StubPaymentService({required this.plans});

  final List<PaymentPlan> plans;
  int purchaseCalls = 0;
  int createTransactionCalls = 0;

  @override
  Future<List<PaymentPlan>> loadActivePlans() async => plans;

  @override
  Future<void> purchaseCourse({
    required String uid,
    required String courseId,
    required PaymentPlan plan,
  }) async {
    purchaseCalls++;
    throw const PaymentsUnavailableException();
  }

  @override
  Future<void> createTransaction(PaymentTransaction transaction) async {
    createTransactionCalls++;
    throw const PaymentsUnavailableException();
  }
}
