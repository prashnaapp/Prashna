import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../home_visual.dart';

class HomeHeroStars extends StatelessWidget {
  const HomeHeroStars({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: _StarsPainter(), child: SizedBox.expand()),
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sparkle = Paint()..color = HomeVisual.star;
    final soft = Paint()..color = Colors.white.withValues(alpha: 0.85);

    const sparkles = <(double, double, double)>[
      (0.10, 0.18, 5.0),
      (0.22, 0.12, 3.2),
      (0.74, 0.16, 4.4),
      (0.88, 0.10, 5.5),
      (0.92, 0.32, 3.4),
      (0.16, 0.46, 3.0),
      (0.62, 0.22, 2.6),
    ];
    for (final star in sparkles) {
      _sparkle(
        canvas,
        Offset(star.$1 * size.width, star.$2 * size.height),
        star.$3,
        sparkle,
      );
    }

    const dots = <(double, double, double)>[
      (0.30, 0.20, 1.3),
      (0.48, 0.14, 1.1),
      (0.84, 0.42, 1.4),
      (0.08, 0.62, 1.2),
      (0.40, 0.58, 1.0),
      (0.70, 0.48, 1.2),
    ];
    for (final dot in dots) {
      canvas.drawCircle(
        Offset(dot.$1 * size.width, dot.$2 * size.height),
        dot.$3,
        soft,
      );
    }
  }

  void _sparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeHeroAtmosphere extends StatelessWidget {
  const HomeHeroAtmosphere({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _AtmospherePainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.28, size.height * 0.96),
        width: size.width * 0.78,
        height: size.height * 0.40,
      ),
      Paint()
        ..color = const Color(0xFF6548F5).withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.98),
        width: size.width * 0.58,
        height: size.height * 0.32,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeBrandMark extends StatelessWidget {
  const HomeBrandMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _BookMarkPainter());
  }
}

class _BookMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final left = Paint()..color = Colors.white;
    final right = Paint()..color = const Color(0xFFE8E4FF);
    final spine = Paint()
      ..color = const Color(0xFFB8B0FF)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final leftPage = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..quadraticBezierTo(w * 0.28, h * 0.16, w * 0.10, h * 0.28)
      ..lineTo(w * 0.16, h * 0.82)
      ..quadraticBezierTo(w * 0.32, h * 0.70, w * 0.50, h * 0.78)
      ..close();
    final rightPage = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..quadraticBezierTo(w * 0.72, h * 0.16, w * 0.90, h * 0.28)
      ..lineTo(w * 0.84, h * 0.82)
      ..quadraticBezierTo(w * 0.68, h * 0.70, w * 0.50, h * 0.78)
      ..close();
    canvas.drawPath(leftPage, left);
    canvas.drawPath(rightPage, right);
    canvas.drawLine(
      Offset(w * 0.50, h * 0.22),
      Offset(w * 0.50, h * 0.78),
      spine,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeRocketScene extends StatelessWidget {
  const HomeRocketScene({super.key, this.width = 176, this.height = 138});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(width, height),
        painter: _RocketScenePainter(),
      ),
    );
  }
}

class _RocketScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final planetCenter = Offset(size.width * 0.78, size.height * 0.26);
    canvas.save();
    canvas.translate(planetCenter.dx, planetCenter.dy);
    canvas.rotate(-0.42);
    canvas.drawOval(
      const Rect.fromLTWH(-30, -7, 60, 14),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..color = const Color(0xFFC5CBFF).withValues(alpha: 0.9),
    );
    canvas.restore();
    canvas.drawCircle(
      planetCenter,
      15,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB4A8FF), Color(0xFF5B4CFF)],
        ).createShader(Rect.fromCircle(center: planetCenter, radius: 15)),
    );
    canvas.drawCircle(
      planetCenter.translate(-4, -3),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    final rocketOrigin = Offset(size.width * 0.40, size.height * 0.62);
    canvas.save();
    canvas.translate(rocketOrigin.dx, rocketOrigin.dy);
    canvas.rotate(-0.58);

    canvas.drawOval(
      const Rect.fromLTWH(-7, 20, 14, 22),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF176), Color(0xFFFF8A65)],
        ).createShader(const Rect.fromLTWH(-7, 20, 14, 22)),
    );

    final smoke = Paint()..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawOval(const Rect.fromLTWH(-10, 38, 10, 8), smoke);
    canvas.drawOval(const Rect.fromLTWH(-2, 44, 12, 9), smoke);
    canvas.drawOval(const Rect.fromLTWH(-8, 52, 9, 7), smoke);

    final body = Path()
      ..moveTo(0, -30)
      ..quadraticBezierTo(15, -4, 11, 18)
      ..lineTo(-11, 18)
      ..quadraticBezierTo(-15, -4, 0, -30)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFD5D8FF)],
        ).createShader(const Rect.fromLTWH(-15, -30, 30, 50)),
    );

    final fin = Paint()..color = const Color(0xFF6C5CE7);
    canvas.drawPath(
      Path()
        ..moveTo(-11, 4)
        ..lineTo(-24, 22)
        ..lineTo(-8, 18)
        ..close(),
      fin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(11, 4)
        ..lineTo(24, 22)
        ..lineTo(8, 18)
        ..close(),
      fin,
    );

    canvas.drawCircle(
      const Offset(0, -6),
      5.4,
      Paint()..color = const Color(0xFF4C8DFF),
    );
    canvas.drawCircle(
      const Offset(0, -6),
      2.6,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeProgressArc extends StatelessWidget {
  const HomeProgressArc({
    super.key,
    required this.progress,
    required this.label,
    this.caption = "Today's Goal",
    this.size = 128,
  });

  final double progress;
  final String label;
  final String caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _ArcPainter(progress: progress.clamp(0.0, 1.0)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: HomeVisual.ink,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: HomeVisual.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = HomeVisual.gaugeTrack;
    canvas.drawArc(rect, start, sweep, false, track);

    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = HomeVisual.gaugeGradient.createShader(rect);
    canvas.drawArc(rect, start, sweep * progress, false, value);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class HomeCtaButton extends StatelessWidget {
  const HomeCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: HomeVisual.ctaGradient,
        borderRadius: BorderRadius.circular(HomeVisual.pillRadius),
        boxShadow: HomeVisual.ctaShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(HomeVisual.pillRadius),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeSurfaceCard extends StatelessWidget {
  const HomeSurfaceCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: HomeVisual.surface,
        borderRadius: BorderRadius.circular(HomeVisual.cardRadius),
        boxShadow: HomeVisual.cardShadow,
      ),
      child: Material(color: Colors.transparent, child: child),
    );
  }
}

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: HomeVisual.ink,
      ),
    );
  }
}

class HomeLinearProgress extends StatelessWidget {
  const HomeLinearProgress({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(HomeVisual.pillRadius),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: HomeVisual.gaugeTrack),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: HomeVisual.ctaGradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum HomeQuickGlyph { books, clipboard, globe, document }

class HomeQuickGlyphIcon extends StatelessWidget {
  const HomeQuickGlyphIcon({super.key, required this.glyph, this.size = 28});

  final HomeQuickGlyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _QuickGlyphPainter(glyph),
    );
  }
}

class _QuickGlyphPainter extends CustomPainter {
  const _QuickGlyphPainter(this.glyph);

  final HomeQuickGlyph glyph;

  @override
  void paint(Canvas canvas, Size size) {
    switch (glyph) {
      case HomeQuickGlyph.books:
        _books(canvas, size);
      case HomeQuickGlyph.clipboard:
        _clipboard(canvas, size);
      case HomeQuickGlyph.globe:
        _globe(canvas, size);
      case HomeQuickGlyph.document:
        _document(canvas, size);
    }
  }

  void _books(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.22, w * 0.26, h * 0.66),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFF8A65),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.14, w * 0.28, h * 0.74),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF4C8DFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.66, h * 0.26, w * 0.26, h * 0.62),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF6C5CE7),
    );
  }

  void _clipboard(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.16, w * 0.64, h * 0.72),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF4C8DFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.34, h * 0.08, w * 0.32, h * 0.16),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF90CAF9),
    );
    final check = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.34, h * 0.48),
      Offset(w * 0.46, h * 0.60),
      check,
    );
    canvas.drawLine(
      Offset(w * 0.46, h * 0.60),
      Offset(w * 0.70, h * 0.38),
      check,
    );
  }

  void _globe(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.36;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF6C5CE7);
    canvas.drawCircle(c, r, stroke);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 0.9, height: r * 2),
      stroke,
    );
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), stroke);
    canvas.drawLine(
      Offset(c.dx - r * 0.7, c.dy - r * 0.55),
      Offset(c.dx + r * 0.7, c.dy - r * 0.55),
      stroke,
    );
  }

  void _document(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.12, w * 0.56, h * 0.76),
        const Radius.circular(4),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF6C5CE7),
    );
    final line = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.34, h * 0.38),
      Offset(w * 0.66, h * 0.38),
      line,
    );
    canvas.drawLine(
      Offset(w * 0.34, h * 0.52),
      Offset(w * 0.66, h * 0.52),
      line,
    );
    canvas.drawLine(
      Offset(w * 0.34, h * 0.66),
      Offset(w * 0.56, h * 0.66),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _QuickGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph;
}
