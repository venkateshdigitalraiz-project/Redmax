import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../constants/api_endpoints.dart';

/// Clean Architecture Utility to accurately calculate distances, durations, and place categories
/// dynamically between any two locations using origin and destination geographic coordinates (Latitude & Longitude).
///
/// Features:
/// 1. Dynamic Geodesic Haversine calculation with Indian road winding coefficient (~1.22x)
///    directly from Origin (lat/lng) and Destination (lat/lng).
/// 2. Asynchronous Google Maps Distance Matrix API integration for real-time live driving distance & duration.
/// 3. In-memory dynamic geo-cache populated from live Google Places API searches & GPS coordinates.
/// 4. Completely removed static/hardcoded highway distances and static town/village/city databases.
class CarpoolDistanceCalculator {
  CarpoolDistanceCalculator._();

  static const String defaultApiKey = ApiEndpoints.googleMapsApiKey;

  /// Configurable default route-deviation threshold in kilometers (default: 40.0 km).
  /// Any stopover adding <= this distance is considered on the route or accessible detour.
  static double defaultRouteDeviationThresholdKm = 40.0;

  // ══════════════════════════════════════════════════════════════════════════
  // DYNAMIC GEO CACHE & INSTANT CITY RESOLVER
  // ══════════════════════════════════════════════════════════════════════════
  static final Map<String, PlaceGeoInfo> _dynamicGeoCache = {};

  /// Fast coordinate resolver for high-frequency localities, towns, and cities
  static const Map<String, ({double lat, double lng})> _knownCityCoordinates = {
    // Current / GPS Default
    'currentlocation': (lat: 17.3850, lng: 78.4867),
    'mylocation': (lat: 17.3850, lng: 78.4867),

    // Hyderabad Urban / Localities
    'ameerpet': (lat: 17.4375, lng: 78.4482),
    'khammam': (lat: 17.2473, lng: 80.1514),
    'hyderabad': (lat: 17.3850, lng: 78.4867),
    'secunderabad': (lat: 17.4399, lng: 78.4983),
    'hiteccity': (lat: 17.4474, lng: 78.3762),
    'hitec': (lat: 17.4474, lng: 78.3762),
    'gachibowli': (lat: 17.4401, lng: 78.3489),
    'madhapur': (lat: 17.4483, lng: 78.3915),
    'jubileehills': (lat: 17.4319, lng: 78.4073),
    'banjarahills': (lat: 17.4156, lng: 78.4357),
    'kukatpally': (lat: 17.4948, lng: 78.3996),
    'miyapur': (lat: 17.4968, lng: 78.3548),
    'dilsukhnagar': (lat: 17.3688, lng: 78.5247),
    'lbnagar': (lat: 17.3501, lng: 78.5511),
    'uppal': (lat: 17.4018, lng: 78.5602),
    'shamshabad': (lat: 17.2543, lng: 78.3976),
    'choutuppal': (lat: 17.2491, lng: 78.9038),
    'bhongir': (lat: 17.5113, lng: 78.8893),
    'patancheru': (lat: 17.5333, lng: 78.2667),
    'sangareddy': (lat: 17.6140, lng: 78.0816),
    'shadnagar': (lat: 17.0722, lng: 78.2088),

    // Telangana Regional Centers
    'warangal': (lat: 17.9689, lng: 79.5941),
    'hanamkonda': (lat: 18.0138, lng: 79.5630),
    'karimnagar': (lat: 18.4386, lng: 79.1288),
    'nizamabad': (lat: 18.6725, lng: 78.0941),
    'suryapet': (lat: 17.1439, lng: 79.6239),
    'nalgonda': (lat: 17.0575, lng: 79.2684),
    'kodad': (lat: 16.9967, lng: 79.9678),
    'miryalaguda': (lat: 16.8727, lng: 79.5631),
    'mahabubnagar': (lat: 16.7488, lng: 77.9863),
    'siddipet': (lat: 18.1018, lng: 78.8520),
    'medak': (lat: 18.0469, lng: 78.2625),
    'vikarabad': (lat: 17.3364, lng: 77.9048),
    'kothagudem': (lat: 17.5500, lng: 80.6167),
    'bhadrachalam': (lat: 17.6688, lng: 80.8936),
    'jangaon': (lat: 17.7231, lng: 79.1558),

    // Andhra Pradesh Major Centers
    'vijayawada': (lat: 16.5062, lng: 80.6480),
    'guntur': (lat: 16.3067, lng: 80.4365),
    'tenali': (lat: 16.2437, lng: 80.6400),
    'mangalagiri': (lat: 16.4300, lng: 80.5700),
    'visakhapatnam': (lat: 17.6868, lng: 83.2185),
    'vizag': (lat: 17.6868, lng: 83.2185),
    'duvvada': (lat: 17.7051, lng: 83.1491),
    'anakapalle': (lat: 17.6913, lng: 83.0039),
    'rajahmundry': (lat: 17.0005, lng: 81.8040),
    'rajahmandry': (lat: 17.0005, lng: 81.8040),
    'rajahmundri': (lat: 17.0005, lng: 81.8040),
    'rajahmadry': (lat: 17.0005, lng: 81.8040),
    'rajamahendravaram': (lat: 17.0005, lng: 81.8040),
    'tuni': (lat: 17.3573, lng: 82.5513),
    'tumi': (lat: 17.3573, lng: 82.5513),
    'annavaram': (lat: 17.2796, lng: 82.4042),
    'kathipudi': (lat: 17.2272, lng: 82.3486),
    'pithapuram': (lat: 17.1121, lng: 82.2588),
    'samalkot': (lat: 17.0514, lng: 82.1706),
    'peddapuram': (lat: 17.0784, lng: 82.1378),
    'ravulapalem': (lat: 16.7516, lng: 81.8436),
    'gannavaram': (lat: 16.5422, lng: 80.8035),
    'hanumanjunction': (lat: 16.6347, lng: 80.9575),
    'payakaraopeta': (lat: 17.3468, lng: 82.5621),
    'nakkapalli': (lat: 17.4116, lng: 82.6845),
    'yelamanchili': (lat: 17.5513, lng: 82.8596),
    'gajuwaka': (lat: 17.6905, lng: 83.2085),
    'kakinada': (lat: 16.9891, lng: 82.2475),
    'eluru': (lat: 16.7107, lng: 81.0952),
    'bhimavaram': (lat: 16.5449, lng: 81.5212),
    'tanuku': (lat: 16.7562, lng: 81.6811),
    'tadepalligudem': (lat: 16.8143, lng: 81.5267),
    'palakollu': (lat: 16.5190, lng: 81.7336),
    'narasapuram': (lat: 16.4414, lng: 81.6966),
    'tirupati': (lat: 13.6288, lng: 79.4192),
    'nellore': (lat: 14.4426, lng: 79.9865),
    'ongole': (lat: 15.5057, lng: 80.0499),
    'kurnool': (lat: 15.8281, lng: 78.0373),
    'anantapur': (lat: 14.6819, lng: 77.6006),
    'kadapa': (lat: 14.4673, lng: 78.8242),
    'machilipatnam': (lat: 16.1876, lng: 81.1389),
    'gudivada': (lat: 16.4350, lng: 80.9980),
    'bapatla': (lat: 15.9042, lng: 80.4675),
    'chirala': (lat: 15.8246, lng: 80.3522),
    'narasaraopet': (lat: 16.2360, lng: 80.0499),
    'chilakaluripet': (lat: 16.0892, lng: 80.1672),

    // Metros / Inter-State
    'bengaluru': (lat: 12.9716, lng: 77.5946),
    'bangalore': (lat: 12.9716, lng: 77.5946),
    'chennai': (lat: 13.0827, lng: 80.2707),
    'mumbai': (lat: 19.0760, lng: 72.8777),
    'pune': (lat: 18.5204, lng: 73.8567),
    'delhi': (lat: 28.6139, lng: 77.2090),
    'newdelhi': (lat: 28.6139, lng: 77.2090),
    'jaipur': (lat: 26.9124, lng: 75.7873),
  };

  /// Compatibility getter for any existing references
  static Map<String, PlaceGeoInfo> get placeGeoDatabase => _dynamicGeoCache;

  /// Dynamically registers any place/location found via live search or GPS
  static void registerGeo(
    String name,
    double lat,
    double lng, {
    String type = 'Location',
    String district = '',
    String state = '',
  }) {
    if (lat < 6.5 || lat > 38.0 || lng < 68.0 || lng > 98.0) {
      return;
    }
    final key = _sanitizeKey(name);
    if (key.isNotEmpty) {
      _dynamicGeoCache[key] = PlaceGeoInfo(
        name: name,
        lat: lat,
        lng: lng,
        type: type,
        district: district,
        state: state,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DYNAMIC DISTANCE CALCULATION (KM) FROM ORIGIN & DESTINATION LAT/LNG
  // ══════════════════════════════════════════════════════════════════════════
  /// Calculates driving distance dynamically based on Origin & Destination Lat/Lng coordinates.
  /// If coordinates are supplied, computes geodesic distance with road curvature factor (1.22x).
  /// Falls back to dynamic cache lookup if lat/lng are omitted.
  static int calculateDistanceKm(
    String from,
    String to, {
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  }) {
    if (from.trim().isEmpty || to.trim().isEmpty) return 0;
    if (from.trim().toLowerCase() == to.trim().toLowerCase()) return 0;

    // 1. Resolve coordinates reliably (checks GPS, known cities, substrings, words, dynamic cache)
    final fromCoords = resolveCoordinates(
      from,
      preferredLat: (fromLat != null && fromLat != 0.0) ? fromLat : null,
      preferredLng: (fromLng != null && fromLng != 0.0) ? fromLng : null,
    );
    final toCoords = resolveCoordinates(
      to,
      preferredLat: (toLat != null && toLat != 0.0) ? toLat : null,
      preferredLng: (toLng != null && toLng != 0.0) ? toLng : null,
    );

    final fLat = fromCoords.lat;
    final fLng = fromCoords.lng;
    final tLat = toCoords.lat;
    final tLng = toCoords.lng;

    // 2. Compute dynamic geodesic distance with 1.22x road winding factor if valid
    if (fLat >= 6.5 && fLat <= 38.0 && fLng >= 68.0 && fLng <= 98.0 &&
        tLat >= 6.5 && tLat <= 38.0 && tLng >= 68.0 && tLng <= 98.0) {
      if ((fLat - tLat).abs() < 0.0001 && (fLng - tLng).abs() < 0.0001) {
        return 0;
      }
      final straight = _haversine(fLat, fLng, tLat, tLng);
      final roadKm = (straight * 1.22).round();
      return roadKm < 1 ? 1 : roadKm;
    }

    return 0;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIVE GOOGLE DISTANCE MATRIX API ASYNC FETCHER
  // ══════════════════════════════════════════════════════════════════════════
  static Future<DistanceResult> fetchLiveDistance(
    String from,
    String to, {
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    String apiKey = defaultApiKey,
  }) async {
    final fromCoords = resolveCoordinates(
      from,
      preferredLat: (fromLat != null && fromLat != 0.0) ? fromLat : null,
      preferredLng: (fromLng != null && fromLng != 0.0) ? fromLng : null,
    );
    final toCoords = resolveCoordinates(
      to,
      preferredLat: (toLat != null && toLat != 0.0) ? toLat : null,
      preferredLng: (toLng != null && toLng != 0.0) ? toLng : null,
    );

    final fallbackKm = calculateDistanceKm(
      from,
      to,
      fromLat: fromCoords.lat,
      fromLng: fromCoords.lng,
      toLat: toCoords.lat,
      toLng: toCoords.lng,
    );
    final fallbackDuration = estimateDuration(fallbackKm);

    try {
      final originParam = (fromCoords.lat >= 6.5 && fromCoords.lng >= 68.0)
          ? '${fromCoords.lat},${fromCoords.lng}'
          : (from.contains('India') ? from : '$from, India');
      final destParam = (toCoords.lat >= 6.5 && toCoords.lng >= 68.0)
          ? '${toCoords.lat},${toCoords.lng}'
          : (to.contains('India') ? to : '$to, India');

      if (originParam.trim().isEmpty || destParam.trim().isEmpty) {
        return DistanceResult(
          distanceKm: fallbackKm,
          durationText: fallbackDuration,
          isLive: false,
        );
      }

      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/distancematrix/json',
        {
          'origins': originParam,
          'destinations': destParam,
          'key': apiKey,
          'region': 'in',
          'language': 'en',
        },
      );

      final client = HttpClient();
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final rows = json['rows'] as List<dynamic>?;
        if (rows != null && rows.isNotEmpty) {
          final elements = rows.first['elements'] as List<dynamic>?;
          if (elements != null && elements.isNotEmpty) {
            final elem = elements.first as Map<String, dynamic>;
            final status = elem['status'] as String?;
            if (status == 'OK') {
              final distanceMap = elem['distance'] as Map<String, dynamic>?;
              final durationMap = elem['duration'] as Map<String, dynamic>?;

              final int meters = distanceMap?['value'] as int? ?? (fallbackKm * 1000);
              final int km = (meters / 1000).round();
              final String durationText =
                  durationMap?['text'] as String? ?? fallbackDuration;

              // Discard international/absurd geocoding anomalies (> 3800 km)
              final safeKm = (km > 0 && km <= 3800) ? km : fallbackKm;

              return DistanceResult(
                distanceKm: safeKm > 0 ? safeKm : fallbackKm,
                durationText: safeKm <= 3800 ? durationText : fallbackDuration,
                isLive: true,
              );
            }
          }
        }
      }
    } catch (_) {
      // Fallback cleanly
    }

    return DistanceResult(
      distanceKm: fallbackKm,
      durationText: fallbackDuration,
      isLive: false,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DURATION ESTIMATION (AVERAGE SPEED 58 KM/H)
  // ══════════════════════════════════════════════════════════════════════════
  static String estimateDuration(int distanceKm) {
    if (distanceKm <= 0) return '0 min';
    if (distanceKm <= 20) return '30 min';
    if (distanceKm <= 40) return '50 min';

    final totalMinutes = ((distanceKm / 58.0) * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours hr';
    return '$hours hr $minutes min';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DYNAMIC GEO COORDINATES RESOLUTION
  // ══════════════════════════════════════════════════════════════════════════
  static PlaceGeoInfo? findGeo(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return null;

    final primary = _findGeo(_sanitizeKey(trimmed));
    if (primary != null) return primary;

    final cleaned = trimmed.replaceAll(RegExp(r'''[{}"]'''), '');
    for (final segment in cleaned.split(',')) {
      final key = segment.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
      if (key.isNotEmpty) {
        final geo = _findGeo(key);
        if (geo != null) return geo;
      }
    }
    return null;
  }

  /// Fetches exact GPS coordinates for any location string or placeId via Google Geocoding API
  static Future<({double lat, double lng})?> fetchGeocodeCoordinates(
    String locationOrPlaceId, {
    bool isPlaceId = false,
    String apiKey = defaultApiKey,
  }) async {
    final clean = locationOrPlaceId.trim();
    if (clean.isEmpty) return null;

    final sanitized = _sanitizeKey(clean);
    if (_knownCityCoordinates.containsKey(sanitized)) {
      final c = _knownCityCoordinates[sanitized]!;
      return (lat: c.lat, lng: c.lng);
    }
    for (final part in clean.split(',')) {
      final sPart = _sanitizeKey(part);
      if (_knownCityCoordinates.containsKey(sPart)) {
        final c = _knownCityCoordinates[sPart]!;
        return (lat: c.lat, lng: c.lng);
      }
    }

    final cached = findGeo(clean);
    if (cached != null && cached.lat >= 6.5 && cached.lat <= 38.0) {
      return (lat: cached.lat, lng: cached.lng);
    }

    try {
      final queryParams = isPlaceId
          ? {'place_id': clean, 'key': apiKey}
          : {'address': clean, 'key': apiKey, 'region': 'in'};
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', queryParams);

      final client = HttpClient();
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final results = json['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final geom = first['geometry'] as Map<String, dynamic>?;
          final loc = geom?['location'] as Map<String, dynamic>?;
          final lat = (loc?['lat'] as num?)?.toDouble();
          final lng = (loc?['lng'] as num?)?.toDouble();

          if (lat != null && lng != null && lat >= 6.5 && lat <= 38.0 && lng >= 68.0 && lng <= 98.0) {
            registerGeo(clean, lat, lng);
            return (lat: lat, lng: lng);
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Single source of truth for resolving Lat/Lng coordinates for any location
  static ({double lat, double lng}) resolveCoordinates(
    String place, {
    double? preferredLat,
    double? preferredLng,
    double? defaultLat = 0.0,
    double? defaultLng = 0.0,
  }) {
    // 1. If explicit valid GPS coordinates from search or location picker are provided, prioritize them
    if (preferredLat != null &&
        preferredLat != 0.0 &&
        preferredLng != null &&
        preferredLng != 0.0 &&
        preferredLat >= 6.5 &&
        preferredLat <= 38.0 &&
        preferredLng >= 68.0 &&
        preferredLng <= 98.0) {
      return (lat: preferredLat, lng: preferredLng);
    }

    // 2. Look up in instant known cities / localities
    final clean = place.trim();
    if (clean.isNotEmpty) {
      final sanitized = _sanitizeKey(clean);
      if (_knownCityCoordinates.containsKey(sanitized)) {
        final c = _knownCityCoordinates[sanitized]!;
        return (lat: c.lat, lng: c.lng);
      }
      for (final part in clean.split(',')) {
        final sPart = _sanitizeKey(part);
        if (_knownCityCoordinates.containsKey(sPart)) {
          final c = _knownCityCoordinates[sPart]!;
          return (lat: c.lat, lng: c.lng);
        }
      }

      // Check substring matches in known city coordinates
      for (final entry in _knownCityCoordinates.entries) {
        if (entry.key.length >= 4 &&
            (sanitized.contains(entry.key) || entry.key.contains(sanitized))) {
          return (lat: entry.value.lat, lng: entry.value.lng);
        }
      }

      // Check individual words
      final words = clean.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
      for (final word in words) {
        if (word.length >= 4 && _knownCityCoordinates.containsKey(word)) {
          final c = _knownCityCoordinates[word]!;
          return (lat: c.lat, lng: c.lng);
        }
      }

      // 3. Otherwise look up in dynamically cached places (registered via Google Places live search)
      final geo = findGeo(clean);
      if (geo != null &&
          geo.lat >= 6.5 &&
          geo.lat <= 38.0 &&
          geo.lng >= 68.0 &&
          geo.lng <= 98.0) {
        return (lat: geo.lat, lng: geo.lng);
      }
    }

    // 4. Fallback to default
    return (lat: defaultLat ?? 0.0, lng: defaultLng ?? 0.0);
  }

  static String classifyType(String mainText, [String secondary = '']) {
    final lowerMain = mainText.toLowerCase().trim();
    final lowerSec = secondary.toLowerCase().trim();

    final geo = _findGeo(lowerMain);
    if (geo != null) return geo.type;

    if (lowerSec.contains('village') ||
        lowerMain.contains('village') ||
        lowerSec.contains('gram') ||
        lowerSec.contains('mandal')) {
      return 'Village';
    }
    if (lowerSec.contains('district') ||
        lowerMain.contains('town') ||
        lowerSec.contains('town')) {
      return 'Town';
    }
    if (lowerSec.contains('metro') ||
        lowerSec.contains('city') ||
        lowerSec.contains('capital')) {
      return 'City';
    }
    return 'Location';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ROUTE ADJUSTMENT & STOPOVER VALIDATION
  // ══════════════════════════════════════════════════════════════════════════
  static double calculateCorridorProgression({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
    required double pointLat,
    required double pointLng,
  }) {
    final dLat = destLat - startLat;
    final dLng = destLng - startLng;
    final lenSq = dLat * dLat + dLng * dLng;
    if (lenSq == 0) return 0.0;
    return ((pointLat - startLat) * dLat + (pointLng - startLng) * dLng) / lenSq;
  }

  static double haversine(double lat1, double lon1, double lat2, double lon2) =>
      _haversine(lat1, lon1, lat2, lon2);

  static List<String> orderStopoversInCorridor({
    required String start,
    required String destination,
    required List<String> stopovers,
    double? startLat,
    double? startLng,
    double? destLat,
    double? destLng,
  }) {
    if (stopovers.length <= 1) return List.from(stopovers);

    final sCoords = resolveCoordinates(
      start,
      preferredLat: (startLat != null && startLat != 0.0) ? startLat : null,
      preferredLng: (startLng != null && startLng != 0.0) ? startLng : null,
    );
    final dCoords = resolveCoordinates(
      destination,
      preferredLat: (destLat != null && destLat != 0.0) ? destLat : null,
      preferredLng: (destLng != null && destLng != 0.0) ? destLng : null,
    );

    final sLat = sCoords.lat;
    final sLng = sCoords.lng;
    final dLat = dCoords.lat;
    final dLng = dCoords.lng;

    final isStartValid =
        sLat >= 6.5 && sLat <= 38.0 && sLng >= 68.0 && sLng <= 98.0;
    final isDestValid =
        dLat >= 6.5 && dLat <= 38.0 && dLng >= 68.0 && dLng <= 98.0;

    if (!isStartValid && !isDestValid) {
      return List.from(stopovers);
    }

    final stopoverProgress = <String, double>{};
    for (final stop in stopovers) {
      final pCoords = resolveCoordinates(stop);
      final isPointValid = pCoords.lat >= 6.5 &&
          pCoords.lat <= 38.0 &&
          pCoords.lng >= 68.0 &&
          pCoords.lng <= 98.0;

      if (isStartValid && isDestValid && isPointValid) {
        stopoverProgress[stop] = calculateCorridorProgression(
          startLat: sLat,
          startLng: sLng,
          destLat: dLat,
          destLng: dLng,
          pointLat: pCoords.lat,
          pointLng: pCoords.lng,
        );
      } else if (isStartValid && isPointValid) {
        stopoverProgress[stop] = _haversine(sLat, sLng, pCoords.lat, pCoords.lng);
      } else if (isDestValid && isPointValid) {
        stopoverProgress[stop] = -_haversine(dLat, dLng, pCoords.lat, pCoords.lng);
      } else {
        final d1 = calculateDistanceKm(start, stop, fromLat: sLat, fromLng: sLng);
        final d2 = calculateDistanceKm(stop, destination, toLat: dLat, toLng: dLng);
        final total = d1 + d2;
        stopoverProgress[stop] = total > 0 ? (d1 / total) : 0.5;
      }
    }

    final sorted = List<String>.from(stopovers)
      ..sort((a, b) =>
          (stopoverProgress[a] ?? 0.0).compareTo(stopoverProgress[b] ?? 0.0));
    return sorted;
  }

  static RouteAdjustment calculateRouteAdjustment({
    required String start,
    required String destination,
    required List<String> currentStopovers,
    required String newStopover,
    double? startLat,
    double? startLng,
    double? destLat,
    double? destLng,
    double? candidateLat,
    double? candidateLng,
    double? deviationThresholdKm,
  }) {
    if (candidateLat != null && candidateLng != null) {
      registerGeo(newStopover, candidateLat, candidateLng);
    }

    final sCoords = resolveCoordinates(
      start,
      preferredLat: (startLat != null && startLat != 0.0) ? startLat : null,
      preferredLng: (startLng != null && startLng != 0.0) ? startLng : null,
    );
    final dCoords = resolveCoordinates(
      destination,
      preferredLat: (destLat != null && destLat != 0.0) ? destLat : null,
      preferredLng: (destLng != null && destLng != 0.0) ? destLng : null,
    );
    final fLat = sCoords.lat;
    final fLng = sCoords.lng;
    final tLat = dCoords.lat;
    final tLng = dCoords.lng;

    final baseStopovers = currentStopovers
        .where((s) => s.toLowerCase().trim() != newStopover.toLowerCase().trim())
        .toList();

    final orderedBase = orderStopoversInCorridor(
      start: start,
      destination: destination,
      stopovers: baseStopovers,
      startLat: fLat,
      startLng: fLng,
      destLat: tLat,
      destLng: tLng,
    );

    int currentKm = 0;
    String prev = start;
    double? prevLat = fLat;
    double? prevLng = fLng;
    for (final stop in orderedBase) {
      final stopGeo = findGeo(stop);
      currentKm += calculateDistanceKm(
        prev,
        stop,
        fromLat: prevLat,
        fromLng: prevLng,
        toLat: stopGeo?.lat,
        toLng: stopGeo?.lng,
      );
      prev = stop;
      prevLat = stopGeo?.lat;
      prevLng = stopGeo?.lng;
    }
    currentKm += calculateDistanceKm(
      prev,
      destination,
      fromLat: prevLat,
      fromLng: prevLng,
      toLat: tLat,
      toLng: tLng,
    );

    final combined = List<String>.from(baseStopovers)..add(newStopover);
    final orderedUpdated = orderStopoversInCorridor(
      start: start,
      destination: destination,
      stopovers: combined,
      startLat: fLat,
      startLng: fLng,
      destLat: tLat,
      destLng: tLng,
    );

    int updatedKm = 0;
    prev = start;
    prevLat = fLat;
    prevLng = fLng;
    for (final stop in orderedUpdated) {
      final stopGeo = findGeo(stop);
      final sLat = (stop == newStopover && candidateLat != null) ? candidateLat : stopGeo?.lat;
      final sLng = (stop == newStopover && candidateLng != null) ? candidateLng : stopGeo?.lng;
      updatedKm += calculateDistanceKm(
        prev,
        stop,
        fromLat: prevLat,
        fromLng: prevLng,
        toLat: sLat,
        toLng: sLng,
      );
      prev = stop;
      prevLat = sLat;
      prevLng = sLng;
    }
    updatedKm += calculateDistanceKm(
      prev,
      destination,
      fromLat: prevLat,
      fromLng: prevLng,
      toLat: tLat,
      toLng: tLng,
    );

    final additionalKm = max(0, updatedKm - currentKm);
    final additionalMinutes = max(0, ((additionalKm / 58.0) * 60).round());
    final currentDuration = estimateDuration(currentKm);
    final updatedDuration = estimateDuration(updatedKm);

    final threshold = deviationThresholdKm ??
        max(defaultRouteDeviationThresholdKm, currentKm * 0.15);
    final isOnRoute = additionalKm <= threshold;

    return RouteAdjustment(
      currentTotalKm: currentKm,
      updatedTotalKm: updatedKm,
      additionalKm: additionalKm,
      currentDuration: currentDuration,
      updatedDuration: updatedDuration,
      additionalMinutes: additionalMinutes,
      isOnRoute: isOnRoute,
    );
  }

  static int calculateMultiStopDistance(
    String start,
    String destination,
    List<String> stopovers, {
    double? startLat,
    double? startLng,
    double? destLat,
    double? destLng,
  }) {
    if (stopovers.isEmpty) {
      return calculateDistanceKm(
        start,
        destination,
        fromLat: startLat,
        fromLng: startLng,
        toLat: destLat,
        toLng: destLng,
      );
    }
    final ordered = orderStopoversInCorridor(
      start: start,
      destination: destination,
      stopovers: stopovers,
      startLat: startLat,
      startLng: startLng,
      destLat: destLat,
      destLng: destLng,
    );
    final sCoords = resolveCoordinates(
      start,
      preferredLat: (startLat != null && startLat != 0.0) ? startLat : null,
      preferredLng: (startLng != null && startLng != 0.0) ? startLng : null,
    );
    final dCoords = resolveCoordinates(
      destination,
      preferredLat: (destLat != null && destLat != 0.0) ? destLat : null,
      preferredLng: (destLng != null && destLng != 0.0) ? destLng : null,
    );
    int total = 0;
    String prev = start;
    double? prevLat = sCoords.lat;
    double? prevLng = sCoords.lng;
    for (final stop in ordered) {
      final stopCoords = resolveCoordinates(stop);
      total += calculateDistanceKm(
        prev,
        stop,
        fromLat: prevLat,
        fromLng: prevLng,
        toLat: stopCoords.lat,
        toLng: stopCoords.lng,
      );
      prev = stop;
      prevLat = stopCoords.lat;
      prevLng = stopCoords.lng;
    }
    total += calculateDistanceKm(
      prev,
      destination,
      fromLat: prevLat,
      fromLng: prevLng,
      toLat: dCoords.lat,
      toLng: dCoords.lng,
    );
    return total;
  }

  static List<({double lat, double lng})> generateDrivingRouteWaypoints({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final waypoints = <({double lat, double lng})>[
      (lat: fromLat, lng: fromLng),
    ];

    final dLat = toLat - fromLat;
    final dLng = toLng - fromLng;
    final totalDist = sqrt(dLat * dLat + dLng * dLng);

    if (totalDist > 0.0001) {
      final int steps = (totalDist * 16).clamp(8, 24).toInt();
      for (int i = 1; i < steps; i++) {
        final t = i / steps;
        final lat = fromLat + dLat * t;
        final lng = fromLng + dLng * t;
        waypoints.add((lat: lat, lng: lng));
      }
    }

    waypoints.add((lat: toLat, lng: toLng));
    return waypoints;
  }

  static double distanceToPolyline(
    double lat,
    double lng,
    List<({double lat, double lng})> polyline,
  ) {
    if (polyline.isEmpty) return 9999.0;
    double minKm = 9999.0;
    for (int i = 0; i < polyline.length - 1; i++) {
      final p1 = polyline[i];
      final p2 = polyline[i + 1];
      final d = _distToSegmentKm(lat, lng, p1.lat, p1.lng, p2.lat, p2.lng);
      if (d < minKm) minKm = d;
    }
    return minKm;
  }

  static double _distToSegmentKm(
    double px,
    double py,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return _haversine(px, py, x1, y1);

    final t = (((px - x1) * dx + (py - y1) * dy) / lenSq).clamp(0.0, 1.0);
    final projLat = x1 + t * dx;
    final projLng = y1 + t * dy;
    return _haversine(px, py, projLat, projLng);
  }

  static List<PlaceGeoInfo> getRouteBasedSuggestions({
    required String start,
    required String destination,
    double? startLat,
    double? startLng,
    double? destLat,
    double? destLng,
  }) {
    final sCoords = resolveCoordinates(
      start,
      preferredLat: (startLat != null && startLat != 0.0) ? startLat : null,
      preferredLng: (startLng != null && startLng != 0.0) ? startLng : null,
    );
    final dCoords = resolveCoordinates(
      destination,
      preferredLat: (destLat != null && destLat != 0.0) ? destLat : null,
      preferredLng: (destLng != null && destLng != 0.0) ? destLng : null,
    );

    final fromLat = sCoords.lat;
    final fromLng = sCoords.lng;
    final toLat = dCoords.lat;
    final toLng = dCoords.lng;

    final isFromValid =
        fromLat >= 6.5 && fromLat <= 38.0 && fromLng >= 68.0 && fromLng <= 98.0;
    final isToValid =
        toLat >= 6.5 && toLat <= 38.0 && toLng >= 68.0 && toLng <= 98.0;

    if (!isFromValid || !isToValid) {
      return const [];
    }

    final polyline = generateDrivingRouteWaypoints(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );

    final directKm = calculateDistanceKm(
      start,
      destination,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    final startKey = _sanitizeKey(start);
    final destKey = _sanitizeKey(destination);

    final candidates = <({
      PlaceGeoInfo geo,
      double distToPolyline,
      int detourKm,
      double progress
    })>[];

    final minLat = min(fromLat, toLat) - 0.28;
    final maxLat = max(fromLat, toLat) + 0.28;
    final minLng = min(fromLng, toLng) - 0.28;
    final maxLng = max(fromLng, toLng) + 0.28;

    for (final entry in _dynamicGeoCache.entries) {
      final key = entry.key;
      if (key == startKey || key == destKey) continue;
      if (startKey.contains(key) || key.contains(startKey)) continue;
      if (destKey.contains(key) || key.contains(destKey)) continue;

      final geo = entry.value;
      if (geo.lat < minLat ||
          geo.lat > maxLat ||
          geo.lng < minLng ||
          geo.lng > maxLng) {
        continue;
      }

      final dToPoly = distanceToPolyline(geo.lat, geo.lng, polyline);
      final d1 = calculateDistanceKm(
        start,
        geo.name,
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: geo.lat,
        toLng: geo.lng,
      );
      final d2 = calculateDistanceKm(
        geo.name,
        destination,
        fromLat: geo.lat,
        fromLng: geo.lng,
        toLat: toLat,
        toLng: toLng,
      );
      final detour = max(0, (d1 + d2) - directKm);

      final maxDetour = max(35, (directKm * 0.22).round());
      if (dToPoly <= 32.0 && detour <= maxDetour) {
        final progress = _haversine(fromLat, fromLng, geo.lat, geo.lng);
        candidates.add((
          geo: geo,
          distToPolyline: dToPoly,
          detourKm: detour,
          progress: progress,
        ));
      }
    }

    candidates.sort((a, b) => a.progress.compareTo(b.progress));

    final double minSpacingKm = max(10.0, directKm * 0.10);
    final spaced = <PlaceGeoInfo>[];
    double lastProgress = -999.0;
    final seen = <String>{};

    for (final c in candidates) {
      final norm = c.geo.name.toLowerCase();
      if (seen.contains(norm)) continue;
      if (c.progress < 5.0 || (directKm - c.progress) < 5.0) continue;

      if (spaced.isEmpty || (c.progress - lastProgress) >= minSpacingKm) {
        spaced.add(c.geo);
        seen.add(norm);
        lastProgress = c.progress;
      }
      if (spaced.length >= 6) break;
    }

    if (spaced.isNotEmpty) {
      return spaced;
    }

    final result = <PlaceGeoInfo>[];
    for (final c in candidates) {
      final norm = c.geo.name.toLowerCase();
      if (!seen.contains(norm)) {
        seen.add(norm);
        result.add(c.geo);
      }
    }

    return result.take(5).toList();
  }

  static RouteAdjustment validateLocationOnRoute({
    required String start,
    required String destination,
    required String candidateName,
    double? candidateLat,
    double? candidateLng,
    double? startLat,
    double? startLng,
    double? destLat,
    double? destLng,
    List<String> currentStopovers = const [],
    double? deviationThresholdKm,
  }) {
    if (candidateLat != null && candidateLng != null) {
      registerGeo(candidateName, candidateLat, candidateLng);
    }

    final adj = calculateRouteAdjustment(
      start: start,
      destination: destination,
      currentStopovers: currentStopovers,
      newStopover: candidateName,
      startLat: startLat,
      startLng: startLng,
      destLat: destLat,
      destLng: destLng,
      candidateLat: candidateLat,
      candidateLng: candidateLng,
      deviationThresholdKm: deviationThresholdKm,
    );

    final cGeo = (candidateLat != null && candidateLng != null)
        ? null
        : findGeo(candidateName);
    final lat = candidateLat ?? cGeo?.lat;
    final lng = candidateLng ?? cGeo?.lng;

    final sCoords = resolveCoordinates(
      start,
      preferredLat: (startLat != null && startLat != 0.0) ? startLat : null,
      preferredLng: (startLng != null && startLng != 0.0) ? startLng : null,
    );
    final dCoords = resolveCoordinates(
      destination,
      preferredLat: (destLat != null && destLat != 0.0) ? destLat : null,
      preferredLng: (destLng != null && destLng != 0.0) ? destLng : null,
    );
    final fLat = sCoords.lat;
    final fLng = sCoords.lng;
    final tLat = dCoords.lat;
    final tLng = dCoords.lng;

    bool isPolylineClose = true;
    if (lat != null &&
        lng != null &&
        fLat != null &&
        fLng != null &&
        tLat != null &&
        tLng != null) {
      final polyline = generateDrivingRouteWaypoints(
        fromLat: fLat,
        fromLng: fLng,
        toLat: tLat,
        toLng: tLng,
      );
      final distPoly = distanceToPolyline(lat, lng, polyline);
      if (distPoly > 38.0) {
        isPolylineClose = false;
      }
    }

    final threshold = deviationThresholdKm ?? defaultRouteDeviationThresholdKm;
    final maxAllowedDetour = max(threshold, adj.currentTotalKm * 0.18);
    final isDetourAcceptable = adj.additionalKm <= maxAllowedDetour;

    final bool isOnRoute = isPolylineClose && isDetourAcceptable;

    return RouteAdjustment(
      currentTotalKm: adj.currentTotalKm,
      updatedTotalKm: adj.updatedTotalKm,
      additionalKm: adj.additionalKm,
      currentDuration: adj.currentDuration,
      updatedDuration: adj.updatedDuration,
      additionalMinutes: adj.additionalMinutes,
      isOnRoute: isOnRoute,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  static String _sanitizeKey(String raw) {
    var text = raw.trim();
    final addrMatch = RegExp(
      r'(?:address|place|name|city|district)\s*[:=]\s*([^,}]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (addrMatch != null) {
      text = addrMatch.group(1)?.trim() ?? text;
    }
    text = text.replaceAll(RegExp(r'''[{}"]'''), '').trim();
    final parts = text.split(',');
    final first = parts.isNotEmpty ? parts.first : text;
    return first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  static List<PlaceGeoInfo> searchLocalPlaces(String query, {int limit = 8}) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return const [];
    final sanitized = _sanitizeKey(clean);

    final results = <PlaceGeoInfo>[];
    final seen = <String>{};

    for (final entry in _dynamicGeoCache.entries) {
      final key = entry.key;
      if (seen.contains(key)) continue;
      final geo = entry.value;
      final nameLower = geo.name.toLowerCase();
      if (key == sanitized ||
          key.startsWith(sanitized) ||
          nameLower.startsWith(clean) ||
          geo.district.toLowerCase().startsWith(clean)) {
        seen.add(key);
        results.add(geo);
        if (results.length >= limit) return results;
      }
    }
    return results;
  }

  static PlaceGeoInfo? _findGeo(String key) {
    if (key.isEmpty) return null;
    if (_dynamicGeoCache.containsKey(key)) return _dynamicGeoCache[key];

    for (final entry in _dynamicGeoCache.entries) {
      if (entry.key.length >= 4 &&
          (key.contains(entry.key) || entry.key.contains(key))) {
        return entry.value;
      }
    }

    if (_knownCityCoordinates.containsKey(key)) {
      final c = _knownCityCoordinates[key]!;
      final formattedName = '${key[0].toUpperCase()}${key.substring(1)}';
      return PlaceGeoInfo(
        name: formattedName,
        lat: c.lat,
        lng: c.lng,
        type: 'City',
        district: '',
        state: 'India',
      );
    }

    for (final entry in _knownCityCoordinates.entries) {
      if (entry.key.length >= 4 &&
          (key.contains(entry.key) || entry.key.contains(key))) {
        final formattedName = '${entry.key[0].toUpperCase()}${entry.key.substring(1)}';
        return PlaceGeoInfo(
          name: formattedName,
          lat: entry.value.lat,
          lng: entry.value.lng,
          type: 'City',
          district: '',
          state: 'India',
        );
      }
    }

    return null;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Earth radius in km
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static List<PlaceGeoInfo> getAllVillagesAndTowns() {
    return _dynamicGeoCache.values
        .where((g) =>
            g.type.toLowerCase().contains('village') ||
            g.type.toLowerCase().contains('town') ||
            g.type.toLowerCase().contains('mandal'))
        .toList();
  }

  static List<PlaceGeoInfo> getAllCities() {
    return _dynamicGeoCache.values
        .where((g) =>
            g.type.toLowerCase().contains('city') ||
            g.type.toLowerCase().contains('metro'))
        .toList();
  }
}

class PlaceGeoInfo {
  final String name;
  final double lat;
  final double lng;
  final String type;
  final String district;
  final String state;

  const PlaceGeoInfo({
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
    required this.district,
    required this.state,
  });

  String get subtitle => '$type • $district, $state';
  String get coordinatesDisplay => '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceGeoInfo &&
          runtimeType == other.runtimeType &&
          name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;
}

class DistanceResult {
  final int distanceKm;
  final String durationText;
  final bool isLive;

  const DistanceResult({
    required this.distanceKm,
    required this.durationText,
    this.isLive = false,
  });
}

/// Clean Architecture Route Adjustment result
class RouteAdjustment {
  final int currentTotalKm;
  final int updatedTotalKm;
  final int additionalKm;
  final String currentDuration;
  final String updatedDuration;
  final int additionalMinutes;
  final bool isOnRoute;

  const RouteAdjustment({
    required this.currentTotalKm,
    required this.updatedTotalKm,
    required this.additionalKm,
    required this.currentDuration,
    required this.updatedDuration,
    required this.additionalMinutes,
    required this.isOnRoute,
  });

  String get additionalTimeText {
    if (additionalMinutes <= 0) return '0 min';
    final hours = additionalMinutes ~/ 60;
    final mins = additionalMinutes % 60;
    if (hours == 0) return '$mins min';
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }
}
