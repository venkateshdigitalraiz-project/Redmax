import '../../domain/entities/search_booking_details_entity.dart';

class DriverDetailsModel extends DriverDetailsEntity {
  const DriverDetailsModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.rating,
    super.totalTrips = 0,
  });

  factory DriverDetailsModel.fromJson(Map<String, dynamic> json) {
    return DriverDetailsModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Driver',
      phone: json['phone']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'rating': rating,
    'totalTrips': totalTrips,
  };
}

class SearchBookingDetailsModel extends SearchBookingDetailsEntity {
  const SearchBookingDetailsModel({
    required super.id,
    required super.publisherId,
    required super.origin,
    required super.destination,
    required super.originLat,
    required super.originLng,
    required super.destinationLat,
    required super.destinationLng,
    required super.departureTime,
    required super.availableSeats,
    required super.pricePerSeat,
    required super.vehicleModel,
    required super.vehicleNumber,
    required super.notes,
    required super.driver,
  });

  factory SearchBookingDetailsModel.fromJson(Map<String, dynamic> json) {
    // Driver parsing
    final driverJson = json['driver'];
    final DriverDetailsEntity driver;
    if (driverJson is Map<String, dynamic>) {
      driver = DriverDetailsModel.fromJson(driverJson);
    } else {
      driver = DriverDetailsEntity(
        id: json['publisherId']?.toString() ?? '',
        name: json['driverName']?.toString() ?? 'Driver',
        phone: json['phone']?.toString() ?? '',
        rating: (json['driverRating'] as num?)?.toDouble() ?? 5.0,
      );
    }

    // Departure time parsing
    DateTime depTime = DateTime.now();
    final rawDeparture = json['departureTime'] ?? json['departure'];
    if (rawDeparture != null) {
      final parsed = DateTime.tryParse(rawDeparture.toString());
      if (parsed != null) depTime = parsed;
    }

    return SearchBookingDetailsModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      publisherId: json['publisherId']?.toString() ?? '',
      origin: json['origin']?.toString() ?? json['from']?.toString() ?? '',
      destination:
          json['destination']?.toString() ?? json['to']?.toString() ?? '',
      originLat: (json['originLat'] as num?)?.toDouble() ?? 0.0,
      originLng: (json['originLng'] as num?)?.toDouble() ?? 0.0,
      destinationLat: (json['destinationLat'] as num?)?.toDouble() ?? 0.0,
      destinationLng: (json['destinationLng'] as num?)?.toDouble() ?? 0.0,
      departureTime: depTime,
      availableSeats:
          (json['availableSeats'] as num?)?.toInt() ??
          (json['seats'] as num?)?.toInt() ??
          1,
      pricePerSeat:
          (json['pricePerSeat'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          0,
      vehicleModel:
          json['vehicleModel']?.toString() ??
          json['vehicle']?.toString() ??
          'Standard Car',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      driver: driver,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'publisherId': publisherId,
    'origin': origin,
    'destination': destination,
    'originLat': originLat,
    'originLng': originLng,
    'destinationLat': destinationLat,
    'destinationLng': destinationLng,
    'departureTime': departureTime.toIso8601String(),
    'availableSeats': availableSeats,
    'pricePerSeat': pricePerSeat,
    'vehicleModel': vehicleModel,
    'vehicleNumber': vehicleNumber,
    'notes': notes,
    'driver': {
      'id': driver.id,
      'name': driver.name,
      'phone': driver.phone,
      'rating': driver.rating,
      'totalTrips': driver.totalTrips,
    },
  };
}

