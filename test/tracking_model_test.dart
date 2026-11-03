import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/features/tracking/models/student_stop.dart';
import 'package:routeguard_cross_app/features/tracking/models/trip_telemetry.dart';

void main() {
  group('Tracking Models Tests', () {
    test('creates TripTelemetry from valid json', () {
      final json = {
        'tripId': 'TRP-100',
        'routeName': 'Ruta Norte 01',
        'driverName': 'Carlos Chofer',
        'vehiclePlate': 'XYZ-123',
        'latitude': -12.0965,
        'longitude': -77.0360,
        'speedKmh': 35.0,
        'status': 'EN_RUTA',
        'totalStudents': 10,
        'onboardStudents': 4,
      };

      final telemetry = TripTelemetry.fromJson(json);

      expect(telemetry.tripId, 'TRP-100');
      expect(telemetry.speedKmh, 35.0);
      expect(telemetry.onboardStudents, 4);
    });

    test('creates StudentStop from valid json', () {
      final json = {
        'id': 'stp-05',
        'studentName': 'Mateo Gómez',
        'address': 'Av. Primavera 120',
        'latitude': -12.11,
        'longitude': -77.02,
        'estimatedTime': '07:20 AM',
        'isPickedUp': true,
      };

      final stop = StudentStop.fromJson(json);

      expect(stop.id, 'stp-05');
      expect(stop.studentName, 'Mateo Gómez');
      expect(stop.isPickedUp, isTrue);
    });
  });
}
