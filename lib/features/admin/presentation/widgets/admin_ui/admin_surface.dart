import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';
import '../../../theme/admin_spacing.dart';

/// Controlled Admin surface family.
///
/// - [standard]: opaque workspace panels / list rows
/// - [emphasized]: stronger panels (auth, important sections)
/// - [glass]: Dashboard top-level destination cards only
enum AdminSurfaceVariant { standard, emphasized, glass }

class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.emphasized = false,
    this.variant,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// Legacy flag — maps to [AdminSurfaceVariant.emphasized] when [variant]
  /// is null.
  final bool emphasized;

  /// Explicit variant. When null, [emphasized] selects standard vs emphasized.
  final AdminSurfaceVariant? variant;

  /// Optional tint for [AdminSurfaceVariant.glass] (destination identity).
  final Color? accentColor;

  AdminSurfaceVariant get _resolvedVariant {
    if (variant != null) return variant!;
    return emphasized
        ? AdminSurfaceVariant.emphasized
        : AdminSurfaceVariant.standard;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedVariant;
    final radius = BorderRadius.circular(switch (resolved) {
      AdminSurfaceVariant.glass => 18,
      AdminSurfaceVariant.emphasized => 20,
      AdminSurfaceVariant.standard => 16,
    });

    final decoration = switch (resolved) {
      AdminSurfaceVariant.standard => BoxDecoration(
        borderRadius: radius,
        color: AdminColors.surfaceElevated,
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: AdminColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AdminColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      AdminSurfaceVariant.emphasized => BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AdminColors.borderStrong),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AdminColors.primarySoft.withValues(alpha: 0.65),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AdminColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      AdminSurfaceVariant.glass => BoxDecoration(
        borderRadius: radius,
        color: Colors.white.withValues(alpha: 0.62),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.atmosphereDeep.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: (accentColor ?? AdminColors.primary).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    };

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: padding ?? const EdgeInsets.all(AdminSpacing.xl),
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        hoverColor: (accentColor ?? AdminColors.primarySoft).withValues(
          alpha: 0.22,
        ),
        splashColor: (accentColor ?? AdminColors.primary).withValues(
          alpha: 0.08,
        ),
        child: content,
      ),
    );
  }
}
