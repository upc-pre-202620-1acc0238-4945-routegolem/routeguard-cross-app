import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/student_stop.dart';
import '../models/trip_history_record.dart';
import '../models/trip_telemetry.dart';

class TrackingRepository {
  final http.Client _client;

  static final List<TripHistoryRecord> _fallbackHistory = [
    TripHistoryRecord(
      tripId: 'TRP-2026-07',
      routeName: 'Ruta 02 - Turno Mañana',
      driverName: 'Carlos Ramírez',
      vehiclePlate: 'ABC-789',
      dateEs: 'Ayer, 07:50 AM',
      dateEn: 'Yesterday, 07:50 AM',
      boardedCount: 14,
      totalStudents: 14,
      status: 'COMPLETED',
      rating: 5,
    ),
    TripHistoryRecord(
      tripId: 'TRP-2026-06',
      routeName: 'Ruta 02 - Turno Tarde',
      driverName: 'Carlos Ramírez',
      vehiclePlate: 'ABC-789',
      dateEs: 'Hace 2 días, 03:45 PM',
      dateEn: '2 days ago, 03:45 PM',
      boardedCount: 13,
      totalStudents: 14,
      status: 'COMPLETED',
    ),
    TripHistoryRecord(
      tripId: 'TRP-2026-05',
      routeName: 'Ruta 01 - Primaria San Borja',
      driverName: 'Luis Johnny Salazar',
      vehiclePlate: 'DEF-456',
      dateEs: 'Hace 3 días, 07:35 AM',
      dateEn: '3 days ago, 07:35 AM',
      boardedCount: 6,
      totalStudents: 12,
      status: 'CANCELLED',
      cancellationReason: 'Bloqueo total de vía',
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
      routeName: 'Ruta 02 - Colegio San Juan',
      driverName: 'Luis Johnny Pérez',
      vehiclePlate: 'B7X-912',
      currentLatitude: -12.0965,
      currentLongitude: -77.0360,
      speedKmh: 28.4,
      status: 'EN_RUTA',
      totalStudents: 14,
      onboardStudents: 6,
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

  /// US-15: Fetches completed/cancelled trips from GET /api/v1/trips with offline fallback.
  Future<List<TripHistoryRecord>> getTripHistory(String token) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}');
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
          return parsed;
        }
      }
    } catch (_) {
      // Offline fallback below
    }
    return List<TripHistoryRecord>.from(_fallbackHistory);
  }

  /// US-09: Records early student absence with resilient offline fallback.
  Future<bool> reportEarlyAbsence({
    required String tripId,
    required String studentName,
    required String reason,
    String notes = '',
    String token = '',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/absences');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'studentName': studentName,
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

  /// US-14: Submits parent service rating (1-5 stars) with offline fallback.
  Future<bool> submitServiceRating({
    required String tripId,
    required int stars,
    String comment = '',
    String token = '',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/rating');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'stars': stars,
              'comment': comment,
            }),
          )
          .timeout(ApiConstants.timeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
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

  /// US-21: Broadcasts force majeure trip cancellation via panic/broadcast endpoint.
  Future<bool> cancelTripForceMajeure({
    required String tripId,
    required String reason,
    String notes = '',
    String token = '',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$tripId/panic');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
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
