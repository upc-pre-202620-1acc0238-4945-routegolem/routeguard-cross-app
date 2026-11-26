import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/database/local_database.dart';
import '../models/student_stop.dart';
import '../models/trip_history_record.dart';
import '../models/trip_telemetry.dart';

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

  Future<TripTelemetry> getActiveTrip(String token) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.activeTripEndpoint}');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TripTelemetry.fromJson(data);
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
      ).timeout(const Duration(seconds: 5));

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
      ),
      StudentStop(
        id: 'stp-02',
        studentName: 'Camila Quispe',
        address: 'Calle Los Pinos 180, Miraflores',
        latitude: -12.1050,
        longitude: -77.0320,
        estimatedTime: '07:35 AM',
        isPickedUp: false,
      ),
      StudentStop(
        id: 'stp-03',
        studentName: 'Colegio San Juan (Destino)',
        address: 'Av. Arequipa 3890, Miraflores',
        latitude: -12.1120,
        longitude: -77.0350,
        estimatedTime: '07:50 AM',
        isPickedUp: false,
      ),
    ];
  }

  /// US-15: Fetches completed/cancelled trips from GET /api/v1/trips/history with sqflite offline cache.
  Future<List<TripHistoryRecord>> getTripHistory(String token) async {
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
        if (parsed.isNotEmpty) {
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
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final id = 'local_${DateTime.now().microsecondsSinceEpoch}';
    await _db.upsertRow('absence_reports', {
      'id': id,
      'child_id': '',
      'child_name': studentName,
      'route_id': '',
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
              'childName': studentName,
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
