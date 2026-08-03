import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/user_profile.dart';

/// Firestore boundary for the top-level `users` collection.
class UserProfileRepository {
  UserProfileRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'users';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(collectionName);

  DocumentReference<Map<String, dynamic>> docRef(String uid) =>
      _users.doc(uid);

  Future<bool> exists(String uid) async {
    final snapshot = await docRef(uid).get();
    return snapshot.exists;
  }

  Future<UserProfile?> getByUid(String uid) async {
    final snapshot = await docRef(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return UserProfile.fromFirestore(uid, snapshot.data()!);
  }

  /// Creates `users/{uid}` for a first-time sign-in.
  Future<void> createProfile({
    required UserProfile profile,
    required String appVersion,
  }) async {
    await docRef(profile.uid).set(profile.toCreateMap(appVersion: appVersion));
  }

  /// Updates login metadata only — never overwrites other profile fields.
  Future<void> touchLogin({
    required String uid,
    required String appVersion,
  }) async {
    await docRef(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
      'lastAppVersion': appVersion,
    });
  }

  /// Creates the profile if missing; otherwise updates login fields only.
  Future<void> createOrTouchLogin({
    required UserProfile profile,
    required String appVersion,
  }) async {
    try {
      final snapshot = await docRef(profile.uid).get();
      if (!snapshot.exists) {
        await createProfile(profile: profile, appVersion: appVersion);
        return;
      }
      await touchLogin(uid: profile.uid, appVersion: appVersion);
    } catch (error, stack) {
      debugPrint('UserProfileRepository.createOrTouchLogin: $error\n$stack');
      rethrow;
    }
  }
}
