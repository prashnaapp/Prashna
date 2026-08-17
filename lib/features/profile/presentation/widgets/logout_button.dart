import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirm(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          'Logout',
          style: AppTextStyles.titleMedium(context).copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onLogout();
    }
  }
}
