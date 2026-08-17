import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../syllabus_visual.dart';

/// Compact purple header that paints behind the status bar.
///
/// Not a Home hero — only the top safe-area / title band.
class SyllabusHeaderBand extends StatelessWidget {
  const SyllabusHeaderBand({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.viewPadding.top > media.padding.top
        ? media.viewPadding.top
        : media.padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: SyllabusVisual.headerGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: child,
        ),
      ),
    );
  }
}
