import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/profile_model.dart';
import 'settings_tile.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onManage,
  });

  final SubscriptionInfo subscription;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Subscription', style: AppTextStyles.titleLarge(context)),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subscription.planName,
                      style: AppTextStyles.titleMedium(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: subscription.isActive
                          ? AppColors.successSurface
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      subscription.isActive ? 'Active' : 'Inactive',
                      style: AppTextStyles.label(context).copyWith(
                        color: subscription.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subscription.expiryDateLabel,
                style: AppTextStyles.bodyMedium(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsTile(
          title: 'Manage Subscription',
          subtitle: 'Billing, renewals & invoices',
          leading: const Icon(
            Icons.workspace_premium_outlined,
            color: AppColors.primary,
          ),
          onTap: onManage,
        ),
      ],
    );
  }
}
