import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_find_ride_bloc.dart';
import '../bloc/carpool_home_bloc.dart';
import 'carpool_find_ride_page.dart';
import 'carpool_publish_ride_page.dart';

/// Carpool Home Page matching the exact design in the screenshot:
/// 1. Soft lavender gradient background with subtle top-right skyline illustration.
/// 2. Top bar: Hamburger menu (or back if popped) & Notification bell with '2' badge.
/// 3. Greeting: "Hello,\nVenkatesh 👋" & "Where do you want to go?".
/// 4. Two Action Cards: Carpool (Royal Purple) & Courier (Warm Golden Orange).
/// 5. "Go Green - Reduce Carbon Footprint" pastel green banner with 3D Earth & leaves.
/// 6. "Popular Routes" card with "See All →" and routes listing prices in INR.
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

  void _openFindRide(BuildContext context, {String? from, String? to}) {
    final bloc = context.read<CarpoolFindRideBloc>();
    bloc.add(
      CarpoolFindRideRouteSelected(
        from ?? bloc.state.from,
        to ?? bloc.state.to,
      ),
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CarpoolFindRidePage()));
  }

  void _openPublishRide(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CarpoolPublishRidePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEBE6FC), Color(0xFFF7F5FE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.40, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Subtle background skyline towers in top right matching screenshot
              Positioned(
                top: 0,
                right: 0,
                width: 220,
                height: 190,
                child: Opacity(
                  opacity: 0.45,
                  child: CustomPaint(painter: _HomeSkylinePainter()),
                ),
              ),

              // Main Scrollable Content
              BlocBuilder<CarpoolHomeBloc, CarpoolHomeState>(
                builder: (context, state) {
                  final userName = state.user?.name.isNotEmpty == true
                      ? state.user!.name
                      : 'Venkatesh';

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      // 1. Top Bar: Hamburger / Back & Bell with '2' badge
                      Row(
                        children: [
                          Builder(
                            builder: (btnCtx) {
                              final canPop = Navigator.of(btnCtx).canPop();
                              return GestureDetector(
                                onTap: () {
                                  if (canPop) {
                                    Navigator.of(btnCtx).pop();
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 2,
                                  ),
                                  child: Icon(
                                    canPop
                                        ? Icons.arrow_back_ios_new_rounded
                                        : Icons.menu_rounded,
                                    size: 26,
                                    color: const Color(0xFF140D43),
                                  ),
                                ),
                              );
                            },
                          ),
                          const Spacer(),
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
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 2. Greeting
                      const Text(
                        'Hello,',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF140D43),
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('👋', style: TextStyle(fontSize: 26)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Where do you want to go?',
                        style: TextStyle(
                          color: Color(0xFF1E174E),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Two Mode Action Cards (Carpool & Courier)
                      Row(
                        children: [
                          // Carpool Card
                          Expanded(
                            child: _ActionCard(
                              title: 'Carpool',
                              subtitle: 'Share Ride',
                              icon: Icons.directions_car_rounded,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF6F35FF), Color(0xFF3309B8)],
                              ),
                              shadowColor: const Color(0xFF4C1CDD),
                              onTap: () => _openPublishRide(context),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Courier Card
                          Expanded(
                            child: _ActionCard(
                              title: 'Courier',
                              subtitle: 'Send Package',
                              icon: Icons.inventory_2_rounded,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFB338), Color(0xFFFF7A00)],
                              ),
                              shadowColor: const Color(0xFFFF8500),
                              onTap: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Courier is coming soon'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 4. "Go Green" Banner
                      const _GoGreenBanner(),

                      const SizedBox(height: 22),

                      // 5. Popular Routes Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Popular Routes',
                            style: TextStyle(
                              fontSize: 19,
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
                                    fontSize: 14,
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

                      // 6. Popular Routes Card
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
                              blurRadius: 18,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Action Card for Carpool and Courier matching screenshot
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 165,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 70),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
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

/// Pastel green "Go Green" banner with 3D Globe & Sprouting leaves
class _GoGreenBanner extends StatelessWidget {
  const _GoGreenBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFD6F9D0), Color(0xFFC0F4BA), Color(0xFFD2F8CC)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go Green',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF133E10),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Reduce Carbon Footprint',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF225F1D),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 3D globe with radial ocean blue gradient
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.35, -0.35),
                      colors: [
                        Color(0xFF64B5F6),
                        Color(0xFF1E88E5),
                        Color(0xFF0D47A1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x331976D2),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.public_rounded,
                    color: Color(0xFF81C784),
                    size: 48,
                  ),
                ),
                // Fresh green leaves sprouting on the left side of the globe
                Positioned(
                  left: 2,
                  bottom: 8,
                  child: Transform.rotate(
                    angle: -0.35,
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF43A047),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle background skyline painter for the top-right corner
class _HomeSkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft pastel building silhouettes
    final paint1 = Paint()
      ..color = const Color(0xFF9080E8).withOpacity(0.30)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = const Color(0xFF7894ED).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final paintTrees = Paint()
      ..color = const Color(0xFF66BB6A).withOpacity(0.40)
      ..style = PaintingStyle.fill;

    // Background tower 1
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          size.width * 0.40,
          size.height * 0.15,
          24,
          size.height * 0.70,
        ),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      paint2,
    );

    // Spire 1
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.40 + 10,
        size.height * 0.05,
        4,
        size.height * 0.10,
      ),
      paint2,
    );

    // Background tower 2 (center tall)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          size.width * 0.65,
          size.height * 0.20,
          28,
          size.height * 0.65,
        ),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      paint1,
    );

    // Spire 2
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.65 + 12,
        size.height * 0.08,
        4,
        size.height * 0.12,
      ),
      paint1,
    );

    // Background building 3
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.35,
          20,
          size.height * 0.50,
        ),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      paint2,
    );

    // Background building 4 (far right)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          size.width * 0.88,
          size.height * 0.30,
          22,
          size.height * 0.55,
        ),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      paint1,
    );

    // Green tree canopy hills at the base of the skyline
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.88),
      35,
      paintTrees,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.85),
      40,
      paintTrees,
    );
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.88),
      36,
      paintTrees,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
