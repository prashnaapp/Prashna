import 'package:flutter/material.dart';

import '../../models/profile_model.dart';
import 'profile_section.dart';
import 'settings_tile.dart';

/// Preferences section. The caller decides which preferences to surface; the
/// Profile tab shows Theme and Notifications only.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.preferences,
    required this.onPreferenceTap,
  });

  final List<ProfilePreference> preferences;
  final void Function(ProfilePreference preference) onPreferenceTap;

  @override
  Widget build(BuildContext context) {
    if (preferences.isEmpty) return const SizedBox.shrink();

    return ProfileSection(
      title: 'Preferences',
      children: [
        for (final preference in preferences)
          SettingsTile(
            title: preference.title,
            subtitle: preference.subtitle,
            icon: _iconFor(preference.id),
            onTap: () => onPreferenceTap(preference),
          ),
      ],
    );
  }

  IconData _iconFor(String id) {
    return switch (id) {
      'theme' => Icons.palette_rounded,
      'notifications' => Icons.notifications_rounded,
      _ => Icons.settings_rounded,
    };
  }
}
