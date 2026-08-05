import '../model/payment_plan.dart';
import '../model/payment_transaction.dart';
import '../repository/payment_repository.dart';

/// App-facing API for payment plans and transactions.
///
/// Thin wrapper around [PaymentRepository] — same layering as
/// ProgressCloudService / BookmarkCloudService / RevisionCloudService.
///
/// Phase A: infrastructure only. No Razorpay, Play Billing, enrollment,
/// subscription gates, or UI.
class PaymentService {
  PaymentService({
    PaymentRepository? repository,
  }) : _repository = repository ?? PaymentRepository();

  static final PaymentService instance = PaymentService();

  final PaymentRepository _repository;

  Future<List<PaymentPlan>> loadActivePlans() =>
      _repository.loadActivePlans();

  Future<void> createTransaction(PaymentTransaction transaction) =>
      _repository.createTransaction(transaction);

  Future<PaymentTransaction?> loadTransaction(String transactionId) =>
      _repository.loadTransaction(transactionId);
}
