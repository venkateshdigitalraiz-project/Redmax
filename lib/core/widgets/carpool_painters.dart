import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_colors.dart';

/// City skyline used behind the car on Splash / Offer / Publish screens.
class CarpoolSkylinePainter extends CustomPainter {
  const CarpoolSkylinePainter({
    this.top = const Color(0xFF6F93F2),
    this.bottom = const Color(0xFFD8CCFA),
  });

  final Color top;
  final Color bottom;

  static const List<double> _heights = [
    .55,
    .8,
    .45,
    .95,
    .6,
    .7,
    .4,
    .85,
    .5,
    .75,
    .35,
    .65,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / _heights.length;
    for (var i = 0; i < _heights.length; i++) {
      final h = size.height * _heights[i];
      final rect = Rect.fromLTWH(i * w + 1.5, size.height - h, w - 3, h);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top.withOpacity(.85), bottom.withOpacity(.15)],
        ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CarpoolSkylinePainter old) =>
      old.top != top || old.bottom != bottom;
}

/// Stylised map with a dashed route (Find a Ride screen).
class CarpoolMapPainter extends CustomPainter {
  const CarpoolMapPainter();

  static const Offset startFraction = Offset(.2, .24);
  static const Offset endFraction = Offset(.82, .72);

  static Path routePath(Size s) {
    return Path()
      ..moveTo(s.width * startFraction.dx, s.height * startFraction.dy)
      ..cubicTo(
        s.width * .38,
        s.height * .62,
        s.width * .6,
        s.height * .18,
        s.width * endFraction.dx,
        s.height * endFraction.dy,
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFDDEFD3),
    );

    final blob = Paint()..color = const Color(0xFFC9E6BE);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .45, -20, size.width * .6, size.height * .5),
      blob,
    );
    canvas.drawOval(
      Rect.fromLTWH(-30, size.height * .55, size.width * .5, size.height * .6),
      blob,
    );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .55,
        size.height * .62,
        size.width * .35,
        size.height * .25,
      ),
      Paint()..color = const Color(0xFFBFE0F5),
    );

    final road = Paint()
      ..color = Colors.white.withOpacity(.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(0, size.height * (.15 + i * .17)),
        Offset(size.width, size.height * (.05 + i * .2)),
        road,
      );
    }
    for (var j = 0; j < 5; j++) {
      canvas.drawLine(
        Offset(size.width * (.1 + j * .2), 0),
        Offset(size.width * (.2 + j * .18), size.height),
        road,
      );
    }

    final routePaint = Paint()
      ..color = AppColors.mapBlue
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final m in routePath(size).computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 8), routePaint);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Confetti dots for the "Ride Published" screen.
class CarpoolConfettiPainter extends CustomPainter {
  const CarpoolConfettiPainter();

  static const List<List<double>> _dots = [
    [.08, .10],
    [.20, .22],
    [.30, .06],
    [.45, .14],
    [.62, .05],
    [.78, .18],
    [.90, .10],
    [.14, .45],
    [.88, .42],
    [.05, .68],
    [.94, .66],
    [.25, .80],
    [.72, .84],
    [.55, .92],
  ];
  static const List<Color> _colors = [
    Color(0xFFFF6B6B),
    Color(0xFF4D7CFE),
    Color(0xFFFFC53D),
    Color(0xFF22C55E),
    Color(0xFFB36BFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _dots.length; i++) {
      final p = Paint()..color = _colors[i % _colors.length];
      final c = Offset(size.width * _dots[i][0], size.height * _dots[i][1]);
      if (i.isEven) {
        canvas.drawCircle(c, 3.5, p);
      } else {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(i * .6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-5, -2, 10, 4),
            const Radius.circular(2),
          ),
          p,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
