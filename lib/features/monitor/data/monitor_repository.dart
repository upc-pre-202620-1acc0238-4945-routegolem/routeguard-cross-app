import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../tracking/models/trip_telemetry.dart';

class MonitorRepository {
  final http.Client _client;

  static final List<TripTelemetry> _mockFleetTrips = [
    TripTelemetry(
      tripId: 'TRP-101',
      routeName: 'Ruta 01 - Primaria San Borja',
      driverName: 'Carlos Ramírez',
      vehiclePlate: 'ABC-789',
      currentLatitude: -12.0965,
      currentLongitude: -77.0360,
      speedKmh: 36.5,
      status: 'EN_RUTA',
      totalStudents: 12,
      onboardStudents: 8,
      nextStopName: 'Parada Parque de la Familia',
      etaNextStopMinutes: 6,
    ),
    TripTelemetry(
      tripId: 'TRP-102',
      routeName: 'Ruta 02 - Turno Mañana Miraflores',
      driverName: 'Luis Johnny Salazar',
      vehiclePlate: 'DEF-456',
      currentLatitude: -12.1220,
      currentLongitude: -77.0320,
      speedKmh: 28.0,
      status: 'EN_RUTA',
      totalStudents: 10,
      onboardStudents: 5,
      nextStopName: 'Parada Av. Larco 820',
      etaNextStopMinutes: 4,
    ),
  ];

  MonitorRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<TripTelemetry>> getActiveFleetTrips([String token = '']) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.liveTripsEndpoint}');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => TripTelemetry.fromJson(json)).toList();
        } else if (data is Map<String, dynamic>) {
          return [TripTelemetry.fromJson(data)];
        }
      }
    } catch (_) {}
    return List.unmodifiable(_mockFleetTrips);
  }
}
