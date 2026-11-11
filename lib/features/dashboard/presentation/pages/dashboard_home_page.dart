import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_service_item.dart';
import '../../domain/entities/recent_activity_entry.dart';
import '../../../party_booking/presentation/pages/party_shell_page.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/active_ride_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/service_grid_card.dart';

/// Dashboard Home Page matching the exact UI design in the screenshot:
/// 1. Top organic wave sky-blue header with Charminar, "Hyderabad ⌵", bell badge, greeting
/// 2. 6 Services Grid (Carpool, Delivery, Party Booking, Tour Packages, Rentals, Fleet / Taxi)
/// 3. Active Ride Card with white sedan car & 'View Details >'
/// 4. Recent Activity section with Carpool Ride (Upcoming) and Delivery Order (Delivered)
class DashboardHomePage extends StatelessWidget {
  final VoidCallback onOpenCarpool;
  final VoidCallback? onOpenPartyBooking;
  final VoidCallback? onOpenActiveRide;
  final VoidCallback? onSeeAllActivity;

  const DashboardHomePage({
    super.key,
    required this.onOpenCarpool,
    this.onOpenPartyBooking,
    this.onOpenActiveRide,
    this.onSeeAllActivity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final data = state.data;

          // Full-screen loading
          if (data == null && state.status == DashboardStatus.loading) {
            return const SafeArea(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0077F6),
                  strokeWidth: 2.5,
                ),
              ),
            );
          }

          // Error / empty state
          if (data == null) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 56,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check your connection and try again.',
                      style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<DashboardBloc>().add(
                        const LoadDashboardDataEvent(),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final viewPadding = MediaQuery.viewPaddingOf(context).top;
          final padding = MediaQuery.paddingOf(context).top;
          final windowPadding =
              View.of(context).padding.top / View.of(context).devicePixelRatio;
          final topPadding = viewPadding > 0
              ? viewPadding
              : (padding > 0 ? padding : (windowPadding > 0 ? windowPadding : 36.0));

          return SafeArea(
            top: false,
            child: RefreshIndicator(
              color: const Color(0xFF0077F6),
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              edgeOffset: topPadding,
              onRefresh: () async {
                context.read<DashboardBloc>().add(
                  const RefreshDashboardDataEvent(),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Organic Wave Blue Header with Charminar
                    DashboardHeader(
                      topPadding: topPadding,
                      userName: data.userName,
                      locationCity: data.locationCity,
                      unreadNotifications: data.unreadNotificationsCount,
                      onLocationTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected Location: ${data.locationCity}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      onNotificationTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You have ${data.unreadNotificationsCount} unread notifications',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),

                  // 2. Services Grid (2 Columns x 3 Rows = 6 items matching screenshot)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.8,
                          ),
                      itemCount: data.services.length,
                      itemBuilder: (context, index) {
                        final service = data.services[index];
                        return ServiceGridCard(
                          service: service,
                          onTap: () {
                            if (service.type == DashboardServiceType.carpool) {
                              onOpenCarpool();
                            } else if (service.type ==
                                DashboardServiceType.partyBooking) {
                              if (onOpenPartyBooking != null) {
                                onOpenPartyBooking!();
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PartyShellPage(),
                                  ),
                                );
                              }
                            } else {
                              _showServiceDialog(
                                context,
                                service.title,
                                service.subtitle,
                                isDark,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),

                  // Transform.translate(
                  //   offset: const Offset(0, -6),
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: 16),
                  //     child: GridView.builder(
                  //       shrinkWrap: true,
                  //       physics: const NeverScrollableScrollPhysics(),
                  //       padding: EdgeInsets.zero,
                  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  //         crossAxisCount: 2,
                  //         crossAxisSpacing: 12,
                  //         mainAxisSpacing: 12,
                  //         childAspectRatio: 1.75,
                  //       ),
                  //       itemCount: data.services.length,
                  //       itemBuilder: (context, index) {
                  //         final service = data.services[index];
                  //         return ServiceGridCard(
                  //           service: service,
                  //           onTap: () {
                  //             if (service.type == DashboardServiceType.carpool) {
                  //               onOpenCarpool();
                  //             } else {
                  //               _showServiceDialog(
                  //                 context,
                  //                 service.title,
                  //                 service.subtitle,
                  //                 isDark,
                  //               );
                  //             }
                  //           },
                  //         );
                  //       },
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 16),

                  // 3. Active Ride Banner Card
                  if (data.activeRide != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ActiveRideCard(
                        banner: data.activeRide!,
                        onViewDetails: () {
                          if (onOpenActiveRide != null) {
                            onOpenActiveRide!();
                          } else {
                            onOpenCarpool();
                          }
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 4. Recent Activity Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RecentActivitySection(
                      activities: data.recentActivities,
                      onSeeAll: () {
                        onSeeAllActivity?.call();
                      },
                      onActivityTap: (activity) {
                        if (activity.type == ActivityType.carpool) {
                          onOpenCarpool();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${activity.title} (${activity.subtitle}) details',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  void _showServiceDialog(
    BuildContext context,
    String serviceName,
    String subtitle,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFF0077F6), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                serviceName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '$subtitle module is active and connected via Pathway clean architecture.',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark
                ? AppColors.darkTextSecondary
                : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0077F6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
