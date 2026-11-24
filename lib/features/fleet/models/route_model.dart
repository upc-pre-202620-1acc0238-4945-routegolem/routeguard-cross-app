import 'route_waypoint.dart';

class RouteModel {
  final String id;
  final String name;
  final String status; // 'DRAFT', 'ACTIVE', 'INACTIVE'
  final int stopCount;
  final List<String> studentIds;
  final String? departureTime;
  final List<RouteWaypoint> waypoints;
  final String driverName;
  final String vehiclePlate;

  RouteModel({
    required this.id,
    required this.name,
    this.status = 'ACTIVE',
    this.stopCount = 4,
    this.studentIds = const [],
    this.departureTime,
    this.waypoints = const [],
    this.driverName = 'Carlos Ramírez',
    this.vehiclePlate = 'ABC-789',
  });

  bool get isEditable => status.toUpperCase() == 'DRAFT';
  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final rawWaypoints = (json['waypoints'] ?? json['stops'] ?? json['Stops']) as List<dynamic>? ?? [];
    final assignment = json['assignment'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final rawStudents = (json['studentIds'] ?? assignment?['children'] ?? assignment?['childIds']) as List<dynamic>? ?? [];
    final rawStatus = (json['status'] ?? json['state'] ?? json['State'] ?? 'ACTIVE').toString().toUpperCase();

    return RouteModel(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      name: json['name'] ?? json['Name'] ?? 'Ruta Escolar',
      status: rawStatus,
      stopCount: json['stopCount'] ?? rawWaypoints.length,
      studentIds: rawStudents.map((e) => e.toString()).toList(),
      departureTime: json['departureTime'] ?? json['DepartureTime'],
      waypoints: rawWaypoints
          .map((w) => RouteWaypoint.fromJson(Map<String, dynamic>.from(w)))
          .toList(),
      driverName: assignment?['driverName'] ?? json['driverName'] ?? 'Carlos Ramírez',
      vehiclePlate: vehicle?['licensePlate'] ?? vehicle?['plate'] ?? json['vehiclePlate'] ?? 'ABC-789',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'stopCount': stopCount,
      'studentIds': studentIds,
      'departureTime': departureTime,
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'driverName': driverName,
      'vehiclePlate': vehiclePlate,
    };
  }
}
