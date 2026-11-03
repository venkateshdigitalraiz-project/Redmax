import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../domain/entities/place_prediction_entity.dart';

class PlacePredictionModel extends PlacePredictionEntity {
  const PlacePredictionModel({
    required super.placeId,
    required super.description,
    required super.mainText,
    required super.secondaryText,
    super.lat,
    super.lng,
  });

  factory PlacePredictionModel.fromJson(Map<String, dynamic> raw) {
    // Supports both Places API (New) suggestion item and Legacy API prediction item
    final json = (raw['placePrediction'] as Map<String, dynamic>?) ?? raw;

    final placeId = (json['placeId'] ?? json['place_id'] ?? json['place'] ?? '')
        as String;

    // Places API (New) fields
    final structuredFormat = json['structuredFormat'] as Map<String, dynamic>?;
    final textObj = json['text'] as Map<String, dynamic>?;

    // Legacy Places API fields
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>?;

    String description = textObj?['text'] as String? ??
        (json['description'] as String? ?? '');

    String mainText = '';
    if (structuredFormat?['mainText'] is Map) {
      mainText =
          (structuredFormat!['mainText'] as Map<String, dynamic>)['text']
                  as String? ??
              '';
    } else if (structuredFormatting?['main_text'] != null) {
      mainText = structuredFormatting!['main_text'] as String? ?? '';
    }

    String secondaryText = '';
    if (structuredFormat?['secondaryText'] is Map) {
      secondaryText =
          (structuredFormat!['secondaryText'] as Map<String, dynamic>)['text']
                  as String? ??
              '';
    } else if (structuredFormatting?['secondary_text'] != null) {
      secondaryText = structuredFormatting!['secondary_text'] as String? ?? '';
    }

    if (mainText.isEmpty) {
      if (description.contains(',')) {
        final parts = description.split(',');
        mainText = parts.first.trim();
        secondaryText = parts.sublist(1).join(',').trim();
      } else {
        mainText = description;
      }
    }

    // Resolve lat/lng from json or fallback to our AP/TS coordinate database
    double? lat = (json['lat'] ?? json['latitude']) as double?;
    double? lng = (json['lng'] ?? json['longitude']) as double?;

    if (lat == null || lng == null) {
      final geo = CarpoolDistanceCalculator.findGeo(mainText);
      if (geo != null) {
        lat = geo.lat;
        lng = geo.lng;
      }
    }

    return PlacePredictionModel(
      placeId: placeId,
      description: description,
      mainText: mainText,
      secondaryText: secondaryText,
      lat: lat,
      lng: lng,
    );
  }

  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'description': description,
    'lat': lat,
    'lng': lng,
    'structured_formatting': {
      'main_text': mainText,
      'secondary_text': secondaryText,
    },
  };
}
