import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle status for a [PaymentTransaction].
enum PaymentTransactionStatus {
  pending,
  success,
  failed,
  cancelled,
}

/// Firestore payment transaction document (`payment_transactions/{transactionId}`).
class PaymentTransaction {
  const PaymentTransaction({
    required this.transactionId,
    required this.uid,
    required this.courseId,
    required this.planId,
    required this.amount,
    required this.currency,
    required this.paymentProvider,
    required this.providerTransactionId,
    required this.status,
    required this.purchasedAt,
    required this.expiresAt,
    required this.metadata,
  });

  final String transactionId;
  final String uid;
  final String courseId;
  final String planId;
  final num amount;
  final String currency;
  final String paymentProvider;
  final String? providerTransactionId;
  final PaymentTransactionStatus status;
  final DateTime? purchasedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  factory PaymentTransaction.fromFirestore(
    String transactionId,
    Map<String, dynamic> data,
  ) {
    final metadataRaw = data['metadata'];
    return PaymentTransaction(
      transactionId: (data['transactionId'] as String?) ?? transactionId,
      uid: (data['uid'] as String?) ?? '',
      courseId: (data['courseId'] as String?) ?? '',
      planId: (data['planId'] as String?) ?? '',
      amount: (data['amount'] as num?) ?? 0,
      currency: (data['currency'] as String?) ?? 'INR',
      paymentProvider: (data['paymentProvider'] as String?) ?? '',
      providerTransactionId: data['providerTransactionId'] as String?,
      status: _parseStatus(data['status'] as String?),
      purchasedAt: _readTimestamp(data['purchasedAt']),
      expiresAt: _readTimestamp(data['expiresAt']),
      metadata: metadataRaw is Map
          ? Map<String, dynamic>.from(metadataRaw)
          : const <String, dynamic>{},
    );
  }

  /// Payload for [PaymentRepository.createTransaction].
  Map<String, dynamic> toCreateMap() {
    return {
      'transactionId': transactionId,
      'uid': uid,
      'courseId': courseId,
      'planId': planId,
      'amount': amount,
      'currency': currency,
      'paymentProvider': paymentProvider,
      'providerTransactionId': providerTransactionId,
      'status': status.name,
      'purchasedAt': purchasedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(purchasedAt!),
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'metadata': metadata,
    };
  }

  static PaymentTransactionStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'success':
        return PaymentTransactionStatus.success;
      case 'failed':
        return PaymentTransactionStatus.failed;
      case 'cancelled':
        return PaymentTransactionStatus.cancelled;
      case 'pending':
      default:
        return PaymentTransactionStatus.pending;
    }
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
