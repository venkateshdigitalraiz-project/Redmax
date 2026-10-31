import '../../domain/entities/carpool_ride.dart';

/// Abstract data source contract for Carpool.
abstract class CarpoolRemoteDataSource {
  Future<List<CarpoolRide>> fetchAvailableRides();
  Future<List<CarpoolRide>> searchRides(String query);
  Future<String> bookRide(String rideId);
}

/// Mock implementation with 6 realistic Hyderabad-based carpool rides.
class CarpoolRemoteDataSourceImpl implements CarpoolRemoteDataSource {
  static const List<CarpoolRide> _mockRides = [
    CarpoolRide(
      id: 'cp_001',
      driverName: 'Rajesh Kumar',
      origin: 'Hyderabad',
      destination: 'Vijayawada',
      departureTime: '06:30 AM',
      date: 'Today',
      seatsAvailable: 3,
      pricePerSeat: 350,
      rating: 4.8,
      vehicleName: 'Toyota Innova Crysta',
      vehicleColor: 'Pearl White',
      isAcAvailable: true,
      distanceKm: 275,
    ),
    CarpoolRide(
      id: 'cp_002',
      driverName: 'Priya Sharma',
      origin: 'Hyderabad',
      destination: 'Bangalore',
      departureTime: '07:00 AM',
      date: 'Today',
      seatsAvailable: 2,
      pricePerSeat: 650,
      rating: 4.9,
      vehicleName: 'Honda City',
      vehicleColor: 'Lunar Silver',
      isAcAvailable: true,
      distanceKm: 570,
    ),
    CarpoolRide(
      id: 'cp_003',
      driverName: 'Anil Reddy',
      origin: 'Hyderabad',
      destination: 'Chennai',
      departureTime: '08:15 AM',
      date: 'Today',
      seatsAvailable: 1,
      pricePerSeat: 750,
      rating: 4.6,
      vehicleName: 'Maruti Ertiga',
      vehicleColor: 'Magma Grey',
      isAcAvailable: true,
      distanceKm: 626,
    ),
    CarpoolRide(
      id: 'cp_004',
      driverName: 'Suresh Babu',
      origin: 'Hyderabad',
      destination: 'Warangal',
      departureTime: '09:00 AM',
      date: 'Today',
      seatsAvailable: 4,
      pricePerSeat: 150,
      rating: 4.4,
      vehicleName: 'Maruti Swift Dzire',
      vehicleColor: 'Midnight Blue',
      isAcAvailable: false,
      distanceKm: 148,
    ),
    CarpoolRide(
      id: 'cp_005',
      driverName: 'Kavitha Nair',
      origin: 'Hyderabad',
      destination: 'Kurnool',
      departureTime: '10:30 AM',
      date: 'Today',
      seatsAvailable: 2,
      pricePerSeat: 280,
      rating: 4.7,
      vehicleName: 'Hyundai i20',
      vehicleColor: 'Fiery Red',
      isAcAvailable: true,
      distanceKm: 212,
    ),
    CarpoolRide(
      id: 'cp_006',
      driverName: 'Venkat Rao',
      origin: 'Secunderabad',
      destination: 'Hyderabad Airport',
      departureTime: '11:45 AM',
      date: 'Today',
      seatsAvailable: 3,
      pricePerSeat: 200,
      rating: 4.5,
      vehicleName: 'Tata Nexon',
      vehicleColor: 'Foliage Green',
      isAcAvailable: true,
      distanceKm: 38,
    ),
  ];

  @override
  Future<List<CarpoolRide>> fetchAvailableRides() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.unmodifiable(_mockRides);
  }

  @override
  Future<List<CarpoolRide>> searchRides(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.trim().isEmpty) return List.unmodifiable(_mockRides);
    final lowerQuery = query.toLowerCase();
    return _mockRides.where((ride) {
      return ride.origin.toLowerCase().contains(lowerQuery) ||
          ride.destination.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<String> bookRide(String rideId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final exists = _mockRides.any((r) => r.id == rideId);
    if (!exists) throw Exception('Ride not found: $rideId');
    return rideId;
  }
}
