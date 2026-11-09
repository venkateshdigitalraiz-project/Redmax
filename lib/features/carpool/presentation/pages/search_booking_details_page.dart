import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/carpool_formatters.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../data/repositories/search_booking_details_repository_impl.dart';
import '../../data/repositories/search_booking_rider_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/search_booking_details_entity.dart';
import '../../domain/usecases/get_search_booking_details_usecase.dart';
import '../../domain/usecases/search_booking_rider_usecases.dart';
import '../bloc/search_booking_details_bloc.dart';

/// Aliases to support exact user naming conventions: `searchbookingdetails`
typedef searchbookingdetails = SearchBookingDetailsPage;
typedef SearchBookingDetails = SearchBookingDetailsPage;

class SearchBookingDetailsPage extends StatelessWidget {
  final String rideId;
  final CarpoolRideEntity? initialRide;

  const SearchBookingDetailsPage({
    super.key,
    required this.rideId,
    this.initialRide,
  });

  /// Static helper to open the details page cleanly
  static Future<bool?> show(
    BuildContext context, {
    required String rideId,
    CarpoolRideEntity? initialRide,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            SearchBookingDetailsPage(rideId: rideId, initialRide: initialRide),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = SearchBookingDetailsRepositoryImpl();
    return BlocProvider<SearchBookingDetailsBloc>(
      create: (_) => SearchBookingDetailsBloc(
        getRideDetails: GetSearchBookingDetailsUseCase(repo),
      )..add(SearchBookingDetailsStarted(rideId)),
      child: _SearchBookingDetailsView(
        rideId: rideId,
        initialRide: initialRide,
      ),
    );
  }
}

class _SearchBookingDetailsView extends StatefulWidget {
  final String rideId;
  final CarpoolRideEntity? initialRide;

  const _SearchBookingDetailsView({required this.rideId, this.initialRide});

  @override
  State<_SearchBookingDetailsView> createState() =>
      _SearchBookingDetailsViewState();
}

class _SearchBookingDetailsViewState extends State<_SearchBookingDetailsView> {
  bool _isBooking = false;

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    await Clipboard.setData(ClipboardData(text: cleanPhone));
    _snack('Phone number $cleanPhone copied to clipboard');
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF5D24F7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _confirmBooking(
    SearchBookingDetailsEntity ride,
    int seats,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.airline_seat_recline_normal_rounded,
                color: Color(0xFF5D24F7),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Seat Booking',
                style: TextStyle(
                  color: Color(0xFF140D43),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ride.cleanOrigin} → ${ride.cleanDestination}',
              style: const TextStyle(
                color: Color(0xFF140D43),
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CarpoolFormatters.headline(ride.departureTime),
              style: const TextStyle(
                color: Color(0xFF5D24F7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8FE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDE8FF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$seats seat(s) × ₹${ride.pricePerSeat}',
                    style: const TextStyle(
                      color: Color(0xFF6B658C),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CarpoolFormatters.rupee(ride.pricePerSeat * seats),
                    style: const TextStyle(
                      color: Color(0xFF5D24F7),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B658C)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D24F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Book Now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isBooking = true);
      try {
        final riderRepo = SearchBookingRiderRepositoryImpl();
        final carpoolEntity = CarpoolRideEntity(
          id: ride.id,
          driverName: ride.driver.name,
          driverRating: ride.driver.rating,
          driverTrips: ride.driver.totalTrips,
          vehicle: ride.vehicleTitle,
          from: ride.cleanOrigin,
          to: ride.cleanDestination,
          departure: ride.departureTime,
          seats: ride.availableSeats,
          pricePerSeat: ride.pricePerSeat,
          distanceKm: 268,
          status: CarpoolRideStatus.upcoming,
          rideType: CarpoolRideType.normal,
        );
        await BookRiderSeatUseCase(
          riderRepo,
        ).call(ride: carpoolEntity, seats: seats);

        if (mounted) {
          _snack('Seat booked successfully! OTP code generated.');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          _snack('Booking failed: $e', isError: true);
        }
      } finally {
        if (mounted) setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDE8FF),
              Color(0xFFF7F5FE),
              Color(0xFFFAFAFF),
              Colors.white,
            ],
            stops: [0.0, 0.22, 0.60, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: BlocConsumer<SearchBookingDetailsBloc, SearchBookingDetailsState>(
            listener: (context, state) {
              if (state.errorMessage != null &&
                  state.errorMessage!.isNotEmpty) {
                _snack(state.errorMessage!, isError: true);
              }
            },
            builder: (context, state) {
              final ride = state.ride;

              return Column(
                children: [
                  // 1. Top App Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFEDE8FF),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4C1CDD,
                                  ).withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF140D43),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ride Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF140D43),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: #${widget.rideId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B658C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFA7F3D0),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: Color(0xFF059669),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Main Content
                  Expanded(
                    child: state.status == CarpoolStatus.loading && ride == null
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF5D24F7),
                                  strokeWidth: 3,
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Loading ride details…',
                                  style: TextStyle(
                                    color: Color(0xFF6B658C),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ride == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Could not load ride details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF140D43),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5D24F7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () => context
                                        .read<SearchBookingDetailsBloc>()
                                        .add(
                                          SearchBookingDetailsStarted(
                                            widget.rideId,
                                          ),
                                        ),
                                    child: const Text(
                                      'Retry',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // ── Route & Timeline Card ────────────────────────
                              _buildRouteCard(ride),
                              const SizedBox(height: 14),

                              // ── Departure Time Card ──────────────────────────
                              _buildTimeCard(ride),
                              const SizedBox(height: 14),

                              // ── Driver Profile Card ──────────────────────────
                              _buildDriverCard(ride),
                              const SizedBox(height: 14),

                              // ── Vehicle & Notes Card ─────────────────────────
                              _buildVehicleNotesCard(ride),
                              const SizedBox(height: 14),

                              // ── Seat Selector & Fare Summary ─────────────────
                              _buildFareSummaryCard(context, state, ride),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      // 3. Floating Bottom Action Button
      bottomNavigationBar:
          BlocBuilder<SearchBookingDetailsBloc, SearchBookingDetailsState>(
            builder: (context, state) {
              final ride = state.ride;
              if (ride == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF140D43).withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.selectedSeats} Seat${state.selectedSeats > 1 ? 's' : ''} Total',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B658C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CarpoolFormatters.rupee(state.totalAmount),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5D24F7),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5D24F7), Color(0xFF3815D8)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4C1CDD).withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(26),
                            onTap: _isBooking
                                ? null
                                : () => _confirmBooking(
                                    ride,
                                    state.selectedSeats,
                                  ),
                            child: Center(
                              child: _isBooking
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: Colors.white,
                                          size: 19,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Confirm & Book Seat',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  /// Route Card displaying Origin and Destination with live Lat/Lng badges
  Widget _buildRouteCard(SearchBookingDetailsEntity ride) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  size: 16,
                  color: Color(0xFF5D24F7),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Route Information',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF140D43),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Highway Drive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D24F7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline: Pickup -> Dropoff
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indicators
                Column(
                  children: [
                    const SizedBox(height: 2),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: const Color(0xFFDDD6FE),
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.4),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
                const SizedBox(width: 12),

                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Pickup
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PICKUP POINT',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            ride.cleanOrigin,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF140D43),
                            ),
                          ),
                          if (ride.originLat != 0.0 && ride.originLng != 0.0)
                            Text(
                              'GPS: ${ride.originLat.toStringAsFixed(4)}, ${ride.originLng.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8B85A8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Dropoff
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DROPOFF POINT',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEF4444),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            ride.cleanDestination,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF140D43),
                            ),
                          ),
                          if (ride.destinationLat != 0.0 &&
                              ride.destinationLng != 0.0)
                            Text(
                              'GPS: ${ride.destinationLat.toStringAsFixed(4)}, ${ride.destinationLng.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8B85A8),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Departure Date & Time Card
  Widget _buildTimeCard(SearchBookingDetailsEntity ride) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.access_time_filled_rounded,
              color: Color(0xFF5D24F7),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Departure Schedule',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B658C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CarpoolFormatters.headline(ride.departureTime),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF140D43),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.airline_seat_recline_normal_rounded,
                  size: 15,
                  color: Color(0xFF5D24F7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${ride.availableSeats} Left',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D24F7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Driver Card with Rating, Phone Call button, and Verified Status
  Widget _buildDriverCard(SearchBookingDetailsEntity ride) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEDE8FF),
                child: Text(
                  ride.driver.name.isNotEmpty ? ride.driver.name[0] : 'D',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5D24F7),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driver.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF140D43),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${ride.driver.rating}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF140D43),
                          ),
                        ),
                        if (ride.driver.totalTrips > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${ride.driver.totalTrips} trips',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B658C),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Call Button
              if (ride.driver.phone.isNotEmpty)
                GestureDetector(
                  onTap: () => _makePhoneCall(ride.driver.phone),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFA7F3D0),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          if (ride.driver.phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_iphone_rounded,
                    size: 14,
                    color: Color(0xFF6B658C),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Phone: ${ride.driver.phone}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF140D43),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Tap to dial',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D24F7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Vehicle Info and Notes Card
  Widget _buildVehicleNotesCard(SearchBookingDetailsEntity ride) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 20,
                  color: Color(0xFF5D24F7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.vehicleModel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF140D43),
                      ),
                    ),
                    if (ride.vehicleNumber.isNotEmpty)
                      Text(
                        ride.vehicleNumber,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Notes / Passenger Instructions
          if (ride.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFD97706),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ride Notes & Instructions',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride.notes,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF78350F),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Seat Selector & Fare Summary Card
  Widget _buildFareSummaryCard(
    BuildContext context,
    SearchBookingDetailsState state,
    SearchBookingDetailsEntity ride,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seat Reservation & Pricing',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF140D43),
            ),
          ),
          const SizedBox(height: 14),

          // Stepper for selecting seats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seats to Book',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF140D43),
                    ),
                  ),
                  Text(
                    'Max ${ride.availableSeats} seat(s) available',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B658C),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5FE),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_rounded,
                        color: Color(0xFF5D24F7),
                        size: 20,
                      ),
                      onPressed: state.selectedSeats > 1
                          ? () => context.read<SearchBookingDetailsBloc>().add(
                              SearchBookingDetailsSeatsChanged(
                                state.selectedSeats - 1,
                              ),
                            )
                          : null,
                    ),
                    Text(
                      '${state.selectedSeats}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF140D43),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF5D24F7),
                        size: 20,
                      ),
                      onPressed: state.selectedSeats < ride.availableSeats
                          ? () => context.read<SearchBookingDetailsBloc>().add(
                              SearchBookingDetailsSeatsChanged(
                                state.selectedSeats + 1,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEDE8FF), height: 1),
          const SizedBox(height: 12),

          // Price per seat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price per seat',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B658C),
                ),
              ),
              Text(
                '${CarpoolFormatters.rupee(ride.pricePerSeat)} / seat',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF140D43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total Fare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable Fare',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF140D43),
                ),
              ),
              Text(
                CarpoolFormatters.rupee(state.totalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5D24F7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
