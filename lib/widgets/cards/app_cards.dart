import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.showShadow = true,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showShadow;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lgAll;
    final content = Container(
      width: double.infinity,
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: radius,
        border: showBorder
            ? Border.all(color: AppColors.divider.withValues(alpha: 0.8))
            : null,
        boxShadow: showShadow ? AppShadows.soft : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trend;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(value, style: AppTextStyles.headline(context)),
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              trend!,
              style: AppTextStyles.label(context).copyWith(color: accent),
            ),
          ],
        ],
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final double progress;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppTextStyles.titleMedium(context)),
              ),
              ?trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: AppTextStyles.bodyMedium(context)),
          ],
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: AppRadius.xxlAll,
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              borderRadius: AppRadius.xxlAll,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${(progress.clamp(0, 1) * 100).round()}% complete',
            style: AppTextStyles.caption(context),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
    this.iconColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.secondary;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.lgAll,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.bodyMedium(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      showShadow: true,
      backgroundColor: AppColors.premiumGoldSurface,
      showBorder: false,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          gradient: LinearGradient(
            colors: [
              AppColors.premiumGold.withValues(alpha: 0.15),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.premiumGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.premium,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.premiumGoldDark,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: AppColors.premiumGoldDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: AppTextStyles.bodyMedium(context)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.emoji_events_rounded,
    this.isUnlocked = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? AppColors.premiumGold : AppColors.textTertiary;

    return AppCard(
      backgroundColor:
          isUnlocked ? AppColors.premiumGoldSurface : AppColors.surface,
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.bodyMedium(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChapterCard extends StatelessWidget {
  const ChapterCard({
    super.key,
    required this.chapterNumber,
    required this.title,
    required this.questionCount,
    this.progress,
    this.onTap,
  });

  final int chapterNumber;
  final String title;
  final int questionCount;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdAll,
            ),
            child: Text(
              '$chapterNumber',
              style: AppTextStyles.titleMedium(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$questionCount questions',
                  style: AppTextStyles.caption(context),
                ),
                if (progress != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(
                    value: progress!.clamp(0, 1),
                    minHeight: 6,
                    borderRadius: AppRadius.xxlAll,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class TestCard extends StatelessWidget {
  const TestCard({
    super.key,
    required this.title,
    required this.durationLabel,
    required this.questionCount,
    this.difficulty,
    this.onTap,
    this.tag,
  });

  final String title;
  final String durationLabel;
  final int questionCount;
  final String? difficulty;
  final String? tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppTextStyles.titleMedium(context)),
              ),
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.xxlAll,
                  ),
                  child: Text(
                    tag!,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _Meta(icon: Icons.schedule_rounded, label: durationLabel),
              _Meta(
                icon: Icons.help_outline_rounded,
                label: '$questionCount Qs',
              ),
              if (difficulty != null)
                _Meta(icon: Icons.speed_rounded, label: difficulty!),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.caption(context)),
      ],
    );
  }
}
