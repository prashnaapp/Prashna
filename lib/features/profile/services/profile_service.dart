import '../models/profile_model.dart';
import '../../authentication/services/auth_service.dart';

/// Profile account data. Uses Firebase Auth user when signed in.
class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  ProfileModel getProfile() {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const ProfileModel(
        name: 'Guest',
        email: '',
        avatarInitials: 'G',
        isPremium: false,
      );
    }

    return ProfileModel(
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Prashna Student',
      email: user.email ?? '',
      avatarInitials: user.initials,
      avatarImageUrl: user.photoUrl,
      isPremium: false,
    );
  }

  SubscriptionInfo getSubscription() => const SubscriptionInfo(
        planName: 'Free Plan',
        expiryDateLabel: 'Upgrade for premium features',
        isActive: false,
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
