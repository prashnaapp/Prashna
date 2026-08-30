import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../home_visual.dart';

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

class HomeProgressArc extends StatelessWidget {
  const HomeProgressArc({
    super.key,
    required this.progress,
    required this.label,
    this.caption = '',
    this.size = 108,
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
                style: TextStyle(
                  fontSize: caption.isEmpty ? size * 0.26 : size * 0.24,
                  fontWeight: FontWeight.w800,
                  color: HomeVisual.ink,
                  height: 1,
                ),
              ),
              if (caption.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: HomeVisual.muted,
                    height: 1.1,
                  ),
                ),
              ],
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
    final stroke = size.width * 0.1;
    final radius = (size.width / 2) - stroke;
    const start = -math.pi / 2;
    const sweep = math.pi * 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = HomeVisual.gaugeTrack;
    canvas.drawArc(rect, start, sweep, false, track);

    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = HomeVisual.primary;
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
    this.height = 48,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(HomeVisual.tileRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: HomeVisual.ctaShadow,
      ),
      child: Material(
        color: HomeVisual.primary,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          child: SizedBox(
            height: height,
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
  const HomeSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.featured = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(HomeVisual.cardRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: featured ? HomeVisual.featuredShadow : HomeVisual.cardShadow,
      ),
      child: Material(
        color: HomeVisual.surface,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: child,
          ),
        ),
      ),
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
        fontWeight: FontWeight.w700,
        color: HomeVisual.ink,
        height: 1.2,
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
        height: 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: HomeVisual.gaugeTrack),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: const ColoredBox(color: HomeVisual.primary),
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
