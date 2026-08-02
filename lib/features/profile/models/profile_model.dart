/// Account & settings models for the Profile feature (Firebase-ready).
class ProfileModel {
  const ProfileModel({
    required this.name,
    required this.email,
    required this.avatarInitials,
    required this.isPremium,
    this.avatarImageUrl,
  });

  final String name;
  final String email;
  final String avatarInitials;
  final bool isPremium;
  final String? avatarImageUrl;
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.planName,
    required this.expiryDateLabel,
    required this.isActive,
  });

  final String planName;
  final String expiryDateLabel;
  final bool isActive;
}

class ProfilePreference {
  const ProfilePreference({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

class ProfileAppInfo {
  const ProfileAppInfo({
    required this.appName,
    required this.versionLabel,
  });

  final String appName;
  final String versionLabel;
}
