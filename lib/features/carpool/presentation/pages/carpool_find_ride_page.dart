import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_find_ride_bloc.dart';

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
                          distanceKm: state.distanceKm,
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

/// Google Maps Route Card matching the exact screenshot
class _GoogleMapRouteCard extends StatelessWidget {
  final String from;
  final String to;
  final int distanceKm;

  const _GoogleMapRouteCard({
    required this.from,
    required this.to,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Pin Tip Anchors matching the exact route start and end points
            final startAnchor = Offset(w * 0.22, h * 0.33);
            final endAnchor = Offset(w * 0.82, h * 0.68);

            return Stack(
              children: [
                // 1. Authentic Google Maps Styled Canvas (Terrain, Roads, River & NH65 Polyline)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GoogleMapCanvasPainter(
                      startPt: startAnchor,
                      endPt: endAnchor,
                    ),
                  ),
                ),

                // 2. Floating Distance Badge (~ 275 km)
                Positioned(
                  top: h * 0.16,
                  left: w * 0.44,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '~ $distanceKm km',
                      style: const TextStyle(
                        color: Color(0xFF140D43),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),

                // 3. Hyderabad Pin (Blue Pin - Needle tip aligned at startAnchor)
                Positioned(
                  left: startAnchor.dx - 16,
                  top: startAnchor.dy - 36,
                  child: const _GoogleMapPin(
                    pinColor: Color(0xFF1A56DB),
                    shadowColor: Color(0x551A56DB),
                  ),
                ),

                // Hyderabad Label (Directly below the pin tip)
                Positioned(
                  left: startAnchor.dx - 55,
                  top: startAnchor.dy + 3,
                  width: 110,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        from,
                        style: const TextStyle(
                          color: Color(0xFF140D43),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Vijayawada Pin (Red Pin - Needle tip aligned at endAnchor)
                Positioned(
                  left: endAnchor.dx - 16,
                  top: endAnchor.dy - 36,
                  child: const _GoogleMapPin(
                    pinColor: Color(0xFFE53935),
                    shadowColor: Color(0x55E53935),
                  ),
                ),

                // Vijayawada Label (Directly below the pin tip)
                Positioned(
                  left: endAnchor.dx - 60,
                  top: endAnchor.dy + 3,
                  width: 120,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        to,
                        style: const TextStyle(
                          color: Color(0xFF140D43),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Subtle "Google" Watermark in bottom-left corner
                Positioned(
                  left: 10,
                  bottom: 6,
                  child: Text(
                    'Google',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B658C).withOpacity(0.40),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Classic Google Maps Teardrop Location Pin
class _GoogleMapPin extends StatelessWidget {
  final Color pinColor;
  final Color shadowColor;

  const _GoogleMapPin({required this.pinColor, required this.shadowColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 38,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Soft pin shadow underneath
          Transform.translate(
            offset: const Offset(0, 3),
            child: Icon(
              Icons.location_on_rounded,
              color: shadowColor,
              size: 38,
            ),
          ),
          // Colored Teardrop Pin
          Icon(Icons.location_on_rounded, color: pinColor, size: 36),
          // White Center Dot
          Positioned(
            top: 7,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vector Painter rendering authentic Google Maps terrain, roads, and highway route
class _GoogleMapCanvasPainter extends CustomPainter {
  final Offset startPt;
  final Offset endPt;

  const _GoogleMapCanvasPainter({required this.startPt, required this.endPt});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Google Maps base ivory/pale terrain background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF4F3ED),
    );

    // 2. Soft Green Field & Forest polygons (Telangana/Andhra countryside)
    final greenPaint1 = Paint()..color = const Color(0xFFD8EED1);
    final greenPaint2 = Paint()..color = const Color(0xFFE4F4DE);
    final greenPaint3 = Paint()..color = const Color(0xFFCEE8C4);

    // Green patch top left
    final p1 = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.44, 0)
      ..quadraticBezierTo(w * 0.36, h * 0.28, w * 0.18, h * 0.36)
      ..quadraticBezierTo(w * 0.05, h * 0.42, 0, h * 0.30)
      ..close();
    canvas.drawPath(p1, greenPaint1);

    // Green patch top right
    final p2 = Path()
      ..moveTo(w * 0.55, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.48)
      ..quadraticBezierTo(w * 0.85, h * 0.38, w * 0.72, h * 0.24)
      ..quadraticBezierTo(w * 0.62, h * 0.10, w * 0.55, 0)
      ..close();
    canvas.drawPath(p2, greenPaint2);

    // Green patch bottom left
    final p3 = Path()
      ..moveTo(0, h * 0.48)
      ..quadraticBezierTo(w * 0.20, h * 0.52, w * 0.28, h * 0.80)
      ..lineTo(w * 0.24, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p3, greenPaint2);

    // Green patch center bottom
    final p4 = Path()
      ..moveTo(w * 0.32, h)
      ..quadraticBezierTo(w * 0.40, h * 0.62, w * 0.60, h * 0.68)
      ..quadraticBezierTo(w * 0.75, h * 0.76, w * 0.86, h)
      ..close();
    canvas.drawPath(p4, greenPaint1);

    // Organic greenery patches
    canvas.drawOval(
      Rect.fromLTWH(w * 0.42, h * 0.10, w * 0.16, h * 0.16),
      greenPaint3,
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.08, h * 0.65, w * 0.16, h * 0.22),
      greenPaint3,
    );

    // 3. Water stream (Krishna / Musi River stream)
    final waterPaint = Paint()
      ..color = const Color(0xFFD0E4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(w * 0.10, 0)
      ..quadraticBezierTo(w * 0.18, h * 0.25, w * 0.12, h * 0.55)
      ..quadraticBezierTo(w * 0.05, h * 0.75, w * 0.15, h);
    canvas.drawPath(riverPath, waterPaint);

    // 4. Subtle Google Maps Local & Secondary Roads (White with faint borders)
    final roadBorder = Paint()
      ..color = const Color(0xFFE2E0D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final roadSurface = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    final roads = [
      // Diagonal road from top-left to bottom-right
      Path()
        ..moveTo(0, h * 0.18)
        ..quadraticBezierTo(w * 0.35, h * 0.22, w * 0.65, h * 0.85)
        ..lineTo(w * 0.75, h),
      // Horizontal cross road
      Path()
        ..moveTo(0, h * 0.62)
        ..quadraticBezierTo(w * 0.45, h * 0.58, w, h * 0.35),
      // Vertical road
      Path()
        ..moveTo(w * 0.38, 0)
        ..quadraticBezierTo(w * 0.32, h * 0.45, w * 0.45, h),
      // East road
      Path()
        ..moveTo(w * 0.70, 0)
        ..quadraticBezierTo(w * 0.78, h * 0.50, w, h * 0.82),
    ];

    for (final r in roads) {
      canvas.drawPath(r, roadBorder);
      canvas.drawPath(r, roadSurface);
    }

    // Yellow State Highway
    final yellowHighway = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final stateHwy = Path()
      ..moveTo(w * 0.20, 0)
      ..quadraticBezierTo(w * 0.45, h * 0.32, w, h * 0.50);
    canvas.drawPath(stateHwy, yellowHighway);

    // 5. Active Google Maps Highway Route (NH65: Hyderabad -> Vijayawada)
    // Connecting startPt and endPt with realistic highway segments
    final routePath = Path()
      ..moveTo(startPt.dx, startPt.dy)
      ..lineTo(w * 0.27, h * 0.32)
      ..lineTo(w * 0.33, h * 0.35)
      ..lineTo(w * 0.40, h * 0.38)
      ..lineTo(w * 0.48, h * 0.45)
      ..lineTo(w * 0.56, h * 0.51)
      ..lineTo(w * 0.65, h * 0.57)
      ..lineTo(w * 0.74, h * 0.63)
      ..lineTo(endPt.dx, endPt.dy);

    // Outer dark-blue casing for high definition
    final routeCasing = Paint()
      ..color = const Color(0xFF0F3182)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, routeCasing);

    // Main vibrant Google Maps Royal Blue Route line
    final routeLine = Paint()
      ..color = const Color(0xFF1A56DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, routeLine);

    // Highway Directional Waypoint Dots
    final dotPaint = Paint()..color = Colors.white;
    for (final metric in routePath.computeMetrics()) {
      final len = metric.length;
      for (double d = len * 0.18; d < len * 0.88; d += len * 0.20) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 2.0, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GoogleMapCanvasPainter old) =>
      old.startPt != startPt || old.endPt != endPt;
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
