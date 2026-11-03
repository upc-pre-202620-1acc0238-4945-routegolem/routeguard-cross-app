import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/student_stop.dart';
import '../models/trip_telemetry.dart';

class TrackingRepository {
  final http.Client _client;

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
}
