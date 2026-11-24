class RouteWaypoint {
  final String id;
  final int orderIndex;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String scheduledTime;

  RouteWaypoint({
    required this.id,
    required this.orderIndex,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.scheduledTime,
  });

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      orderIndex: json['orderIndex'] ?? json['order'] ?? json['Order'] ?? 1,
      name: json['name'] ?? json['Name'] ?? 'Parada Escolar',
      address: json['address'] ?? json['Address'] ?? json['name'] ?? '',
      latitude: (json['latitude'] ?? json['Latitude'] as num?)?.toDouble() ?? -12.0965,
      longitude: (json['longitude'] ?? json['Longitude'] as num?)?.toDouble() ?? -77.0360,
      scheduledTime: json['scheduledTime'] ?? json['time'] ?? '07:15 AM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderIndex': orderIndex,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'scheduledTime': scheduledTime,
    };
  }
}
