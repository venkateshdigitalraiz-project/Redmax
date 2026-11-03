import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_find_ride_bloc.dart';
import '../widgets/carpool_route_selector_card.dart';
import '../widgets/real_google_map_preview.dart';

/// CarpoolFindRidePage - Matches screenshot design:
/// 1. Lavender gradient background.
/// 2. Top bar: Back arrow, "Find a Ride" title, and right tune/filter icon.
/// 3. Filter Pills: "Today" (royal purple gradient with glow shadow), "Tomorrow", "Any Time".
/// 4. Google Maps Route Card:
///    - Google Maps styled terrain with greenery, roads, rivers, and highway NH65.
///    - Royal Blue pin at Hyderabad and Bright Red pin at Vijayawada.
///    - Highway route line with directional markers.
///    - Floating white distance pill "~ 275 km".
/// 5. Ride Result Cards:
///    - Driver avatar, name, rating (trips), vehicle, seats count, favorite heart, price/seat.
///    - Full-width royal purple gradient "Book Ride" pill button.
/// 6. Screen fit: Clean scrolling with no overflows on any device.
class CarpoolFindRidePage extends StatelessWidget {
  final CarpoolFindRideBloc? bloc;

  const CarpoolFindRidePage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(value: bloc!, child: const _FindRideView());
    }
    try {
      context.read<CarpoolFindRideBloc>();
      return const _FindRideView();
    } catch (_) {
      final remoteDataSource = CarpoolMockDataSource();
      final repository = CarpoolRepositoryImpl(remoteDataSource);
      return BlocProvider(
        create: (_) => CarpoolFindRideBloc(
          searchRides: CarpoolSearchRidesUseCase(repository),
          bookRide: CarpoolBookRideUseCase(repository),
        )..add(const CarpoolFindRideFilterChanged(CarpoolDayFilter.today)),
        child: const _FindRideView(),
      );
    }
  }
}

class _FindRideView extends StatefulWidget {
  const _FindRideView();

  @override
  State<_FindRideView> createState() => _FindRideViewState();
}

class _FindRideViewState extends State<_FindRideView> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<CarpoolFindRideBloc>();
    if (bloc.state.rides.isEmpty) {
      bloc.add(const CarpoolFindRideFilterChanged(CarpoolDayFilter.today));
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
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
            colors: [Color(0xFFEDE8FF), Color(0xFFF7F5FE), Colors.white],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: BlocConsumer<CarpoolFindRideBloc, CarpoolFindRideState>(
            listenWhen: (p, c) => c.message != null && p.message != c.message,
            listener: (context, state) => _snack(state.message!),
            builder: (context, state) {
              return Column(
                children: [
                  // 1. Top Bar: Back arrow, "Find a Ride" title, and tune icon
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF140D43),
                              size: 26,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Find a Ride',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF140D43),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _snack('Route filter options'),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF140D43),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Filter Pills: "Today", "Tomorrow", "Any Time"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterPill(
                            label: 'Today',
                            isSelected: state.filter == CarpoolDayFilter.today,
                            onTap: () =>
                                context.read<CarpoolFindRideBloc>().add(
                                  const CarpoolFindRideFilterChanged(
                                    CarpoolDayFilter.today,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterPill(
                            label: 'Tomorrow',
                            isSelected:
                                state.filter == CarpoolDayFilter.tomorrow,
                            onTap: () =>
                                context.read<CarpoolFindRideBloc>().add(
                                  const CarpoolFindRideFilterChanged(
                                    CarpoolDayFilter.tomorrow,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterPill(
                            label: 'Any Time',
                            isSelected:
                                state.filter == CarpoolDayFilter.anyTime,
                            onTap: () =>
                                context.read<CarpoolFindRideBloc>().add(
                                  const CarpoolFindRideFilterChanged(
                                    CarpoolDayFilter.anyTime,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Scrollable Content: Google Maps Route + Ride Cards
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        // Google Maps Route Card
                        _GoogleMapRouteCard(
                          from: state.from,
                          to: state.to,
                          fromLat: state.fromLat,
                          fromLng: state.fromLng,
                          toLat: state.toLat,
                          toLng: state.toLng,
                          distanceKm: state.distanceKm,
                          onFromTap: () async {
                            final v = await carpoolSelectLocation(
                              context,
                              title: 'Search Pickup Location',
                              initialValue: state.from,
                              isPickup: true,
                            );
                            if (v != null && v.name.trim().isNotEmpty) {
                              context.read<CarpoolFindRideBloc>().add(
                                CarpoolFindRideRouteSelected(
                                  v.name.trim(),
                                  state.to,
                                  fromLat: v.lat,
                                  fromLng: v.lng,
                                  toLat: state.toLat,
                                  toLng: state.toLng,
                                ),
                              );
                            }
                          },
                          onToTap: () async {
                            final v = await carpoolSelectLocation(
                              context,
                              title: 'Search Drop Location',
                              initialValue: state.to,
                              isPickup: false,
                            );
                            if (v != null && v.name.trim().isNotEmpty) {
                              context.read<CarpoolFindRideBloc>().add(
                                CarpoolFindRideRouteSelected(
                                  state.from,
                                  v.name.trim(),
                                  fromLat: state.fromLat,
                                  fromLng: state.fromLng,
                                  toLat: v.lat,
                                  toLng: v.lng,
                                ),
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Search Results / Ride Cards
                        if (state.rides.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No rides found on this route.\nTry another day or time.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF6B658C),
                                  fontSize: 14.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        else
                          for (final ride in state.rides)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _RideCard(
                                ride: ride,
                                isFavorite: state.favorites.contains(ride.id),
                                isBooking: state.bookingId == ride.id,
                                onFavorite: () =>
                                    context.read<CarpoolFindRideBloc>().add(
                                      CarpoolFindRideFavoriteToggled(ride.id),
                                    ),
                                onBook: () => context
                                    .read<CarpoolFindRideBloc>()
                                    .add(CarpoolFindRideBookPressed(ride)),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Filter pill button with active gradient and soft glow shadow
class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6F35FF), Color(0xFF3309B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFEBE6FC),
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4C1CDD).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF140D43),
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}

/// Google Maps Route Card powered by RealGoogleMapPreview
class _GoogleMapRouteCard extends StatelessWidget {
  final String from;
  final String to;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final int distanceKm;
  final VoidCallback? onFromTap;
  final VoidCallback? onToTap;

  const _GoogleMapRouteCard({
    required this.from,
    required this.to,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.distanceKm,
    this.onFromTap,
    this.onToTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3BF5).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 1. Slippy Real Google Map with Route Polyline, Google Pins & Zoom Controls
            Positioned.fill(
              child: RealGoogleMapPreview(
                from: from,
                to: to,
                fromLat: fromLat,
                fromLng: fromLng,
                toLat: toLat,
                toLng: toLng,
                distanceKm: distanceKm,
                durationText: CarpoolDistanceCalculator.estimateDuration(
                  distanceKm,
                ),
                isCompact: true,
              ),
            ),

            // 2. Interactive Route Locations Bar (Bottom Card with quick tap-to-change)
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEDE8FF),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // From chip
                    Expanded(
                      child: InkWell(
                        onTap: onFromTap,
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1976D2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                from,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF6B658C),
                      ),
                    ),
                    // To chip
                    Expanded(
                      child: InkWell(
                        onTap: onToTap,
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Color(0xFFD93025),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                to,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



/// Ride Card matching screenshot precisely
class _RideCard extends StatelessWidget {
  final CarpoolRideEntity ride;
  final bool isFavorite;
  final bool isBooking;
  final VoidCallback onFavorite;
  final VoidCallback onBook;

  const _RideCard({
    required this.ride,
    required this.isFavorite,
    required this.isBooking,
    required this.onFavorite,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = ride.driverName.contains('Ramesh')
        ? 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?fit=crop&w=150&h=150'
        : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=150&h=150';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3BF5).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top Row: Avatar, Info, Favorite Heart, Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Avatar
              ClipOval(
                child: Image.network(
                  photoUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFEBE6FC),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF3815D8),
                      size: 32,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Driver Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName,
                      style: const TextStyle(
                        color: Color(0xFF140D43),
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${ride.driverRating}',
                          style: const TextStyle(
                            color: Color(0xFF140D43),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          ' (${ride.driverTrips} trips)',
                          style: const TextStyle(
                            color: Color(0xFF6B658C),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ride.vehicle,
                      style: const TextStyle(
                        color: Color(0xFF6B658C),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.group_rounded,
                          size: 17,
                          color: Color(0xFF6B658C),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${ride.seats} Seats',
                          style: const TextStyle(
                            color: Color(0xFF140D43),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Column: Heart Icon on Top, Price on Bottom
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: const Color(0xFF6F35FF),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  RichText(
                    text: TextSpan(
                      text: '₹${ride.pricePerSeat}',
                      style: const TextStyle(
                        color: Color(0xFF140D43),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                      children: const [
                        TextSpan(
                          text: '/seat',
                          style: TextStyle(
                            color: Color(0xFF6B658C),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Full-Width "Book Ride" Button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isBooking ? null : onBook,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6F35FF), Color(0xFF3309B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(23),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4C1CDD).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isBooking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Book Ride',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
