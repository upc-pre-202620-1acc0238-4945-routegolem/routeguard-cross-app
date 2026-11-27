import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoadRouteResult {
  final List<LatLng> path;
  final double distanceMeters;
  final double durationSeconds;

  const RoadRouteResult({
    required this.path,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class ArrivalEstimateResult {
  final double distanceMeters;
  final int etaMinutes;

  const ArrivalEstimateResult({
    required this.distanceMeters,
    required this.etaMinutes,
  });
}

/// Fetches real road-following polylines and travel estimates using Mapbox Directions
/// (when MAPBOX_ACCESS_TOKEN is provided via --dart-define) or OSRM public routing API
/// matching the OpenStreetMap tiles used by flutter_map.
class RoadRoutingService {
  static const String _mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  static const Duration _timeout = Duration(seconds: 8);
  static const Duration _failureCooldown = Duration(seconds: 20);

  final http.Client _client;
  final Map<String, RoadRouteResult> _routeCache = {};
  final Map<String, DateTime> _failedKeys = {};

  static final RoadRoutingService instance = RoadRoutingService();

  RoadRoutingService({http.Client? client}) : _client = client ?? http.Client();

  String _keyFor(List<LatLng> points) => points
      .map((p) => '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}')
      .join(';');

  Future<RoadRouteResult?> getRoadRoute(List<LatLng> points) async {
    if (points.length < 2) return null;

    // Deduplicate consecutive identical points
    final cleaned = <LatLng>[];
    for (final p in points) {
      if (cleaned.isEmpty ||
          (cleaned.last.latitude - p.latitude).abs() > 1e-6 ||
          (cleaned.last.longitude - p.longitude).abs() > 1e-6) {
        cleaned.add(p);
      }
    }
    if (cleaned.length < 2) return null;

    final key = _keyFor(cleaned);
    final cached = _routeCache[key];
    if (cached != null) return cached;

    final failedAt = _failedKeys[key];
    if (failedAt != null && DateTime.now().difference(failedAt) < _failureCooldown) {
      return null;
    }

    final coordsPath = cleaned.map((p) => '${p.longitude},${p.latitude}').join(';');

    // 1. Optional Mapbox Directions API if token was passed via --dart-define
    if (_mapboxToken.startsWith('pk.') && cleaned.length <= 25) {
      final mapboxUri = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/$coordsPath'
        '?geometries=geojson&overview=full&access_token=$_mapboxToken',
      );
      final mapboxResult = await _fetchGeoJsonRoute(mapboxUri);
      if (mapboxResult != null) {
        _routeCache[key] = mapboxResult;
        return mapboxResult;
      }
    }

    // 2. OSRM public driving router (OpenStreetMap road network, zero-key)
    final osrmUri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordsPath'
      '?overview=full&geometries=geojson',
    );
    final osrmResult = await _fetchGeoJsonRoute(osrmUri);
    if (osrmResult != null) {
      _routeCache[key] = osrmResult;
      return osrmResult;
    }

    _failedKeys[key] = DateTime.now();
    return null;
  }

  Future<ArrivalEstimateResult?> estimateArrival(LatLng from, LatLng to) async {
    final result = await getRoadRoute([from, to]);
    if (result == null) return null;
    final eta = (result.durationSeconds / 60.0).ceil();
    return ArrivalEstimateResult(
      distanceMeters: result.distanceMeters,
      etaMinutes: eta < 1 ? 1 : eta,
    );
  }

  Future<RoadRouteResult?> _fetchGeoJsonRoute(Uri uri) async {
    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final first = routes.first;
      if (first is! Map<String, dynamic>) return null;
      final geometry = first['geometry'];
      if (geometry is! Map<String, dynamic>) return null;
      final coords = geometry['coordinates'];
      if (coords is! List || coords.length < 2) return null;

      final path = <LatLng>[];
      for (final item in coords) {
        if (item is List && item.length >= 2) {
          final lng = (item[0] as num?)?.toDouble();
          final lat = (item[1] as num?)?.toDouble();
          if (lat != null && lng != null) {
            path.add(LatLng(lat, lng));
          }
        }
      }
      if (path.length < 2) return null;

      final distance = (first['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (first['duration'] as num?)?.toDouble() ?? 0.0;
      return RoadRouteResult(
        path: path,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _routeCache.clear();
    _failedKeys.clear();
  }
}
