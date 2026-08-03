import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.surfaceVariant,
          elevation: 0,
          side: BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleGMark(),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Continue with Google',
                    style: AppTextStyles.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleGMark extends StatelessWidget {
  const _GoogleGMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'G',
        style: AppTextStyles.titleMedium(context).copyWith(
          color: const Color(0xFF4285F4),
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
