import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';

class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(emphasized ? 20 : 16);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding ?? const EdgeInsets.all(AdminSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: emphasized
            ? AdminColors.surfaceElevated.withValues(alpha: 0.94)
            : AdminColors.surfaceElevated,
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: AdminColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: emphasized ? 28 : 18,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: emphasized
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.96),
                  AdminColors.primarySoft.withValues(alpha: 0.55),
                ],
              )
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        hoverColor: AdminColors.primarySoft.withValues(alpha: 0.35),
        child: content,
      ),
    );
  }
}
