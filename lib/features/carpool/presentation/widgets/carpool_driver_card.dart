import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_colors.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_ride.dart';

/// Displays driver information section in the ride detail page.
class CarpoolDriverCard extends StatelessWidget {
  final CarpoolRide ride;

  const CarpoolDriverCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorderLight : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 15 : 7),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Your Driver',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withAlpha(25),
                child: Text(
                  ride.driverName.isNotEmpty
                      ? ride.driverName[0].toUpperCase()
                      : 'D',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Star rating
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final starVal = i + 1;
                          return Icon(
                            starVal <= ride.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: const Color(0xFFF59E0B),
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          ride.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorderLight : AppColors.borderLight,
          ),
          const SizedBox(height: 14),
          // Vehicle info row
          Row(
            children: [
              _vehicleChip(
                icon: Icons.directions_car_rounded,
                label: ride.vehicleName,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _vehicleChip(
                icon: Icons.palette_rounded,
                label: ride.vehicleColor,
                isDark: isDark,
              ),
              if (ride.isAcAvailable) ...[
                const SizedBox(width: 8),
                _vehicleChip(
                  icon: Icons.ac_unit_rounded,
                  label: 'AC Available',
                  isDark: isDark,
                  highlight: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _vehicleChip({
    required IconData icon,
    required String label,
    required bool isDark,
    bool highlight = false,
  }) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF0EA5E9).withAlpha(20)
              : (isDark ? AppColors.darkBorderLight : AppColors.borderLight),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: highlight
                  ? const Color(0xFF0EA5E9)
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: highlight
                      ? const Color(0xFF0EA5E9)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
