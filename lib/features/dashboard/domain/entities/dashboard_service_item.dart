import 'package:equatable/equatable.dart';

enum DashboardServiceType {
  carpool,
  delivery,
  partyBooking,
  tourPackages,
  rentals,
  fleetTaxi,
}

class DashboardServiceItem extends Equatable {
  final String id;
  final DashboardServiceType type;
  final String title;
  final String subtitle;
  final String route;

  const DashboardServiceItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  List<Object?> get props => [id, type, title, subtitle, route];
}
