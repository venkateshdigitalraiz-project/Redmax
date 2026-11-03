import 'dart:convert';
import 'dart:io';

import '../../../../core/utils/carpool_distance_calculator.dart';
import '../models/place_prediction_model.dart';

abstract class PlacesRemoteDataSource {
  Future<List<PlacePredictionModel>> getPlacePredictions(String query);
}

class GooglePlacesRemoteDataSourceImpl implements PlacesRemoteDataSource {
  final String apiKey;
  final HttpClient _client;

  GooglePlacesRemoteDataSourceImpl({
    required this.apiKey,
    HttpClient? client,
  }) : _client = client ?? HttpClient();

  @override
  Future<List<PlacePredictionModel>> getPlacePredictions(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return _getDefaultPopularPlaces();
    }

    // 1. Google Places API (New): Primary endpoint enabled on modern Google Cloud projects.
    // Accurately discovers Indian villages, mandals, towns, cities, districts, and localities.
    try {
      final uriNew = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );
      final request = await _client.postUrl(uriNew).timeout(
        const Duration(seconds: 7),
      );
      request.headers.set('X-Goog-Api-Key', apiKey);
      request.headers.set('Content-Type', 'application/json');
      request.write(
        jsonEncode({
          'input': cleanQuery,
          'includedRegionCodes': ['in'],
        }),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 7),
      );
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final map = jsonDecode(body) as Map<String, dynamic>;
        final suggestions = map['suggestions'] as List<dynamic>?;
        if (suggestions != null && suggestions.isNotEmpty) {
          final results = suggestions
              .map(
                (e) => PlacePredictionModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
          if (results.isNotEmpty) return results;
        }
      }
    } catch (_) {
      // Fall through to Legacy / Offline fallback
    }

    // 2. Google Places API (Legacy) Fallback
    try {
      final uriLegacy = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': cleanQuery,
          'key': apiKey,
          'components': 'country:in',
          'language': 'en',
        },
      );
      final req = await _client.getUrl(uriLegacy).timeout(
        const Duration(seconds: 6),
      );
      final res = await req.close().timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final map = jsonDecode(body) as Map<String, dynamic>;
        final status = map['status'] as String? ?? '';
        if (status == 'OK') {
          final predictions = (map['predictions'] as List<dynamic>? ?? [])
              .map(
                (e) => PlacePredictionModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
          if (predictions.isNotEmpty) return predictions;
        }
      }
    } catch (_) {
      // Fall through to rich local fallback
    }

    return _filterFallback(cleanQuery);
  }

  List<PlacePredictionModel> _filterFallback(String query) {
    final lower = query.toLowerCase();
    final all = _getDefaultPopularPlaces();
    final matched = all.where((p) {
      return p.mainText.toLowerCase().contains(lower) ||
          p.secondaryText.toLowerCase().contains(lower) ||
          p.description.toLowerCase().contains(lower);
    }).toList();

    if (matched.isNotEmpty) return matched;

    final capitalized = query.isNotEmpty
        ? '${query[0].toUpperCase()}${query.substring(1)}'
        : query;

    final geo = CarpoolDistanceCalculator.findGeo(capitalized);

    return [
      PlacePredictionModel(
        placeId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        description: '$capitalized, India',
        mainText: capitalized,
        secondaryText: geo != null ? geo.subtitle : 'Village / Town / City in India',
        lat: geo?.lat,
        lng: geo?.lng,
      ),
      ...all,
    ];
  }

  List<PlacePredictionModel> _getDefaultPopularPlaces() {
    final seen = <String>{};
    final list = <PlacePredictionModel>[];

    for (final geo in CarpoolDistanceCalculator.placeGeoDatabase.values) {
      final key = geo.name.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        list.add(
          PlacePredictionModel(
            placeId: 'geo_${geo.name.toLowerCase().replaceAll(' ', '_')}',
            description: '${geo.name}, ${geo.district}, ${geo.state}, India',
            mainText: geo.name,
            secondaryText: geo.subtitle,
            lat: geo.lat,
            lng: geo.lng,
          ),
        );
      }
    }
    return list;
  }
}
