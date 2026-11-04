import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import '../widgets/real_google_map_preview.dart';
import 'carpool_ride_published_page.dart';

/// Clean Architecture Route Summary & Booking Confirmation Screen.
/// - Top half: Authentic Google Maps route canvas showing from & to distance and pins.
/// - Bottom half: Card with from & to locations, date & time, seat booking,
///   distance-based price breakdown (₹10/km), and Confirm Booking button.
class CarpoolRideSummaryPage extends StatelessWidget {
  final CarpoolOfferRideBloc? bloc;

  const CarpoolRideSummaryPage({super.key, this.bloc});

  /// Navigates to [CarpoolRideSummaryPage] sharing the given [CarpoolOfferRideBloc].
  static Future<void> show(BuildContext context, CarpoolOfferRideBloc bloc) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: CarpoolRideSummaryPage(bloc: bloc),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(value: bloc!, child: const _RideSummaryView());
    }

    try {
      context.read<CarpoolOfferRideBloc>();
      return const _RideSummaryView();
    } catch (_) {
      final remoteDataSource = CarpoolMockDataSource();
      final repository = CarpoolRepositoryImpl(remoteDataSource);
      return BlocProvider(
        create: (_) => CarpoolOfferRideBloc(
          publishRide: CarpoolPublishRideUseCase(repository),
        ),
        child: const _RideSummaryView(),
      );
    }
  }
}

class _RideSummaryView extends StatefulWidget {
  const _RideSummaryView();

  @override
  State<_RideSummaryView> createState() => _RideSummaryViewState();
}

class _RideSummaryViewState extends State<_RideSummaryView> {
  DistanceResult? _liveDistanceResult;
  String? _lastFrom;
  String? _lastTo;
  bool _isMapFullscreen = false;

  void _fetchDistance(String from, String to) {
    if (_lastFrom == from && _lastTo == to) return;
    _lastFrom = from;
    _lastTo = to;

    CarpoolDistanceCalculator.fetchLiveDistance(from, to).then((res) {
      if (mounted) {
        setState(() {
          _liveDistanceResult = res;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CarpoolOfferRideBloc, CarpoolOfferRideState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, s) {
        if (s.status == CarpoolStatus.success && s.publishedRide != null) {
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CarpoolRidePublishedPage(ride: s.publishedRide!),
            ),
          );
        } else if (s.status == CarpoolStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.error ?? 'Could not confirm booking')),
          );
        }
      },
      builder: (context, s) {
        _fetchDistance(s.from, s.to);

        final bloc = context.read<CarpoolOfferRideBloc>();
        final screenHeight = MediaQuery.of(context).size.height;
        final mapHeight = _isMapFullscreen
            ? screenHeight * 0.78
            : screenHeight * 0.44;

        // Pricing logic: ₹10 per km as requested
        const int ratePerKm = 10;
        final int activeDistanceKm = s.selectedStopovers.isNotEmpty
            ? CarpoolDistanceCalculator.calculateMultiStopDistance(
                s.from,
                s.to,
                s.selectedStopovers.toList(),
                startLat: s.fromLat,
                startLng: s.fromLng,
                destLat: s.toLat,
                destLng: s.toLng,
              )
            : (_liveDistanceResult?.distanceKm ??
                  CarpoolDistanceCalculator.calculateDistanceKm(
                    s.from,
                    s.to,
                    fromLat: s.fromLat,
                    fromLng: s.fromLng,
                    toLat: s.toLat,
                    toLng: s.toLng,
                  ));
        final int distanceKm = activeDistanceKm;
        final int calculatedTotalPrice = distanceKm * ratePerKm;
        final int calculatedPricePerSeat =
            (calculatedTotalPrice / (s.seats > 0 ? s.seats : 1)).round();
        final int effectivePricePerSeat =
            s.pricePerSeat ?? calculatedPricePerSeat;
        final int effectiveTotalPrice = effectivePricePerSeat * s.seats;
        final int totalPrice = effectiveTotalPrice;
        final int pricePerSeat = effectivePricePerSeat;
        final String durationText =
            _liveDistanceResult?.durationText ??
            CarpoolDistanceCalculator.estimateDuration(distanceKm);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F6FD),
          body: Stack(
            children: [
              // ══════════════════════════════════════════════════════════════
              // TOP HALF: GOOGLE MAP WITH ROUTE, DISTANCE & PINS
              // ══════════════════════════════════════════════════════════════
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                top: 0,
                left: 0,
                right: 0,
                height: mapHeight,
                child: RealGoogleMapPreview(
                  from: s.from,
                  to: s.to,
                  fromLat: s.fromLat,
                  fromLng: s.fromLng,
                  toLat: s.toLat,
                  toLng: s.toLng,
                  distanceKm: distanceKm,
                  durationText: durationText,
                  isExpanded: _isMapFullscreen,
                  onToggleExpand: () {
                    setState(() {
                      _isMapFullscreen = !_isMapFullscreen;
                    });
                  },
                ),
              ),

              // ══════════════════════════════════════════════════════════════
              // TOP APP BAR OVERLAY ON MAP (Back button & Title)
              // ══════════════════════════════════════════════════════════════
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF140D43),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 14,
                        //     vertical: 8,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withOpacity(0.92),
                        //     borderRadius: BorderRadius.circular(20),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: Colors.black.withOpacity(0.08),
                        //         blurRadius: 8,
                        //         offset: const Offset(0, 2),
                        //       ),
                        //     ],
                        //   ),
                        //   child: const Text(
                        //     'Route & Ride Summary',
                        //     style: TextStyle(
                        //       fontSize: 15.5,
                        //       fontWeight: FontWeight.w800,
                        //       color: Color(0xFF140D43),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),

              // ══════════════════════════════════════════════════════════════
              // BOTTOM HALF: RIDE DETAILS, SEAT BOOKING & PRICING CARD
              // ══════════════════════════════════════════════════════════════
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                top: mapHeight - 24,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B3BF5).withOpacity(0.10),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Little Drag Handle with interactive flexible toggle
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _isMapFullscreen = !_isMapFullscreen;
                          });
                        },
                        onVerticalDragEnd: (details) {
                          final v = details.primaryVelocity ?? 0;
                          if (v > 100 && !_isMapFullscreen) {
                            setState(() => _isMapFullscreen = true);
                          } else if (v < -100 && _isMapFullscreen) {
                            setState(() => _isMapFullscreen = false);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 4.5,
                                margin: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6CEF8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isMapFullscreen
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: const Color(0xFF5B3BF5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isMapFullscreen
                                        ? "Tap to View Ride Details"
                                        : "Swipe down or tap for Flexible Map",
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5B3BF5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scrollable Details Body
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          children: [
                            // ── 1. Route Locations Card ─────────────────────
                            _buildRouteCard(
                              s.from,
                              s.to,
                              distanceKm,
                              durationText,
                              stopovers: s.selectedStopovers.toList(),
                            ),

                            const SizedBox(height: 14),

                            // ── 2. Date & Time Row ──────────────────────────
                            _buildDateTimeRow(s.departure),

                            const SizedBox(height: 14),

                            // ── 3. Number of Seats Booking ──────────────────
                            _buildSeatsBookingRow(s.seats, bloc),

                            const SizedBox(height: 16),

                            // ── 4. Distance & Price Calculation (₹10/km) ────
                            // _buildPriceCalculationCard(
                            //   distanceKm: distanceKm,
                            //   ratePerKm: ratePerKm,
                            //   totalPrice: totalPrice,
                            //   pricePerSeat: pricePerSeat,
                            //   seats: s.seats,
                            // ),
                            _buildPriceMarginRow(
                              pricePerSeat: effectivePricePerSeat,
                              totalPrice: effectiveTotalPrice,
                              distanceKm: distanceKm,
                              ratePerKm: ratePerKm,
                              bloc: bloc,
                            ),
                            const SizedBox(height: 18),

                            // ── 5. Confirm Booking Button ───────────────────
                            _buildConfirmBookingButton(
                              isLoading: s.status == CarpoolStatus.loading,
                              onPressed: () =>
                                  bloc.add(const CarpoolOfferPublishPressed()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Estimates travel duration based on distance
  // String _estimateDuration(int distanceKm) {
  //   final totalMinutes = (distanceKm / 65 * 60).round();
  //   final hours = totalMinutes ~/ 60;
  //   final mins = totalMinutes % 60;
  //   if (hours > 0) {
  //     return '$hours hr ${mins > 0 ? '$mins min' : ''}';
  //   }
  //   return '$mins min';
  // }

  /// Builds the Route From & To display card with accurate Google Map styling
  Widget _buildRouteCard(
    String from,
    String to,
    int distanceKm,
    String duration, {
    List<String> stopovers = const [],
  }) {
    final fromGeo = CarpoolDistanceCalculator.findGeo(from);
    final toGeo = CarpoolDistanceCalculator.findGeo(to);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3BF5).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Google Maps Route Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Color(0xFF1A73E8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Google Maps Route',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF140D43),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$distanceKm km • $duration',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Pick-up (From) Row with Google Maps Blue Pin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A56DB).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.circle,
                  color: Color(0xFF1A56DB),
                  size: 11,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PICK-UP LOCATION',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B658C),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      from,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF140D43),
                      ),
                    ),
                    if (fromGeo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        fromGeo.subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (stopovers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Container(
                width: 2,
                height: 10,
                color: const Color(0xFF1A73E8),
              ),
            ),
            for (final stop in stopovers) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF5D24F7),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          stop,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF140D43),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Stopover',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4C2BF0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Container(
                  width: 2,
                  height: 10,
                  color: const Color(0xFF1A73E8),
                ),
              ),
            ],
          ] else ...[
            // Connecting Highway Line with Route Tag
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const SizedBox(width: 11),
                  Container(
                    width: 2,
                    height: 22,
                    color: const Color(0xFF1A73E8),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE8FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Fastest Highway Route',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3815D8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Drop-off (To) Row with Google Maps Red Pin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFE53935),
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DROP-OFF LOCATION',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B658C),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      to,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF140D43),
                      ),
                    ),
                    if (toGeo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        toGeo.subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the Date & Time Row with rounded info pills
  Widget _buildDateTimeRow(DateTime departure) {
    return Row(
      children: [
        // Date Pill
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF3815D8),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                      Text(
                        CarpoolFormatters.date(departure),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Time Pill
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF3815D8),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                      Text(
                        CarpoolFormatters.time(departure),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the Seats Booking Row with Stepper
  Widget _buildSeatsBookingRow(int seats, CarpoolOfferRideBloc bloc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_seat_rounded,
            color: Color(0xFF3815D8),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seats Available / Booking',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF140D43),
                  ),
                ),
                Text(
                  'Select number of passenger seats',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B658C),
                  ),
                ),
              ],
            ),
          ),
          // Stepper
          Row(
            children: [
              _StepperBtn(
                icon: Icons.remove_rounded,
                onTap: () => bloc.add(const CarpoolOfferSeatsChanged(-1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$seats',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF140D43),
                  ),
                ),
              ),
              _StepperBtn(
                icon: Icons.add_rounded,
                onTap: () => bloc.add(const CarpoolOfferSeatsChanged(1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the Price Margin Row matching the exact style of [_buildSeatsBookingRow]
  Widget _buildPriceMarginRow({
    required int pricePerSeat,
    required int totalPrice,
    required int distanceKm,
    required int ratePerKm,
    required CarpoolOfferRideBloc bloc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.currency_rupee_rounded,
            color: Color(0xFF3815D8),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price per Seat / Margin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF140D43),
                  ),
                ),
                // Text(
                //   '₹$ratePerKm/km ($distanceKm km) • Total: ₹$totalPrice',
                //   maxLines: 1,
                //   overflow: TextOverflow.ellipsis,
                //   style: const TextStyle(
                //     fontSize: 11.5,
                //     fontWeight: FontWeight.w500,
                //     color: Color(0xFF6B658C),
                //   ),
                // ),
              ],
            ),
          ),
          // Price Stepper in the exact style of seats stepper
          Row(
            children: [
              _StepperBtn(
                icon: Icons.remove_rounded,
                onTap: () => bloc.add(
                  CarpoolOfferPriceChanged(-10, currentBasePrice: pricePerSeat),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '₹$pricePerSeat',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF140D43),
                  ),
                ),
              ),
              _StepperBtn(
                icon: Icons.add_rounded,
                onTap: () => bloc.add(
                  CarpoolOfferPriceChanged(10, currentBasePrice: pricePerSeat),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the Price & Distance breakdown card at ₹10/km
  // Widget _buildPriceCalculationCard({
  //   required int distanceKm,
  //   required int ratePerKm,
  //   required int totalPrice,
  //   required int pricePerSeat,
  //   required int seats,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFF4F1FD),
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: const Color(0xFFE2DCF9), width: 1.3),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Row(
  //           children: [
  //             Icon(
  //               Icons.receipt_long_rounded,
  //               color: Color(0xFF3815D8),
  //               size: 20,
  //             ),
  //             SizedBox(width: 8),
  //             Text(
  //               'Price & Fare Breakdown',
  //               style: TextStyle(
  //                 fontSize: 14.5,
  //                 fontWeight: FontWeight.w800,
  //                 color: Color(0xFF140D43),
  //               ),
  //             ),
  //             Spacer(),
  //             // Rate badge: 10 ₹/km
  //             _RateBadge(rateText: '₹10 / km'),
  //           ],
  //         ),
  //         const SizedBox(height: 12),

  //         // Distance row
  //         _buildFareRow('Estimated Distance', '$distanceKm km'),
  //         const SizedBox(height: 6),

  //         // Rate per km row
  //         _buildFareRow('Rate per Kilometer', '₹$ratePerKm / km'),
  //         const SizedBox(height: 6),

  //         // Calculation row
  //         _buildFareRow(
  //           'Distance Fare ($distanceKm km × ₹$ratePerKm)',
  //           '₹$totalPrice',
  //         ),
  //         const SizedBox(height: 6),

  //         // Per seat estimate
  //         // _buildFareRow('Price per Seat ($seats seats)', '₹$pricePerSeat / seat'),
  //         const Divider(height: 16, thickness: 1, color: Color(0xFFE2DCF9)),

  //         // Total Fare Highlight Row
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             const Text(
  //               'Total Price',
  //               style: TextStyle(
  //                 fontSize: 15.5,
  //                 fontWeight: FontWeight.w800,
  //                 color: Color(0xFF140D43),
  //               ),
  //             ),
  //             Text(
  //               '₹$totalPrice',
  //               style: const TextStyle(
  //                 fontSize: 22,
  //                 fontWeight: FontWeight.w900,
  //                 color: Color(0xFF3815D8),
  //                 letterSpacing: -0.5,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFareRow(String title, String value) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Text(
  //         title,
  //         style: const TextStyle(
  //           fontSize: 12.5,
  //           fontWeight: FontWeight.w500,
  //           color: Color(0xFF6B658C),
  //         ),
  //       ),
  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontSize: 13,
  //           fontWeight: FontWeight.w700,
  //           color: Color(0xFF140D43),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  /// Builds the Confirm Booking Gradient Button
  Widget _buildConfirmBookingButton({
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D24F7), Color(0xFF300AB3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.38),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Confirm Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Rate badge pill indicating ₹10 / km
class _RateBadge extends StatelessWidget {
  final String rateText;
  const _RateBadge({required this.rateText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
      ),
      child: Text(
        rateText,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF15803D),
        ),
      ),
    );
  }
}

/// Stepper Button (+ / -)
class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2DCF9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B3BF5).withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0xFF3815D8)),
      ),
    );
  }
}
