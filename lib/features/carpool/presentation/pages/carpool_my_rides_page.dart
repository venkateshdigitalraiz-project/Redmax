import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../domain/entities/carpool_entities.dart';
import '../bloc/carpool_my_rides_bloc.dart';

/// CarpoolMyRidesPage - Matches screenshot design:
/// 1. Lavender gradient background.
/// 2. Top bar: "My Rides" title and notification bell.
/// 3. Segmented Pill Tabs: "Upcoming" (royal purple gradient) and "Past".
/// 4. Ride Cards:
///    - Top: Status badge ("Upcoming"), Date • Time, Route, and Car asset image (`active_car_cutout.png`).
///    - Middle: Driver avatar, name, star rating, circular Call & Chat buttons.
///    - Bottom: "View Details" pill button and "Cancel Ride" pill button.
class CarpoolMyRidesPage extends StatelessWidget {
  const CarpoolMyRidesPage({super.key});

  void _snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Future<void> _confirmCancel(
    BuildContext context,
    CarpoolRideEntity ride,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel this ride?',
          style: TextStyle(
            color: Color(0xFF140D43),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '${ride.from} → ${ride.to}\n'
          '${CarpoolFormatters.headline(ride.departure)}',
          style: const TextStyle(color: Color(0xFF6B658C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep ride',
              style: TextStyle(
                color: Color(0xFF6B658C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel ride',
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${ride.from} → ${ride.to}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CarpoolFormatters.headline(ride.departure),
              style: const TextStyle(
                color: Color(0xFF3815D8),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF3F0FD)),
            _detail('Driver', ride.driverName),
            _detail(
              'Rating',
              '★ ${ride.driverRating} (${ride.driverTrips} trips)',
            ),
            _detail('Vehicle', ride.vehicle),
            _detail('Seats Booked', '${ride.seats} seat(s)'),
            _detail(
              'Price',
              '${CarpoolFormatters.rupee(ride.pricePerSeat)} / seat',
            ),
            _detail('Distance', '~${ride.distanceKm} km'),
            _detail(
              'Ride Type',
              ride.rideType == CarpoolRideType.premium ? 'Premium' : 'Normal',
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(
          k,
          style: const TextStyle(
            color: Color(0xFF6B658C),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          v,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF140D43),
          ),
        ),
      ],
    ),
  );

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
          child: BlocConsumer<CarpoolMyRidesBloc, CarpoolMyRidesState>(
            listenWhen: (p, c) => c.message != null && p.message != c.message,
            listener: (context, s) => _snack(context, s.message!),
            builder: (context, s) {
              final rides = s.visibleRides;
              return Column(
                children: [
                  // 1. Top Bar: "My Rides" and Bell Notification
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                    child: Row(
                      children: [
                        const Text(
                          'My Rides',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF140D43),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _snack(context, 'No new notifications'),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF140D43),
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Segmented Pill Tabs ("Upcoming" / "Past")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBE6FC),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        children: [
                          // Upcoming Tab
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
                                            Color(0xFF5428E8),
                                            Color(0xFF240DA2),
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
                                child: Text(
                                  'Upcoming',
                                  style: TextStyle(
                                    color: s.tabIndex == 0
                                        ? Colors.white
                                        : const Color(0xFF140D43),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
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
                                            Color(0xFF6F35FF),
                                            Color(0xFF3309B8),
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
                                child: Text(
                                  'Past',
                                  style: TextStyle(
                                    color: s.tabIndex == 1
                                        ? Colors.white
                                        : const Color(0xFF140D43),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Rides List or Empty State
                  Expanded(
                    child: s.status == CarpoolStatus.loading && s.rides.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3815D8),
                            ),
                          )
                        : rides.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Text(
                                s.tabIndex == 0
                                    ? 'No upcoming rides.\nTap + below to offer or find a ride.'
                                    : 'No past rides yet.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF6B658C),
                                  fontSize: 14.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
                            itemCount: rides.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, i) {
                              final ride = rides[i];
                              return _MyRideCard(
                                ride: ride,
                                onDetails: () => _showDetails(context, ride),
                                onCancel: () => _confirmCancel(context, ride),
                                onCall: () => _snack(
                                  context,
                                  'Calling ${ride.driverName}…',
                                ),
                                onChat: () => _snack(
                                  context,
                                  'Opening chat with ${ride.driverName}',
                                ),
                              );
                            },
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

/// My Ride Card matching screenshot precisely
class _MyRideCard extends StatelessWidget {
  final CarpoolRideEntity ride;
  final VoidCallback onDetails;
  final VoidCallback onCancel;
  final VoidCallback onCall;
  final VoidCallback onChat;

  const _MyRideCard({
    required this.ride,
    required this.onDetails,
    required this.onCancel,
    required this.onCall,
    required this.onChat,
  });

  String get _statusLabel {
    switch (ride.status) {
      case CarpoolRideStatus.upcoming:
        return 'Upcoming';
      case CarpoolRideStatus.completed:
        return 'Completed';
      case CarpoolRideStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get _statusColor {
    switch (ride.status) {
      case CarpoolRideStatus.upcoming:
        return const Color(0xFFFFFFFF);
      case CarpoolRideStatus.completed:
        return const Color(0xFF16A34A);
      case CarpoolRideStatus.cancelled:
        return const Color(0xFFDC2626);
    }
  }

  Color get _statusBg {
    switch (ride.status) {
      case CarpoolRideStatus.upcoming:
        return const Color(0xFF6F35FF).withOpacity(0.6);
      case CarpoolRideStatus.completed:
        return const Color(0xFF16A34A).withOpacity(0.6);
      case CarpoolRideStatus.cancelled:
        return const Color(0xFFDC2626).withOpacity(0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpcoming = ride.status == CarpoolRideStatus.upcoming;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status pill, Date/Time, Route & White Car asset on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Date • Time
                    Text(
                      CarpoolFormatters.headline(ride.departure),
                      style: const TextStyle(
                        color: Color(0xFF140D43),
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Route
                    Text(
                      '${ride.from} → ${ride.to}',
                      style: const TextStyle(
                        color: Color(0xFF140D43),
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Car Asset Image
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.asset(
                  'assets/images/active_car_cutout.png',
                  width: 120,
                  height: 68,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/active_car.png',
                    width: 120,
                    height: 68,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 90,
                      height: 55,
                      color: const Color(0xFFEBE6FC),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Color(0xFF3815D8),
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Middle Row: Driver photo, name, star rating, Call & Chat circular buttons
          Row(
            children: [
              // Driver Avatar
              ClipOval(
                child: Image.network(
                  ride.driverName.contains('Ramesh')
                      ? 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?fit=crop&w=150&h=150'
                      : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=150&h=150',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 42,
                    height: 42,
                    color: const Color(0xFFEBE6FC),
                    alignment: Alignment.center,
                    child: Text(
                      ride.driverName.isNotEmpty ? ride.driverName[0] : 'D',
                      style: const TextStyle(
                        color: Color(0xFF3815D8),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Driver Name & Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName,
                      style: const TextStyle(
                        color: Color(0xFF140D43),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${ride.driverRating}',
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
              // Circular Call button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCall,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBE6FC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    color: Color(0xFF3815D8),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Circular Chat button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChat,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBE6FC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Color(0xFF3815D8),
                    size: 19,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bottom Row: "View Details" (light periwinkle pill) & "Cancel Ride" (light red pill)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDetails,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFE1FD),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE0D8FD),
                        width: 1.0,
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: Color(0xFF3815D8),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isUpcoming ? onCancel : null,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? const Color(0xFFFFF2F2)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isUpcoming
                            ? const Color(0xFFFFCDD2)
                            : const Color(0xFFE5E7EB),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      isUpcoming ? 'Cancel Ride' : 'Cancelled',
                      style: TextStyle(
                        color: isUpcoming
                            ? const Color(0xFFE53935)
                            : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
