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
  });

  factory TripTelemetry.fromJson(Map<String, dynamic> json) {
    return TripTelemetry(
      tripId: json['tripId']?.toString() ?? 'TRP-101',
      routeName: json['routeName'] ?? 'Ruta Escolar Norte A-1',
      driverName: json['driverName'] ?? 'Luis Johnny (Conductor Oficial)',
      vehiclePlate: json['vehiclePlate'] ?? 'ABC-789',
      currentLatitude: (json['latitude'] as num?)?.toDouble() ?? -12.0872,
      currentLongitude: (json['longitude'] as num?)?.toDouble() ?? -77.0350,
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 32.5,
      status: json['status'] ?? 'IN_PROGRESS',
      totalStudents: json['totalStudents'] ?? 12,
      onboardStudents: json['onboardStudents'] ?? 5,
    );
  }
}
