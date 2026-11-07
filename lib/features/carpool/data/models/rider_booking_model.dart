import '../../domain/entities/rider_booking_entity.dart';

class RiderBookingModel extends RiderBookingEntity {
  const RiderBookingModel({
    required super.id,
    required super.rideId,
    required super.driverName,
    required super.driverPhone,
    required super.driverRating,
    required super.vehicle,
    required super.from,
    required super.to,
    required super.departure,
    required super.seatsBooked,
    required super.pricePerSeat,
    required super.totalAmount,
    required super.status,
    required super.bookingDate,
    super.vehicleNumber,
    super.otpCode,
  });

  factory RiderBookingModel.fromJson(Map<String, dynamic> json) {
    // 1. Driver info
    String driverName = 'Driver';
    String driverPhone = '+91 98765 43210';
    double driverRating = 4.8;
    if (json['driver'] is Map<String, dynamic>) {
      final d = json['driver'] as Map<String, dynamic>;
      driverName = d['name']?.toString() ?? driverName;
      driverPhone = d['phone']?.toString() ?? driverPhone;
      driverRating = (d['rating'] as num?)?.toDouble() ?? driverRating;
    } else {
      driverName = json['driverName']?.toString() ?? driverName;
      driverPhone = json['driverPhone']?.toString() ?? driverPhone;
      driverRating =
          (json['driverRating'] as num?)?.toDouble() ?? driverRating;
    }

    // 2. Locations
    final from = json['from']?.toString() ??
        json['origin']?.toString() ??
        json['pickup']?.toString() ??
        '';
    final to = json['to']?.toString() ??
        json['destination']?.toString() ??
        json['dropoff']?.toString() ??
        '';

    // 3. Timestamps
    DateTime departure = DateTime.now().add(const Duration(hours: 3));
    final depRaw = json['departure'] ?? json['departureTime'] ?? json['date'];
    if (depRaw != null) {
      final parsed = DateTime.tryParse(depRaw.toString());
      if (parsed != null) departure = parsed.toLocal();
    }

    DateTime bookingDate = DateTime.now();
    final bookRaw = json['bookingDate'] ?? json['createdAt'];
    if (bookRaw != null) {
      final parsed = DateTime.tryParse(bookRaw.toString());
      if (parsed != null) bookingDate = parsed.toLocal();
    }

    // 4. Seats & Pricing
    final seatsBooked = (json['seatsBooked'] as num?)?.toInt() ??
        (json['seats'] as num?)?.toInt() ??
        1;
    final pricePerSeat = (json['pricePerSeat'] as num?)?.toInt() ??
        (json['price'] as num?)?.toInt() ??
        250;
    final totalAmount = (json['totalAmount'] as num?)?.toInt() ??
        (json['totalPrice'] as num?)?.toInt() ??
        (seatsBooked * pricePerSeat);

    // 5. Vehicle
    final vehicle = json['vehicle']?.toString() ??
        json['vehicleModel']?.toString() ??
        'Honda City';
    final vehicleNumber = json['vehicleNumber']?.toString() ?? 'DL 01 AB 1234';
    final otpCode = json['otpCode']?.toString() ?? '4821';

    // 6. Status
    RiderBookingStatus status = RiderBookingStatus.confirmed;
    final statusStr = json['status']?.toString().toLowerCase();
    if (statusStr != null) {
      if (statusStr == 'completed') {
        status = RiderBookingStatus.completed;
      } else if (statusStr == 'cancelled' || statusStr == 'canceled') {
        status = RiderBookingStatus.cancelled;
      } else {
        status = RiderBookingStatus.confirmed;
      }
    }

    return RiderBookingModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          'bk-${DateTime.now().millisecondsSinceEpoch}',
      rideId: json['rideId']?.toString() ?? 'ride-default',
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      vehicle: vehicle,
      from: from,
      to: to,
      departure: departure,
      seatsBooked: seatsBooked,
      pricePerSeat: pricePerSeat,
      totalAmount: totalAmount,
      status: status,
      bookingDate: bookingDate,
      vehicleNumber: vehicleNumber,
      otpCode: otpCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rideId': rideId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'driverRating': driverRating,
        'vehicle': vehicle,
        'from': from,
        'to': to,
        'departure': departure.toIso8601String(),
        'seatsBooked': seatsBooked,
        'pricePerSeat': pricePerSeat,
        'totalAmount': totalAmount,
        'status': status.name,
        'bookingDate': bookingDate.toIso8601String(),
        'vehicleNumber': vehicleNumber,
        'otpCode': otpCode,
      };

  @override
  RiderBookingModel copyWith({
    RiderBookingStatus? status,
  }) {
    return RiderBookingModel(
      id: id,
      rideId: rideId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      vehicle: vehicle,
      from: from,
      to: to,
      departure: departure,
      seatsBooked: seatsBooked,
      pricePerSeat: pricePerSeat,
      totalAmount: totalAmount,
      status: status ?? this.status,
      bookingDate: bookingDate,
      vehicleNumber: vehicleNumber,
      otpCode: otpCode,
    );
  }
}

