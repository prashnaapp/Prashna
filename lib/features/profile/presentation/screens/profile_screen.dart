import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../services/profile_service.dart';
import '../widgets/legal_section.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/settings_section.dart';
import '../widgets/subscription_card.dart';
import '../widgets/support_section.dart';

/// Account & Settings tab — no Progress / Analytics / Achievements.
///
/// Scaffold → AppBar → SafeArea → AppResponsivePadding → TabScrollView
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ProfileService.instance;
    final profile = service.getProfile();
    final subscription = service.getSubscription();
    final preferences = service.getPreferences();
    final appInfo = service.getAppInfo();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: TabScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            children: [
              ProfileHeaderCard(
                profile: profile,
                onEditProfile: () => _soon(context, 'Edit Profile'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SubscriptionCard(
                subscription: subscription,
                onManage: () => _soon(context, 'Manage Subscription'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SettingsSection(
                preferences: preferences,
                onPreferenceTap: (pref) => _soon(context, pref.title),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SupportSection(
                onHelpCenter: () => _soon(context, 'Help Center'),
                onContactUs: () => _soon(context, 'Contact Us'),
                onReportBug: () => _soon(context, 'Report a Bug'),
                onFaq: () => _soon(context, 'FAQ'),
                onRateApp: () => _soon(context, 'Rate App'),
                onShareApp: () => _soon(context, 'Share App'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              LegalSection(
                appInfo: appInfo,
                onPrivacyPolicy: () => _soon(context, 'Privacy Policy'),
                onTerms: () => _soon(context, 'Terms & Conditions'),
                onAbout: () => _soon(context, 'About ${appInfo.appName}'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              LogoutButton(
                onLogout: () => _onLogout(context),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  void _soon(BuildContext context, String title) {
    // TODO: Wire real navigation / deep links.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title — coming soon')),
    );
  }

  void _onLogout(BuildContext context) {
    // TODO: Connect AuthService.signOut when auth is ready.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout — coming soon')),
    );
  }
}
