import '../../domain/entities/party_entities.dart';

class PartyCategoryModel extends PartyCategoryEntity {
  const PartyCategoryModel({
    required super.id,
    required super.name,
    required super.shortName,
    super.imageUrl,
  });

  factory PartyCategoryModel.fromJson(Map<String, dynamic> json) =>
      PartyCategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        shortName: json['shortName'] as String,
        imageUrl: (json['imageUrl'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'shortName': shortName, 'imageUrl': imageUrl};
}

class PartyVenueModel extends PartyVenueEntity {
  const PartyVenueModel({
    required super.id,
    required super.name,
    required super.location,
    required super.rating,
    required super.reviewCount,
    required super.priceFrom,
    required super.capacity,
    required super.hasAc,
    required super.hasParking,
    required super.hasCatering,
    required super.description,
    required super.categoryIds,
    super.imageUrls,
    super.imageCount,
  });

  factory PartyVenueModel.fromJson(Map<String, dynamic> json) =>
      PartyVenueModel(
        id: json['id'] as String,
        name: json['name'] as String,
        location: json['location'] as String,
        rating: (json['rating'] as num).toDouble(),
        reviewCount: json['reviewCount'] as int,
        priceFrom: json['priceFrom'] as int,
        capacity: json['capacity'] as int,
        hasAc: json['hasAc'] as bool,
        hasParking: json['hasParking'] as bool,
        hasCatering: json['hasCatering'] as bool,
        description: json['description'] as String,
        categoryIds: List<String>.from(json['categoryIds'] as List),
        imageUrls: List<String>.from((json['imageUrls'] as List?) ?? const []),
        imageCount: (json['imageCount'] as int?) ?? 8,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'rating': rating,
        'reviewCount': reviewCount,
        'priceFrom': priceFrom,
        'capacity': capacity,
        'hasAc': hasAc,
        'hasParking': hasParking,
        'hasCatering': hasCatering,
        'description': description,
        'categoryIds': categoryIds,
        'imageUrls': imageUrls,
        'imageCount': imageCount,
      };
}

class PartyBookingModel extends PartyBookingEntity {
  const PartyBookingModel({
    required super.id,
    required super.venue,
    required super.date,
    required super.timeSlot,
    required super.guests,
    required super.status,
    required super.guestName,
    required super.phone,
    required super.notes,
    required super.paymentMethod,
    required super.totalAmount,
    required super.advanceAmount,
  });

  factory PartyBookingModel.fromJson(Map<String, dynamic> json) =>
      PartyBookingModel(
        id: json['id'] as String,
        venue: PartyVenueModel.fromJson(json['venue'] as Map<String, dynamic>),
        date: DateTime.parse(json['date'] as String),
        timeSlot: json['timeSlot'] as String,
        guests: json['guests'] as int,
        status: PartyBookingStatus.values.byName(json['status'] as String),
        guestName: json['guestName'] as String,
        phone: json['phone'] as String,
        notes: (json['notes'] as String?) ?? '',
        paymentMethod:
            PartyPaymentMethod.values.byName(json['paymentMethod'] as String),
        totalAmount: json['totalAmount'] as int,
        advanceAmount: json['advanceAmount'] as int,
      );

  @override
  PartyBookingModel copyWith({PartyBookingStatus? status}) => PartyBookingModel(
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
}
