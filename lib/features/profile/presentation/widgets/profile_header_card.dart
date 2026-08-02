import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/profile_model.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.profile,
    required this.onEditProfile,
  });

  final ProfileModel profile;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: profile.avatarImageUrl == null
                    ? null
                    : NetworkImage(profile.avatarImageUrl!),
                child: profile.avatarImageUrl == null
                    ? Text(
                        profile.avatarInitials,
                        style: AppTextStyles.titleLarge(context).copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.name,
                      style: AppTextStyles.titleLarge(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      profile.email,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    if (profile.isPremium) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.premiumGoldSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.premiumGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Premium',
                          style: AppTextStyles.label(context).copyWith(
                            color: AppColors.premiumGoldDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSecondaryButton(
            label: 'Edit Profile',
            onPressed: onEditProfile,
          ),
        ],
      ),
    );
  }
}
