class TripTelemetry {
  final String tripId;
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

  TripTelemetry({
    required this.tripId,
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

    return TripTelemetry(
      tripId: (json['tripId'] ?? json['TripId'])?.toString() ?? 'TRP-101',
      routeName: json['routeName'] ?? json['RouteName'] ?? 'Ruta Escolar Norte A-1',
      driverName: json['driverName'] ?? json['DriverName'] ?? 'Luis Johnny (Conductor Oficial)',
      vehiclePlate: json['vehiclePlate'] ?? json['VehiclePlate'] ?? 'ABC-789',
      currentLatitude: lat ?? -12.0872,
      currentLongitude: lng ?? -77.0350,
      speedKmh: speed ?? 32.5,
      status: (json['status'] ?? json['Status'] ?? 'IN_PROGRESS').toString().toUpperCase(),
      totalStudents: json['totalStudents'] ?? json['totalChildren'] ?? json['TotalChildren'] ?? 12,
      onboardStudents: json['onboardStudents'] ?? json['boardedCount'] ?? json['BoardedCount'] ?? 5,
      nextStopName: json['nextStopName'],
      etaNextStopMinutes: json['etaNextStopMinutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
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
