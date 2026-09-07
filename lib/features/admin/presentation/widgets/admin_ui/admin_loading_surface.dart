import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';
import 'admin_surface.dart';

/// Lightweight loading surface for Admin lists (no heavy animation).
class AdminLoadingSurface extends StatelessWidget {
  const AdminLoadingSurface({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.pagePadding,
        AdminSpacing.sm,
        AdminSpacing.pagePadding,
        AdminSpacing.pagePadding,
      ),
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: AdminSpacing.md),
      itemBuilder: (context, index) {
        return AdminSurface(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Bar(width: 72, height: 22),
                  const Spacer(),
                  _Bar(width: 64, height: 22),
                ],
              ),
              const SizedBox(height: AdminSpacing.md),
              const _Bar(width: double.infinity, height: 14),
              const SizedBox(height: AdminSpacing.sm),
              const _Bar(width: 280, height: 14),
              const SizedBox(height: AdminSpacing.md),
              const _Bar(width: 200, height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      constraints: width == double.infinity
          ? const BoxConstraints(minWidth: double.infinity)
          : null,
      decoration: BoxDecoration(
        color: AdminColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
