import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_colors.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_find_ride_bloc.dart';
import '../bloc/carpool_home_bloc.dart';
import '../bloc/carpool_nav_cubit.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import 'carpool_find_ride_page.dart';
import 'carpool_offer_ride_page.dart';
import 'carpool_publish_ride_page.dart';

// Carpool Home Page – exact 1:1 match with the target UI design:
// 1. Top bar: Hamburger menu (3 horizontal rounded bars) & Notification bell with '2' badge.
// 2. Header: "Hello,\nVenkatesh 👋" & "Where do you want to go?" with top-right skyline illustration.
// 3. Action Cards: "Carpool" (Royal Purple with 3D sleek front car) & "Courier" (Golden Orange with 3D isometric parcel box).
// 4. "Go Green - Reduce Carbon Footprint" silky mint-lime gradient banner with 3D Earth Globe & glossy sprouting leaves.
// 5. "Popular Routes" section with "See All →" and white rounded card with royal blue location pins & prices in INR.
class CarpoolHomePage extends StatelessWidget {
  const CarpoolHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<CarpoolHomeBloc>();
      return const _CarpoolHomeView();
    } catch (_) {
      final remoteDataSource = CarpoolMockDataSource();
      final repository = CarpoolRepositoryImpl(remoteDataSource);
      return MultiBlocProvider(
        providers: [
          BlocProvider<CarpoolHomeBloc>(
            create: (_) => CarpoolHomeBloc(
              getUser: CarpoolGetUserUseCase(repository),
              getPopularRoutes: CarpoolGetPopularRoutesUseCase(repository),
            )..add(const CarpoolHomeStarted()),
          ),
          BlocProvider<CarpoolFindRideBloc>(
            create: (_) => CarpoolFindRideBloc(
              searchRides: CarpoolSearchRidesUseCase(repository),
              bookRide: CarpoolBookRideUseCase(repository),
            ),
          ),
        ],
        child: const _CarpoolHomeView(),
      );
    }
  }
}

class _CarpoolHomeView extends StatelessWidget {
  const _CarpoolHomeView();

  void _openFindRide(
    BuildContext context, {
    String? from,
    String? to,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  }) {
    final bloc = context.read<CarpoolFindRideBloc>();
    final f = from ?? bloc.state.from;
    final t = to ?? bloc.state.to;
    bloc.add(
      CarpoolFindRideRouteSelected(
        f,
        t,
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      ),
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CarpoolFindRidePage()));
  }

  void _openPublishRide(BuildContext context) {
    CarpoolPublishRidePage.show(context);
  }

  void _openOfferRide(BuildContext context) {
    CarpoolHomeBloc? homeBloc;
    CarpoolNavCubit? navCubit;
    CarpoolOfferRideBloc? offerBloc;

    try {
      homeBloc = context.read<CarpoolHomeBloc>();
    } catch (_) {}
    try {
      navCubit = context.read<CarpoolNavCubit>();
    } catch (_) {}
    try {
      offerBloc = context.read<CarpoolOfferRideBloc>();
    } catch (_) {}

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            if (homeBloc != null) BlocProvider.value(value: homeBloc),
            if (navCubit != null) BlocProvider.value(value: navCubit),
            if (offerBloc != null) BlocProvider.value(value: offerBloc),
          ],
          child: const CarpoolOfferRidePage(),
        ),
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
            colors: [Color(0xFFEDE8FF), Color(0xFFF7F5FE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient soft purple wave in bottom right
            Positioned(
              right: -30,
              bottom: 20,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFDED6FD).withOpacity(0.50),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 1. Background City Skyline Image across the wishes / greeting header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 255,
              child: IgnorePointer(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.74, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/carpool_home_bg.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) =>
                        const CustomPaint(painter: _CitySkylineArtPainter()),
                  ),
                ),
              ),
            ),

            // 2. Main Scrollable Content
            SafeArea(
              bottom: false,
              child: BlocBuilder<CarpoolHomeBloc, CarpoolHomeState>(
                builder: (context, state) {
                  final userName = state.user?.name.isNotEmpty == true
                      ? state.user!.name
                      : 'Venkatesh';

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Top Bar: Back Arrow & Notification Bell
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Arrow icon for backpress
                          GestureDetector(
                            onTap: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).maybePop();
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 2,
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 24,
                                color: Color(0xFF140D43),
                              ),
                            ),
                          ),

                          // Notification bell with red '2' badge
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('2 unread notifications'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 28,
                                    color: Color(0xFF140D43),
                                  ),
                                  Positioned(
                                    right: -3,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.5),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 17,
                                        minHeight: 17,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '2',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Greeting: "Hello,\nVenkatesh 👋"
                      const Text(
                        'Hello,',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF140D43),
                          height: 1.15,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF140D43),
                              height: 1.15,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('👋', style: TextStyle(fontSize: 28)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Where do you want to go?',
                        style: TextStyle(
                          color: Color(0xFF1E174E),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Two Mode Action Cards: Carpool & Courier
                      Row(
                        children: [
                          // Carpool Card (Deep Purple with 3D sleek car)
                          Expanded(
                            child: _CarpoolActionCard(
                              onTap: () => _openPublishRide(context),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Offer Ride Card (Golden Orange with 3D Searching Glass)
                          Expanded(
                            child: _CourierActionCard(
                              onTap: () => _openOfferRide(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // "Go Green - Reduce Carbon Footprint" Banner
                      const _GoGreenBanner(),

                      const SizedBox(height: 22),

                      // Popular Routes Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Popular Routes',
                            style: TextStyle(
                              fontSize: 19.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF140D43),
                              letterSpacing: -0.2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openFindRide(context),
                            behavior: HitTestBehavior.opaque,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'See All',
                                  style: TextStyle(
                                    color: Color(0xFF3815D8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF3815D8),
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Popular Routes Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFEDE8FF),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B3BF5).withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: state.status == CarpoolStatus.loading
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF3815D8),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < state.routes.length;
                                    i++
                                  ) ...[
                                    InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _openFindRide(
                                        context,
                                        from: state.routes[i].from,
                                        to: state.routes[i].to,
                                        fromLat: state.routes[i].fromLat,
                                        fromLng: state.routes[i].fromLng,
                                        toLat: state.routes[i].toLat,
                                        toLng: state.routes[i].toLng,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_rounded,
                                              color: Color(0xFF3815D8),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                '${state.routes[i].from} → ${state.routes[i].to}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.5,
                                                  color: Color(0xFF140D43),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              CarpoolFormatters.rupee(
                                                state.routes[i].price,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: Color(0xFF140D43),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (i != state.routes.length - 1)
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFF1EEFC),
                                      ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carpool Action Card with rich royal purple gradient & custom 3D car silhouette
class _CarpoolActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CarpoolActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 172,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3815D8).withOpacity(0.38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 3D Front Car Silhouette matching design
            const SizedBox(
              width: 58,
              height: 48,
              child: CustomPaint(painter: _FrontCarArtPainter()),
            ),
            const SizedBox(height: 8),
            const Text(
              'Carpool',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Publish Ride',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Courier Action Card with warm golden-orange gradient & 3D isometric parcel box
class _CourierActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CourierActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 172,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB300), Color(0xFFFF9100), Color(0xFFFF6D00)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A00).withOpacity(0.38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 3D Isometric Cardboard Box
            const SizedBox(
              width: 58,
              height: 48,
              child: CustomPaint(painter: _IsometricParcelBoxPainter()),
            ),
            const SizedBox(height: 8),
            const Text(
              'Offer Ride',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Offer a Ride',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fresh mint-lime "Go Green" banner with 3D Globe & Sprouting leaves
class _GoGreenBanner extends StatelessWidget {
  const _GoGreenBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        gradient: AppColors.goGreenGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Text on the left
          const Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            right: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go Green',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F3811),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Reduce Carbon Footprint',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),

          // Earth image fitting card right side with full height
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/earth.png',
              fit: BoxFit.fitHeight,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 72,
                child: CustomPaint(painter: _GoGreenGlobeLeavesPainter()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Front Car Art Painter matching the exact sleek white vehicle in the design
class _FrontCarArtPainter extends CustomPainter {
  const _FrontCarArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintDark = Paint()
      ..color = const Color(0xFF1A0A7A)
      ..style = PaintingStyle.fill;

    // 1. Car Cabin & Windshield Roof
    final cabinPath = Path();
    cabinPath.moveTo(w * 0.22, h * 0.45);
    cabinPath.quadraticBezierTo(w * 0.26, h * 0.14, w * 0.38, h * 0.12);
    cabinPath.lineTo(w * 0.62, h * 0.12);
    cabinPath.quadraticBezierTo(w * 0.74, h * 0.14, w * 0.78, h * 0.45);
    cabinPath.close();
    canvas.drawPath(cabinPath, paintWhite);

    // Windshield glass (subtle purple/blue dark tint)
    final glassPath = Path();
    glassPath.moveTo(w * 0.26, h * 0.43);
    glassPath.quadraticBezierTo(w * 0.30, h * 0.18, w * 0.40, h * 0.16);
    glassPath.lineTo(w * 0.60, h * 0.16);
    glassPath.quadraticBezierTo(w * 0.70, h * 0.18, w * 0.74, h * 0.43);
    glassPath.close();
    canvas.drawPath(glassPath, paintDark);

    // Windshield reflection shine
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final shinePath = Path();
    shinePath.moveTo(w * 0.34, h * 0.42);
    shinePath.lineTo(w * 0.44, h * 0.17);
    shinePath.lineTo(w * 0.49, h * 0.17);
    shinePath.lineTo(w * 0.39, h * 0.42);
    shinePath.close();
    canvas.drawPath(shinePath, shinePaint);

    // 2. Car Hood & Body
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.10, h * 0.42, w * 0.80, h * 0.42),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, paintWhite);

    // Side mirrors
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.38, w * 0.09, h * 0.12),
        const Radius.circular(3),
      ),
      paintWhite,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.87, h * 0.38, w * 0.09, h * 0.12),
        const Radius.circular(3),
      ),
      paintWhite,
    );

    // 3. Headlights (Oval glowing lights)
    final paintLight = Paint()
      ..color = const Color(0xFF240DA2)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.22, h * 0.54),
        width: w * 0.13,
        height: h * 0.12,
      ),
      paintLight,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.78, h * 0.54),
        width: w * 0.13,
        height: h * 0.12,
      ),
      paintLight,
    );

    // Front center grille slot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.68),
          width: w * 0.36,
          height: h * 0.08,
        ),
        const Radius.circular(3),
      ),
      paintLight,
    );

    // Front lower intake & bumper tires
    final tirePaint = Paint()
      ..color = const Color(0xFF130663)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.12, h * 0.80, w * 0.12, h * 0.12),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.76, h * 0.80, w * 0.12, h * 0.12),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      tirePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Isometric Searching Magnifying Glass for Carpool Search Ride Card
class _IsometricParcelBoxPainter extends CustomPainter {
  const _IsometricParcelBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft blurred drop shadow underneath the magnifying glass
    final shadowPaint = Paint()
      ..color = const Color(0xFFBF360C).withOpacity(0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Lens shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.44, h * 0.46),
        width: w * 0.54,
        height: h * 0.52,
      ),
      shadowPaint,
    );

    // Handle shadow
    final handleShadowPaint = Paint()
      ..color = const Color(0xFFBF360C).withOpacity(0.30)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(
      Offset(w * 0.62, h * 0.62),
      Offset(w * 0.88, h * 0.88),
      handleShadowPaint,
    );

    // 2. Angled 3D Handle
    // Handle rear 3D depth rim
    final handleDepthPaint = Paint()
      ..color = const Color(0xFFE65100)
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.59, h * 0.59),
      Offset(w * 0.86, h * 0.86),
      handleDepthPaint,
    );

    // Main glossy white handle
    final handlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.58, h * 0.58),
      Offset(w * 0.85, h * 0.85),
      handlePaint,
    );

    // Golden metallic connector collar between rim and handle
    final collarPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.54, h * 0.54),
      Offset(w * 0.61, h * 0.61),
      collarPaint,
    );

    // 3. Magnifying Glass Lens
    final lensCenter = Offset(w * 0.38, h * 0.38);
    final lensRadius = w * 0.26;

    // Translucent glass fill with subtle light blue/white glow
    final glassPaint = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lensCenter, lensRadius, glassPaint);

    final glassFrostPaint = Paint()
      ..color = const Color(0xFFE0F7FA).withOpacity(0.32)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lensCenter, lensRadius - 1.5, glassFrostPaint);

    // Outer 3D bevel / rim shadow
    final rimBevelPaint = Paint()
      ..color = const Color(0xFFE65100).withOpacity(0.50)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(lensCenter.dx + 1.2, lensCenter.dy + 1.2),
      lensRadius,
      rimBevelPaint,
    );

    // Main crisp white outer circular rim
    final rimPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(lensCenter, lensRadius, rimPaint);

    // Inner rim accent ring
    final innerRimPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(lensCenter, lensRadius - 2.4, innerRimPaint);

    // 4. Glossy Lens Glare / Reflection (curved top-left arc)
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.88)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shineRect = Rect.fromCircle(
      center: lensCenter,
      radius: lensRadius - 4.5,
    );
    canvas.drawArc(shineRect, -2.6, 1.5, false, shinePaint);

    // Secondary soft reflection sparkle dot
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(lensCenter.dx + 4.5, lensCenter.dy + 4.5),
      1.6,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Earth Globe with Glossy Sprouting Leaves for the Go Green Banner
class _GoGreenGlobeLeavesPainter extends CustomPainter {
  const _GoGreenGlobeLeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final globeCenter = Offset(w * 0.60, h * 0.46);
    final radius = w * 0.36;

    // Globe ocean background with spherical 3D lighting
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.40),
        colors: const [
          Color(0xFF81D4FA),
          Color(0xFF29B6F6),
          Color(0xFF0288D1),
          Color(0xFF01579B),
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: globeCenter, radius: radius));

    canvas.drawCircle(globeCenter, radius, oceanPaint);

    // Clip to globe circle for continents
    canvas.save();
    final globePath = Path()
      ..addOval(Rect.fromCircle(center: globeCenter, radius: radius));
    canvas.clipPath(globePath);

    // Continents (emerald & bright lime green)
    final continentPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    // North America / Europe shape
    final c1 = Path()
      ..moveTo(globeCenter.dx - radius * 0.6, globeCenter.dy - radius * 0.4)
      ..quadraticBezierTo(
        globeCenter.dx - radius * 0.2,
        globeCenter.dy - radius * 0.8,
        globeCenter.dx + radius * 0.2,
        globeCenter.dy - radius * 0.5,
      )
      ..lineTo(globeCenter.dx + radius * 0.4, globeCenter.dy - radius * 0.1)
      ..quadraticBezierTo(
        globeCenter.dx - radius * 0.1,
        globeCenter.dy + radius * 0.1,
        globeCenter.dx - radius * 0.6,
        globeCenter.dy - radius * 0.4,
      );
    canvas.drawPath(c1, continentPaint);

    // Asia / India / Africa shape
    final c2 = Path()
      ..moveTo(globeCenter.dx - radius * 0.1, globeCenter.dy + radius * 0.1)
      ..quadraticBezierTo(
        globeCenter.dx + radius * 0.6,
        globeCenter.dy - radius * 0.1,
        globeCenter.dx + radius * 0.8,
        globeCenter.dy + radius * 0.4,
      )
      ..quadraticBezierTo(
        globeCenter.dx + radius * 0.3,
        globeCenter.dy + radius * 0.8,
        globeCenter.dx - radius * 0.1,
        globeCenter.dy + radius * 0.6,
      )
      ..close();
    canvas.drawPath(c2, continentPaint);

    // Specular glossy reflection on top of the globe
    final glossPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.55),
              Colors.white.withOpacity(0.0),
            ],
          ).createShader(
            Rect.fromLTWH(
              globeCenter.dx - radius,
              globeCenter.dy - radius,
              radius * 2,
              radius,
            ),
          );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(globeCenter.dx, globeCenter.dy - radius * 0.4),
        width: radius * 1.5,
        height: radius * 0.8,
      ),
      glossPaint,
    );

    canvas.restore();

    // Sprouting glossy green leaves on the left of the globe
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
      ).createShader(Rect.fromLTWH(0, h * 0.30, w * 0.45, h * 0.65));

    // Leaf 1: pointing up-left
    final leaf1 = Path()
      ..moveTo(w * 0.32, h * 0.65)
      ..quadraticBezierTo(w * 0.05, h * 0.50, w * 0.05, h * 0.35)
      ..quadraticBezierTo(w * 0.28, h * 0.30, w * 0.32, h * 0.65)
      ..close();
    canvas.drawPath(leaf1, leafPaint);

    // Leaf 1 vein
    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.30, h * 0.62),
      Offset(w * 0.08, h * 0.38),
      veinPaint,
    );

    // Leaf 2: pointing lower-left
    final leaf2 = Path()
      ..moveTo(w * 0.35, h * 0.70)
      ..quadraticBezierTo(w * 0.12, h * 0.72, w * 0.15, h * 0.88)
      ..quadraticBezierTo(w * 0.35, h * 0.90, w * 0.35, h * 0.70)
      ..close();
    canvas.drawPath(leaf2, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rich City Skyline Illustration for the top-right header background
class _CitySkylineArtPainter extends CustomPainter {
  const _CitySkylineArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft sky gradient glow in upper background
    final skyGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.6),
        radius: 1.2,
        colors: [
          const Color(0xFFFFCCBC).withOpacity(0.35),
          const Color(0xFFD1C4E9).withOpacity(0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyGlow);

    // Tower colors in rich blue/violet atmospheric haze
    final towerPaintFar = Paint()
      ..color = const Color(0xFF9FA8DA).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final towerPaintMid = Paint()
      ..color = const Color(0xFF7986CB).withOpacity(0.50)
      ..style = PaintingStyle.fill;

    final towerPaintNear = Paint()
      ..color = const Color(0xFF5C6BC0).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // Window grid dots & lines
    final windowPaint = Paint()
      ..color = Colors.white.withOpacity(0.40)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // 1. Far background towers
    canvas.drawRect(
      Rect.fromLTWH(w * 0.15, h * 0.38, 22, h * 0.50),
      towerPaintFar,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.32, h * 0.25, 26, h * 0.60),
      towerPaintFar,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.85, h * 0.30, 24, h * 0.60),
      towerPaintFar,
    );

    // 2. Mid towers
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.48, h * 0.18, 30, h * 0.70),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      towerPaintMid,
    );

    // Spire on center tower
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48 + 13, h * 0.06, 3.5, h * 0.12),
      towerPaintMid,
    );
    // Beacon light at spire tip
    canvas.drawCircle(
      Offset(w * 0.48 + 14.7, h * 0.06),
      2.5,
      Paint()..color = const Color(0xFFFF5252),
    );

    // Windows on mid tower
    for (double y = h * 0.22; y < h * 0.75; y += 12) {
      canvas.drawLine(Offset(w * 0.51, y), Offset(w * 0.55, y), windowPaint);
      canvas.drawLine(Offset(w * 0.60, y), Offset(w * 0.64, y), windowPaint);
    }

    // 3. Tall primary skyscraper (Right-Center)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.68, h * 0.12, 34, h * 0.78),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      towerPaintNear,
    );

    // Tall spire
    canvas.drawRect(
      Rect.fromLTWH(w * 0.68 + 15, h * 0.03, 4, h * 0.09),
      towerPaintNear,
    );
    canvas.drawCircle(
      Offset(w * 0.68 + 17, h * 0.03),
      3,
      Paint()..color = const Color(0xFFFF1744),
    );

    // Windows on primary skyscraper
    for (double y = h * 0.16; y < h * 0.80; y += 10) {
      canvas.drawLine(Offset(w * 0.71, y), Offset(w * 0.78, y), windowPaint);
      canvas.drawLine(Offset(w * 0.81, y), Offset(w * 0.88, y), windowPaint);
    }

    // 4. Lush rolling green treetops at the base of the skyline
    final treePaintBack = Paint()
      ..color = const Color(0xFF43A047).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final treePaintFront = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.70)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.25, h * 0.86), 28, treePaintBack);
    canvas.drawCircle(Offset(w * 0.48, h * 0.84), 34, treePaintBack);
    canvas.drawCircle(Offset(w * 0.75, h * 0.82), 36, treePaintBack);
    canvas.drawCircle(Offset(w * 0.95, h * 0.84), 30, treePaintBack);

    canvas.drawCircle(Offset(w * 0.36, h * 0.90), 32, treePaintFront);
    canvas.drawCircle(Offset(w * 0.62, h * 0.88), 38, treePaintFront);
    canvas.drawCircle(Offset(w * 0.88, h * 0.89), 34, treePaintFront);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
