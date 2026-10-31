import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_colors.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_ride.dart';

/// A polished card widget that displays a single [CarpoolRide] in the list.
class CarpoolRideCard extends StatelessWidget {
  final CarpoolRide ride;
  final VoidCallback onTap;

  const CarpoolRideCard({
    super.key,
    required this.ride,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorderLight : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 18 : 8),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Route header with gradient accent
            _buildRouteHeader(isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  _buildDriverRow(isDark),
                  const SizedBox(height: 10),
                  _buildDetailsRow(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withAlpha(25)
            : AppColors.carpoolBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Origin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ride.origin,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Route line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 1.5,
                  color: AppColors.textTertiary,
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                Container(
                  width: 20,
                  height: 1.5,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          // Destination
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        ride.destination,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5B4F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRow(bool isDark) {
    return Row(
      children: [
        // Driver avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withAlpha(30),
          child: Text(
            ride.driverName.isNotEmpty
                ? ride.driverName[0].toUpperCase()
                : 'D',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ride.driverName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${ride.vehicleName} · ${ride.vehicleColor}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Rating
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 3),
              Text(
                ride.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow(bool isDark) {
    return Row(
      children: [
        // Time
        _infoChip(
          icon: Icons.access_time_rounded,
          label: ride.departureTime,
          iconColor: AppColors.primary,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        // Seats
        _infoChip(
          icon: Icons.airline_seat_recline_normal_rounded,
          label: '${ride.seatsAvailable} seats',
          iconColor: AppColors.success,
          isDark: isDark,
        ),
        if (ride.isAcAvailable) ...[
          const SizedBox(width: 8),
          _infoChip(
            icon: Icons.ac_unit_rounded,
            label: 'AC',
            iconColor: const Color(0xFF0EA5E9),
            isDark: isDark,
          ),
        ],
        const Spacer(),
        // Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${ride.pricePerSeat.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'per seat',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? iconColor.withAlpha(20)
            : iconColor.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
