import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../authentication/models/auth_user.dart';
import '../model/user_profile.dart';
import '../repository/user_profile_repository.dart';

/// Creates / maintains Firestore user profiles after authentication.
///
/// Auth stays in [AuthService]; this service owns only profile documents.
class UserProfileService {
  UserProfileService({
    UserProfileRepository? repository,
  }) : _repository = repository ?? UserProfileRepository();

  static final UserProfileService instance = UserProfileService();

  final UserProfileRepository _repository;
  String? _cachedAppVersion;

  Future<UserProfile?> getProfile(String uid) => _repository.getByUid(uid);

  /// Call after a successful Google Sign-In.
  ///
  /// - Missing `users/{uid}` → create full profile
  /// - Existing document → update `lastLogin` + `lastAppVersion` only
  Future<void> ensureProfileAfterLogin(AuthUser user) async {
    final appVersion = await _resolveAppVersion();
    final profile = UserProfile(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoUrl,
      role: 'student',
      subscription: const UserSubscription.freeActive(),
      currentCourse: null,
      isActive: true,
      createdAt: null,
      lastLogin: null,
      lastAppVersion: appVersion,
    );

    await _repository.createOrTouchLogin(
      profile: profile,
      appVersion: appVersion,
    );
  }

  Future<String> _resolveAppVersion() async {
    if (_cachedAppVersion != null) return _cachedAppVersion!;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedAppVersion = info.version;
    } catch (error, stack) {
      debugPrint('PackageInfo failed: $error\n$stack');
      _cachedAppVersion = '1.0.0';
    }
    return _cachedAppVersion!;
  }
}
