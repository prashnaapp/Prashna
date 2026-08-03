import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore user profile document (`users/{uid}`).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.role,
    required this.subscription,
    required this.currentCourse,
    required this.isActive,
    required this.createdAt,
    required this.lastLogin,
    required this.lastAppVersion,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String role;
  final UserSubscription subscription;
  final String? currentCourse;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final String? lastAppVersion;

  factory UserProfile.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final subscriptionRaw = data['subscription'];
    return UserProfile(
      uid: (data['uid'] as String?) ?? uid,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: (data['role'] as String?) ?? 'student',
      subscription: subscriptionRaw is Map
          ? UserSubscription.fromMap(
              Map<String, dynamic>.from(subscriptionRaw),
            )
          : const UserSubscription.freeActive(),
      currentCourse: data['currentCourse'] as String?,
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: _readTimestamp(data['createdAt']),
      lastLogin: _readTimestamp(data['lastLogin']),
      lastAppVersion: data['lastAppVersion'] as String?,
    );
  }

  /// Payload for first-time profile creation only.
  Map<String, dynamic> toCreateMap({
    required String appVersion,
  }) {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'subscription': subscription.toMap(),
      'currentCourse': currentCourse,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'lastAppVersion': appVersion,
    };
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class UserSubscription {
  const UserSubscription({
    required this.plan,
    required this.status,
    this.expiryDate,
  });

  const UserSubscription.freeActive()
      : plan = 'free',
        status = 'active',
        expiryDate = null;

  final String plan;
  final String status;
  final DateTime? expiryDate;

  factory UserSubscription.fromMap(Map<String, dynamic> data) {
    return UserSubscription(
      plan: (data['plan'] as String?) ?? 'free',
      status: (data['status'] as String?) ?? 'active',
      expiryDate: data['expiryDate'] is Timestamp
          ? (data['expiryDate'] as Timestamp).toDate()
          : data['expiryDate'] as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan,
      'status': status,
      'expiryDate': expiryDate,
    };
  }
}
