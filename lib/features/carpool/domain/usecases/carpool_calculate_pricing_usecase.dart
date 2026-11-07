import 'package:equatable/equatable.dart';
import '../entities/carpool_pricing_entity.dart';
import '../repositories/carpool_repository.dart';

class CarpoolCalculatePricingParams extends Equatable {
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;

  const CarpoolCalculatePricingParams({
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
  });

  Map<String, dynamic> toJson() => {
        'originLat': originLat,
        'originLng': originLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
      };

  @override
  List<Object?> get props => [
        originLat,
        originLng,
        destinationLat,
        destinationLng,
      ];
}

class CarpoolCalculatePricingUseCase {
  final CarpoolRepository repository;

  const CarpoolCalculatePricingUseCase(this.repository);

  Future<CarpoolPricingEntity> call(CarpoolCalculatePricingParams params) {
    return repository.calculatePricing(params);
  }
}

