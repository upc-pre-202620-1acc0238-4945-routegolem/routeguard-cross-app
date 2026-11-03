class StudentStop {
  final String id;
  final String studentName;
  final String address;
  final double latitude;
  final double longitude;
  final String estimatedTime;
  final bool isPickedUp;

  StudentStop({
    required this.id,
    required this.studentName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.estimatedTime,
    this.isPickedUp = false,
  });

  factory StudentStop.fromJson(Map<String, dynamic> json) {
    return StudentStop(
      id: json['id']?.toString() ?? '',
      studentName: json['studentName'] ?? json['name'] ?? 'Estudiante',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -12.0865,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -77.0345,
      estimatedTime: json['estimatedTime'] ?? '07:30 AM',
      isPickedUp: json['isPickedUp'] ?? false,
    );
  }
}
