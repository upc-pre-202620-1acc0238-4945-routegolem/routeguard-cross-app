import 'student_stop.dart';

class LiveChildInfo {
  final String childId;
  final String name;
  final String boardingState;

  const LiveChildInfo({
    required this.childId,
    required this.name,
    required this.boardingState,
  });

  factory LiveChildInfo.fromJson(Map<String, dynamic> json) {
    return LiveChildInfo(
      childId: (json['childId'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? 'Estudiante').toString(),
      boardingState: (json['boardingState'] ?? 'MISSING').toString().toUpperCase(),
    );
  }
}

class TripTelemetry {
  final String tripId;
  final String? routeId;
  final String routeName;
  final String driverName;
  final String vehiclePlate;
  final double currentLatitude;
  final double currentLongitude;
  final double speedKmh;
  final String status;
  final int totalStudents;
  final int onboardStudents;
  final String? nextStopName;
  final int? etaNextStopMinutes;
  final String? vehicleModel;
  final String? driverPhone;
  final String? driverLicense;
  final String? driverLicenseCategory;
  final String? soatPolicy;
  final String? soatInsurer;
  final String? soatExpiresAt;
  final bool hasLiveLocation;
  final int? locationRecordedAtMs;
  final List<StudentStop> stops;
  final List<LiveChildInfo> children;

  TripTelemetry({
    required this.tripId,
    this.routeId,
    required this.routeName,
    required this.driverName,
    required this.vehiclePlate,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.speedKmh,
    required this.status,
    required this.totalStudents,
    required this.onboardStudents,
    this.nextStopName,
    this.etaNextStopMinutes,
    this.vehicleModel,
    this.driverPhone,
    this.driverLicense,
    this.driverLicenseCategory,
    this.soatPolicy,
    this.soatInsurer,
    this.soatExpiresAt,
    this.hasLiveLocation = true,
    this.locationRecordedAtMs,
    this.stops = const [],
    this.children = const [],
  });

  factory TripTelemetry.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final lat = location != null
        ? (location['latitude'] ?? location['Latitude'] as num?)?.toDouble()
        : (json['latitude'] ?? json['currentLatitude'] as num?)?.toDouble();
    final lng = location != null
        ? (location['longitude'] ?? location['Longitude'] as num?)?.toDouble()
        : (json['longitude'] ?? json['currentLongitude'] as num?)?.toDouble();
    final speed = location != null
        ? (location['speedKmh'] ?? location['SpeedKmh'] as num?)?.toDouble()
        : (json['speedKmh'] as num?)?.toDouble();
    final recordedAtMs = location != null
        ? (location['recordedAt'] as num?)?.toInt()
        : (json['recordedAt'] as num?)?.toInt();

    final rawStops = json['stops'] as List<dynamic>? ?? const [];
    final parsedStops = rawStops
        .whereType<Map<String, dynamic>>()
        .map(StudentStop.fromJson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final rawChildren = json['children'] as List<dynamic>? ?? const [];
    final parsedChildren = rawChildren
        .whereType<Map<String, dynamic>>()
        .map(LiveChildInfo.fromJson)
        .toList();

    final fallbackLat = parsedStops.isNotEmpty ? parsedStops.first.latitude : -12.0872;
    final fallbackLng = parsedStops.isNotEmpty ? parsedStops.first.longitude : -77.0350;
    final nextUnreached = parsedStops.where((s) => !s.isPickedUp).firstOrNull;

    return TripTelemetry(
      tripId: (json['tripId'] ?? json['TripId'] ?? json['id'])?.toString() ?? 'TRP-101',
      routeId: (json['routeId'] ?? json['RouteId'])?.toString(),
      routeName: json['routeName'] ?? json['RouteName'] ?? 'Ruta San Martín - Turno Mañana',
      driverName: json['driverName'] ?? json['DriverName'] ?? 'Carlos Ramirez',
      vehiclePlate: json['vehiclePlate'] ?? json['VehiclePlate'] ?? 'ABC-123',
      currentLatitude: lat ?? fallbackLat,
      currentLongitude: lng ?? fallbackLng,
      speedKmh: speed ?? 0.0,
      status: (json['status'] ?? json['Status'] ?? 'IN_PROGRESS').toString().toUpperCase(),
      totalStudents: json['totalStudents'] ?? json['totalChildren'] ?? json['TotalChildren'] ?? 12,
      onboardStudents: json['onboardStudents'] ?? json['boardedCount'] ?? json['BoardedCount'] ?? 5,
      nextStopName: json['nextStopName']?.toString() ?? nextUnreached?.studentName,
      etaNextStopMinutes: (json['etaNextStopMinutes'] as num?)?.toInt(),
      vehicleModel: json['vehicleModel']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      driverLicense: json['driverLicense']?.toString(),
      driverLicenseCategory: json['driverLicenseCategory']?.toString(),
      soatPolicy: json['soatPolicy']?.toString(),
      soatInsurer: json['soatInsurer']?.toString(),
      soatExpiresAt: json['soatExpiresAt']?.toString(),
      hasLiveLocation: lat != null && lng != null,
      locationRecordedAtMs: recordedAtMs,
      stops: parsedStops,
      children: parsedChildren,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      if (routeId != null) 'routeId': routeId,
      'routeName': routeName,
      'driverName': driverName,
      'vehiclePlate': vehiclePlate,
      'latitude': currentLatitude,
      'longitude': currentLongitude,
      'speedKmh': speedKmh,
      'status': status,
      'totalStudents': totalStudents,
      'onboardStudents': onboardStudents,
      if (nextStopName != null) 'nextStopName': nextStopName,
      if (etaNextStopMinutes != null) 'etaNextStopMinutes': etaNextStopMinutes,
    };
  }
}
