import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/session_manager.dart';
import '../../driver/models/driver_passenger.dart';
import '../../fleet/models/route_model.dart';
import '../models/student_stop.dart';
import '../models/trip_history_record.dart';
import '../models/trip_telemetry.dart';

class ParentTrackingResult {
  final bool hasActiveTrip;
  final TripTelemetry? telemetry;
  final List<StudentStop> stops;
  final bool isOfflineFallback;

  const ParentTrackingResult({
    required this.hasActiveTrip,
    this.telemetry,
    this.stops = const [],
    this.isOfflineFallback = false,
  });
}

class DriverActiveTripResult {
  final bool hasActiveTrip;
  final String? tripId;
  final String? routeId;
  final String? routeName;
  final String? vehiclePlate;
  final String? driverName;
  final List<StudentStop> stops;
  final List<DriverPassenger> passengers;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? speedKmh;
  final List<RouteModel> assignedRoutes;
  final bool isOfflineFallback;

  const DriverActiveTripResult({
    required this.hasActiveTrip,
    this.tripId,
    this.routeId,
    this.routeName,
    this.vehiclePlate,
    this.driverName,
    this.stops = const [],
    this.passengers = const [],
    this.currentLatitude,
    this.currentLongitude,
    this.speedKmh,
    this.assignedRoutes = const [],
    this.isOfflineFallback = false,
  });
}

class TrackingRepository {
  final http.Client _client;
  final LocalDatabase _db = LocalDatabase.instance;

  static final List<TripHistoryRecord> _fallbackHistory = [
    TripHistoryRecord(
      tripId: 'TRP-2026-07',
      routeName: 'Ruta San Martín - Turno Mañana',
      driverName: 'Carlos Ramirez',
      vehiclePlate: 'ABC-123',
      dateEs: 'Ayer, 07:50 AM',
      dateEn: 'Yesterday, 07:50 AM',
      boardedCount: 14,
      totalStudents: 14,
      status: 'COMPLETED',
      rating: 5,
    ),
    TripHistoryRecord(
      tripId: 'TRP-2026-06',
      routeName: 'Ruta 01 - Primaria San Borja',
      driverName: 'Carlos Ramirez',
      vehiclePlate: 'ABC-123',
      dateEs: 'Hace 2 días, 07:45 AM',
      dateEn: '2 days ago, 07:45 AM',
      boardedCount: 13,
      totalStudents: 14,
      status: 'COMPLETED',
    ),
    TripHistoryRecord(
      tripId: 'TRP-2026-05',
      routeName: 'Ruta 02 - Turno Mañana',
      driverName: 'Carlos Ramirez',
      vehiclePlate: 'ABC-123',
      dateEs: 'Hace 4 días, 07:10 AM',
      dateEn: '4 days ago, 07:10 AM',
      boardedCount: 0,
      totalStudents: 14,
      status: 'CANCELLED',
      cancellationReason: 'Falla mecánica grave',
    ),
  ];

  TrackingRepository({http.Client? client}) : _client = client ?? http.Client();

  bool _isLiveToken(String token) =>
      token.isNotEmpty && !token.startsWith('mock_') && !token.startsWith('demo-');

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  /// Parent live trip tracking via GET /api/v1/parents/{parentId}/active-trip.
  /// Returns hasActiveTrip=false when backend responds 204 No Content.
  /// Falls back to offline demo data only when offline / mock token / server unreachable.
  Future<ParentTrackingResult> getParentActiveTrip(
    String token, {
    String? parentId,
    String? userId,
    SessionManager? sessionManager,
  }) async {
    var resolvedParentId = parentId ?? sessionManager?.profileId;
    final resolvedUserId = userId ?? sessionManager?.userId;

    if (_isLiveToken(token)) {
      if (resolvedParentId == null || resolvedParentId.isEmpty) {
        resolvedParentId = await _resolveParentProfileId(token, resolvedUserId);
        if (resolvedParentId != null && sessionManager != null) {
          await sessionManager.setProfileId(resolvedParentId);
        }
      }

      if (resolvedParentId != null && resolvedParentId.isNotEmpty) {
        final uri = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.parentsEndpoint}/$resolvedParentId/active-trip',
        );
        try {
          final response = await _client
              .get(uri, headers: _headers(token))
              .timeout(ApiConstants.timeout);

          if (response.statusCode == 204) {
            return const ParentTrackingResult(hasActiveTrip: false, stops: []);
          }
          if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic>) {
              final telemetry = TripTelemetry.fromJson(data);
              return ParentTrackingResult(
                hasActiveTrip: true,
                telemetry: telemetry,
                stops: telemetry.stops,
              );
            }
          }
        } catch (_) {
          // Offline fallback below
        }
      }
    }

    final fallbackTelemetry = await getActiveTrip(token);
    final fallbackStops = await getStudentStops(token);
    return ParentTrackingResult(
      hasActiveTrip: true,
      telemetry: fallbackTelemetry,
      stops: fallbackStops,
      isOfflineFallback: true,
    );
  }

  Future<String?> _resolveParentProfileId(String token, String? userId) async {
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.parentsEndpoint}'),
            headers: _headers(token),
          )
          .timeout(ApiConstants.timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final uid = (item['userId'] ?? item['UserId'])?.toString();
              if (userId != null && uid == userId) {
                return (item['id'] ?? item['Id'])?.toString();
              }
            }
          }
          if (decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
            return (decoded.first['id'] ?? decoded.first['Id'])?.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveDriverProfileId(String token, String? userId) async {
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}'),
            headers: _headers(token),
          )
          .timeout(ApiConstants.timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final uid = (item['userId'] ?? item['UserId'])?.toString();
              if (userId != null && uid == userId) {
                return (item['id'] ?? item['Id'])?.toString();
              }
            }
          }
          if (decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
            return (decoded.first['id'] ?? decoded.first['Id'])?.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetches the driver's active trip from GET /api/v1/trips + route details + latest GPS,
  /// or assigned ACTIVE routes when the driver has no trip in progress.
  Future<DriverActiveTripResult> getDriverActiveTrip(
    String token, {
    SessionManager? sessionManager,
    String? organizationId,
    String? driverProfileId,
    String? userId,
  }) async {
    if (!_isLiveToken(token)) {
      return const DriverActiveTripResult(hasActiveTrip: false, isOfflineFallback: true);
    }

    final orgId = organizationId ?? sessionManager?.organizationId ?? '';
    final uid = userId ?? sessionManager?.userId;
    var driverId = driverProfileId ?? sessionManager?.profileId;
    if (driverId == null || driverId.isEmpty) {
      driverId = await _resolveDriverProfileId(token, uid);
      if (driverId != null && sessionManager != null) {
        await sessionManager.setProfileId(driverId);
      }
    }

    try {
      final tripsRes = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}'),
            headers: _headers(token),
          )
          .timeout(ApiConstants.timeout);

      if (tripsRes.statusCode == 200) {
        final tripsJson = jsonDecode(tripsRes.body);
        if (tripsJson is List) {
          final activeList = tripsJson
              .whereType<Map<String, dynamic>>()
              .where((t) {
                final state = (t['tripState'] ?? t['status'] ?? '')
                    .toString()
                    .toUpperCase();
                if (state != 'IN_PROGRESS') return false;
                if (driverId != null && driverId.isNotEmpty) {
                  final tripDriver =
                      (t['driverId'] ?? t['DriverId'] ?? '').toString();
                  if (tripDriver.isNotEmpty && tripDriver != driverId) {
                    return false;
                  }
                }
                return true;
              })
              .toList();

          if (activeList.isNotEmpty) {
            activeList.sort((a, b) {
              final at = DateTime.tryParse((a['startTime'] ?? '').toString());
              final bt = DateTime.tryParse((b['startTime'] ?? '').toString());
              if (at != null && bt != null) return bt.compareTo(at);
              return 0;
            });
            final activeTrip = activeList.first;
            final tripId = (activeTrip['id'] ?? activeTrip['tripId'] ?? '').toString();
            final routeId = (activeTrip['routeId'] ?? '').toString();

            RouteModel? route;
            if (routeId.isNotEmpty) {
              final routeRes = await _client
                  .get(
                    Uri.parse('${ApiConstants.baseUrl}${ApiConstants.routesEndpoint}/$routeId'),
                    headers: _headers(token),
                  )
                  .timeout(ApiConstants.timeout);
              if (routeRes.statusCode == 200) {
                final routeJson = jsonDecode(routeRes.body);
                if (routeJson is Map<String, dynamic>) {
                  route = RouteModel.fromJson(routeJson);
                }
              }
            }

            double? latestLat;
            double? latestLng;
            double? latestSpeed;
            try {
              final locRes = await _client
                  .get(
                    Uri.parse(
                      '${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/locations/latest',
                    ),
                    headers: _headers(token),
                  )
                  .timeout(ApiConstants.timeout);
              if (locRes.statusCode == 200 && locRes.body.trim().isNotEmpty) {
                final locJson = jsonDecode(locRes.body);
                if (locJson is Map<String, dynamic>) {
                  latestLat = (locJson['latitude'] as num?)?.toDouble();
                  latestLng = (locJson['longitude'] as num?)?.toDouble();
                  latestSpeed = (locJson['speedKmh'] as num?)?.toDouble();
                }
              }
            } catch (_) {}

            final stops = (route?.waypoints ?? [])
                .map(
                  (w) => StudentStop(
                    id: w.id,
                    studentName: w.name,
                    address: w.address,
                    latitude: w.latitude,
                    longitude: w.longitude,
                    estimatedTime: w.scheduledTime,
                    order: w.orderIndex,
                  ),
                )
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));

            final attendancesRaw = activeTrip['attendances'] as List<dynamic>? ?? const [];
            final attendanceMap = <String, String>{};
            for (final item in attendancesRaw) {
              if (item is Map<String, dynamic>) {
                final cid = (item['childId'] ?? '').toString();
                final st = (item['boardingState'] ?? 'MISSING').toString().toUpperCase();
                if (cid.isNotEmpty) attendanceMap[cid] = st;
              }
            }

            final childIds = route?.studentIds.isNotEmpty == true
                ? route!.studentIds
                : attendanceMap.keys.toList();

            final passengers = <DriverPassenger>[];
            for (var i = 0; i < childIds.length; i++) {
              final cid = childIds[i];
              final state = attendanceMap[cid] ?? 'MISSING';
              final status = state == 'BOARDED'
                  ? PassengerBoardingStatus.boarded
                  : (state == 'OMITTED'
                      ? PassengerBoardingStatus.absent
                      : PassengerBoardingStatus.pending);
              final stopLabel = stops.isNotEmpty
                  ? stops[i % stops.length].studentName
                  : (route?.name ?? 'Parada escolar');
              passengers.add(
                DriverPassenger(
                  id: cid,
                  name: 'Estudiante ${i + 1}',
                  grade: route?.name ?? 'Ruta Escolar',
                  stopAddress: stopLabel,
                  scheduledTime: route?.departureTime ?? '07:00',
                  status: status,
                ),
              );
            }

            return DriverActiveTripResult(
              hasActiveTrip: true,
              tripId: tripId,
              routeId: routeId,
              routeName: route?.name ?? 'Ruta Escolar',
              vehiclePlate: route?.vehiclePlate ?? 'ABC-123',
              driverName: sessionManager?.fullName,
              stops: stops,
              passengers: passengers,
              currentLatitude: latestLat ?? (stops.isNotEmpty ? stops.first.latitude : null),
              currentLongitude: latestLng ?? (stops.isNotEmpty ? stops.first.longitude : null),
              speedKmh: latestSpeed,
            );
          }

          // No active trip on backend: fetch assigned ACTIVE routes for driver
          final orgQuery = orgId.isNotEmpty ? '?organizationId=$orgId' : '';
          final routesRes = await _client
              .get(
                Uri.parse('${ApiConstants.baseUrl}${ApiConstants.routesEndpoint}$orgQuery'),
                headers: _headers(token),
              )
              .timeout(ApiConstants.timeout);

          final assigned = <RouteModel>[];
          if (routesRes.statusCode == 200) {
            final routesJson = jsonDecode(routesRes.body);
            if (routesJson is List) {
              for (final item in routesJson.whereType<Map<String, dynamic>>()) {
                final r = RouteModel.fromJson(item);
                final assignment = item['assignment'] as Map<String, dynamic>?;
                final assignedDriverId = assignment?['driverId']?.toString();
                if (r.isActive &&
                    (driverId == null ||
                        driverId.isEmpty ||
                        assignedDriverId == driverId)) {
                  assigned.add(r);
                }
              }
            }
          }

          return DriverActiveTripResult(
            hasActiveTrip: false,
            assignedRoutes: assigned,
          );
        }
      }
    } catch (_) {}

    return const DriverActiveTripResult(hasActiveTrip: false, isOfflineFallback: true);
  }

  Future<bool> startDriverTrip(
    String token, {
    required String organizationId,
    required String routeId,
    required String driverId,
  }) async {
    if (!_isLiveToken(token)) return false;
    try {
      final createRes = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}'),
            headers: _headers(token),
            body: jsonEncode({
              'organizationId': organizationId,
              'routeId': routeId,
              'driverId': driverId,
            }),
          )
          .timeout(ApiConstants.timeout);
      if (createRes.statusCode >= 200 && createRes.statusCode < 300) {
        final created = jsonDecode(createRes.body) as Map<String, dynamic>;
        final tripId = (created['id'] ?? created['tripId'] ?? '').toString();
        if (tripId.isEmpty) return false;
        final startRes = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/start'),
              headers: _headers(token),
            )
            .timeout(ApiConstants.timeout);
        return startRes.statusCode >= 200 && startRes.statusCode < 300;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> setBoardingStatus({
    required String token,
    required String tripId,
    required String childId,
    required String boardingState,
  }) async {
    if (!_isLiveToken(token)) return false;
    try {
      final res = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/boarding'),
            headers: _headers(token),
            body: jsonEncode({
              'childId': childId,
              'boardingState': boardingState,
            }),
          )
          .timeout(ApiConstants.timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeTrip({
    required String token,
    required String tripId,
  }) async {
    if (!_isLiveToken(token)) return false;
    try {
      final res = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/complete'),
            headers: _headers(token),
          )
          .timeout(ApiConstants.timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<TripTelemetry> getActiveTrip(String token) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.activeTripEndpoint}');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return TripTelemetry.fromJson(Map<String, dynamic>.from(data.first));
        } else if (data is Map<String, dynamic>) {
          return TripTelemetry.fromJson(data);
        }
      }
    } catch (_) {
      // Fallback telemetry
    }

    // Default real-time coordinates around San Isidro / Miraflores, Lima (near colegios)
    return TripTelemetry(
      tripId: 'TRP-2026-08',
      routeName: 'Ruta San Martín - Turno Mañana',
      driverName: 'Carlos Ramirez',
      vehiclePlate: 'ABC-123',
      currentLatitude: -12.0965,
      currentLongitude: -77.0360,
      speedKmh: 28.4,
      status: 'EN_RUTA',
      totalStudents: 14,
      onboardStudents: 6,
      vehicleModel: 'Mercedes-Benz Sprinter 416',
      driverPhone: '+51 987 654 321',
      driverLicense: 'Q-44556677',
      driverLicenseCategory: 'A-IIIa',
      soatPolicy: 'SOAT-2026-88412',
      soatInsurer: 'Rímac Seguros',
      soatExpiresAt: '15/12/2026',
    );
  }

  Future<List<StudentStop>> getStudentStops(String token) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.stopsEndpoint}');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => StudentStop.fromJson(json)).toList();
      }
    } catch (_) {
      // Fallback stops
    }

    return [
      StudentStop(
        id: 'stp-01',
        studentName: 'Mateo Gómez (Hijo)',
        address: 'Av. Javier Prado Este 2450, San Borja',
        latitude: -12.0920,
        longitude: -77.0280,
        estimatedTime: '07:25 AM',
        isPickedUp: true,
        order: 1,
      ),
      StudentStop(
        id: 'stp-02',
        studentName: 'Camila Quispe',
        address: 'Calle Los Pinos 180, Miraflores',
        latitude: -12.1050,
        longitude: -77.0320,
        estimatedTime: '07:35 AM',
        isPickedUp: false,
        order: 2,
      ),
      StudentStop(
        id: 'stp-03',
        studentName: 'Colegio San Juan (Destino)',
        address: 'Av. Arequipa 3890, Miraflores',
        latitude: -12.1120,
        longitude: -77.0350,
        estimatedTime: '07:50 AM',
        isPickedUp: false,
        order: 3,
      ),
    ];
  }

  /// US-15: Fetches trips from GET /api/v1/trips/history with sqflite offline cache.
  Future<List<TripHistoryRecord>> getTripHistory(
    String token, {
    SessionManager? sessionManager,
    String? userId,
  }) async {
    final resolvedUid = userId ?? sessionManager?.userId;
    if (resolvedUid != null &&
        resolvedUid.isNotEmpty &&
        sessionManager != null &&
        sessionManager.cacheOwner != resolvedUid) {
      await _db.clearUserScopedCaches();
      await sessionManager.setCacheOwner(resolvedUid);
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/history');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> items = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['items'] is List
                ? decoded['items'] as List<dynamic>
                : <dynamic>[]);
        final parsed = items
            .whereType<Map<String, dynamic>>()
            .map(TripHistoryRecord.fromJson)
            .toList();
        await _db.replaceSyncedRows(
          'trip_history_cache',
          parsed
              .map((e) => <String, Object?>{
                    'trip_id': e.tripId,
                    'route_id': '',
                    'route_name': e.routeName,
                    'driver_name': e.driverName,
                    'vehicle_plate': e.vehiclePlate,
                    'status': e.status,
                    'boarded_count': e.boardedCount,
                    'total_students': e.totalStudents,
                    'start_time': e.dateEs,
                    'end_time': e.dateEn,
                    'my_rating': e.rating,
                    'cancellation_reason': e.cancellationReason,
                  })
              .toList(),
          pk: 'trip_id',
          hasPendingSync: false,
        );
        return parsed;
      }
    } catch (_) {
      // Offline sqflite fallback below
    }
    final cached = await _db.queryAll('trip_history_cache');
    if (cached.isNotEmpty) {
      return cached
          .map((r) => TripHistoryRecord(
                tripId: r['trip_id']?.toString() ?? '',
                routeName: r['route_name']?.toString() ?? '',
                driverName: r['driver_name']?.toString() ?? '',
                vehiclePlate: r['vehicle_plate']?.toString() ?? '',
                dateEs: r['start_time']?.toString() ?? '',
                dateEn: r['end_time']?.toString() ?? '',
                boardedCount: (r['boarded_count'] as num?)?.toInt() ?? 0,
                totalStudents: (r['total_students'] as num?)?.toInt() ?? 0,
                status: r['status']?.toString() ?? 'COMPLETED',
                rating: (r['my_rating'] as num?)?.toInt(),
                cancellationReason: r['cancellation_reason']?.toString(),
              ))
          .toList();
    }
    return List<TripHistoryRecord>.from(_fallbackHistory);
  }

  /// US-09: Records early student absence in sqflite and POST /api/v1/absences.
  Future<bool> reportEarlyAbsence({
    required String tripId,
    required String studentName,
    required String reason,
    String notes = '',
    String token = '',
    String? childId,
    String? routeId,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final id = 'local_${DateTime.now().microsecondsSinceEpoch}';
    await _db.upsertRow('absence_reports', {
      'id': id,
      'child_id': childId ?? '',
      'child_name': studentName,
      'route_id': routeId ?? '',
      'absence_date': today,
      'reason': reason,
      'notes': notes,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'pending_sync': 1,
    });
    final uri = Uri.parse('${ApiConstants.baseUrl}/absences');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              if (childId != null && childId.isNotEmpty) 'childId': childId,
              'childName': studentName,
              if (routeId != null && routeId.isNotEmpty) 'routeId': routeId,
              'absenceDate': today,
              'reason': reason,
              'notes': notes,
            }),
          )
          .timeout(ApiConstants.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _db.deleteById('absence_reports', id);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// US-14: Submits parent service rating (1-5 stars) into sqflite and POST /api/v1/trips/{id}/rating.
  Future<bool> submitServiceRating({
    required String tripId,
    required int stars,
    String comment = '',
    String token = '',
  }) async {
    await _db.upsertRow(
      'trip_ratings',
      {
        'trip_id': tripId,
        'stars': stars,
        'comment': comment,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'pending_sync': 1,
      },
      pk: 'trip_id',
    );
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/rating');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'stars': stars,
              'comment': comment,
            }),
          )
          .timeout(ApiConstants.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _db.upsertRow(
          'trip_ratings',
          {
            'trip_id': tripId,
            'stars': stars,
            'comment': comment,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'pending_sync': 0,
          },
          pk: 'trip_id',
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// US-29: Posts roadblock/incident alert to /api/v1/trips/{id}/incidents with offline fallback.
  Future<bool> reportTripIncident({
    required String tripId,
    required String category,
    required int delayMinutes,
    String notes = '',
    String token = '',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/incidents');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'description': '$category (+$delayMinutes min)${notes.isNotEmpty ? ': $notes' : ''}',
              'category': category,
              'delayMinutes': delayMinutes,
              'notes': notes,
            }),
          )
          .timeout(ApiConstants.timeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// US-21: Broadcasts force majeure trip cancellation via POST /api/v1/trips/{id}/cancel (with panic fallback).
  Future<bool> cancelTripForceMajeure({
    required String tripId,
    required String reason,
    String notes = '',
    String token = '',
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final cancelUri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/cancel');
    try {
      final response = await _client
          .post(
            cancelUri,
            headers: headers,
            body: jsonEncode({'reason': reason, 'notes': notes}),
          )
          .timeout(ApiConstants.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) return true;
    } catch (_) {}

    final panicUri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/panic');
    try {
      final response = await _client
          .post(
            panicUri,
            headers: headers,
            body: jsonEncode({
              'type': 'FORCE_MAJEURE_CANCELLATION',
              'reason': reason,
              'notes': notes,
            }),
          )
          .timeout(ApiConstants.timeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
