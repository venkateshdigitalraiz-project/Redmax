import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/recent_activity_entry.dart';

/// Recent Activity section matching the exact UI design in the screenshot:
/// - "Recent Activity" header with blue "See All >" link
/// - White cards with subtle border and shadow
/// - Circular icon with matching soft tint
/// - Clean status pill badge ("Upcoming" in green, "Delivered" in blue)
/// - Subtitle / Route / Order ID on the right
class RecentActivitySection extends StatelessWidget {
  final List<RecentActivityEntry> activities;
  final VoidCallback onSeeAll;
  final ValueChanged<RecentActivityEntry>? onActivityTap;

  const RecentActivitySection({
    super.key,
    required this.activities,
    required this.onSeeAll,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0077F6),
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF0077F6),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Activity List Items
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: activities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildActivityCard(context, activities[index], isDark);
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    RecentActivityEntry item,
    bool isDark,
  ) {
    final activityStyle = _getActivityStyle(item.type, isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onActivityTap?.call(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorderLight : const Color(0xFFF1F5F9),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(25)
                    : const Color(0xFF0F172A).withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular Soft Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activityStyle.iconBgColor,
                ),
                child: Center(child: _buildActivityIcon(item.type, activityStyle)),
              ),

              const SizedBox(width: 12),

              // Title and Timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.timestampText,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge & Subtitle (Route or Order ID)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(item.status),
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityIcon(ActivityType type, _ActivityIconStyle style) {
    if (type == ActivityType.delivery) {
      return CustomPaint(
        size: const Size(22, 22),
        painter: _MiniBoxPainter(),
      );
    }
    return Icon(
      style.icon,
      size: 22,
      color: style.iconColor,
    );
  }

  _ActivityIconStyle _getActivityStyle(ActivityType type, bool isDark) {
    switch (type) {
      case ActivityType.carpool:
        return _ActivityIconStyle(
          icon: Icons.directions_car_filled_rounded,
          iconColor: const Color(0xFF1570EF),
          iconBgColor: isDark ? const Color(0xFF173566) : const Color(0xFFDBEAFE),
        );
      case ActivityType.delivery:
        return _ActivityIconStyle(
          icon: Icons.inventory_2_rounded,
          iconColor: const Color(0xFFEA580C),
          iconBgColor: isDark ? const Color(0xFF4D2406) : const Color(0xFFFFEDD5),
        );
      case ActivityType.taxi:
        return _ActivityIconStyle(
          icon: Icons.local_taxi_rounded,
          iconColor: const Color(0xFFDB2777),
          iconBgColor: isDark ? const Color(0xFF4D1231) : const Color(0xFFFCE7F3),
        );
      case ActivityType.rental:
        return _ActivityIconStyle(
          icon: Icons.car_rental_rounded,
          iconColor: const Color(0xFF0D9488),
          iconBgColor: isDark ? const Color(0xFF10433D) : const Color(0xFFCCFBF1),
        );
    }
  }

  Widget _buildStatusBadge(ActivityStatus status) {
    final Color bgColor;
    final Color textColor;
    final String text;

    switch (status) {
      case ActivityStatus.upcoming:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        text = 'Upcoming';
        break;
      case ActivityStatus.delivered:
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        text = 'Delivered';
        break;
      case ActivityStatus.completed:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        text = 'Completed';
        break;
      case ActivityStatus.cancelled:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.1,
        ),
      ),
    );
  }
}

class _ActivityIconStyle {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _ActivityIconStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class _MiniBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.44;
    final h = size.height * 0.25;
    final sideH = size.height * 0.38;

    final topPath = Path()
      ..moveTo(cx, cy - h - 1)
      ..lineTo(cx + w, cy - 1)
      ..lineTo(cx, cy + h - 1)
      ..lineTo(cx - w, cy - 1)
      ..close();
    canvas.drawPath(topPath, Paint()..color = const Color(0xFFFDBA74)..style = PaintingStyle.fill);

    final leftPath = Path()
      ..moveTo(cx - w, cy - 1)
      ..lineTo(cx, cy + h - 1)
      ..lineTo(cx, cy + h + sideH - 1)
      ..lineTo(cx - w, cy + sideH - 1)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = const Color(0xFFEA580C)..style = PaintingStyle.fill);

    final rightPath = Path()
      ..moveTo(cx, cy + h - 1)
      ..lineTo(cx + w, cy - 1)
      ..lineTo(cx + w, cy + sideH - 1)
      ..lineTo(cx, cy + h + sideH - 1)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = const Color(0xFFC2410C)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
