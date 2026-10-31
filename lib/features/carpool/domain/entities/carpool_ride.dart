import 'package:equatable/equatable.dart';

/// Entity representing a single carpool ride listing.
class CarpoolRide extends Equatable {
  final String id;
  final String driverName;
  final String? driverAvatar;
  final String origin;
  final String destination;
  final String departureTime;
  final String date;
  final int seatsAvailable;
  final double pricePerSeat;
  final double rating;
  final String vehicleName;
  final String vehicleColor;
  final bool isAcAvailable;
  final double distanceKm;

  const CarpoolRide({
    required this.id,
    required this.driverName,
    this.driverAvatar,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.date,
    required this.seatsAvailable,
    required this.pricePerSeat,
    required this.rating,
    required this.vehicleName,
    required this.vehicleColor,
    required this.isAcAvailable,
    required this.distanceKm,
  });

  @override
  List<Object?> get props => [
        id,
        driverName,
        driverAvatar,
        origin,
        destination,
        departureTime,
        date,
        seatsAvailable,
        pricePerSeat,
        rating,
        vehicleName,
        vehicleColor,
        isAcAvailable,
        distanceKm,
      ];
}
