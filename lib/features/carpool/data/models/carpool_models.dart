import '../../domain/entities/carpool_entities.dart';

class CarpoolUserModel extends CarpoolUserEntity {
  const CarpoolUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.rating,
    required super.isPremium,
  });

  factory CarpoolUserModel.fromJson(Map<String, dynamic> json) =>
      CarpoolUserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        rating: (json['rating'] as num).toDouble(),
        isPremium: json['isPremium'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'rating': rating,
        'isPremium': isPremium,
      };
}

class CarpoolPopularRouteModel extends CarpoolPopularRouteEntity {
  const CarpoolPopularRouteModel(
      {required super.from, required super.to, required super.price});

  factory CarpoolPopularRouteModel.fromJson(Map<String, dynamic> json) =>
      CarpoolPopularRouteModel(
        from: json['from'] as String,
        to: json['to'] as String,
        price: json['price'] as int,
      );

  Map<String, dynamic> toJson() => {'from': from, 'to': to, 'price': price};
}

class CarpoolRideModel extends CarpoolRideEntity {
  const CarpoolRideModel({
    required super.id,
    required super.driverName,
    required super.driverRating,
    required super.driverTrips,
    required super.vehicle,
    required super.from,
    required super.to,
    required super.departure,
    required super.seats,
    required super.pricePerSeat,
    required super.distanceKm,
    required super.status,
    required super.rideType,
  });

  factory CarpoolRideModel.fromJson(Map<String, dynamic> json) =>
      CarpoolRideModel(
        id: json['id'] as String,
        driverName: json['driverName'] as String,
        driverRating: (json['driverRating'] as num).toDouble(),
        driverTrips: json['driverTrips'] as int,
        vehicle: json['vehicle'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        departure: DateTime.parse(json['departure'] as String),
        seats: json['seats'] as int,
        pricePerSeat: json['pricePerSeat'] as int,
        distanceKm: json['distanceKm'] as int,
        status: CarpoolRideStatus.values.byName(json['status'] as String),
        rideType: CarpoolRideType.values.byName(json['rideType'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'driverName': driverName,
        'driverRating': driverRating,
        'driverTrips': driverTrips,
        'vehicle': vehicle,
        'from': from,
        'to': to,
        'departure': departure.toIso8601String(),
        'seats': seats,
        'pricePerSeat': pricePerSeat,
        'distanceKm': distanceKm,
        'status': status.name,
        'rideType': rideType.name,
      };

  @override
  CarpoolRideModel copyWith({CarpoolRideStatus? status, int? seats}) =>
      CarpoolRideModel(
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

class CarpoolTransactionModel extends CarpoolTransactionEntity {
  const CarpoolTransactionModel({
    required super.id,
    required super.title,
    required super.date,
    required super.amount,
    required super.type,
  });

  factory CarpoolTransactionModel.fromJson(Map<String, dynamic> json) =>
      CarpoolTransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
        type: CarpoolTransactionType.values.byName(json['type'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type.name,
      };
}

class CarpoolWalletModel extends CarpoolWalletEntity {
  const CarpoolWalletModel(
      {required super.balance, required super.transactions});

  factory CarpoolWalletModel.fromJson(Map<String, dynamic> json) =>
      CarpoolWalletModel(
        balance: (json['balance'] as num).toDouble(),
        transactions: (json['transactions'] as List)
            .map((e) =>
                CarpoolTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CarpoolMessageModel extends CarpoolMessageEntity {
  const CarpoolMessageModel({
    required super.id,
    required super.senderName,
    required super.preview,
    required super.timeAgo,
    required super.unreadCount,
    required super.category,
  });

  factory CarpoolMessageModel.fromJson(Map<String, dynamic> json) =>
      CarpoolMessageModel(
        id: json['id'] as String,
        senderName: json['senderName'] as String,
        preview: json['preview'] as String,
        timeAgo: json['timeAgo'] as String,
        unreadCount: json['unreadCount'] as int,
        category:
            CarpoolMessageCategory.values.byName(json['category'] as String),
      );
}
