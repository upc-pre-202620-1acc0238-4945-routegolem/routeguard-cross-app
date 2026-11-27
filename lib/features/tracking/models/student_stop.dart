class StudentStop {
  final String id;
  final String studentName;
  final String address;
  final double latitude;
  final double longitude;
  final String estimatedTime;
  final bool isPickedUp;
  final int order;

  StudentStop({
    required this.id,
    required this.studentName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.estimatedTime,
    this.isPickedUp = false,
    this.order = 1,
  });

  factory StudentStop.fromJson(Map<String, dynamic> json) {
    final name = (json['studentName'] ?? json['name'] ?? 'Parada').toString();
    final orderVal = (json['order'] as num?)?.toInt() ?? 1;
    return StudentStop(
      id: (json['id'] ?? json['stopId'] ?? 'stp_$orderVal').toString(),
      studentName: name,
      address: (json['address'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? -12.0865,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -77.0345,
      estimatedTime: (json['estimatedTime'] ?? '#$orderVal').toString(),
      isPickedUp: (json['isPickedUp'] ?? json['reached'] ?? false) == true,
      order: orderVal,
    );
  }
}
