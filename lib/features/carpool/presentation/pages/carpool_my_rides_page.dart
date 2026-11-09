import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../domain/entities/carpool_entities.dart';
import '../bloc/carpool_my_rides_bloc.dart';
import 'carpool_publish_ride_page.dart';

/// CarpoolMyRidesPage - Modern, beautiful, and user-catching dashboard
/// displaying real published rides fetched from:
/// GET /api/carpool/my-published-rides
class CarpoolMyRidesPage extends StatefulWidget {
  const CarpoolMyRidesPage({super.key});

  @override
  State<CarpoolMyRidesPage> createState() => _CarpoolMyRidesPageState();
}

class _CarpoolMyRidesPageState extends State<CarpoolMyRidesPage> {
  @override
  void initState() {
    super.initState();
    // Fetch live published rides automatically when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CarpoolMyRidesBloc>().add(const CarpoolMyRidesStarted());
      }
    });
  }

  Future<void> _onRefresh() async {
    context.read<CarpoolMyRidesBloc>().add(const CarpoolMyRidesStarted());
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _snack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF3815D8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    CarpoolRideEntity ride,
  ) async {
    final originInfo = _PublishedRideCard._resolveLocation(
      ride.from,
      ride.originCity,
    );
    final destInfo = _PublishedRideCard._resolveLocation(
      ride.to,
      ride.destinationCity,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cancel this ride?',
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
              '${originInfo.place} → ${destInfo.place}',
              style: const TextStyle(
                color: Color(0xFF140D43),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (originInfo.city.isNotEmpty || destInfo.city.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '${originInfo.city} to ${destInfo.city}',
                style: const TextStyle(
                  color: Color(0xFF6B658C),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              CarpoolFormatters.headline(ride.departure),
              style: const TextStyle(
                color: Color(0xFF5D24F7),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            if (ride.totalBookings > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFD97706),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This ride has ${ride.totalBookings} active booking(s). Passengers will be notified.',
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep Ride',
              style: TextStyle(
                color: Color(0xFF6B658C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirm Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.read<CarpoolMyRidesBloc>().add(
        CarpoolMyRidesCancelPressed(ride.id),
      );
    }
  }

  void _showDetails(BuildContext context, CarpoolRideEntity ride) {
    final originInfo = _PublishedRideCard._resolveLocation(
      ride.from,
      ride.originCity,
    );
    final destInfo = _PublishedRideCard._resolveLocation(
      ride.to,
      ride.destinationCity,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDD6FE),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${originInfo.place} → ${destInfo.place}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (originInfo.city.isNotEmpty || destInfo.city.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${originInfo.city} to ${destInfo.city}',
                          style: const TextStyle(
                            color: Color(0xFF6B658C),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        CarpoolFormatters.headline(ride.departure),
                        style: const TextStyle(
                          color: Color(0xFF5D24F7),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(ride.status),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: Color(0xFFEDE8FF), height: 1),
            const SizedBox(height: 12),
            _detailRow(
              Icons.confirmation_number_rounded,
              'Ride ID',
              '#${ride.id}',
            ),
            _detailRow(
              Icons.trip_origin_rounded,
              'Pickup Location',
              originInfo.city.isNotEmpty &&
                      originInfo.city != originInfo.place
                  ? '${originInfo.place} (${originInfo.city})'
                  : originInfo.place,
            ),
            _detailRow(
              Icons.location_on_rounded,
              'Dropoff Location',
              destInfo.city.isNotEmpty &&
                      destInfo.city != destInfo.place
                  ? '${destInfo.place} (${destInfo.city})'
                  : destInfo.place,
            ),
            _detailRow(
              Icons.person_pin_rounded,
              'Driver (Publisher)',
              ride.driverName,
            ),
            _detailRow(
              Icons.airline_seat_recline_normal_rounded,
              'Available Seats',
              '${ride.seats} seat(s) remaining',
            ),
            _detailRow(
              Icons.people_alt_rounded,
              'Total Bookings',
              '${ride.totalBookings} passenger(s)',
              valueColor: const Color(0xFF059669),
            ),
            _detailRow(
              Icons.payments_rounded,
              'Price per Seat',
              '${CarpoolFormatters.rupee(ride.pricePerSeat)} / seat',
              valueColor: const Color(0xFF5D24F7),
            ),
            _detailRow(Icons.directions_car_rounded, 'Vehicle', ride.vehicle),
            _detailRow(
              Icons.straighten_rounded,
              'Distance',
              '~${ride.distanceKm} km',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5D24F7), width: 1.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Color(0xFF5D24F7),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B658C)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B658C),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: valueColor ?? const Color(0xFF140D43),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(CarpoolRideStatus status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case CarpoolRideStatus.upcoming:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = '● Active';
        break;
      case CarpoolRideStatus.completed:
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF4F46E5);
        label = '✔ Completed';
        break;
      case CarpoolRideStatus.cancelled:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = '✕ Cancelled';
        break;
      // ignore: unreachable_switch_default
      default:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = '● Active';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
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
            colors: [
              Color(0xFFEDE8FF),
              Color(0xFFF7F5FE),
              Color(0xFFFAFAFF),
              Colors.white,
            ],
            stops: [0.0, 0.25, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: BlocConsumer<CarpoolMyRidesBloc, CarpoolMyRidesState>(
            listenWhen: (p, c) => c.message != null && p.message != c.message,
            listener: (context, s) => _snack(context, s.message!),
            builder: (context, s) {
              final rides = s.visibleRides;
              final totalBookingsCount = s.totalBookingsCount;

              return RefreshIndicator(
                color: const Color(0xFF5D24F7),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // 1. Top Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'My Published Rides',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF140D43),
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Manage your active listings & bookings',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B658C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Summary Metric Strip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF5D24F7),
                                    Color(0xFF3815D8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4C1CDD,
                                    ).withOpacity(0.32),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _metricItem(
                                    'Published',
                                    '${s.rides.length}',
                                    Icons.directions_car_filled_rounded,
                                  ),
                                  _verticalDivider(),
                                  _metricItem(
                                    'Active',
                                    '${s.upcomingCount}',
                                    Icons.check_circle_rounded,
                                  ),
                                  _verticalDivider(),
                                  _metricItem(
                                    'Bookings',
                                    '$totalBookingsCount',
                                    Icons.confirmation_number_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Segmented Pill Tabs ("Active & Upcoming" / "Past")
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBE6FC),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            children: [
                              // Upcoming / Active Tab
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => context
                                      .read<CarpoolMyRidesBloc>()
                                      .add(const CarpoolMyRidesTabChanged(0)),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: s.tabIndex == 0
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF5D24F7),
                                                Color(0xFF300AB3),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: s.tabIndex == 0
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF4C1CDD,
                                                ).withOpacity(0.35),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Active & Upcoming',
                                          style: TextStyle(
                                            color: s.tabIndex == 0
                                                ? Colors.white
                                                : const Color(0xFF140D43),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: s.tabIndex == 0
                                                ? Colors.white.withOpacity(0.24)
                                                : const Color(0xFFDDD6FE),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${s.upcomingCount}',
                                            style: TextStyle(
                                              color: s.tabIndex == 0
                                                  ? Colors.white
                                                  : const Color(0xFF5D24F7),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Past Tab
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => context
                                      .read<CarpoolMyRidesBloc>()
                                      .add(const CarpoolMyRidesTabChanged(1)),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: s.tabIndex == 1
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF5D24F7),
                                                Color(0xFF300AB3),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: s.tabIndex == 1
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF4C1CDD,
                                                ).withOpacity(0.35),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Past & Completed',
                                          style: TextStyle(
                                            color: s.tabIndex == 1
                                                ? Colors.white
                                                : const Color(0xFF140D43),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: s.tabIndex == 1
                                                ? Colors.white.withOpacity(0.24)
                                                : const Color(0xFFDDD6FE),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${s.pastCount}',
                                            style: TextStyle(
                                              color: s.tabIndex == 1
                                                  ? Colors.white
                                                  : const Color(0xFF5D24F7),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Rides Content (Loading, Empty State, or List)
                    if (s.status == CarpoolStatus.loading && s.rides.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF5D24F7),
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Loading your published rides…',
                                style: TextStyle(
                                  color: Color(0xFF6B658C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (rides.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context, s.tabIndex),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final ride = rides[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _PublishedRideCard(
                                ride: ride,
                                isCancelling: s.cancellingRideId == ride.id,
                                onDetails: () => _showDetails(context, ride),
                                onCancel: () => _confirmCancel(context, ride),
                              ),
                            );
                          }, childCount: rides.length),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.85), size: 15),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withOpacity(0.25),
    );
  }

  Widget _buildEmptyState(BuildContext context, int tabIndex) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D24F7).withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                color: Color(0xFF5D24F7),
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tabIndex == 0
                  ? 'No Active Published Rides'
                  : 'No Past Rides Found',
              style: const TextStyle(
                color: Color(0xFF140D43),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tabIndex == 0
                  ? 'You haven\'t published any upcoming carpools yet. Offer a ride now to share fuel costs!'
                  : 'Your completed or cancelled rides will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B658C),
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (tabIndex == 0) ...[
              const SizedBox(height: 22),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5D24F7), Color(0xFF300AB3)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4C1CDD).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Publish a Ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => CarpoolPublishRidePage.show(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Attractive, Eye-Catching Published Ride Card
class _PublishedRideCard extends StatelessWidget {
  final CarpoolRideEntity ride;
  final bool isCancelling;
  final VoidCallback onDetails;
  final VoidCallback onCancel;

  const _PublishedRideCard({
    required this.ride,
    this.isCancelling = false,
    required this.onDetails,
    required this.onCancel,
  });

  static ({String place, String city}) _resolveLocation(
    String raw,
    String? fallbackCity,
  ) {
    if (raw.isEmpty) {
      return (place: fallbackCity ?? '', city: fallbackCity ?? '');
    }
    String city = fallbackCity?.trim() ?? '';

    // Extract city if present via city: ... or district: ...
    final cityMatch = RegExp(
      r'(?:city|district)\s*[:=]\s*([^,}]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (cityMatch != null) {
      final parsedCity = cityMatch
              .group(1)
              ?.trim()
              .replaceAll(RegExp(r'''[{}"]'''), '') ??
          '';
      if (parsedCity.isNotEmpty) {
        city = parsedCity;
      }
    }

    // Thoroughly strip metadata keys like lat, lng, latitude, longitude, city, etc.
    String cleaned = raw
        .replaceAll(
          RegExp(
            r',?\s*(?:lat|lng|latitude|longitude)\s*[:=][^,}]+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r',?\s*(?:city|district|state|country|zip|pin|postalCode|type)\s*[:=][^,}]+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'^\s*\{\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\}\s*$', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'^(?:address|place|name)\s*[:=]\s*', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'(?:address|place|name)\s*[:=]\s*', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'''[{}"]'''), '')
        .trim();

    if (cleaned.endsWith(',')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }

    String place = cleaned;
    if (cleaned.contains(',')) {
      final parts = cleaned
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        place = parts.first;
        if (city.isEmpty && parts.length > 1) {
          city = parts.last;
        }
      }
    }

    if (city.isEmpty) {
      city = place;
    }
    return (place: place, city: city);
  }

  Widget _buildLocationItem({
    required String place,
    required String city,
    required bool isOrigin,
  }) {
    final showCity =
        city.isNotEmpty &&
        city.toLowerCase() != place.toLowerCase() &&
        !place.toLowerCase().contains(city.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          place,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF140D43),
          ),
        ),
        if (showCity) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_city_rounded,
                size: 13,
                color: const Color(0xFF5D24F7).withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B658C),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUpcoming = ride.status == CarpoolRideStatus.upcoming;
    final originInfo = _resolveLocation(ride.from, ride.originCity);
    final destInfo = _resolveLocation(ride.to, ride.destinationCity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Badges Row (Status, Bookings Badge, Ride ID)
          Row(
            children: [
              // Status Pill
              _buildStatusBadge(ride.status),
              const SizedBox(width: 8),

              // Total Bookings Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: ride.totalBookings > 0
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        )
                      : null,
                  color: ride.totalBookings == 0
                      ? const Color(0xFFF3F0FD)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.confirmation_number_rounded,
                      size: 13,
                      color: ride.totalBookings > 0
                          ? Colors.white
                          : const Color(0xFF5D24F7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ride.totalBookings > 0
                          ? '${ride.totalBookings} Booking${ride.totalBookings > 1 ? 's' : ''}'
                          : '0 Bookings',
                      style: TextStyle(
                        color: ride.totalBookings > 0
                            ? Colors.white
                            : const Color(0xFF5D24F7),
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Departure Date & Time Row with Icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: Color(0xFF5D24F7),
                ),
                const SizedBox(width: 8),
                Text(
                  CarpoolFormatters.headline(ride.departure),
                  style: const TextStyle(
                    color: Color(0xFF140D43),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: Color(0xFF5D24F7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${ride.distanceKm} km',
                  style: const TextStyle(
                    color: Color(0xFF5D24F7),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Route Visualizer (Origin -> Destination Timeline)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vertical Path Indicator
                Column(
                  children: [
                    const SizedBox(height: 3),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 6,
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
                        shape: BoxShape.circle,
                        color: const Color(0xFFEF4444),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                ),
                const SizedBox(width: 12),

                // Locations Text (Mentions city names and clean place names)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLocationItem(
                        place: originInfo.place,
                        city: originInfo.city,
                        isOrigin: true,
                      ),
                      const SizedBox(height: 12),
                      _buildLocationItem(
                        place: destInfo.place,
                        city: destInfo.city,
                        isOrigin: false,
                      ),
                    ],
                  ),
                ),

                // Vehicle Icon or Mini Graphic
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Image.asset(
                      'assets/images/active_car_cutout.png',
                      width: 78,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Color(0xFF5D24F7),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. Key Metrics Strip (Price, Seats Available, Vehicle)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8FE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDE8FF), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricColumn(
                  'Price / seat',
                  CarpoolFormatters.rupee(ride.pricePerSeat),
                  color: const Color(0xFF5D24F7),
                ),
                _dividerVertical(),
                _metricColumn(
                  'Seats Left',
                  '${ride.seats}',
                  color: const Color(0xFF140D43),
                ),
                _dividerVertical(),
                _metricColumn(
                  'Vehicle',
                  ride.vehicle.split('•').first.trim(),
                  color: const Color(0xFF140D43),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 5. Action Buttons ("View Details" & "Cancel Ride")
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDetails,
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFE8FD),
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(
                        color: const Color(0xFFDDD6FE),
                        width: 1.1,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFF5D24F7),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: Color(0xFF5D24F7),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isUpcoming) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isCancelling ? null : onCancel,
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: const Color(0xFFFFCDD2),
                          width: 1.1,
                        ),
                      ),
                      child: isCancelling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFFEF4444),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFFEF4444),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Cancel Ride',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value, {required Color color}) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B658C),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _dividerVertical() {
    return Container(width: 1, height: 26, color: const Color(0xFFE5E1F6));
  }

  Widget _buildStatusBadge(CarpoolRideStatus status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case CarpoolRideStatus.upcoming:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = 'Active';
        break;
      case CarpoolRideStatus.completed:
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF4F46E5);
        label = 'Completed';
        break;
      case CarpoolRideStatus.cancelled:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = 'Cancelled';
        break;
      default:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = 'Active';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
