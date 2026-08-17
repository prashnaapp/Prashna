import 'package:flutter/material.dart';

import '../../../../navigation/tab_scroll_view.dart';
import '../../../authentication/screens/login_screen.dart';
import '../../../authentication/services/auth_service.dart';
import '../../../syllabus/presentation/widgets/landing_sheet.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';
import '../profile_navigation.dart';
import '../profile_visual.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_hero.dart';
import '../widgets/profile_section.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/subscription_card.dart';
import '../widgets/support_section.dart';

/// Account & Settings tab — purple hero waving into a scrolling content sheet,
/// matching the Chapters, Test Series, and Progress landings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Preferences surfaced on this tab. The service keeps its full list for
  /// other callers; the Profile UI shows only these two.
  static const _visiblePreferences = {'theme', 'notifications'};

  @override
  Widget build(BuildContext context) {
    final service = ProfileService.instance;
    final profile = service.getProfile();
    final subscription = service.getSubscription();
    final preferences = service
        .getPreferences()
        .where((item) => _visiblePreferences.contains(item.id))
        .toList();

    return Scaffold(
      backgroundColor: ProfileVisual.page,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight = (constraints.maxHeight * 0.22).clamp(192.0, 224.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: ProfileHero(height: heroHeight),
              ),
              Positioned(
                top: heroHeight - LandingSheet.heroOverlap,
                left: 0,
                right: 0,
                bottom: 0,
                child: LandingSheet(
                  expand: true,
                  padding: EdgeInsets.zero,
                  child: _ProfileBody(
                    profile: profile,
                    subscription: subscription,
                    preferences: preferences,
                    onEditProfile: () => _soon(context, 'Edit Profile'),
                    onManageSubscription: () =>
                        _soon(context, 'Manage Subscription'),
                    onPreference: (title) => _soon(context, title),
                    onContactUs: () => _soon(context, 'Contact Us'),
                    onShareApp: () => _soon(context, 'Share App'),
                    onLogout: () => _onLogout(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _soon(BuildContext context, String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title — coming soon')));
  }

  Future<void> _onLogout(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.subscription,
    required this.preferences,
    required this.onEditProfile,
    required this.onManageSubscription,
    required this.onPreference,
    required this.onContactUs,
    required this.onShareApp,
    required this.onLogout,
  });

  final ProfileModel profile;
  final SubscriptionInfo subscription;
  final List<ProfilePreference> preferences;
  final VoidCallback onEditProfile;
  final VoidCallback onManageSubscription;
  final ValueChanged<String> onPreference;
  final VoidCallback onContactUs;
  final VoidCallback onShareApp;
  final VoidCallback onLogout;

  /// Breathing room between sections.
  static const double _sectionGap = 20;

  @override
  Widget build(BuildContext context) {
    return TabScrollView(
      // TabScrollView adds the bottom-navigation inset, so Logout always
      // clears the floating bar.
      padding: const EdgeInsets.fromLTRB(
        ProfileVisual.pagePadding,
        LandingSheet.topPad,
        ProfileVisual.pagePadding,
        0,
      ),
      children: [
        ProfileHeaderCard(profile: profile, onEditProfile: onEditProfile),
        const SizedBox(height: _sectionGap),
        SubscriptionCard(
          subscription: subscription,
          onManage: onManageSubscription,
        ),
        const SizedBox(height: _sectionGap),
        ProfileSection(
          title: 'Activity',
          children: [
            SettingsTile(
              key: const ValueKey('test-history-tile'),
              title: 'Test History',
              subtitle: 'View your completed test attempts',
              icon: Icons.bar_chart_rounded,
              onTap: () => openTestHistory(context),
            ),
          ],
        ),
        const SizedBox(height: _sectionGap),
        SettingsSection(
          preferences: preferences,
          onPreferenceTap: (pref) => onPreference(pref.title),
        ),
        const SizedBox(height: _sectionGap),
        SupportSection(onContactUs: onContactUs, onShareApp: onShareApp),
        const SizedBox(height: 22),
        LogoutButton(onLogout: onLogout),
      ],
    );
  }
}
