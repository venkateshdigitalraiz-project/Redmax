import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_service_item.dart';

class ServiceGridCard extends StatelessWidget {
  final DashboardServiceItem service;
  final VoidCallback onTap;

  const ServiceGridCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _getServiceStyle(service.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: style.cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.cardBorderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: style.cardBorderColor.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Vertically centered icon matching design
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(child: _buildServiceIcon(style)),
                ),
                const SizedBox(width: 9),
                // Title and Subtitle aligned and vertically centered
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          service.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom-Right Circular Arrow Button
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.arrowBgColor,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: style.arrowColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon(_ServiceStyle style) {
    if (style.type == DashboardServiceType.delivery) {
      // 3D Isometric Orange Parcel Box
      return CustomPaint(
        size: const Size(30, 30),
        painter: _IsometricBoxPainter(),
      );
    }

    if (style.type == DashboardServiceType.partyBooking) {
      // Purple Calendar with checkmarks
      return CustomPaint(
        size: const Size(28, 28),
        painter: _CalendarPartyPainter(),
      );
    }

    return Icon(style.icon, size: 30, color: style.iconColor);
  }

  _ServiceStyle _getServiceStyle(DashboardServiceType type) {
    switch (type) {
      case DashboardServiceType.carpool:
        return const _ServiceStyle(
          type: DashboardServiceType.carpool,
          icon: Icons.directions_car_filled_rounded,
          iconColor: Color(0xFF4F3BE8),
          cardBgColor: Color(0xFFF6F5FE),
          cardBorderColor: Color(0xFFE8E4FD),
          arrowColor: Color(0xFF4F3BE8),
          arrowBgColor: Color(0xFFECE7FD),
        );
      case DashboardServiceType.delivery:
        return const _ServiceStyle(
          type: DashboardServiceType.delivery,
          icon: Icons.inventory_2_rounded,
          iconColor: Color(0xFFF56A00),
          cardBgColor: Color(0xFFFFF6EE),
          cardBorderColor: Color(0xFFFDE5D2),
          arrowColor: Color(0xFFF56A00),
          arrowBgColor: Color(0xFFFCE4D0),
        );
      case DashboardServiceType.partyBooking:
        return const _ServiceStyle(
          type: DashboardServiceType.partyBooking,
          icon: Icons.calendar_month_rounded,
          iconColor: Color(0xFF843CE6),
          cardBgColor: Color(0xFFFAF5FF),
          cardBorderColor: Color(0xFFEDE2FE),
          arrowColor: Color(0xFF843CE6),
          arrowBgColor: Color(0xFFEFE2FD),
        );
      case DashboardServiceType.tourPackages:
        return const _ServiceStyle(
          type: DashboardServiceType.tourPackages,
          icon: Icons.luggage_rounded,
          iconColor: Color(0xFF00A86B),
          cardBgColor: Color(0xFFEFF9F4),
          cardBorderColor: Color(0xFFD5EFE3),
          arrowColor: Color(0xFF00A86B),
          arrowBgColor: Color(0xFFD8F3E5),
        );
      case DashboardServiceType.rentals:
        return const _ServiceStyle(
          type: DashboardServiceType.rentals,
          icon: Icons.directions_car_rounded,
          iconColor: Color(0xFF00B4D8),
          cardBgColor: Color(0xFFEFF9FA),
          cardBorderColor: Color(0xFFD4F2F4),
          arrowColor: Color(0xFF00B4D8),
          arrowBgColor: Color(0xFFD4F4F6),
        );
      case DashboardServiceType.fleetTaxi:
        return const _ServiceStyle(
          type: DashboardServiceType.fleetTaxi,
          icon: Icons.local_taxi_rounded,
          iconColor: Color(0xFFE91E63),
          cardBgColor: Color(0xFFFDF2F7),
          cardBorderColor: Color(0xFFFCE0EE),
          arrowColor: Color(0xFFE91E63),
          arrowBgColor: Color(0xFFFCDDEE),
        );
    }
  }
}

class _ServiceStyle {
  final DashboardServiceType type;
  final IconData icon;
  final Color iconColor;
  final Color cardBgColor;
  final Color cardBorderColor;
  final Color arrowColor;
  final Color arrowBgColor;

  const _ServiceStyle({
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.cardBgColor,
    required this.cardBorderColor,
    required this.arrowColor,
    required this.arrowBgColor,
  });
}

/// Custom painter for the 3D isometric delivery box matching screenshot
class _IsometricBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.44;
    final h = size.height * 0.25;
    final sideH = size.height * 0.38;

    // Top Face (Lighter orange)
    final topPath = Path()
      ..moveTo(cx, cy - h - 2)
      ..lineTo(cx + w, cy - 2)
      ..lineTo(cx, cy + h - 2)
      ..lineTo(cx - w, cy - 2)
      ..close();
    final topPaint = Paint()
      ..color = const Color(0xFFFFA538)
      ..style = PaintingStyle.fill;
    canvas.drawPath(topPath, topPaint);

    // Left Face (Vibrant orange)
    final leftPath = Path()
      ..moveTo(cx - w, cy - 2)
      ..lineTo(cx, cy + h - 2)
      ..lineTo(cx, cy + h + sideH - 2)
      ..lineTo(cx - w, cy + sideH - 2)
      ..close();
    final leftPaint = Paint()
      ..color = const Color(0xFFF56A00)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftPath, leftPaint);

    // Right Face (Deep shaded orange)
    final rightPath = Path()
      ..moveTo(cx, cy + h - 2)
      ..lineTo(cx + w, cy - 2)
      ..lineTo(cx + w, cy + sideH - 2)
      ..lineTo(cx, cy + h + sideH - 2)
      ..close();
    final rightPaint = Paint()
      ..color = const Color(0xFFD65200)
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightPath, rightPaint);

    // Tape line across top & front
    final tapePaint = Paint()
      ..color = const Color(0xFFFFD49E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawLine(
      Offset(cx - w * 0.5, cy - h * 0.5 - 2),
      Offset(cx, cy + h - 2),
      tapePaint,
    );
    canvas.drawLine(
      Offset(cx, cy + h - 2),
      Offset(cx, cy + h + sideH - 2),
      tapePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the purple Party Booking calendar matching screenshot
class _CalendarPartyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 4, size.width - 4, size.height - 5),
      const Radius.circular(5),
    );
    final bgPaint = Paint()
      ..color = const Color(0xFF843CE6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // Top Binder Rings
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 1.5, 3.5, 5),
        const Radius.circular(2),
      ),
      ringPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 9.5, 1.5, 3.5, 5),
        const Radius.circular(2),
      ),
      ringPaint,
    );

    // White horizontal rows with checklist dots
    final linePaint = Paint()
      ..color = Colors.white.withAlpha(220)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const startY = 11.0;
    const spacing = 4.2;

    for (int i = 0; i < 3; i++) {
      final y = startY + i * spacing;
      canvas.drawCircle(Offset(6.5, y), 1.2, dotPaint);
      canvas.drawLine(Offset(10, y), Offset(size.width - 6, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
