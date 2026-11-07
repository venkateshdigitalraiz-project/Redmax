import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_colors.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';

import '../../../../core/carpool_core.dart';
import '../../domain/entities/carpool_entities.dart';

/// Card used in "Find a Ride".
class CarpoolFindRideCard extends StatelessWidget {
  const CarpoolFindRideCard({
    super.key,
    required this.ride,
    required this.isFavorite,
    required this.isBooking,
    required this.onFavorite,
    required this.onBook,
  });

  final CarpoolRideEntity ride;
  final bool isFavorite;
  final bool isBooking;
  final VoidCallback onFavorite;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return CarpoolCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarpoolAvatar(name: ride.driverName, size: 58),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    CarpoolRatingRow(
                      rating: ride.driverRating,
                      trips: ride.driverTrips,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.vehicle,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.seats} Seats',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${CarpoolFormatters.rupee(ride.pricePerSeat)}/seat',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onFavorite,
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.error : AppColors.navInactive,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CarpoolPrimaryButton(
            label: 'Book Ride',
            height: 44,
            isLoading: isBooking,
            onPressed: onBook,
          ),
        ],
      ),
    );
  }
}

/// Card used in "My Rides".
class CarpoolMyRideCard extends StatelessWidget {
  const CarpoolMyRideCard({
    super.key,
    required this.ride,
    required this.onDetails,
    required this.onCancel,
    required this.onCall,
    required this.onChat,
  });

  final CarpoolRideEntity ride;
  final VoidCallback onDetails;
  final VoidCallback onCancel;
  final VoidCallback onCall;
  final VoidCallback onChat;

  String get _chipLabel {
    switch (ride.status) {
      case CarpoolRideStatus.upcoming:
        return 'Upcoming';
      case CarpoolRideStatus.completed:
        return 'Completed';
      case CarpoolRideStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Upcoming';
    }
  }

  Color get _chipColor {
    switch (ride.status) {
      case CarpoolRideStatus.cancelled:
        return AppColors.error;
      case CarpoolRideStatus.completed:
        return AppColors.success;
      case CarpoolRideStatus.upcoming:
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = ride.status == CarpoolRideStatus.upcoming;
    return CarpoolCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _chipColor.withOpacity(.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _chipLabel,
                        style: TextStyle(
                          color: _chipColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      CarpoolFormatters.headline(ride.departure),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ride.from} → ${ride.to}',
                      style: const TextStyle(
                        color: AppColors.adminCardDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.directions_car_filled_rounded,
                size: 56,
                color: Color(0xFFB8C2E0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CarpoolAvatar(name: ride.driverName, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    CarpoolRatingRow(rating: ride.driverRating),
                  ],
                ),
              ),
              CarpoolRoundIconButton(
                icon: Icons.call_rounded,
                size: 40,
                background: AppColors.lilac,
                color: AppColors.primary,
                onTap: onCall,
              ),
              const SizedBox(width: 8),
              CarpoolRoundIconButton(
                icon: Icons.chat_bubble_rounded,
                size: 40,
                background: AppColors.lilac,
                color: AppColors.primary,
                onTap: onChat,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CarpoolSoftButton(
                  label: 'View Details',
                  onPressed: onDetails,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: upcoming
                    ? CarpoolSoftButton(
                        label: 'Cancel Ride',
                        onPressed: onCancel,
                        color: AppColors.error,
                        background: AppColors.fleetIcon,
                        borderColor: AppColors.error.withOpacity(.5),
                      )
                    : CarpoolSoftButton(
                        label: 'Book Again',
                        onPressed: onDetails,
                        color: Colors.white,
                        background: AppColors.primary,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
