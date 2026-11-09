import 'package:equatable/equatable.dart';

/// Driver Details Entity
class DriverDetailsEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final int totalTrips;

  const DriverDetailsEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    this.totalTrips = 0,
  });

  @override
  List<Object?> get props => [id, name, phone, rating, totalTrips];
}

/// Search Booking Details Entity (matching GET /api/carpool/rides/:id response)
class SearchBookingDetailsEntity extends Equatable {
  final String id;
  final String publisherId;
  final String origin;
  final String destination;
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final DateTime departureTime;
  final int availableSeats;
  final int pricePerSeat;
  final String vehicleModel;
  final String vehicleNumber;
  final String notes;
  final DriverDetailsEntity driver;

  const SearchBookingDetailsEntity({
    required this.id,
    required this.publisherId,
    required this.origin,
    required this.destination,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.departureTime,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.notes,
    required this.driver,
  });

  /// Clean readable title for the vehicle
  String get vehicleTitle {
    if (vehicleModel.isEmpty && vehicleNumber.isEmpty) return 'Standard Car';
    if (vehicleNumber.isEmpty) return vehicleModel;
    return '$vehicleModel ($vehicleNumber)';
  }

  /// Clean place helper for display
  static String cleanLocation(String raw) {
    if (raw.isEmpty) return '';
    var cleaned = raw.replaceAll(RegExp(r'''[{}"]'''), '').trim();
    final addrMatch = RegExp(
      r'(?:address|place|name)\s*[:=]\s*([^,}]+)',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (addrMatch != null) {
      cleaned = addrMatch.group(1)?.trim() ?? cleaned;
    }
    return cleaned;
  }

  String get cleanOrigin => cleanLocation(origin);
  String get cleanDestination => cleanLocation(destination);

  @override
  List<Object?> get props => [
    id,
    publisherId,
    origin,
    destination,
    originLat,
    originLng,
    destinationLat,
    destinationLng,
    departureTime,
    availableSeats,
    pricePerSeat,
    vehicleModel,
    vehicleNumber,
    notes,
    driver,
  ];
}
