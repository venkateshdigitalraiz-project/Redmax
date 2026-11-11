import 'dart:convert';
import 'dart:io';
import 'dart:math';

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

  static const String defaultApiKey = 'AIzaSyBpCA99uGvcf267xPpDxv1dWsFkOqB3RYU';

  /// Configurable default route-deviation threshold in kilometers (default: 40.0 km).
  /// Any stopover adding <= this distance is considered on the route or accessible detour.
  static double defaultRouteDeviationThresholdKm = 40.0;

  // ══════════════════════════════════════════════════════════════════════════
  // DYNAMIC GEO CACHE (Populated from Live Searches & GPS Coordinates)
  // ══════════════════════════════════════════════════════════════════════════
  static final Map<String, PlaceGeoInfo> _dynamicGeoCache = {};

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
    final f = _sanitizeKey(from);
    final t = _sanitizeKey(to);

    // 1. Resolve coordinates from arguments or dynamic cache
    final geoFrom = _findGeo(f);
    final geoTo = _findGeo(t);

    final fLat = (fromLat != null && fromLat != 0.0) ? fromLat : geoFrom?.lat;
    final fLng = (fromLng != null && fromLng != 0.0) ? fromLng : geoFrom?.lng;
    final tLat = (toLat != null && toLat != 0.0) ? toLat : geoTo?.lat;
    final tLng = (toLng != null && toLng != 0.0) ? toLng : geoTo?.lng;

    // 2. Compute dynamic distance if coordinates are present
    if (fLat != null && fLng != null && tLat != null && tLng != null &&
        fLat != 0.0 && fLng != 0.0 && tLat != 0.0 && tLng != 0.0) {
      if ((fLat - tLat).abs() < 0.0001 && (fLng - tLng).abs() < 0.0001) {
        return 0;
      }
      final straight = _haversine(fLat, fLng, tLat, tLng);
      // Realistic road winding factor (1.22x) for highways and urban roads
      final roadKm = (straight * 1.22).round();
      return roadKm < 1 ? 1 : roadKm;
    }

    if (f.isNotEmpty && t.isNotEmpty && f == t) return 0;

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
    final fallbackKm = calculateDistanceKm(
      from,
      to,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    final fallbackDuration = estimateDuration(fallbackKm);

    try {
      final originParam = (fromLat != null && fromLng != null && fromLat != 0.0 && fromLng != 0.0)
          ? '$fromLat,$fromLng'
          : from;
      final destParam = (toLat != null && toLng != null && toLat != 0.0 && toLng != 0.0)
          ? '$toLat,$toLng'
          : to;

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

              return DistanceResult(
                distanceKm: km > 0 ? km : fallbackKm,
                durationText: durationText,
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

    // 2. Otherwise look up in dynamically cached places (registered via Google Places live search)
    final clean = place.trim();
    if (clean.isNotEmpty) {
      final geo = findGeo(clean);
      if (geo != null &&
          geo.lat >= 6.5 &&
          geo.lat <= 38.0 &&
          geo.lng >= 68.0 &&
          geo.lng <= 98.0) {
        return (lat: geo.lat, lng: geo.lng);
      }
    }

    // 3. Fallback to default
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

    final sGeo = findGeo(start);
    final dGeo = findGeo(destination);
    final sLat = startLat ?? sGeo?.lat;
    final sLng = startLng ?? sGeo?.lng;
    final dLat = destLat ?? dGeo?.lat;
    final dLng = destLng ?? dGeo?.lng;

    if (sLat == null || sLng == null || dLat == null || dLng == null) {
      return List.from(stopovers);
    }

    final stopoverProgress = <String, double>{};
    for (final stop in stopovers) {
      final geo = findGeo(stop);
      if (geo != null) {
        stopoverProgress[stop] = calculateCorridorProgression(
          startLat: sLat,
          startLng: sLng,
          destLat: dLat,
          destLng: dLng,
          pointLat: geo.lat,
          pointLng: geo.lng,
        );
      } else {
        final d1 = calculateDistanceKm(start, stop, fromLat: sLat, fromLng: sLng);
        final d2 = calculateDistanceKm(stop, destination, toLat: dLat, toLng: dLng);
        final total = d1 + d2;
        stopoverProgress[stop] = total > 0 ? (d1 / total) : 0.5;
      }
    }

    final sorted = List<String>.from(stopovers)
      ..sort((a, b) => (stopoverProgress[a] ?? 0.0).compareTo(stopoverProgress[b] ?? 0.0));
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

    final sGeo = findGeo(start);
    final dGeo = findGeo(destination);
    final fLat = startLat ?? sGeo?.lat;
    final fLng = startLng ?? sGeo?.lng;
    final tLat = destLat ?? dGeo?.lat;
    final tLng = destLng ?? dGeo?.lng;

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
    int total = 0;
    String prev = start;
    double? prevLat = startLat;
    double? prevLng = startLng;
    for (final stop in ordered) {
      final stopGeo = findGeo(stop);
      total += calculateDistanceKm(
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
    total += calculateDistanceKm(
      prev,
      destination,
      fromLat: prevLat,
      fromLng: prevLng,
      toLat: destLat,
      toLng: destLng,
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
    final sGeo = findGeo(start);
    final dGeo = findGeo(destination);

    final fromLat = startLat ?? sGeo?.lat;
    final fromLng = startLng ?? sGeo?.lng;
    final toLat = destLat ?? dGeo?.lat;
    final toLng = destLng ?? dGeo?.lng;

    if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
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

    final sGeo = findGeo(start);
    final dGeo = findGeo(destination);
    final fLat = startLat ?? sGeo?.lat;
    final fLng = startLng ?? sGeo?.lng;
    final tLat = destLat ?? dGeo?.lat;
    final tLng = destLng ?? dGeo?.lng;

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
    if (_dynamicGeoCache.containsKey(key)) return _dynamicGeoCache[key];

    for (final entry in _dynamicGeoCache.entries) {
      if (entry.key.length >= 4 &&
          (key.contains(entry.key) || entry.key.contains(key))) {
        return entry.value;
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
