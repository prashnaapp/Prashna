import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/profile_model.dart';
import 'settings_tile.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Preferences', style: AppTextStyles.titleLarge(context)),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < preferences.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          SettingsTile(
            title: preferences[i].title,
            subtitle: preferences[i].subtitle,
            leading: Icon(
              _iconFor(preferences[i].id),
              color: AppColors.primary,
            ),
            onTap: () => onPreferenceTap(preferences[i]),
          ),
        ],
      ],
    );
  }

  IconData _iconFor(String id) {
    return switch (id) {
      'language' => Icons.language_rounded,
      'theme' => Icons.palette_outlined,
      'notifications' => Icons.notifications_outlined,
      'downloads' => Icons.download_outlined,
      _ => Icons.settings_outlined,
    };
  }
}
