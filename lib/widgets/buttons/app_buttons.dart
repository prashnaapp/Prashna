import 'package:flutter/material.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_spacing.dart';

enum AppButtonSize { medium, large }

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.size = AppButtonSize.large,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;
  final AppButtonSize size;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final height = size == AppButtonSize.large ? 52.0 : 44.0;
    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      loadingColor: Theme.of(context).colorScheme.onPrimary,
    );

    final button = AnimatedOpacity(
      duration: AppAnimations.fast,
      opacity: _enabled ? 1 : 0.55,
      child: FilledButton(
        onPressed: _enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          minimumSize: expand ? Size.fromHeight(height) : Size(0, height),
          padding: EdgeInsets.symmetric(
            horizontal: expand ? AppSpacing.xxl : AppSpacing.xl,
          ),
        ),
        child: child,
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      loadingColor: colorScheme.onSecondaryContainer,
    );

    final button = AnimatedOpacity(
      duration: AppAnimations.fast,
      opacity: _enabled ? 1 : 0.55,
      child: FilledButton.tonal(
        onPressed: _enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          minimumSize: expand ? const Size.fromHeight(52) : null,
        ),
        child: child,
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      loadingColor: Theme.of(context).colorScheme.primary,
    );

    final button = OutlinedButton(
      onPressed: _enabled ? onPressed : null,
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isLoading = false,
    this.variant = AppIconButtonVariant.standard,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isLoading;
  final AppIconButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Widget iconWidget = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          )
        : Icon(icon, size: 22);

    final button = switch (variant) {
      AppIconButtonVariant.standard => IconButton(
          onPressed: isLoading ? null : onPressed,
          icon: iconWidget,
        ),
      AppIconButtonVariant.filled => IconButton.filled(
          onPressed: isLoading ? null : onPressed,
          icon: iconWidget,
        ),
      AppIconButtonVariant.tonal => IconButton.filledTonal(
          onPressed: isLoading ? null : onPressed,
          icon: iconWidget,
        ),
    };

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

enum AppIconButtonVariant { standard, filled, tonal }

/// Primary action with a dedicated loading API (alias of [AppPrimaryButton]).
class AppLoadingButton extends AppPrimaryButton {
  const AppLoadingButton({
    super.key,
    required super.label,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.expand,
  });
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.loadingColor,
    this.icon,
  });

  final String label;
  final bool isLoading;
  final Color loadingColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: loadingColor,
        ),
      );
    }

    if (icon == null) {
      return Text(label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
