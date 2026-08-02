import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import 'settings_tile.dart';

class SupportSection extends StatelessWidget {
  const SupportSection({
    super.key,
    required this.onHelpCenter,
    required this.onContactUs,
    required this.onReportBug,
    required this.onFaq,
    required this.onRateApp,
    required this.onShareApp,
  });

  final VoidCallback onHelpCenter;
  final VoidCallback onContactUs;
  final VoidCallback onReportBug;
  final VoidCallback onFaq;
  final VoidCallback onRateApp;
  final VoidCallback onShareApp;

  @override
  Widget build(BuildContext context) {
    final tiles = <({String title, IconData icon, VoidCallback onTap})>[
      (title: 'Help Center', icon: Icons.help_outline_rounded, onTap: onHelpCenter),
      (title: 'Contact Us', icon: Icons.mail_outline_rounded, onTap: onContactUs),
      (title: 'Report a Bug', icon: Icons.bug_report_outlined, onTap: onReportBug),
      (title: 'FAQ', icon: Icons.quiz_outlined, onTap: onFaq),
      (title: 'Rate App', icon: Icons.star_outline_rounded, onTap: onRateApp),
      (title: 'Share App', icon: Icons.share_outlined, onTap: onShareApp),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Support', style: AppTextStyles.titleLarge(context)),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          SettingsTile(
            title: tiles[i].title,
            leading: Icon(tiles[i].icon, color: AppColors.primary),
            onTap: tiles[i].onTap,
          ),
        ],
      ],
    );
  }
}
