import 'package:equatable/equatable.dart';

class PlacePredictionEntity extends Equatable {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? lat;
  final double? lng;

  const PlacePredictionEntity({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.lat,
    this.lng,
  });

  @override
  List<Object?> get props => [
        placeId,
        description,
        mainText,
        secondaryText,
        lat,
        lng,
      ];
}
