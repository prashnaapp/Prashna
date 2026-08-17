import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../home_visual.dart';
import 'home_decorations.dart';
import 'welcome_section.dart';

/// Purple surface + decorations. Painted BEHIND Home scroll content.
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
    final decorOpacity = (1.0 - t).clamp(0.0, 1.0);
    final radius = lerpDouble(32, 0, t)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: HomeVisual.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
      child: decorOpacity <= 0.01
          ? const SizedBox.expand()
          : Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: decorOpacity,
                    child: const HomeHeroStars(),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: decorOpacity,
                    child: const HomeHeroAtmosphere(),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: lerpDouble(20, -48, t)!,
                  child: Opacity(
                    opacity: decorOpacity,
                    child: Transform.scale(
                      scale: lerpDouble(1, 0.15, t)!,
                      alignment: Alignment.bottomRight,
                      child: const HomeRocketScene(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Branding chrome painted ABOVE scroll content.
///
/// Expanded: transparent fill so backdrop decorations stay visible.
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
    final radius = lerpDouble(32, 0, t)!;
    // Fill only as we collapse so the sticky bar is opaque and we never
    // double-paint an expanded purple sheet over the rocket/planet.
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
          top: lerpDouble(topInset + 8, topInset + 2, t)!,
          left: HomeVisual.pagePadding,
          right: HomeVisual.pagePadding,
          child: const _HomeBrandBar(),
        ),
        if (greetOpacity > 0.01)
          Positioned(
            top: lerpDouble(topInset + 66, topInset + 40, t)!,
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
        const HomeBrandMark(size: 28),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Prashna',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          tooltip: 'Notifications',
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }
}
