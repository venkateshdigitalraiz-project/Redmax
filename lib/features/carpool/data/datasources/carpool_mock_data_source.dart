import 'package:pathway/core/utils/carpool_distance_calculator.dart';

import '../../domain/entities/carpool_entities.dart';
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

    _myRides = [
      CarpoolRideModel(
        id: 'r1',
        driverName: 'Ramesh Kumar',
        driverRating: 4.8,
        driverTrips: 120,
        vehicle: 'Maruti Dzire',
        from: 'Hyderabad',
        to: 'Vijayawada',
        departure: at(1, 9),
        seats: 3,
        pricePerSeat: 250,
        distanceKm: 275,
        status: CarpoolRideStatus.upcoming,
        rideType: CarpoolRideType.normal,
      ),
      CarpoolRideModel(
        id: 'r2',
        driverName: 'Srinivas',
        driverRating: 4.7,
        driverTrips: 95,
        vehicle: 'Honda City',
        from: 'Hyderabad',
        to: 'Guntur',
        departure: at(3, 18),
        seats: 2,
        pricePerSeat: 260,
        distanceKm: 300,
        status: CarpoolRideStatus.upcoming,
        rideType: CarpoolRideType.normal,
      ),
      CarpoolRideModel(
        id: 'r3',
        driverName: 'Anil Reddy',
        driverRating: 4.6,
        driverTrips: 64,
        vehicle: 'Hyundai i20',
        from: 'Hyderabad',
        to: 'Bangalore',
        departure: at(-6, 7),
        seats: 3,
        pricePerSeat: 600,
        distanceKm: 570,
        status: CarpoolRideStatus.completed,
        rideType: CarpoolRideType.premium,
      ),
    ];

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
    _popularRoutes.removeWhere((r) =>
        r.from.toLowerCase() == from.toLowerCase() &&
        r.to.toLowerCase() == to.toLowerCase());
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
    await _latency();
    final dist = CarpoolDistanceCalculator.calculateDistanceKm(p.from, p.to);
    final totalFare = dist * 10;
    final pricePerSeat = (totalFare / (p.seats > 0 ? p.seats : 1)).round();

    final ride = CarpoolRideModel(
      id: 'r${_idCounter++}',
      driverName: 'Venkatesh',
      driverRating: 4.9,
      driverTrips: 18,
      vehicle: 'Honda City',
      from: p.from,
      to: p.to,
      departure: p.departure,
      seats: p.seats,
      pricePerSeat: pricePerSeat,
      distanceKm: dist,
      status: CarpoolRideStatus.upcoming,
      rideType: p.rideType,
    );
    _myRides.add(ride);
    return ride;
  }

  @override
  Future<List<CarpoolRideModel>> fetchMyRides() async {
    await _latency();
    final list = [..._myRides]
      ..sort((a, b) => a.departure.compareTo(b.departure));
    return list;
  }

  @override
  Future<void> cancelRide(String rideId) async {
    await _latency();
    final i = _myRides.indexWhere((r) => r.id == rideId);
    if (i != -1) {
      _myRides[i] = _myRides[i].copyWith(status: CarpoolRideStatus.cancelled);
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
}
