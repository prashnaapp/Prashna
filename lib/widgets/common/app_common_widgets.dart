import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../buttons/app_buttons.dart';
import 'app_pill.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium(context)),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!, style: AppTextStyles.bodyMedium(context)),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(AppIcons.search, size: 22),
        suffixIcon: onClear != null
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(AppIcons.close, size: 20),
              )
            : null,
      ),
    );
  }
}

class AppProgressIndicator extends StatelessWidget {
  const AppProgressIndicator({
    super.key,
    this.label,
    this.message,
  });

  final String? label;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppCircularProgress(size: 40, strokeWidth: 3),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(label!, style: AppTextStyles.titleMedium(context)),
        ],
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ],
    );
  }
}

class AppCircularProgress extends StatelessWidget {
  const AppCircularProgress({
    super.key,
    this.value,
    this.size = 48,
    this.strokeWidth = 4,
    this.color,
    this.trackColor,
  });

  final double? value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: strokeWidth,
        color: color ?? Theme.of(context).colorScheme.primary,
        backgroundColor: trackColor ?? AppColors.surfaceVariant,
      ),
    );
  }
}

class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.backgroundColor,
    this.showLabel = false,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadius.xxlAll,
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: height,
            color: color ?? Theme.of(context).colorScheme.primary,
            backgroundColor: backgroundColor ?? AppColors.surfaceVariant,
            borderRadius: AppRadius.xxlAll,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(clamped * 100).round()}%',
            style: AppTextStyles.caption(context),
            textAlign: TextAlign.end,
          ),
        ],
      ],
    );
  }
}

enum AppBadgeVariant { primary, success, warning, error, gold, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.primary,
    this.icon,
  });

  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  (Color bg, Color fg) _colors() {
    return switch (variant) {
      AppBadgeVariant.primary => (
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.primary,
        ),
      AppBadgeVariant.success => (
          AppColors.successSurface,
          AppColors.success,
        ),
      AppBadgeVariant.warning => (
          AppColors.warningSurface,
          AppColors.warning,
        ),
      AppBadgeVariant.error => (
          AppColors.errorSurface,
          AppColors.error,
        ),
      AppBadgeVariant.gold => (
          AppColors.premiumGoldSurface,
          AppColors.premiumGoldDark,
        ),
      AppBadgeVariant.neutral => (
          AppColors.surfaceVariant,
          AppColors.textSecondary,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.xxlAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.onSelected,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return AppSelectionPill(
      label: label,
      selected: selected,
      icon: icon,
      onTap: onSelected == null ? null : () => onSelected!(!selected),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Symbols.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.primaryStrong),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge(context),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xxxl),
            AppPrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.message = 'Loading…',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppProgressIndicator(
        label: message,
      ),
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.error, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.titleLarge(context)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xxxl),
            AppOutlinedButton(
              label: 'Try again',
              icon: AppIcons.refresh,
              onPressed: onRetry,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 48,
    this.showBadge = false,
    this.badgeColor,
  });

  final String? imageUrl;
  final String? initials;
  final double size;
  final bool showBadge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final fallback = initials?.trim().isNotEmpty == true
        ? initials!.trim().substring(0, 1).toUpperCase()
        : '?';

    Widget avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      foregroundColor: AppColors.primary,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              fallback,
              style: AppTextStyles.titleMedium(context).copyWith(
                color: AppColors.primary,
                fontSize: size * 0.38,
              ),
            )
          : null,
    );

    if (!showBadge) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: badgeColor ?? AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Responsive horizontal padding based on screen width.
class AppResponsivePadding extends StatelessWidget {
  const AppResponsivePadding({
    super.key,
    required this.child,
    this.maxContentWidth = 600,
  });

  final Widget child;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 360
        ? AppSpacing.lg
        : width < 400
            ? AppSpacing.xxl
            : AppSpacing.xxxl;

    // Width-only constraint. Do not force minHeight to the viewport —
    // that stretches tab content and creates blank scroll space.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: child,
        ),
      ),
    );
  }
}
