import 'package:flutter/material.dart';

/// Curved bottom edge of the home hero header.
class PartyHeroClipper extends CustomClipper<Path> {
  const PartyHeroClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 38)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height + 14,
        size.width,
        size.height - 54,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Colourful confetti dashes for the "Booking Confirmed" screen.
class PartyConfettiPainter extends CustomPainter {
  const PartyConfettiPainter();

  static const List<List<double>> _pieces = [
    [.06, .05], [.15, .13], [.26, .04], [.38, .16], [.58, .07], [.72, .15],
    [.84, .05], [.93, .17], [.10, .26], [.22, .34], [.80, .30], [.92, .38],
    [.05, .44], [.66, .24], [.46, .30], [.96, .50], [.14, .54], [.88, .60],
  ];
  static const List<Color> _colors = [
    Color(0xFF22C55E), Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFFFFC53D),
    Color(0xFFB36BFF), Color(0xFFFF8FB1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _pieces.length; i++) {
      final paint = Paint()..color = _colors[i % _colors.length];
      final c = Offset(size.width * _pieces[i][0], size.height * _pieces[i][1]);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * .7);
      if (i % 4 == 0) {
        canvas.drawCircle(Offset.zero, 3, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-7, -2.5, 14, 5), const Radius.circular(2)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
