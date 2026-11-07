import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/rider_booking_entity.dart';
import '../../domain/repositories/search_booking_rider_repository.dart';
import '../models/carpool_models.dart';
import '../models/rider_booking_model.dart';

class SearchBookingRiderRepositoryImpl implements SearchBookingRiderRepository {
  static final SearchBookingRiderRepositoryImpl _instance =
      SearchBookingRiderRepositoryImpl._internal();
  factory SearchBookingRiderRepositoryImpl() => _instance;

  SearchBookingRiderRepositoryImpl._internal() {
    final now = DateTime.now();
    // Pre-populate with realistic rider bookings
    _bookings = [
      RiderBookingModel(
        id: 'bk-101',
        rideId: 'ride-901',
        driverName: 'Ramesh Sharma',
        driverPhone: '+91 98451 23456',
        driverRating: 4.8,
        vehicle: 'Maruti Suzuki Dzire',
        vehicleNumber: 'TS 09 AB 1234',
        from: 'Hitech City, Hyderabad',
        to: 'Benz Circle, Vijayawada',
        departure: now.add(const Duration(days: 1, hours: 2)),
        seatsBooked: 2,
        pricePerSeat: 350,
        totalAmount: 700,
        status: RiderBookingStatus.confirmed,
        bookingDate: now.subtract(const Duration(hours: 4)),
        otpCode: '5821',
      ),
      RiderBookingModel(
        id: 'bk-102',
        rideId: 'ride-902',
        driverName: 'Kiran Varma',
        driverPhone: '+91 97012 34567',
        driverRating: 4.9,
        vehicle: 'Honda City',
        vehicleNumber: 'AP 16 CD 5678',
        from: 'Gachibowli, Hyderabad',
        to: 'MG Road, Bangalore',
        departure: now.subtract(const Duration(days: 3)),
        seatsBooked: 1,
        pricePerSeat: 650,
        totalAmount: 650,
        status: RiderBookingStatus.completed,
        bookingDate: now.subtract(const Duration(days: 4)),
        otpCode: '8910',
      ),
    ];
  }

  late final List<RiderBookingEntity> _bookings;

  @override
  Future<List<RiderBookingEntity>> getRiderBookings() async {
    // Attempt to fetch from API if available
    try {
      final storage = AuthLocalStorage();
      await storage.init();
      final token = await storage.getAccessTokenAsync();

      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/carpool/bookings/my',
        );
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        final request = await client
            .getUrl(uri)
            .timeout(const Duration(seconds: 4));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        final response = await request.close().timeout(
          const Duration(seconds: 4),
        );
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final decoded = jsonDecode(body);
          List<dynamic> listJson = [];
          if (decoded is Map<String, dynamic>) {
            if (decoded['data'] is List) listJson = decoded['data'] as List;
            if (decoded['data'] is Map && decoded['data']['bookings'] is List) {
              listJson = decoded['data']['bookings'] as List;
            }
          } else if (decoded is List) {
            listJson = decoded;
          }

          if (listJson.isNotEmpty) {
            final fetched = listJson
                .whereType<Map<String, dynamic>>()
                .map((j) => RiderBookingModel.fromJson(j))
                .toList();
            _bookings.clear();
            _bookings.addAll(fetched);
            return fetched;
          }
        }
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 300));
    return [..._bookings]..sort((a, b) => b.departure.compareTo(a.departure));
  }

  @override
  Future<List<CarpoolRideEntity>> searchRides({
    required String from,
    required String to,
    DateTime? date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final resolvedDate = date ?? DateTime.now().add(const Duration(hours: 4));

    // Dynamic rides tailored to the rider's search query
    final dist = CarpoolDistanceCalculator.calculateDistanceKm(from, to);
    final basePrice = dist > 0 ? (dist * 3.5).round() : 350;

    return [
      CarpoolRideModel(
        id: 'sr-101',
        driverName: 'Suresh Rao',
        driverRating: 4.9,
        driverTrips: 84,
        vehicle: 'Hyundai Creta',
        from: from.isNotEmpty ? from : 'Connaught Place, New Delhi',
        to: to.isNotEmpty ? to : 'Sindhi Camp, Jaipur',
        departure: resolvedDate,
        seats: 3,
        pricePerSeat: basePrice > 0 ? basePrice : 450,
        distanceKm: dist > 0 ? dist : 268,
        status: CarpoolRideStatus.upcoming,
        rideType: CarpoolRideType.normal,
        totalBookings: 1,
        vehicleModel: 'Hyundai Creta',
        vehicleNumber: 'DL 02 CD 4567',
      ),
      CarpoolRideModel(
        id: 'sr-102',
        driverName: 'Anil Kumar',
        driverRating: 4.7,
        driverTrips: 112,
        vehicle: 'Honda City',
        from: from.isNotEmpty ? from : 'Connaught Place, New Delhi',
        to: to.isNotEmpty ? to : 'Sindhi Camp, Jaipur',
        departure: resolvedDate.add(const Duration(hours: 2)),
        seats: 2,
        pricePerSeat: basePrice > 0 ? (basePrice * 0.95).round() : 420,
        distanceKm: dist > 0 ? dist : 268,
        status: CarpoolRideStatus.upcoming,
        rideType: CarpoolRideType.premium,
        totalBookings: 2,
        vehicleModel: 'Honda City',
        vehicleNumber: 'DL 01 AB 9876',
      ),
      CarpoolRideModel(
        id: 'sr-103',
        driverName: 'Vikram Joshi',
        driverRating: 4.8,
        driverTrips: 45,
        vehicle: 'Maruti Suzuki Brezza',
        from: from.isNotEmpty ? from : 'Connaught Place, New Delhi',
        to: to.isNotEmpty ? to : 'Sindhi Camp, Jaipur',
        departure: resolvedDate.add(const Duration(hours: 4)),
        seats: 4,
        pricePerSeat: basePrice > 0 ? (basePrice * 1.05).round() : 480,
        distanceKm: dist > 0 ? dist : 268,
        status: CarpoolRideStatus.upcoming,
        rideType: CarpoolRideType.normal,
        totalBookings: 0,
        vehicleModel: 'Brezza',
        vehicleNumber: 'HR 26 DQ 1122',
      ),
    ];
  }

  @override
  Future<RiderBookingEntity> bookSeat({
    required CarpoolRideEntity ride,
    required int seats,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newBooking = RiderBookingModel(
      id: 'bk-${DateTime.now().millisecondsSinceEpoch % 10000}',
      rideId: ride.id,
      driverName: ride.driverName,
      driverPhone: '+91 98765 12340',
      driverRating: ride.driverRating,
      vehicle: ride.vehicle,
      vehicleNumber: ride.vehicleNumber ?? 'Verified Car',
      from: ride.from,
      to: ride.to,
      departure: ride.departure,
      seatsBooked: seats,
      pricePerSeat: ride.pricePerSeat,
      totalAmount: ride.pricePerSeat * seats,
      status: RiderBookingStatus.confirmed,
      bookingDate: DateTime.now(),
      otpCode: '${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}',
    );

    _bookings.insert(0, newBooking);
    return newBooking;
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(
        status: RiderBookingStatus.cancelled,
      );
    }
  }
}
