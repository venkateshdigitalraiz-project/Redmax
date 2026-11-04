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
      return const [];
    }

    // 1. Google Places API (New): Primary endpoint enabled on modern Google Cloud projects.
    try {
      final uriNew = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );
      final request = await _client.postUrl(uriNew).timeout(
        const Duration(seconds: 4),
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
        const Duration(seconds: 4),
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
      // Fall through to real-time OSM Geocoder
    }

    // 2. Real-Time Dynamic OpenStreetMap Photon Geocoder
    // Discovers every village, town, mandal, district, locality & city across India
    // with exact live latitude and longitude without static hardcoded data.
    try {
      final photonResults = await _fetchFromPhoton(cleanQuery);
      if (photonResults.isNotEmpty) {
        return photonResults;
      }
    } catch (_) {
      // Fall through to Nominatim
    }

    // 3. OpenStreetMap Nominatim Live Geocoder Fallback
    try {
      final nominatimResults = await _fetchFromNominatim(cleanQuery);
      if (nominatimResults.isNotEmpty) {
        return nominatimResults;
      }
    } catch (_) {
      // Fall through to dynamic query fallback
    }

    return _dynamicSingleFallback(cleanQuery);
  }

  /// Fetches places from Photon (OpenStreetMap Elasticsearch geocoder).
  /// Accurately returns towns, mandals, and villages with real coordinates.
  Future<List<PlacePredictionModel>> _fetchFromPhoton(String query) async {
    final uri = Uri.parse(
      'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=15',
    );
    final req = await _client.getUrl(uri).timeout(const Duration(seconds: 4));
    req.headers.set('User-Agent', 'PathwayCarpoolApp/1.0');
    final res = await req.close().timeout(const Duration(seconds: 4));

    if (res.statusCode != 200) return const [];

    final body = await res.transform(utf8.decoder).join();
    final map = jsonDecode(body) as Map<String, dynamic>;
    final features = map['features'] as List<dynamic>? ?? [];

    final results = <PlacePredictionModel>[];
    final seen = <String>{};

    for (final f in features) {
      final geom = f['geometry'] as Map<String, dynamic>?;
      final props = f['properties'] as Map<String, dynamic>? ?? {};

      final coords = geom?['coordinates'] as List<dynamic>?;
      final double? lng = (coords != null && coords.isNotEmpty)
          ? (coords[0] as num).toDouble()
          : null;
      final double? lat = (coords != null && coords.length > 1)
          ? (coords[1] as num).toDouble()
          : null;

      final name = ((props['name'] ?? props['city'] ?? props['locality'] ?? '') as String).trim();
      if (name.isEmpty) continue;

      final state = (props['state'] ?? '') as String;
      final district = (props['district'] ?? props['county'] ?? '') as String;
      final country = (props['country'] ?? 'India') as String;
      final osmValue = (props['osm_value'] ?? props['type'] ?? '') as String;

      final secParts = <String>[];
      if (district.isNotEmpty && district.toLowerCase() != name.toLowerCase()) {
        secParts.add(district);
      }
      if (state.isNotEmpty) {
        secParts.add(state);
      }
      if (country.isNotEmpty) {
        secParts.add(country);
      }
      final secondaryText = secParts.join(', ');
      final description = secondaryText.isNotEmpty ? '$name, $secondaryText' : name;

      final uniqueKey = '${name.toLowerCase()}_${lat?.toStringAsFixed(3)}_${lng?.toStringAsFixed(3)}';
      if (seen.contains(uniqueKey)) continue;
      seen.add(uniqueKey);

      // Register live coordinates into CarpoolDistanceCalculator for instant distance & map rendering
      if (lat != null && lng != null) {
        CarpoolDistanceCalculator.registerGeo(
          name,
          lat,
          lng,
          type: osmValue.isNotEmpty ? osmValue : 'Town / Village',
          district: district,
          state: state,
        );
      }

      final placeId = 'osm_${props['osm_type'] ?? 'p'}_${props['osm_id'] ?? uniqueKey}';

      results.add(
        PlacePredictionModel(
          placeId: placeId,
          description: description,
          mainText: name,
          secondaryText: secondaryText.isNotEmpty ? secondaryText : 'India',
          lat: lat,
          lng: lng,
        ),
      );
    }

    return results;
  }

  /// Live Nominatim (OpenStreetMap) Fallback
  Future<List<PlacePredictionModel>> _fetchFromNominatim(String query) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'countrycodes': 'in',
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
      },
    );
    final req = await _client.getUrl(uri).timeout(const Duration(seconds: 4));
    req.headers.set('User-Agent', 'PathwayCarpoolApp/1.0');
    final res = await req.close().timeout(const Duration(seconds: 4));

    if (res.statusCode != 200) return const [];

    final body = await res.transform(utf8.decoder).join();
    final list = jsonDecode(body) as List<dynamic>? ?? [];

    final results = <PlacePredictionModel>[];
    final seen = <String>{};

    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final displayName = (item['display_name'] ?? '') as String;
      final rawName = (item['name'] ?? '') as String;
      final parts = displayName.split(',');
      final mainText = rawName.isNotEmpty ? rawName : (parts.isNotEmpty ? parts.first.trim() : query);
      final secondaryText = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

      final double? lat = double.tryParse((item['lat'] ?? '').toString());
      final double? lng = double.tryParse((item['lon'] ?? '').toString());

      final key = '${mainText.toLowerCase()}_${lat?.toStringAsFixed(3)}_${lng?.toStringAsFixed(3)}';
      if (seen.contains(key)) continue;
      seen.add(key);

      if (lat != null && lng != null) {
        CarpoolDistanceCalculator.registerGeo(
          mainText,
          lat,
          lng,
          type: (item['addresstype'] ?? item['type'] ?? 'Village / Town').toString(),
        );
      }

      results.add(
        PlacePredictionModel(
          placeId: (item['place_id'] ?? key).toString(),
          description: displayName,
          mainText: mainText,
          secondaryText: secondaryText,
          lat: lat,
          lng: lng,
        ),
      );
    }

    return results;
  }

  List<PlacePredictionModel> _dynamicSingleFallback(String query) {
    final capitalized = query.isNotEmpty
        ? '${query[0].toUpperCase()}${query.substring(1)}'
        : query;

    final geo = CarpoolDistanceCalculator.findGeo(capitalized);

    return [
      PlacePredictionModel(
        placeId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        description: '$capitalized, India',
        mainText: capitalized,
        secondaryText: geo != null ? geo.subtitle : 'Village / Town / Location in India',
        lat: geo?.lat,
        lng: geo?.lng,
      ),
    ];
  }
}
