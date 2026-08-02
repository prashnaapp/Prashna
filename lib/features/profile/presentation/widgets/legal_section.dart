import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/profile_model.dart';
import 'settings_tile.dart';

class LegalSection extends StatelessWidget {
  const LegalSection({
    super.key,
    required this.appInfo,
    required this.onPrivacyPolicy,
    required this.onTerms,
    required this.onAbout,
  });

  final ProfileAppInfo appInfo;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTerms;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Legal', style: AppTextStyles.titleLarge(context)),
        const SizedBox(height: AppSpacing.lg),
        SettingsTile(
          title: 'Privacy Policy',
          leading: const Icon(
            Icons.privacy_tip_outlined,
            color: AppColors.primary,
          ),
          onTap: onPrivacyPolicy,
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsTile(
          title: 'Terms & Conditions',
          leading: const Icon(
            Icons.description_outlined,
            color: AppColors.primary,
          ),
          onTap: onTerms,
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsTile(
          title: 'About ${appInfo.appName}',
          subtitle: appInfo.versionLabel,
          leading: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
          ),
          onTap: onAbout,
        ),
      ],
    );
  }
}
