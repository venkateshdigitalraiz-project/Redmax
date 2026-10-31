import 'package:equatable/equatable.dart';
import 'active_ride_banner.dart';
import 'dashboard_service_item.dart';
import 'recent_activity_entry.dart';

class DashboardData extends Equatable {
  final String userName;
  final String locationCity;
  final int unreadNotificationsCount;
  final List<DashboardServiceItem> services;
  final ActiveRideBanner? activeRide;
  final List<RecentActivityEntry> recentActivities;

  const DashboardData({
    required this.userName,
    required this.locationCity,
    required this.unreadNotificationsCount,
    required this.services,
    this.activeRide,
    required this.recentActivities,
  });

  @override
  List<Object?> get props => [
        userName,
        locationCity,
        unreadNotificationsCount,
        services,
        activeRide,
        recentActivities,
      ];
}
