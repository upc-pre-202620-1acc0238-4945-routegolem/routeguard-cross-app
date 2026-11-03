class SafetyAlert {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final String type; // 'BOARDING', 'ARRIVED', 'TRAFFIC', 'INFO'

  SafetyAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
  });

  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    return SafetyAlert(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Aviso escolar',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? 'Hoy 07:25 AM',
      type: json['type'] ?? 'INFO',
    );
  }
}
