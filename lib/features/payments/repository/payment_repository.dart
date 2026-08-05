import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/payment_plan.dart';
import '../model/payment_transaction.dart';

/// Firestore boundary for `payment_plans` and `payment_transactions`.
///
/// Infrastructure only — no provider SDKs, enrollment, or UI wiring.
class PaymentRepository {
  PaymentRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String plansCollectionName = 'payment_plans';
  static const String transactionsCollectionName = 'payment_transactions';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _plans =>
      _firestore.collection(plansCollectionName);

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection(transactionsCollectionName);

  DocumentReference<Map<String, dynamic>> planDocRef(String planId) =>
      _plans.doc(planId);

  DocumentReference<Map<String, dynamic>> transactionDocRef(
    String transactionId,
  ) =>
      _transactions.doc(transactionId);

  /// Loads plans where `isActive == true`.
  Future<List<PaymentPlan>> loadActivePlans() async {
    try {
      final snapshot = await _plans.where('isActive', isEqualTo: true).get();
      return [
        for (final doc in snapshot.docs)
          PaymentPlan.fromFirestore(doc.id, doc.data()),
      ];
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in PaymentRepository.loadActivePlans: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('PaymentRepository.loadActivePlans: $error\n$stack');
      rethrow;
    }
  }

  /// Creates `payment_transactions/{transactionId}`.
  Future<void> createTransaction(PaymentTransaction transaction) async {
    try {
      await transactionDocRef(transaction.transactionId)
          .set(transaction.toCreateMap());
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in PaymentRepository.createTransaction: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('PaymentRepository.createTransaction: $error\n$stack');
      rethrow;
    }
  }

  Future<PaymentTransaction?> loadTransaction(String transactionId) async {
    try {
      final snapshot = await transactionDocRef(transactionId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return PaymentTransaction.fromFirestore(transactionId, snapshot.data()!);
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in PaymentRepository.loadTransaction: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint('PaymentRepository.loadTransaction: $error\n$stack');
      rethrow;
    }
  }
}
