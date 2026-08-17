import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/profile_model.dart';
import '../profile_visual.dart';
import 'profile_section.dart';
import 'settings_tile.dart';

/// Subscription section — current plan status plus the manage entry point.
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
    return ProfileSection(
      title: 'Subscription',
      children: [
        SettingsTile(
          title: subscription.planName,
          subtitle: subscription.expiryDateLabel,
          icon: Icons.workspace_premium_rounded,
          trailing: _PlanBadge(isActive: subscription.isActive),
        ),
        SettingsTile(
          title: 'Manage Subscription',
          subtitle: 'Billing, renewals & invoices',
          icon: Icons.card_membership_rounded,
          onTap: onManage,
        ),
      ],
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : ProfileVisual.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.12 : 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: AppTextStyles.caption(context).copyWith(
          color: isActive ? AppColors.success : ProfileVisual.accent,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
