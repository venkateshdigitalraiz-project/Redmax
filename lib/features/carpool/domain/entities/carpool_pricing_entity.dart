import 'package:equatable/equatable.dart';

class CarpoolAllowedPriceRange extends Equatable {
  final int min;
  final int max;
  final int allowedDeviationPercent;
  final int minAllowedDeviationPercent;
  final int maxAllowedDeviationPercent;

  const CarpoolAllowedPriceRange({
    required this.min,
    required this.max,
    this.allowedDeviationPercent = 30,
    this.minAllowedDeviationPercent = 25,
    this.maxAllowedDeviationPercent = 30,
  });

  factory CarpoolAllowedPriceRange.fromJson(Map<String, dynamic> json) {
    return CarpoolAllowedPriceRange(
      min: (json['min'] as num?)?.toInt() ?? 0,
      max: (json['max'] as num?)?.toInt() ?? 0,
      allowedDeviationPercent:
          (json['allowedDeviationPercent'] as num?)?.toInt() ?? 30,
      minAllowedDeviationPercent:
          (json['minAllowedDeviationPercent'] as num?)?.toInt() ?? 25,
      maxAllowedDeviationPercent:
          (json['maxAllowedDeviationPercent'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'allowedDeviationPercent': allowedDeviationPercent,
        'minAllowedDeviationPercent': minAllowedDeviationPercent,
        'maxAllowedDeviationPercent': maxAllowedDeviationPercent,
      };

  @override
  List<Object?> get props => [
        min,
        max,
        allowedDeviationPercent,
        minAllowedDeviationPercent,
        maxAllowedDeviationPercent,
      ];
}

class CarpoolPricingEntity extends Equatable {
  final double distanceKm;
  final double effectiveDistanceKm;
  final int durationMinutes;
  final String provider;
  final double ratePerKm;
  final int suggestedPrice;
  final CarpoolAllowedPriceRange allowedPriceRange;
  final int platformCharge;
  final int riderBookingFee;
  final String driverCommissionType;
  final int driverCommissionValue;
  final bool enableNegotiation;
  final Map<String, dynamic> rawData;

  const CarpoolPricingEntity({
    required this.distanceKm,
    required this.effectiveDistanceKm,
    required this.durationMinutes,
    required this.provider,
    required this.ratePerKm,
    required this.suggestedPrice,
    required this.allowedPriceRange,
    required this.platformCharge,
    required this.riderBookingFee,
    required this.driverCommissionType,
    required this.driverCommissionValue,
    required this.enableNegotiation,
    this.rawData = const {},
  });

  int get minAllowedPrice => allowedPriceRange.min;
  int get maxAllowedPrice => allowedPriceRange.max;

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    }
    return '$minutes min';
  }

  factory CarpoolPricingEntity.fromJson(Map<String, dynamic> json) {
    final rangeMap = json['allowedPriceRange'] is Map<String, dynamic>
        ? json['allowedPriceRange'] as Map<String, dynamic>
        : <String, dynamic>{};

    return CarpoolPricingEntity(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      effectiveDistanceKm:
          (json['effectiveDistanceKm'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      provider: json['provider']?.toString() ?? 'osrm',
      ratePerKm: (json['ratePerKm'] as num?)?.toDouble() ?? 3.5,
      suggestedPrice: (json['suggestedPrice'] as num?)?.toInt() ?? 0,
      allowedPriceRange: CarpoolAllowedPriceRange.fromJson(rangeMap),
      platformCharge: (json['platformCharge'] as num?)?.toInt() ?? 0,
      riderBookingFee: (json['riderBookingFee'] as num?)?.toInt() ?? 0,
      driverCommissionType:
          json['driverCommissionType']?.toString() ?? 'percent',
      driverCommissionValue:
          (json['driverCommissionValue'] as num?)?.toInt() ?? 0,
      enableNegotiation: json['enableNegotiation'] as bool? ?? true,
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'distanceKm': distanceKm,
        'effectiveDistanceKm': effectiveDistanceKm,
        'durationMinutes': durationMinutes,
        'provider': provider,
        'ratePerKm': ratePerKm,
        'suggestedPrice': suggestedPrice,
        'allowedPriceRange': allowedPriceRange.toJson(),
        'platformCharge': platformCharge,
        'riderBookingFee': riderBookingFee,
        'driverCommissionType': driverCommissionType,
        'driverCommissionValue': driverCommissionValue,
        'enableNegotiation': enableNegotiation,
      };

  @override
  List<Object?> get props => [
        distanceKm,
        effectiveDistanceKm,
        durationMinutes,
        provider,
        ratePerKm,
        suggestedPrice,
        allowedPriceRange,
        platformCharge,
        riderBookingFee,
        driverCommissionType,
        driverCommissionValue,
        enableNegotiation,
      ];
}

