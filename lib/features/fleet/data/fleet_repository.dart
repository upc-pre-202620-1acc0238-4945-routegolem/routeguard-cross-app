import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/route_model.dart';
import '../models/route_waypoint.dart';

class FleetRepository {
  final http.Client _client;

  static final List<RouteModel> _mockRoutes = [
    RouteModel(
      id: 'rt_01',
      name: 'Ruta 01 - Primaria San Borja',
      status: 'ACTIVE',
      stopCount: 4,
      studentIds: ['stu_01', 'stu_02', 'stu_03', 'stu_04'],
      departureTime: '06:50 AM',
      driverName: 'Carlos Ramírez',
      vehiclePlate: 'ABC-789',
      waypoints: [
        RouteWaypoint(
          id: 'wp_01',
          orderIndex: 1,
          name: 'Parada Javier Prado Este 2450',
          address: 'Av. Javier Prado Este 2450, San Borja',
          latitude: -12.0920,
          longitude: -77.0280,
          scheduledTime: '07:05 AM',
        ),
        RouteWaypoint(
          id: 'wp_02',
          orderIndex: 2,
          name: 'Parada Av. Aviación 1400',
          address: 'Av. Aviación 1400, San Borja',
          latitude: -12.0965,
          longitude: -77.0360,
          scheduledTime: '07:18 AM',
        ),
        RouteWaypoint(
          id: 'wp_03',
          orderIndex: 3,
          name: 'Parada Parque de la Familia',
          address: 'Calle Las Flores 320, San Borja',
          latitude: -12.1020,
          longitude: -77.0420,
          scheduledTime: '07:30 AM',
        ),
        RouteWaypoint(
          id: 'wp_04',
          orderIndex: 4,
          name: 'Colegio San Juan (Destino)',
          address: 'Av. Primavera 120, Surco',
          latitude: -12.1105,
          longitude: -77.0480,
          scheduledTime: '07:45 AM',
        ),
      ],
    ),
    RouteModel(
      id: 'rt_02',
      name: 'Ruta 02 - Turno Mañana Miraflores',
      status: 'ACTIVE',
      stopCount: 3,
      studentIds: ['stu_01', 'stu_02'],
      departureTime: '07:00 AM',
      driverName: 'Luis Johnny Salazar',
      vehiclePlate: 'DEF-456',
      waypoints: [
        RouteWaypoint(
          id: 'wp_11',
          orderIndex: 1,
          name: 'Parada Malecón de la Marina 450',
          address: 'Malecón de la Marina 450, Miraflores',
          latitude: -12.1180,
          longitude: -77.0450,
          scheduledTime: '07:10 AM',
        ),
        RouteWaypoint(
          id: 'wp_12',
          orderIndex: 2,
          name: 'Parada Av. Larco 820',
          address: 'Av. Larco 820, Miraflores',
          latitude: -12.1240,
          longitude: -77.0310,
          scheduledTime: '07:25 AM',
        ),
        RouteWaypoint(
          id: 'wp_13',
          orderIndex: 3,
          name: 'Colegio San Juan (Destino)',
          address: 'Av. Primavera 120, Surco',
          latitude: -12.1105,
          longitude: -77.0480,
          scheduledTime: '07:50 AM',
        ),
      ],
    ),
    RouteModel(
      id: 'rt_03',
      name: 'Ruta 03 - Tarde Secundaria Surco',
      status: 'DRAFT',
      stopCount: 2,
      studentIds: ['stu_03'],
      departureTime: '01:30 PM',
      driverName: 'Carlos Ramírez',
      vehiclePlate: 'ABC-789',
      waypoints: [
        RouteWaypoint(
          id: 'wp_21',
          orderIndex: 1,
          name: 'Colegio San Juan (Salida)',
          address: 'Av. Primavera 120, Surco',
          latitude: -12.1105,
          longitude: -77.0480,
          scheduledTime: '01:45 PM',
        ),
        RouteWaypoint(
          id: 'wp_22',
          orderIndex: 2,
          name: 'Parada Av. Benavides 2800',
          address: 'Av. Benavides 2800, Surco',
          latitude: -12.1280,
          longitude: -77.0150,
          scheduledTime: '02:10 PM',
        ),
      ],
    ),
  ];

  FleetRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<RouteModel>> getRoutes([String token = '']) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.routesEndpoint}');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RouteModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return List.unmodifiable(_mockRoutes);
  }

  Future<RouteModel?> getRouteDetail(String routeId, [String token = '']) async {
    final routes = await getRoutes(token);
    try {
      return routes.firstWhere((r) => r.id == routeId);
    } catch (_) {
      return _mockRoutes.first;
    }
  }

  Future<RouteModel> createRoute(String name, [String token = '']) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.routesEndpoint}');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'name': name}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final created = RouteModel.fromJson(data);
        _mockRoutes.add(created);
        return created;
      }
    } catch (_) {}

    final newRoute = RouteModel(
      id: 'rt_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      status: 'DRAFT',
      stopCount: 0,
      studentIds: [],
      waypoints: [],
    );
    _mockRoutes.add(newRoute);
    return newRoute;
  }

  Future<void> addWaypoint(String routeId, RouteWaypoint waypoint, [String token = '']) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.routesEndpoint}/$routeId/stops');
    try {
      await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': waypoint.name,
          'latitude': waypoint.latitude,
          'longitude': waypoint.longitude,
          'order': waypoint.orderIndex,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    final index = _mockRoutes.indexWhere((r) => r.id == routeId);
    if (index != -1) {
      final old = _mockRoutes[index];
      final updatedWaypoints = [...old.waypoints, waypoint];
      _mockRoutes[index] = RouteModel(
        id: old.id,
        name: old.name,
        status: old.status,
        stopCount: updatedWaypoints.length,
        studentIds: old.studentIds,
        departureTime: old.departureTime,
        driverName: old.driverName,
        vehiclePlate: old.vehiclePlate,
        waypoints: updatedWaypoints,
      );
    }
  }

  Future<void> activateRoute(String routeId, [String token = '']) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.routesEndpoint}/$routeId/activate');
    try {
      await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    final index = _mockRoutes.indexWhere((r) => r.id == routeId);
    if (index != -1) {
      final old = _mockRoutes[index];
      _mockRoutes[index] = RouteModel(
        id: old.id,
        name: old.name,
        status: 'ACTIVE',
        stopCount: old.stopCount,
        studentIds: old.studentIds,
        departureTime: old.departureTime ?? '07:00 AM',
        driverName: old.driverName,
        vehiclePlate: old.vehiclePlate,
        waypoints: old.waypoints,
      );
    }
  }

  Future<void> assignDriverAndVehicle(
    String routeId,
    String driverName,
    String vehiclePlate,
  ) async {
    final index = _mockRoutes.indexWhere((r) => r.id == routeId);
    if (index != -1) {
      final old = _mockRoutes[index];
      _mockRoutes[index] = RouteModel(
        id: old.id,
        name: old.name,
        status: old.status,
        stopCount: old.stopCount,
        studentIds: old.studentIds,
        departureTime: old.departureTime,
        driverName: driverName,
        vehiclePlate: vehiclePlate,
        waypoints: old.waypoints,
      );
    }
  }
}
