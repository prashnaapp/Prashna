import '../models/profile_model.dart';

/// Profile account data. Dummy today; swap for Firebase later.
class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  ProfileModel getProfile() => const ProfileModel(
        name: 'Renu Mohan',
        email: 'renu@prashna.app',
        avatarInitials: 'RM',
        isPremium: true,
      );

  SubscriptionInfo getSubscription() => const SubscriptionInfo(
        planName: 'Premium Annual',
        expiryDateLabel: 'Expires 12 Mar 2027',
        isActive: true,
      );

  List<ProfilePreference> getPreferences() => const [
        ProfilePreference(
          id: 'language',
          title: 'Language',
          subtitle: 'English',
        ),
        ProfilePreference(
          id: 'theme',
          title: 'Theme',
          subtitle: 'System default',
        ),
        ProfilePreference(
          id: 'notifications',
          title: 'Notifications',
          subtitle: 'Reminders & updates',
        ),
        ProfilePreference(
          id: 'downloads',
          title: 'Downloads',
          subtitle: 'Offline content',
        ),
      ];

  ProfileAppInfo getAppInfo() => const ProfileAppInfo(
        appName: 'Prashna',
        versionLabel: 'Version 1.0.0',
      );
}
