import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore payment plan document (`payment_plans/{planId}`).
class PaymentPlan {
  const PaymentPlan({
    required this.planId,
    required this.courseId,
    required this.title,
    required this.description,
    required this.amount,
    required this.currency,
    required this.durationDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String planId;
  final String courseId;
  final String title;
  final String description;
  final num amount;
  final String currency;
  final int durationDays;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PaymentPlan.fromFirestore(
    String planId,
    Map<String, dynamic> data,
  ) {
    return PaymentPlan(
      planId: (data['planId'] as String?) ?? planId,
      courseId: (data['courseId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      amount: (data['amount'] as num?) ?? 0,
      currency: (data['currency'] as String?) ?? 'INR',
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 0,
      isActive: (data['isActive'] as bool?) ?? false,
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'courseId': courseId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'durationDays': durationDays,
      'isActive': isActive,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
