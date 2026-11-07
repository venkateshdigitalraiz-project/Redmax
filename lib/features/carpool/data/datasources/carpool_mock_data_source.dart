import 'dart:convert';
import 'dart:io';
import 'package:pathway/core/constants/api_endpoints.dart';
import 'package:pathway/core/storage/auth_local_storage.dart';
import 'package:pathway/core/utils/api_logger.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';

import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/carpool_pricing_entity.dart';
import '../../domain/usecases/carpool_calculate_pricing_usecase.dart';
import '../models/carpool_models.dart';
import 'carpool_remote_data_source.dart';

/// In-memory implementation so the app runs without a backend.
/// Replace with a Dio/http based implementation of [CarpoolRemoteDataSource].
class CarpoolMockDataSource implements CarpoolRemoteDataSource {
  static final CarpoolMockDataSource _instance =
      CarpoolMockDataSource._internal();

  factory CarpoolMockDataSource() => _instance;

  CarpoolMockDataSource._internal() {
    final now = DateTime.now();
    DateTime at(int dayOffset, int hour) =>
        DateTime(now.year, now.month, now.day + dayOffset, hour);

    // Initialized empty - loads real published rides via /api/carpool/my-published-rides
    _myRides = [];

    _transactions = [
      CarpoolTransactionModel(
        id: 't1',
        title: 'Ride Payment',
        date: at(0, 9),
        amount: -250,
        type: CarpoolTransactionType.payment,
      ),
      CarpoolTransactionModel(
        id: 't2',
        title: 'Referral Reward',
        date: at(-3, 10),
        amount: 100,
        type: CarpoolTransactionType.reward,
      ),
      CarpoolTransactionModel(
        id: 't3',
        title: 'Added Money',
        date: at(-6, 12),
        amount: 500,
        type: CarpoolTransactionType.topUp,
      ),
    ];
  }

  late final List<CarpoolRideModel> _myRides;
  late final List<CarpoolTransactionModel> _transactions;
  double _balance = 850;
  int _idCounter = 100;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Future<CarpoolUserModel> fetchUser() async {
    await _latency();
    return const CarpoolUserModel(
      id: 'u1',
      name: 'Venkatesh',
      email: 'venkatesh@gmail.com',
      rating: 4.9,
      isPremium: true,
    );
  }

  late final List<CarpoolPopularRouteModel> _popularRoutes = [
    const CarpoolPopularRouteModel(
      from: 'Hyderabad',
      to: 'Vijayawada',
      price: 250,
      fromLat: 17.3850,
      fromLng: 78.4867,
      toLat: 16.5062,
      toLng: 80.6480,
    ),
    const CarpoolPopularRouteModel(
      from: 'Hyderabad',
      to: 'Bangalore',
      price: 600,
      fromLat: 17.3850,
      fromLng: 78.4867,
      toLat: 12.9716,
      toLng: 77.5946,
    ),
    const CarpoolPopularRouteModel(
      from: 'Hyderabad',
      to: 'Chennai',
      price: 700,
      fromLat: 17.3850,
      fromLng: 78.4867,
      toLat: 13.0827,
      toLng: 80.2707,
    ),
  ];

  @override
  Future<List<CarpoolPopularRouteModel>> fetchPopularRoutes() async {
    await _latency();
    return [..._popularRoutes];
  }

  void addPopularRoute(
    String from,
    String to,
    int price, {
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  }) {
    _popularRoutes.removeWhere(
      (r) =>
          r.from.toLowerCase() == from.toLowerCase() &&
          r.to.toLowerCase() == to.toLowerCase(),
    );
    _popularRoutes.insert(
      0,
      CarpoolPopularRouteModel(
        from: from,
        to: to,
        price: price,
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      ),
    );
  }

  @override
  Future<List<CarpoolRideModel>> searchRides(
    CarpoolSearchRidesParams params,
  ) async {
    await _latency();
    final now = DateTime.now();
    final day = params.filter == CarpoolDayFilter.tomorrow ? 1 : 0;
    DateTime at(int hour) => DateTime(now.year, now.month, now.day + day, hour);
    return [
      CarpoolRideModel(
        id: 's1',
        driverName: 'Ramesh Kumar',
        driverRating: 4.8,
        driverTrips: 120,
        vehicle: 'Maruti Dzire',
        from: params.from,
        to: params.to,
        departure: at(9),
        seats: 3,
        pricePerSeat: 250,
        distanceKm: 275,
        status: CarpoolRideStatus.upcoming,
        rideType: CarpoolRideType.normal,
      ),
      CarpoolRideModel(
        id: 's2',
        driverName: 'Srinivas',
        driverRating: 4.7,
        driverTrips: 95,
        vehicle: 'Honda City',
        from: params.from,
        to: params.to,
        departure: at(11),
        seats: 3,
        pricePerSeat: 260,
        distanceKm: 275,
        status: CarpoolRideStatus.upcoming,
        rideType: CarpoolRideType.normal,
      ),
    ];
  }

  @override
  Future<void> bookRide(String rideId) => _latency();

  @override
  Future<CarpoolRideModel> publishRide(CarpoolPublishRideParams p) async {
    const targetUrl = ApiEndpoints.publishRide;
    final uri = Uri.parse(targetUrl);
    final payloadJson = jsonEncode(p.toJson());

    // Retrieve fresh access token from SharedPreferences via AuthLocalStorage
    final storage = AuthLocalStorage();
    await storage.init();
    final token = await storage.getAccessTokenAsync();

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    ApiLogger.logRequest(
      title: 'PUBLISH_RIDE',
      url: targetUrl,
      method: 'POST',
      body: payloadJson,
      headers: requestHeaders,
    );

    try {
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
        title: 'PUBLISH_RIDE',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          Map<String, dynamic> rideData = {};
          if (decoded['data'] is Map<String, dynamic> &&
              decoded['data']['ride'] is Map<String, dynamic>) {
            rideData = decoded['data']['ride'] as Map<String, dynamic>;
          } else if (decoded['data'] is Map<String, dynamic>) {
            rideData = decoded['data'] as Map<String, dynamic>;
          } else if (decoded['ride'] is Map<String, dynamic>) {
            rideData = decoded['ride'] as Map<String, dynamic>;
          } else {
            rideData = decoded;
          }

          final ride = CarpoolRideModel.fromJson(rideData);
          _myRides.add(ride);
          return ride;
        }
      }

      String errorMsg = 'Publish ride failed: ${response.statusCode}';
      try {
        final decodedErr = jsonDecode(responseBody);
        if (decodedErr is Map<String, dynamic> &&
            decodedErr['message'] != null) {
          errorMsg = decodedErr['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMsg);
    } catch (e) {
      ApiLogger.logError(title: 'PUBLISH_RIDE', url: targetUrl, error: e);
      rethrow;
    }
  }

  @override
  Future<List<CarpoolRideModel>> fetchMyRides() async {
    const targetUrl = ApiEndpoints.myPublishedRides;
    final uri = Uri.parse(targetUrl);

    // Retrieve access token
    final storage = AuthLocalStorage();
    await storage.init();
    final token = await storage.getAccessTokenAsync();

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    ApiLogger.logRequest(
      title: 'GET_MY_PUBLISHED_RIDES',
      url: targetUrl,
      method: 'GET',
      body: '',
      headers: requestHeaders,
    );

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 10));

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'GET_MY_PUBLISHED_RIDES',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        List<dynamic> rideListJson = [];
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map<String, dynamic> &&
              decoded['data']['rides'] is List) {
            rideListJson = decoded['data']['rides'] as List;
          } else if (decoded['data'] is List) {
            rideListJson = decoded['data'] as List;
          } else if (decoded['rides'] is List) {
            rideListJson = decoded['rides'] as List;
          }
        } else if (decoded is List) {
          rideListJson = decoded;
        }

        final rides = rideListJson
            .whereType<Map<String, dynamic>>()
            .map((r) => CarpoolRideModel.fromJson(r))
            .toList();

        _myRides.clear();
        _myRides.addAll(rides);
        return rides;
      }
      throw Exception(
        'Failed to fetch published rides: ${response.statusCode}',
      );
    } catch (e) {
      ApiLogger.logError(
        title: 'GET_MY_PUBLISHED_RIDES',
        url: targetUrl,
        error: e,
      );
      // Graceful fallback to cached rides if server is unreachable
      final list = [..._myRides]
        ..sort((a, b) => a.departure.compareTo(b.departure));
      return list;
    }
  }

  @override
  Future<void> cancelRide(String rideId) async {
    final targetUrl = ApiEndpoints.cancelBooking(rideId);
    final fallbackUrl = ApiEndpoints.cancelRide(rideId);

    // Retrieve access token
    final storage = AuthLocalStorage();
    await storage.init();
    final token = await storage.getAccessTokenAsync();

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final bodyMap = <String, dynamic>{
      'reason': 'Travel plans changed',
    };
    final bodyJson = jsonEncode(bodyMap);

    ApiLogger.logRequest(
      title: 'CANCEL_BOOKING',
      url: targetUrl,
      method: 'POST',
      body: bodyJson,
      headers: requestHeaders,
    );

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      var uri = Uri.parse(targetUrl);

      var request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.add(utf8.encode(bodyJson));

      var response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      var responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'CANCEL_BOOKING',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      // If bookings/:id/cancel returns 404, fallback to rides/:id/cancel
      if (response.statusCode == 404) {
        ApiLogger.logRequest(
          title: 'CANCEL_RIDE_FALLBACK',
          url: fallbackUrl,
          method: 'POST',
          body: bodyJson,
          headers: requestHeaders,
        );
        uri = Uri.parse(fallbackUrl);
        request = await client
            .postUrl(uri)
            .timeout(const Duration(seconds: 10));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (token != null && token.isNotEmpty) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        }
        request.add(utf8.encode(bodyJson));
        response = await request.close().timeout(
          const Duration(seconds: 10),
        );
        responseBody = await response.transform(utf8.decoder).join();

        ApiLogger.logResponse(
          title: 'CANCEL_RIDE_FALLBACK',
          url: fallbackUrl,
          statusCode: response.statusCode,
          responseBody: responseBody,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success
      } else {
        String msg = 'Failed to cancel ($rideId): ${response.statusCode}';
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      ApiLogger.logError(
        title: 'CANCEL_BOOKING',
        url: targetUrl,
        error: e,
      );
      rethrow;
    } finally {
      final i = _myRides.indexWhere((r) => r.id == rideId);
      if (i != -1) {
        _myRides[i] = _myRides[i].copyWith(status: CarpoolRideStatus.cancelled);
      }
    }
  }

  CarpoolWalletModel _wallet() => CarpoolWalletModel(
    balance: _balance,
    transactions: List.of(_transactions),
  );

  @override
  Future<CarpoolWalletModel> fetchWallet() async {
    await _latency();
    return _wallet();
  }

  @override
  Future<CarpoolWalletModel> addMoney(double amount) async {
    await _latency();
    _balance += amount;
    _transactions.insert(
      0,
      CarpoolTransactionModel(
        id: 't${_idCounter++}',
        title: 'Added Money',
        date: DateTime.now(),
        amount: amount,
        type: CarpoolTransactionType.topUp,
      ),
    );
    return _wallet();
  }

  @override
  Future<List<CarpoolMessageModel>> fetchMessages() async {
    await _latency();
    return const [
      CarpoolMessageModel(
        id: 'm1',
        senderName: 'Ramesh Kumar',
        preview: 'Thanks for the ride!',
        timeAgo: '2m',
        unreadCount: 1,
        category: CarpoolMessageCategory.rides,
      ),
      CarpoolMessageModel(
        id: 'm2',
        senderName: 'Srinivas',
        preview: 'See you soon',
        timeAgo: '1h',
        unreadCount: 0,
        category: CarpoolMessageCategory.rides,
      ),
      CarpoolMessageModel(
        id: 'm3',
        senderName: 'Support Team',
        preview: 'Your ticket #4587 is updated',
        timeAgo: '1d',
        unreadCount: 0,
        category: CarpoolMessageCategory.support,
      ),
      CarpoolMessageModel(
        id: 'm4',
        senderName: 'System',
        preview: 'Welcome to RideMax!',
        timeAgo: '2d',
        unreadCount: 0,
        category: CarpoolMessageCategory.system,
      ),
    ];
  }

  @override
  Future<CarpoolPricingEntity> calculatePricing(
    CarpoolCalculatePricingParams params,
  ) async {
    const targetUrl = ApiEndpoints.calculatePricing;
    final uri = Uri.parse(targetUrl);
    final payloadJson = jsonEncode(params.toJson());

    ApiLogger.logRequest(
      title: 'CALCULATE_PRICING',
      url: targetUrl,
      method: 'POST',
      body: payloadJson,
    );

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(payloadJson);

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'CALCULATE_PRICING',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
          return CarpoolPricingEntity.fromJson(data);
        }
      }
      throw Exception('Pricing calculation failed: ${response.statusCode}');
    } catch (e) {
      ApiLogger.logError(title: 'CALCULATE_PRICING', url: targetUrl, error: e);
      // Fallback matching user provided response format if backend is offline
      const double dist = 268.4;
      const double rate = 3.5;
      const int suggested = 939;
      return const CarpoolPricingEntity(
        distanceKm: dist,
        effectiveDistanceKm: dist,
        durationMinutes: 310,
        provider: 'osrm',
        ratePerKm: rate,
        suggestedPrice: suggested,
        allowedPriceRange: CarpoolAllowedPriceRange(
          min: 704,
          max: 1221,
          allowedDeviationPercent: 30,
          minAllowedDeviationPercent: 25,
          maxAllowedDeviationPercent: 30,
        ),
        platformCharge: 15,
        riderBookingFee: 15,
        driverCommissionType: 'percent',
        driverCommissionValue: 0,
        enableNegotiation: true,
      );
    }
  }
}
