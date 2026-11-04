import 'package:equatable/equatable.dart';

enum CarpoolRideStatus { upcoming, completed, cancelled }

enum CarpoolRideType { normal, premium }

enum CarpoolDayFilter { today, tomorrow, anyTime }

enum CarpoolTransactionType { payment, reward, topUp }

enum CarpoolMessageCategory { rides, support, system }

class CarpoolUserEntity extends Equatable {
  const CarpoolUserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.rating,
    required this.isPremium,
  });

  final String id;
  final String name;
  final String email;
  final double rating;
  final bool isPremium;

  @override
  List<Object?> get props => [id, name, email, rating, isPremium];
}

class CarpoolPopularRouteEntity extends Equatable {
  const CarpoolPopularRouteEntity({
    required this.from,
    required this.to,
    required this.price,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  final String from;
  final String to;
  final int price;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  @override
  List<Object?> get props => [from, to, price, fromLat, fromLng, toLat, toLng];
}

class CarpoolRideEntity extends Equatable {
  const CarpoolRideEntity({
    required this.id,
    required this.driverName,
    required this.driverRating,
    required this.driverTrips,
    required this.vehicle,
    required this.from,
    required this.to,
    required this.departure,
    required this.seats,
    required this.pricePerSeat,
    required this.distanceKm,
    required this.status,
    required this.rideType,
  });

  final String id;
  final String driverName;
  final double driverRating;
  final int driverTrips;
  final String vehicle;
  final String from;
  final String to;
  final DateTime departure;
  final int seats;
  final int pricePerSeat;
  final int distanceKm;
  final CarpoolRideStatus status;
  final CarpoolRideType rideType;

  CarpoolRideEntity copyWith({CarpoolRideStatus? status, int? seats}) {
    return CarpoolRideEntity(
      id: id,
      driverName: driverName,
      driverRating: driverRating,
      driverTrips: driverTrips,
      vehicle: vehicle,
      from: from,
      to: to,
      departure: departure,
      seats: seats ?? this.seats,
      pricePerSeat: pricePerSeat,
      distanceKm: distanceKm,
      status: status ?? this.status,
      rideType: rideType,
    );
  }

  @override
  List<Object?> get props => [
        id, driverName, driverRating, driverTrips, vehicle, from, to,
        departure, seats, pricePerSeat, distanceKm, status, rideType,
      ];
}

class CarpoolPublishRideParams extends Equatable {
  const CarpoolPublishRideParams({
    required this.from,
    required this.to,
    required this.departure,
    required this.seats,
    required this.rideType,
    this.pricePerSeat,
  });

  final String from;
  final String to;
  final DateTime departure;
  final int seats;
  final CarpoolRideType rideType;
  final int? pricePerSeat;

  @override
  List<Object?> get props => [from, to, departure, seats, rideType, pricePerSeat];
}

class CarpoolSearchRidesParams extends Equatable {
  const CarpoolSearchRidesParams({
    required this.from,
    required this.to,
    required this.filter,
  });

  final String from;
  final String to;
  final CarpoolDayFilter filter;

  @override
  List<Object?> get props => [from, to, filter];
}

class CarpoolTransactionEntity extends Equatable {
  const CarpoolTransactionEntity({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
  });

  final String id;
  final String title;
  final DateTime date;
  final double amount;
  final CarpoolTransactionType type;

  @override
  List<Object?> get props => [id, title, date, amount, type];
}

class CarpoolWalletEntity extends Equatable {
  const CarpoolWalletEntity({required this.balance, required this.transactions});

  final double balance;
  final List<CarpoolTransactionEntity> transactions;

  @override
  List<Object?> get props => [balance, transactions];
}

class CarpoolMessageEntity extends Equatable {
  const CarpoolMessageEntity({
    required this.id,
    required this.senderName,
    required this.preview,
    required this.timeAgo,
    required this.unreadCount,
    required this.category,
  });

  final String id;
  final String senderName;
  final String preview;
  final String timeAgo;
  final int unreadCount;
  final CarpoolMessageCategory category;

  @override
  List<Object?> get props =>
      [id, senderName, preview, timeAgo, unreadCount, category];
}
