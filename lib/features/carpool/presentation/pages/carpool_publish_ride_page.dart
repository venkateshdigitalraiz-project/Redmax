import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import 'carpool_select_route_page.dart';
import 'carpool_stopovers_page.dart';

/// Screen "Publish a Ride" – matches the exact design screenshot:
/// 1. Top bar with clean back button, "Publish a Ride" title, and tune icon.
/// 2. Framed car illustration with curved organic bottom border.
/// 3. "Share Your Journey" header and subtitle.
/// 4. Pure white card with Date, Time, Route, and Seats Available stepper.
/// 5. Vibrant royal purple gradient "Publish Ride →" button.
class CarpoolPublishRidePage extends StatelessWidget {
  final CarpoolOfferRideBloc? bloc;

  const CarpoolPublishRidePage({super.key, this.bloc});

  /// Navigates to [CarpoolPublishRidePage] safely on the root navigator.
  static Future<void> show(BuildContext context, [CarpoolOfferRideBloc? bloc]) {
    final b =
        bloc ??
        () {
          try {
            return context.read<CarpoolOfferRideBloc>();
          } catch (_) {
            return null;
          }
        }();

    b?.add(const CarpoolOfferClearRoute());

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => b != null
            ? BlocProvider.value(
                value: b,
                child: CarpoolPublishRidePage(bloc: b),
              )
            : const CarpoolPublishRidePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(value: bloc!, child: const _PublishRideView());
    }

    try {
      context.read<CarpoolOfferRideBloc>();
      return const _PublishRideView();
    } catch (_) {
      final remoteDataSource = CarpoolMockDataSource();
      final repository = CarpoolRepositoryImpl(remoteDataSource);
      return BlocProvider(
        create: (_) => CarpoolOfferRideBloc(
          publishRide: CarpoolPublishRideUseCase(repository),
        ),
        child: const _PublishRideView(),
      );
    }
  }
}

class _PublishRideView extends StatefulWidget {
  const _PublishRideView();

  @override
  State<_PublishRideView> createState() => _PublishRideViewState();
}

class _PublishRideViewState extends State<_PublishRideView> {
  bool _isNavigating = false;
  bool _hasSelectedRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<CarpoolOfferRideBloc>();
        bloc.add(const CarpoolOfferResetStatus());
        bloc.add(const CarpoolOfferClearRoute());
      }
    });
  }

  Future<void> _onPublishPressed(
    BuildContext context,
    CarpoolOfferRideBloc bloc,
    CarpoolOfferRideState s,
  ) async {
    if (_isNavigating) return;

    final from = s.from.trim();
    final to = s.to.trim();

    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both pick-up and drop-off locations'),
          backgroundColor: Color(0xFF3815D8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await CarpoolSelectRoutePage.show(context, bloc);
      if (mounted) {
        final curState = bloc.state;
        if (curState.from.trim().isNotEmpty && curState.to.trim().isNotEmpty) {
          setState(() => _hasSelectedRoute = true);
        }
      }
      return;
    }

    if (from.toLowerCase() == to.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick-up and drop-off locations cannot be the same'),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      CarpoolSelectRoutePage.show(context, bloc);
      return;
    }

    setState(() => _isNavigating = true);

    // Resolve coordinates using unified resolveCoordinates helper
    final originCoords = CarpoolDistanceCalculator.resolveCoordinates(
      from,
      preferredLat: s.fromLat != 0.0 ? s.fromLat : null,
      preferredLng: s.fromLng != 0.0 ? s.fromLng : null,
      defaultLat: s.fromLat,
      defaultLng: s.fromLng,
    );
    final destCoords = CarpoolDistanceCalculator.resolveCoordinates(
      to,
      preferredLat: s.toLat != 0.0 ? s.toLat : null,
      preferredLng: s.toLng != 0.0 ? s.toLng : null,
      defaultLat: s.toLat,
      defaultLng: s.toLng,
    );

    bloc.add(
      CarpoolOfferFromChanged(
        from,
        lat: originCoords.lat,
        lng: originCoords.lng,
      ),
    );
    bloc.add(
      CarpoolOfferToChanged(
        to,
        lat: destCoords.lat,
        lng: destCoords.lng,
      ),
    );

    bloc.add(
      CarpoolOfferCalculatePricing(
        originLat: originCoords.lat,
        originLng: originCoords.lng,
        destinationLat: destCoords.lat,
        destinationLng: destCoords.lng,
      ),
    );

    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: CarpoolStopoversPage(bloc: bloc),
            ),
          ),
        )
        .then((_) {
          if (mounted) {
            setState(() => _isNavigating = false);
            bloc.add(const CarpoolOfferResetStatus());
          }
        });
  }

  Future<void> _pickDate(BuildContext context, CarpoolOfferRideState s) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: s.departure.isBefore(now) ? now : s.departure,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3815D8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF140D43),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      context.read<CarpoolOfferRideBloc>().add(CarpoolOfferDateChanged(picked));
    }
  }

  Future<void> _pickTime(BuildContext context, CarpoolOfferRideState s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: s.departure.hour,
        minute: s.departure.minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3815D8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF140D43),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      context.read<CarpoolOfferRideBloc>().add(
        CarpoolOfferTimeChanged(picked.hour, picked.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarpoolOfferRideBloc, CarpoolOfferRideState>(
      builder: (context, s) {
        final bloc = context.read<CarpoolOfferRideBloc>();
        final isToday = CarpoolFormatters.isSameDay(
          s.departure,
          DateTime.now(),
        );

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFEBE6FC),
                  Color(0xFFF7F5FE),
                  Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.40, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF140D43),
                              size: 26,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Publish a Ride',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF140D43),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF140D43),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        // Car Illustration with Rounded Border Radius & Elevation
                        const _CarIllustrationHeader(showPin: true),

                        const SizedBox(height: 12),

                        // Section Title & Subtitle
                        const Text(
                          'Share Your Journey',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF140D43),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Publish your ride and help others\ntravel together & save money.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6B658C),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Main Details Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFEDE8FF),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5B3BF5,
                                  ).withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Column(
                              children: [
                                // Date Row
                                _CardInfoRow(
                                  icon: Icons.calendar_month_rounded,
                                  title: isToday ? 'Today' : 'Date',
                                  subtitle: CarpoolFormatters.date(s.departure),
                                  onTap: () => _pickDate(context, s),
                                ),

                                const _CardDivider(),

                                // Time Row
                                _CardInfoRow(
                                  icon: Icons.access_time_rounded,
                                  title: 'Time',
                                  subtitle: CarpoolFormatters.time(s.departure),
                                  onTap: () => _pickTime(context, s),
                                ),

                                const _CardDivider(),

                                // Route Row
                                () {
                                  final bool hasFrom =
                                      _hasSelectedRoute &&
                                      s.from.trim().isNotEmpty;
                                  final bool hasTo =
                                      _hasSelectedRoute &&
                                      s.to.trim().isNotEmpty;
                                  final bool hasRoute = hasFrom && hasTo;

                                  final String routeSubtitle = hasRoute
                                      ? '${s.from.trim()} → ${s.to.trim()}'
                                      : (hasFrom
                                            ? '${s.from.trim()} → Select drop-off'
                                            : (hasTo
                                                  ? 'Select pick-up → ${s.to.trim()}'
                                                  : 'Select Route'));

                                  return _CardInfoRow(
                                    icon: Icons.location_on_rounded,
                                    title: 'Route',
                                    subtitle: routeSubtitle,
                                    isRouteBold: hasRoute,
                                    isPlaceholder: !hasRoute,
                                    onTap: () async {
                                      await CarpoolSelectRoutePage.show(
                                        context,
                                        bloc,
                                      );
                                      if (mounted) {
                                        final curState = bloc.state;
                                        if (curState.from.trim().isNotEmpty ||
                                            curState.to.trim().isNotEmpty) {
                                          setState(
                                            () => _hasSelectedRoute = true,
                                          );
                                        }
                                      }
                                    },
                                  );
                                }(),

                                const _CardDivider(),

                                // Seats Available Row with Stepper
                                // Padding(
                                //   padding: const EdgeInsets.symmetric(
                                //     vertical: 8,
                                //     horizontal: 4,
                                //   ),
                                //   child: Row(
                                //     children: [
                                //       const Icon(
                                //         Icons.event_seat_rounded,
                                //         color: AppColors.primaryDark,
                                //         size: 26,
                                //       ),
                                //       const SizedBox(width: 14),
                                //       const Text(
                                //         'Seats Available',
                                //         style: TextStyle(
                                //           fontWeight: FontWeight.w700,
                                //           fontSize: 14.5,
                                //           color: Color(0xFF140D43),
                                //         ),
                                //       ),
                                //       const Spacer(),
                                //       _SeatsStepper(
                                //         count: s.seats,
                                //         onMinus: () => bloc.add(
                                //           const CarpoolOfferSeatsChanged(-1),
                                //         ),
                                //         onPlus: () => bloc.add(
                                //           const CarpoolOfferSeatsChanged(1),
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Publish Ride Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _PublishButton(
                            isLoading: _isNavigating,
                            onPressed: () =>
                                _onPublishPressed(context, bloc, s),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Car illustration header with full-width organic double-curve bottom wave
/// and stylized location pin matching the screenshot design.
class _CarIllustrationHeader extends StatelessWidget {
  final bool showPin;
  const _CarIllustrationHeader({this.showPin = true});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = (screenWidth * (358 / 538)).clamp(215.0, 255.0);

    return SizedBox(
      height: bannerHeight,
      width: screenWidth,
      child: Stack(
        children: [
          // 1. Clipped Car Image with organic bottom curve
          Transform.flip(
            flipX: true,
            child: ClipPath(
              clipper: const _PublishRideBottomCurveClipper(),
              child: Image.asset(
                'assets/images/rider_image.jpg',
                width: screenWidth,
                height: bannerHeight,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: bannerHeight,
                    width: screenWidth,
                    color: const Color(0xFFEBE6FC),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      size: 64,
                      color: Color(0xFF5B3BF5),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Highlight border stroke and white fill along the organic curved edge
          Positioned.fill(
            child: CustomPaint(
              size: Size(screenWidth, bannerHeight),
              painter: const _PublishRideBottomCurvePainter(),
            ),
          ),

          // 3. Decorative Top-Right Location Pin with White Center & Shadow
          if (showPin)
            Positioned(
              top: 18,
              right: 32,
              child: Container(
                width: 38,
                height: 48,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft drop shadow
                    Transform.translate(
                      offset: const Offset(0, 3),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 42,
                        color: const Color(0xFF4C22E8).withOpacity(0.30),
                      ),
                    ),
                    // Deep Purple Pin
                    const Icon(
                      Icons.location_on_rounded,
                      size: 40,
                      color: Color(0xFF4C22E8),
                    ),
                    // White Center Dot
                    Positioned(
                      top: 9,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Organic sea wave clipping path:
/// Curves up on sides like rolling sea wave crests, dipping smoothly in the center under the car.
class _PublishRideBottomCurveClipper extends CustomClipper<Path> {
  const _PublishRideBottomCurveClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    const waveH = 50.0;
    final waveTop = h - waveH;
    final path = Path();

    // Start at top-left, go down left edge to start of sea wave
    path.lineTo(0, waveTop + waveH * 0.45);

    // Left sea wave curving up to crest at (0.12 * w, waveTop)
    path.quadraticBezierTo(w * 0.08, waveTop, w * 0.16, waveTop + waveH * 0.15);

    // Roll down into center valley under the road
    path.quadraticBezierTo(
      w * 0.50,
      waveTop + waveH * 0.95,
      w * 0.84,
      waveTop + waveH * 0.15,
    );

    // Right sea wave curving up to crest at (0.88 * w, waveTop) and down to edge
    path.quadraticBezierTo(w * 0.92, waveTop, w, waveTop + waveH * 0.45);

    // Close path across the top
    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Paints solid white below the sea wave and draws a crisp highlight along the crest
class _PublishRideBottomCurvePainter extends CustomPainter {
  const _PublishRideBottomCurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const waveH = 50.0;
    final waveTop = h - waveH;

    // 1. Solid White Fill below the wave to connect seamlessly with the body
    final fillPath = Path()
      ..moveTo(0, waveTop + waveH * 0.45)
      ..quadraticBezierTo(w * 0.08, waveTop, w * 0.16, waveTop + waveH * 0.15)
      ..quadraticBezierTo(
        w * 0.50,
        waveTop + waveH * 0.95,
        w * 0.84,
        waveTop + waveH * 0.15,
      )
      ..quadraticBezierTo(w * 0.92, waveTop, w, waveTop + waveH * 0.45)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 2. Stroke along the sea wave crest line
    final strokePath = Path()
      ..moveTo(0, waveTop + waveH * 0.45)
      ..quadraticBezierTo(w * 0.08, waveTop, w * 0.16, waveTop + waveH * 0.15)
      ..quadraticBezierTo(
        w * 0.50,
        waveTop + waveH * 0.95,
        w * 0.84,
        waveTop + waveH * 0.15,
      )
      ..quadraticBezierTo(w * 0.92, waveTop, w, waveTop + waveH * 0.45);

    // Subtle soft glow along wave edge
    final glowPaint = Paint()
      ..color = const Color(0xFF5B3BF5).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(strokePath, glowPaint);

    // Crisp white border highlight stroke
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Single row item inside the details card
class _CardInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isRouteBold;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  const _CardInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isRouteBold = false,
    this.isPlaceholder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1D1464), size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B658C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isPlaceholder
                        ? FontWeight.w600
                        : FontWeight.w800,
                    color: isPlaceholder
                        ? const Color(0xFF8E88B0)
                        : const Color(0xFF140D43),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9E9AB8),
            size: 22,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: rowContent,
        ),
      );
    }

    return rowContent;
  }
}

/// Subtle divider line between card rows
class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1EEFC));
  }
}

/// Lavender pill-shaped stepper matching the exact design
class _SeatsStepper extends StatelessWidget {
  final int count;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _SeatsStepper({
    required this.count,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus Button
          GestureDetector(
            onTap: onMinus,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: const Icon(
                Icons.remove_rounded,
                size: 18,
                color: Color(0xFF3815D8),
              ),
            ),
          ),

          // Count Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
              ),
            ),
          ),

          // Plus Button
          GestureDetector(
            onTap: onPlus,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: Color(0xFF3815D8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Royal purple gradient button matching the exact design
class _PublishButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _PublishButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onPressed,
      child: Container(
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
                          'Publish Ride',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
