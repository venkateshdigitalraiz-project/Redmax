import '../../domain/entities/active_ride_banner.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_service_item.dart';
import '../../domain/entities/recent_activity_entry.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardData> fetchDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  @override
  Future<DashboardData> fetchDashboardData() async {
    // Simulating realistic backend latency
    await Future.delayed(const Duration(milliseconds: 150));

    return const DashboardData(
      userName: 'Venkatesh',
      locationCity: 'Hyderabad',
      unreadNotificationsCount: 2,
      services: [
        DashboardServiceItem(
          id: 'srv_carpool',
          type: DashboardServiceType.carpool,
          title: 'Carpool',
          subtitle: 'Find or offer rides',
          route: '/carpool',
        ),
        DashboardServiceItem(
          id: 'srv_delivery',
          type: DashboardServiceType.delivery,
          title: 'Delivery',
          subtitle: 'Send & receive parcels',
          route: '/delivery',
        ),
        DashboardServiceItem(
          id: 'srv_party',
          type: DashboardServiceType.partyBooking,
          title: 'Party Booking',
          subtitle: 'Plan your events',
          route: '/party-booking',
        ),
        DashboardServiceItem(
          id: 'srv_tours',
          type: DashboardServiceType.tourPackages,
          title: 'Tour Packages',
          subtitle: 'Explore amazing tours',
          route: '/tours',
        ),
        DashboardServiceItem(
          id: 'srv_rentals',
          type: DashboardServiceType.rentals,
          title: 'Rentals',
          subtitle: 'Rent a car easily',
          route: '/rentals',
        ),
        DashboardServiceItem(
          id: 'srv_fleet',
          type: DashboardServiceType.fleetTaxi,
          title: 'Fleet / Taxi',
          subtitle: 'Book a taxi service',
          route: '/fleet-taxi',
        ),
      ],
      activeRide: ActiveRideBanner(
        id: 'active_ride_101',
        title: 'Active Ride',
        origin: 'Hyderabad',
        destination: 'Vijayawada',
        timeRemaining: '1h 20m remaining',
        carImageUrl: 'assets/images/active_car.png',
      ),
      recentActivities: [
        RecentActivityEntry(
          id: 'act_1',
          title: 'Carpool Ride',
          timestampText: 'Today • 10:30 AM',
          subtitle: 'Hyderabad ➔ Suryapet',
          status: ActivityStatus.upcoming,
          type: ActivityType.carpool,
        ),
        RecentActivityEntry(
          id: 'act_2',
          title: 'Delivery Order',
          timestampText: 'Yesterday • 06:15 PM',
          subtitle: '#DEL12345',
          status: ActivityStatus.delivered,
          type: ActivityType.delivery,
        ),
      ],
    );
  }
}
