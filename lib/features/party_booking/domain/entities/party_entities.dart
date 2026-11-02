import 'package:equatable/equatable.dart';

enum PartyBookingStatus { pending, confirmed, completed, cancelled }

enum PartyPaymentMethod { upi, card, netBanking }

/// Business error shown to the user.
class PartyFailure implements Exception {
  const PartyFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class PartyCategoryEntity extends Equatable {
  const PartyCategoryEntity({
    required this.id,
    required this.name,
    required this.shortName,
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final String shortName;
  final String imageUrl;

  @override
  List<Object?> get props => [id, name, shortName, imageUrl];
}

class PartyVenueEntity extends Equatable {
  const PartyVenueEntity({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.priceFrom,
    required this.capacity,
    required this.hasAc,
    required this.hasParking,
    required this.hasCatering,
    required this.description,
    required this.categoryIds,
    this.imageUrls = const [],
    this.imageCount = 8,
  });

  final String id;
  final String name;
  final String location;
  final double rating;
  final int reviewCount;
  final int priceFrom;
  final int capacity;
  final bool hasAc;
  final bool hasParking;
  final bool hasCatering;
  final String description;
  final List<String> categoryIds;
  final List<String> imageUrls;
  final int imageCount;

  String get coverImage => imageUrls.isEmpty ? '' : imageUrls.first;

  @override
  List<Object?> get props => [
        id, name, location, rating, reviewCount, priceFrom, capacity, hasAc,
        hasParking, hasCatering, description, categoryIds, imageUrls, imageCount,
      ];
}

class PartyBookingEntity extends Equatable {
  const PartyBookingEntity({
    required this.id,
    required this.venue,
    required this.date,
    required this.timeSlot,
    required this.guests,
    required this.status,
    required this.guestName,
    required this.phone,
    required this.notes,
    required this.paymentMethod,
    required this.totalAmount,
    required this.advanceAmount,
  });

  final String id;
  final PartyVenueEntity venue;
  final DateTime date;
  final String timeSlot;
  final int guests;
  final PartyBookingStatus status;
  final String guestName;
  final String phone;
  final String notes;
  final PartyPaymentMethod paymentMethod;
  final int totalAmount;
  final int advanceAmount;

  bool get isUpcoming {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return (status == PartyBookingStatus.pending ||
            status == PartyBookingStatus.confirmed) &&
        !date.isBefore(startOfToday);
  }

  PartyBookingEntity copyWith({PartyBookingStatus? status}) =>
      PartyBookingEntity(
        id: id,
        venue: venue,
        date: date,
        timeSlot: timeSlot,
        guests: guests,
        status: status ?? this.status,
        guestName: guestName,
        phone: phone,
        notes: notes,
        paymentMethod: paymentMethod,
        totalAmount: totalAmount,
        advanceAmount: advanceAmount,
      );

  @override
  List<Object?> get props => [
        id, venue, date, timeSlot, guests, status, guestName, phone, notes,
        paymentMethod, totalAmount, advanceAmount,
      ];
}

class PartySearchVenuesParams extends Equatable {
  const PartySearchVenuesParams({this.query = '', this.categoryId});
  final String query;
  final String? categoryId;
  @override
  List<Object?> get props => [query, categoryId];
}

class PartyTimeSlotsParams extends Equatable {
  const PartyTimeSlotsParams({required this.venueId, required this.date});
  final String venueId;
  final DateTime date;
  @override
  List<Object?> get props => [venueId, date];
}

class PartyCreateBookingParams extends Equatable {
  const PartyCreateBookingParams({
    required this.venueId,
    required this.date,
    required this.timeSlot,
    required this.guests,
    required this.guestName,
    required this.phone,
    required this.notes,
    required this.paymentMethod,
  });

  final String venueId;
  final DateTime date;
  final String timeSlot;
  final int guests;
  final String guestName;
  final String phone;
  final String notes;
  final PartyPaymentMethod paymentMethod;

  @override
  List<Object?> get props =>
      [venueId, date, timeSlot, guests, guestName, phone, notes, paymentMethod];
}
