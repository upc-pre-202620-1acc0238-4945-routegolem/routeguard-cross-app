import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/features/fleet/data/fleet_repository.dart';
import 'package:routeguard_cross_app/features/fleet/models/route_model.dart';
import 'package:routeguard_cross_app/features/fleet/models/route_waypoint.dart';

void main() {
  group('Fleet Models & Repository Tests', () {
    test('RouteWaypoint JSON serialization and deserialization', () {
      final json = {
        'id': 'wp_01',
        'orderIndex': 1,
        'name': 'Parada Av. Larco 100',
        'address': 'Av. Larco 100, Miraflores',
        'latitude': -12.1200,
        'longitude': -77.0300,
        'scheduledTime': '07:15 AM',
      };

      final wp = RouteWaypoint.fromJson(json);
      expect(wp.id, 'wp_01');
      expect(wp.orderIndex, 1);
      expect(wp.name, 'Parada Av. Larco 100');
      expect(wp.scheduledTime, '07:15 AM');

      final serialized = wp.toJson();
      expect(serialized['address'], 'Av. Larco 100, Miraflores');
    });

    test('RouteModel status checks and waypoints parsing', () {
      final draftRoute = RouteModel(
        id: 'rt_draft',
        name: 'Ruta Borrador',
        status: 'DRAFT',
        stopCount: 0,
      );
      expect(draftRoute.isEditable, isTrue);
      expect(draftRoute.isActive, isFalse);

      final activeRoute = RouteModel(
        id: 'rt_active',
        name: 'Ruta Operativa',
        status: 'ACTIVE',
        stopCount: 3,
      );
      expect(activeRoute.isEditable, isFalse);
      expect(activeRoute.isActive, isTrue);
    });

    test('RouteModel parses backend RouteResource (State, Stops, Vehicle, Assignment)', () {
      final backendJson = {
        'id': 'route-guid-1',
        'name': 'Ruta Backend Oficial',
        'state': 'DRAFT',
        'departureTime': '06:45 AM',
        'stops': [
          {
            'id': 'stop-1',
            'name': 'Parada Av. Angamos',
            'latitude': -12.1100,
            'longitude': -77.0300,
            'order': 1,
          },
          {
            'id': 'stop-2',
            'name': 'Colegio San Juan',
            'latitude': -12.1150,
            'longitude': -77.0350,
            'order': 2,
          },
        ],
        'vehicle': {
          'licensePlate': 'DEF-999',
        },
        'assignment': {
          'driverName': 'Luis Johnny Salazar',
          'childIds': ['c-1', 'c-2'],
        },
      };

      final route = RouteModel.fromJson(backendJson);

      expect(route.id, 'route-guid-1');
      expect(route.name, 'Ruta Backend Oficial');
      expect(route.status, 'DRAFT');
      expect(route.isEditable, isTrue);
      expect(route.waypoints.length, 2);
      expect(route.waypoints.first.name, 'Parada Av. Angamos');
      expect(route.waypoints.first.orderIndex, 1);
      expect(route.vehiclePlate, 'DEF-999');
      expect(route.driverName, 'Luis Johnny Salazar');
      expect(route.studentIds.length, 2);
    });

    test('FleetRepository CRUD and route activation in fallback mode', () async {
      final repo = FleetRepository();

      final routes = await repo.getRoutes();
      expect(routes.length, greaterThanOrEqualTo(2));

      // Create new draft route
      final created = await repo.createRoute('Ruta Test 99');
      expect(created.name, 'Ruta Test 99');
      expect(created.status, 'DRAFT');
      expect(created.isEditable, isTrue);

      // Add waypoint to draft route
      final newWaypoint = RouteWaypoint(
        id: 'wp_test',
        orderIndex: 1,
        name: 'Parada Nueva',
        address: 'Calle San Juan 123',
        latitude: -12.09,
        longitude: -77.03,
        scheduledTime: '07:20 AM',
      );
      await repo.addWaypoint(created.id, newWaypoint);

      final updated = await repo.getRouteDetail(created.id);
      expect(updated, isNotNull);
      expect(updated!.waypoints.any((w) => w.id == 'wp_test'), isTrue);

      // Activate route
      await repo.activateRoute(created.id);
      final activated = await repo.getRouteDetail(created.id);
      expect(activated!.isActive, isTrue);
      expect(activated.isEditable, isFalse);
    });
  });
}
