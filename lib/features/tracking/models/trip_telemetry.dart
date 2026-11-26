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
  final String? vehicleModel;
  final String? driverPhone;
  final String? driverLicense;
  final String? driverLicenseCategory;
  final String? soatPolicy;
  final String? soatInsurer;
  final String? soatExpiresAt;

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
    this.vehicleModel,
    this.driverPhone,
    this.driverLicense,
    this.driverLicenseCategory,
    this.soatPolicy,
    this.soatInsurer,
    this.soatExpiresAt,
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
      routeName: json['routeName'] ?? json['RouteName'] ?? 'Ruta San Martín - Turno Mañana',
      driverName: json['driverName'] ?? json['DriverName'] ?? 'Carlos Ramirez',
      vehiclePlate: json['vehiclePlate'] ?? json['VehiclePlate'] ?? 'ABC-123',
      currentLatitude: lat ?? -12.0872,
      currentLongitude: lng ?? -77.0350,
      speedKmh: speed ?? 32.5,
      status: (json['status'] ?? json['Status'] ?? 'IN_PROGRESS').toString().toUpperCase(),
      totalStudents: json['totalStudents'] ?? json['totalChildren'] ?? json['TotalChildren'] ?? 12,
      onboardStudents: json['onboardStudents'] ?? json['boardedCount'] ?? json['BoardedCount'] ?? 5,
      nextStopName: json['nextStopName'],
      etaNextStopMinutes: json['etaNextStopMinutes'],
      vehicleModel: json['vehicleModel']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      driverLicense: json['driverLicense']?.toString(),
      driverLicenseCategory: json['driverLicenseCategory']?.toString(),
      soatPolicy: json['soatPolicy']?.toString(),
      soatInsurer: json['soatInsurer']?.toString(),
      soatExpiresAt: json['soatExpiresAt']?.toString(),
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
