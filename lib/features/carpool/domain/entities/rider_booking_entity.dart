import 'package:equatable/equatable.dart';

enum RiderBookingStatus { confirmed, completed, cancelled }

/// Entity representing a booking made by a rider/passenger.
class RiderBookingEntity extends Equatable {
  const RiderBookingEntity({
    required this.id,
    required this.rideId,
    required this.driverName,
    required this.driverPhone,
    required this.driverRating,
    required this.vehicle,
    required this.from,
    required this.to,
    required this.departure,
    required this.seatsBooked,
    required this.pricePerSeat,
    required this.totalAmount,
    required this.status,
    required this.bookingDate,
    this.vehicleNumber,
    this.otpCode,
  });

  final String id;
  final String rideId;
  final String driverName;
  final String driverPhone;
  final double driverRating;
  final String vehicle;
  final String from;
  final String to;
  final DateTime departure;
  final int seatsBooked;
  final int pricePerSeat;
  final int totalAmount;
  final RiderBookingStatus status;
  final DateTime bookingDate;
  final String? vehicleNumber;
  final String? otpCode;

  RiderBookingEntity copyWith({
    RiderBookingStatus? status,
  }) {
    return RiderBookingEntity(
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

  @override
  List<Object?> get props => [
        id,
        rideId,
        driverName,
        driverPhone,
        driverRating,
        vehicle,
        from,
        to,
        departure,
        seatsBooked,
        pricePerSeat,
        totalAmount,
        status,
        bookingDate,
        vehicleNumber,
        otpCode,
      ];
}

