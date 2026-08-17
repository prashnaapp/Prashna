import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Deep indigo/purple hero used on Home, Instructions, and Profile.
class AppHeroBanner extends StatelessWidget {
  const AppHeroBanner({
    super.key,
    required this.child,
    this.height,
    this.padding,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.xxl),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -30,
              child: _Blob(size: 140, opacity: 0.16),
            ),
            Positioned(
              left: -28,
              bottom: -36,
              child: _Blob(size: 120, opacity: 0.12),
            ),
            Positioned(
              right: 48,
              bottom: 18,
              child: _Blob(size: 36, opacity: 0.18),
            ),
            SizedBox(
              width: double.infinity,
              height: height,
              child: Padding(
                padding: padding ??
                    EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      MediaQuery.paddingOf(context).top + AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textOnPrimary.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class AppHeroIconButton extends StatelessWidget {
  const AppHeroIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.textOnPrimary.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: AppColors.textOnPrimary),
      ),
    );
    return button;
  }
}

class AppOnHeroText {
  static TextStyle brand(BuildContext context) =>
      AppTextStyles.titleLarge(context).copyWith(
        color: AppColors.textOnPrimary,
        fontWeight: FontWeight.w800,
      );

  static TextStyle title(BuildContext context) =>
      AppTextStyles.headline(context).copyWith(
        color: AppColors.textOnPrimary,
        fontWeight: FontWeight.w700,
      );

  static TextStyle body(BuildContext context) =>
      AppTextStyles.bodyMedium(context).copyWith(
        color: AppColors.textOnPrimary.withValues(alpha: 0.86),
      );
}
