import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_colors.dart';
import '../bloc/carpool_bloc.dart';
import '../bloc/carpool_event.dart';
import '../bloc/carpool_state.dart';
import '../widgets/carpool_booking_bar.dart';
import '../widgets/carpool_driver_card.dart';
import '../widgets/carpool_route_visualizer.dart';
import 'carpool_booking_success_page.dart';

/// Detail page for a single [CarpoolRide]. Reads [selectedRide] from [CarpoolBloc].
class CarpoolRideDetailPage extends StatelessWidget {
  const CarpoolRideDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CarpoolBloc, CarpoolState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status &&
          (curr.status == CarpoolStatus.booked ||
              curr.status == CarpoolStatus.error),
      listener: (context, state) {
        if (state.status == CarpoolStatus.booked &&
            state.selectedRide != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<CarpoolBloc>(),
                child: const CarpoolBookingSuccessPage(),
              ),
            ),
          );
        } else if (state.status == CarpoolStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(state.errorMessage ?? 'Booking failed. Try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      buildWhen: (prev, curr) =>
          prev.selectedRide != curr.selectedRide ||
          prev.selectedSeats != curr.selectedSeats ||
          prev.status != curr.status,
      builder: (context, state) {
        final ride = state.selectedRide;
        if (ride == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isBooking = state.status == CarpoolStatus.booking;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.background,
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // App bar with gradient
                    SliverAppBar(
                      expandedHeight: 120,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      leading: Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(60, 8, 16, 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ride Details',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ride.origin} → ${ride.destination}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withAlpha(200),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Route card
                          CarpoolRouteVisualizer(
                            origin: ride.origin,
                            destination: ride.destination,
                            distanceKm: ride.distanceKm,
                            departureTime: ride.departureTime,
                            date: ride.date,
                          ),
                          const SizedBox(height: 16),

                          // Driver card
                          CarpoolDriverCard(ride: ride),
                          const SizedBox(height: 16),

                          // Fare breakdown
                          _buildFareCard(context, isDark, state),
                          const SizedBox(height: 16),

                          // Amenities
                          _buildAmenitiesCard(context, isDark, ride.isAcAvailable),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              // Sticky booking bar
              CarpoolBookingBar(
                pricePerSeat: ride.pricePerSeat,
                selectedSeats: state.selectedSeats,
                maxSeats: ride.seatsAvailable,
                isBooking: isBooking,
                onSeatsChanged: (seats) => context
                    .read<CarpoolBloc>()
                    .add(CarpoolSeatCountChangedEvent(seats)),
                onBook: () => context.read<CarpoolBloc>().add(
                      BookCarpoolRideEvent(
                        rideId: ride.id,
                        seats: state.selectedSeats,
                      ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFareCard(
    BuildContext context,
    bool isDark,
    CarpoolState state,
  ) {
    final ride = state.selectedRide!;
    final total = ride.pricePerSeat * state.selectedSeats;

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
          Text(
            'Fare Breakdown',
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
          _fareRow(
            label: 'Price per seat',
            value: '₹${ride.pricePerSeat.toStringAsFixed(0)}',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _fareRow(
            label: 'Seats selected',
            value: '${state.selectedSeats}',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorderLight : AppColors.borderLight,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fareRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesCard(
    BuildContext context,
    bool isDark,
    bool isAcAvailable,
  ) {
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
          Text(
            'Amenities',
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _amenityBadge(
                icon: Icons.wifi_rounded,
                label: 'Luggage Space',
                isDark: isDark,
              ),
              _amenityBadge(
                icon: Icons.music_note_rounded,
                label: 'Music',
                isDark: isDark,
              ),
              if (isAcAvailable)
                _amenityBadge(
                  icon: Icons.ac_unit_rounded,
                  label: 'Air Conditioning',
                  isDark: isDark,
                  highlight: true,
                ),
              _amenityBadge(
                icon: Icons.pets_rounded,
                label: 'Pet Friendly',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amenityBadge({
    required IconData icon,
    required String label,
    required bool isDark,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF0EA5E9).withAlpha(20)
            : (isDark ? AppColors.darkBorderLight : AppColors.borderLight),
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(
                color: const Color(0xFF0EA5E9).withAlpha(80),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlight ? const Color(0xFF0EA5E9) : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: highlight
                  ? const Color(0xFF0EA5E9)
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
