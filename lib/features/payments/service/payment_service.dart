import '../model/payment_plan.dart';
import '../model/payment_transaction.dart';
import '../payments_unavailable_exception.dart';
import '../repository/payment_repository.dart';

/// App-facing API for payment plans and transactions.
///
/// Plan catalog reads remain available for the subscription paywall UI.
/// Client purchase / transaction creation is disabled until a trusted
/// payment provider and backend grant entitlements server-side.
class PaymentService {
  PaymentService({
    PaymentRepository? repository,
  }) : _repositoryOverride = repository;

  static final PaymentService instance = PaymentService();

  final PaymentRepository? _repositoryOverride;
  PaymentRepository? _repositoryCache;

  PaymentRepository get _repository =>
      _repositoryOverride ?? (_repositoryCache ??= PaymentRepository());

  Future<List<PaymentPlan>> loadActivePlans() =>
      _repository.loadActivePlans();

  /// Client transaction creation is disabled (lockdown).
  Future<void> createTransaction(PaymentTransaction transaction) async {
    throw const PaymentsUnavailableException(
      'Client payment transaction writes are disabled. '
      'Trusted payment records must be created by a backend.',
    );
  }

  /// Client purchase / entitlement grant is disabled (lockdown).
  ///
  /// Does not create transactions, does not activate enrollment, and does
  /// not report payment success.
  Future<void> purchaseCourse({
    required String uid,
    required String courseId,
    required PaymentPlan plan,
  }) async {
    throw const PaymentsUnavailableException();
  }
}
