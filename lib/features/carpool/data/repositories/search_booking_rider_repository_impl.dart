import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../../../core/utils/api_logger.dart';
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
    _bookings = [];
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

  static String _extractCleanCity(String location) {
    var raw = location.trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('{')) {
      final cityMatch = RegExp(
        r'(?:city|district)\s*[:=]\s*([^,}]+)',
        caseSensitive: false,
      ).firstMatch(raw);
      if (cityMatch != null) {
        return cityMatch.group(1)?.trim() ?? raw;
      }
      final addrMatch = RegExp(
        r'(?:address|place|name)\s*[:=]\s*([^,}]+)',
        caseSensitive: false,
      ).firstMatch(raw);
      if (addrMatch != null) {
        raw = addrMatch.group(1)?.trim() ?? raw;
      }
    }

    raw = raw.replaceAll(RegExp(r'''[{}"]'''), '').trim();
    if (raw.contains(',')) {
      final parts = raw
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        final last = parts.last;
        if (last.toLowerCase().contains('delhi')) return 'Delhi';
        return last;
      }
    }
    if (raw.toLowerCase().contains('delhi')) return 'Delhi';
    return raw;
  }

  @override
  Future<List<CarpoolRideEntity>> searchRides({
    required String from,
    required String to,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    DateTime? date,
    int? seats,
    int? radiusKm,
  }) async {
    final originCoords = CarpoolDistanceCalculator.resolveCoordinates(
      from,
      preferredLat: originLat,
      preferredLng: originLng,
      defaultLat: originLat ?? 0.0,
      defaultLng: originLng ?? 0.0,
    );
    final destCoords = CarpoolDistanceCalculator.resolveCoordinates(
      to,
      preferredLat: destinationLat,
      preferredLng: destinationLng,
      defaultLat: destinationLat ?? 0.0,
      defaultLng: destinationLng ?? 0.0,
    );

    final resolvedOriginLat = originCoords.lat;
    final resolvedOriginLng = originCoords.lng;
    final resolvedDestLat = destCoords.lat;
    final resolvedDestLng = destCoords.lng;

    final resolvedDate = date ?? DateTime.now();
    final dateStr =
        '${resolvedDate.year.toString().padLeft(4, '0')}-${resolvedDate.month.toString().padLeft(2, '0')}-${resolvedDate.day.toString().padLeft(2, '0')}';
    final passengersCount = (seats != null && seats > 0) ? seats : 2;
    final resolvedRadius = radiusKm ?? 30;

    final targetUrl = ApiEndpoints.searchRides;
    final uri = Uri.parse(targetUrl);

    final requestBody = {
      'originLat': resolvedOriginLat,
      'originLng': resolvedOriginLng,
      'destinationLat': resolvedDestLat,
      'destinationLng': resolvedDestLng,
      'date': dateStr,
      'passengers': passengersCount,
      'radiusKm': resolvedRadius,
    };
    final payloadJson = jsonEncode(requestBody);

    try {
      final storage = AuthLocalStorage();
      await storage.init();
      final token = await storage.getAccessTokenAsync();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      ApiLogger.logRequest(
        title: 'SEARCH_CARPOOL_RIDES',
        url: targetUrl,
        method: 'POST',
        body: payloadJson,
        headers: headers,
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.write(payloadJson);

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'SEARCH_CARPOOL_RIDES',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);
        List<dynamic> listJson = [];
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map<String, dynamic> &&
              decoded['data']['rides'] is List) {
            listJson = decoded['data']['rides'] as List;
          } else if (decoded['data'] is List) {
            listJson = decoded['data'] as List;
          } else if (decoded['rides'] is List) {
            listJson = decoded['rides'] as List;
          }
        } else if (decoded is List) {
          listJson = decoded;
        }

        final results = listJson
            .whereType<Map<String, dynamic>>()
            .map((j) => CarpoolRideModel.fromJson(j))
            .toList();
        return results;
      }
    } catch (e) {
      ApiLogger.logError(
        title: 'SEARCH_CARPOOL_RIDES',
        url: targetUrl,
        error: e,
      );
    }

    return [];
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
