import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class AuthBrandingHeader extends StatelessWidget {
  const AuthBrandingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.xlAll,
            boxShadow: AppShadows.soft,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/icon/app_icon.png',
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => const Icon(
              Icons.school_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'ప్రశ్న',
          style: AppTextStyles.display(context).copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'PRASHNA',
          style: AppTextStyles.titleLarge(context).copyWith(
            letterSpacing: 4,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Prepare • Practice • Succeed',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
