import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/active_ride_banner.dart';

/// Active Ride card matching the screenshot:
/// - Blue to indigo gradient background
/// - White sedan car visual on the left
/// - 'Active Ride', 'Hyderabad ➔ Vijayawada', '🕒 1h 20m remaining'
/// - White pill button 'View Details >'
class ActiveRideCard extends StatelessWidget {
  final ActiveRideBanner banner;
  final VoidCallback onViewDetails;

  const ActiveRideCard({
    super.key,
    required this.banner,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkHeaderGradient
            : AppColors.activeRideGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(isDark ? 40 : 80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background soft glowing aura
          Positioned(
            left: 20,
            bottom: -20,
            child: Container(
              width: 140,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // White Sedan Car Graphic on the left
                SizedBox(
                  width: 84,
                  height: 50,
                  child: Image.asset(
                    banner.carImageUrl ?? 'assets/images/active_car.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => Image.asset(
                      'assets/images/active_car.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Image.asset(
                        'assets/images/active_car.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (cx, er, st) => const _WhiteSedanCarWidget(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Center Info: Active Ride, Route, Time remaining
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${banner.origin}  ➔  ${banner.destination}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withAlpha(230),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.white.withAlpha(210),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                banner.timeRemaining,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withAlpha(210),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: "View Details >" White Pill Button
                GestureDetector(
                  onTap: onViewDetails,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF1E3A8A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stylized modern white sedan car drawing matching the image asset
class _WhiteSedanCarWidget extends StatelessWidget {
  const _WhiteSedanCarWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(95, 56),
      painter: _WhiteSedanPainter(),
    );
  }
}

class _WhiteSedanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.88), width: w * 0.85, height: 10),
      shadowPaint,
    );

    // Car Roof / Windows Cabin
    final cabinPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final cabinPath = Path()
      ..moveTo(w * 0.18, h * 0.52)
      ..lineTo(w * 0.32, h * 0.22)
      ..lineTo(w * 0.68, h * 0.22)
      ..lineTo(w * 0.84, h * 0.52)
      ..close();
    canvas.drawPath(cabinPath, cabinPaint);

    // Front/Side tinted glass
    final glassPaint = Paint()
      ..color = const Color(0xFF94A3B8).withAlpha(160)
      ..style = PaintingStyle.fill;
    final glassPath = Path()
      ..moveTo(w * 0.34, h * 0.25)
      ..lineTo(w * 0.65, h * 0.25)
      ..lineTo(w * 0.78, h * 0.50)
      ..lineTo(w * 0.24, h * 0.50)
      ..close();
    canvas.drawPath(glassPath, glassPaint);

    // Car Body (Pure White Sedan with soft shading)
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final bodyPath = Path()
      ..moveTo(w * 0.05, h * 0.64)
      ..quadraticBezierTo(w * 0.04, h * 0.52, w * 0.15, h * 0.52)
      ..lineTo(w * 0.25, h * 0.50)
      ..lineTo(w * 0.75, h * 0.50)
      ..quadraticBezierTo(w * 0.90, h * 0.54, w * 0.95, h * 0.64)
      ..lineTo(w * 0.94, h * 0.74)
      ..lineTo(w * 0.06, h * 0.74)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Headlight
    final headlightPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.88, h * 0.56, 6, 4), const Radius.circular(2)),
      headlightPaint,
    );

    // Front Grille
    final grillePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.92, h * 0.62, 3, 7), const Radius.circular(1)),
      grillePaint,
    );

    // Wheels (Dark alloy rims & tires)
    final tirePaint = Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.fill;
    final rimPaint = Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.fill;

    // Rear Wheel
    canvas.drawCircle(Offset(w * 0.24, h * 0.76), 9, tirePaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.76), 5, rimPaint);

    // Front Wheel
    canvas.drawCircle(Offset(w * 0.76, h * 0.76), 9, tirePaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.76), 5, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
