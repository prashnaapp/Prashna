import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../home_visual.dart';
import 'home_decorations.dart';
import 'welcome_section.dart';

/// Purple surface. Painted BEHIND Home scroll content.
///
/// No branding text — that lives in [HomeHeroChrome] so Prashna / greeting
/// cannot be duplicated across layers.
class HomeHeroBackdrop extends StatelessWidget {
  const HomeHeroBackdrop({
    super.key,
    this.collapseProgress = 0,
  });

  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    final t = collapseProgress.clamp(0.0, 1.0);
    final radius = lerpDouble(28, 0, t)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: HomeVisual.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
    );
  }
}

/// Branding chrome painted ABOVE scroll content.
///
/// Expanded: transparent fill so the backdrop stays the single purple surface.
/// Collapsed: opaque purple bar so content cannot show through the sticky header.
class HomeHeroChrome extends StatelessWidget {
  const HomeHeroChrome({
    super.key,
    required this.topInset,
    this.collapseProgress = 0,
  });

  final double topInset;
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    final t = collapseProgress.clamp(0.0, 1.0);
    final greetOpacity = (1.0 - t).clamp(0.0, 1.0);
    final radius = lerpDouble(28, 0, t)!;
    final fillOpacity = Curves.easeIn.transform(t);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        if (fillOpacity > 0.01)
          Positioned.fill(
            child: Opacity(
              opacity: fillOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: HomeVisual.heroGradient,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(radius)),
                ),
              ),
            ),
          ),
        Positioned(
          top: lerpDouble(topInset + 6, topInset + 4, t)!,
          left: HomeVisual.pagePadding,
          right: HomeVisual.pagePadding,
          child: const _HomeBrandBar(),
        ),
        if (greetOpacity > 0.01)
          Positioned(
            top: lerpDouble(topInset + 48, topInset + 36, t)!,
            left: HomeVisual.pagePadding,
            right: HomeVisual.pagePadding,
            child: Opacity(
              opacity: greetOpacity,
              child: const WelcomeSection(),
            ),
          ),
      ],
    );
  }
}

class _HomeBrandBar extends StatelessWidget {
  const _HomeBrandBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HomeBrandMark(size: 24),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: Text(
            'Prashna',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          tooltip: 'Notifications',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }
}
