import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:routeguard_cross_app/core/database/local_database.dart';
import 'package:routeguard_cross_app/core/network/road_routing_service.dart';
import 'package:routeguard_cross_app/features/alerts/data/notifications_repository.dart';
import 'package:routeguard_cross_app/features/tracking/data/tracking_repository.dart';
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

    test('creates TripTelemetry from backend LiveTripResource (nested location, boardedCount)', () {
      final backendJson = {
        'tripId': 'TRP-LIVE-200',
        'routeName': 'Ruta 01 - Primaria San Borja',
        'driverName': 'Carlos Ramírez',
        'vehiclePlate': 'ABC-789',
        'location': {
          'latitude': -12.0920,
          'longitude': -77.0280,
          'speedKmh': 38.5,
          'recordedAt': 1700000000000,
        },
        'status': 'IN_PROGRESS',
        'totalChildren': 15,
        'boardedCount': 8,
        'nextStopName': 'Colegio San Juan',
        'etaNextStopMinutes': 5,
      };

      final telemetry = TripTelemetry.fromJson(backendJson);

      expect(telemetry.tripId, 'TRP-LIVE-200');
      expect(telemetry.currentLatitude, -12.0920);
      expect(telemetry.currentLongitude, -77.0280);
      expect(telemetry.speedKmh, 38.5);
      expect(telemetry.totalStudents, 15);
      expect(telemetry.onboardStudents, 8);
      expect(telemetry.nextStopName, 'Colegio San Juan');
      expect(telemetry.etaNextStopMinutes, 5);
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

    test('RoadRoutingService parses street-following GeoJSON road geometry', () async {
      final service = RoadRoutingService(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'Ok',
              'routes': [
                {
                  'distance': 1850.5,
                  'duration': 240.0,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-77.0280, -12.0920],
                      [-77.0295, -12.0950],
                      [-77.0310, -12.0990],
                      [-77.0320, -12.1050],
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final result = await service.getRoadRoute(const [
        LatLng(-12.0920, -77.0280),
        LatLng(-12.1050, -77.0320),
      ]);

      expect(result, isNotNull);
      expect(result!.path.length, 4);
      expect(result.path[1].latitude, closeTo(-12.0950, 0.0001));
      expect(result.distanceMeters, closeTo(1850.5, 0.1));
    });

    test('TrackingRepository.getDriverActiveTrip scopes active trip by driverProfileId', () async {
      final repo = TrackingRepository(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/trips')) {
            return http.Response(
              jsonEncode([
                {
                  'id': 'trip-carlos',
                  'driverId': 'drv-carlos',
                  'routeId': 'route-carlos',
                  'tripState': 'IN_PROGRESS',
                  'startTime': '2026-11-27T07:00:00Z',
                },
                {
                  'id': 'trip-luis',
                  'driverId': 'drv-luis',
                  'routeId': 'route-luis',
                  'tripState': 'IN_PROGRESS',
                  'startTime': '2026-11-27T07:10:00Z',
                },
              ]),
              200,
            );
          }
          if (request.url.path.endsWith('/routes/route-carlos')) {
            return http.Response(
              jsonEncode({
                'id': 'route-carlos',
                'name': 'Ruta San Borja',
                'vehicle': {'licensePlate': 'ABC-123'},
                'stops': [],
              }),
              200,
            );
          }
          return http.Response('[]', 200);
        }),
      );

      final result = await repo.getDriverActiveTrip(
        'jwt-token-carlos',
        driverProfileId: 'drv-carlos',
        userId: 'usr-carlos',
      );

      expect(result.isOfflineFallback, isFalse);
      expect(result.hasActiveTrip, isTrue);
      expect(result.tripId, 'trip-carlos');
      expect(result.routeId, 'route-carlos');
      expect(result.routeName, 'Ruta San Borja');
    });

    test('NotificationsRepository queries parentId-scoped alerts for PARENT role', () async {
      LocalDatabase.instance.clearMemoryForTesting();
      Uri? capturedUri;
      final repo = NotificationsRepository(
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(
            jsonEncode([
              {
                'id': 'n-1',
                'title': 'Unidad cerca de parada',
                'body': 'Tu hijo está a 3 minutos',
                'type': 'ARRIVAL',
                'channel': 'PUSH',
                'createdAt': '2026-11-27T07:20:00Z',
                'delivered': false,
              },
            ]),
            200,
          );
        }),
      );

      final alerts = await repo.getNotifications(
        token: 'jwt-parent',
        role: 'PARENT',
        userId: 'usr-parent-2',
        profileId: 'par-jorge',
      );

      expect(capturedUri?.queryParameters['parentId'], 'par-jorge');
      expect(alerts.length, 1);
      expect(alerts.first.id, 'n-1');
    });
  });
}
