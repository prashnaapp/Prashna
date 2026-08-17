import 'package:flutter/material.dart';

import 'profile_section.dart';
import 'settings_tile.dart';

/// Support section — Contact Us and Share App.
class SupportSection extends StatelessWidget {
  const SupportSection({
    super.key,
    required this.onContactUs,
    required this.onShareApp,
  });

  final VoidCallback onContactUs;
  final VoidCallback onShareApp;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Support',
      children: [
        SettingsTile(
          title: 'Contact Us',
          subtitle: "We're here to help you",
          icon: Icons.mail_rounded,
          onTap: onContactUs,
        ),
        SettingsTile(
          title: 'Share App',
          subtitle: 'Share Prashna with your friends',
          icon: Icons.share_rounded,
          onTap: onShareApp,
        ),
      ],
    );
  }
}
