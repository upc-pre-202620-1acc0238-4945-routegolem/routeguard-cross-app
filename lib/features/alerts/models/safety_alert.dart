import 'package:flutter/foundation.dart';

class SafetyAlert {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final String type; // 'PANIC', 'BOARDING', 'ARRIVED', 'TRAFFIC', 'INFO'

  SafetyAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
  });

  static final List<SafetyAlert> _initialAlerts = [
    SafetyAlert(
      id: 'alt-01',
      title: 'Abordaje Confirmado',
      message: 'Tu hijo Mateo Gómez ha subido a la unidad de transporte en Parada Javier Prado Este 2450.',
      timestamp: 'Hoy, 07:25 AM',
      type: 'BOARDING',
    ),
    SafetyAlert(
      id: 'alt-02',
      title: 'Inicio de Recorrido Escolar',
      message: 'El conductor Luis Johnny inició la Ruta 02 hacia el Colegio San Juan.',
      timestamp: 'Hoy, 07:10 AM',
      type: 'INFO',
    ),
    SafetyAlert(
      id: 'alt-03',
      title: 'Llegada Segura al Colegio',
      message: 'Ayer todos los estudiantes fueron entregados en la puerta principal del colegio sin incidentes.',
      timestamp: 'Ayer, 07:52 AM',
      type: 'ARRIVED',
    ),
    SafetyAlert(
      id: 'alt-04',
      title: 'Aviso de Tránsito Matutino',
      message: 'Congestión moderada reportada en Av. Javier Prado. Tiempo estimado de retraso: +5 minutos.',
      timestamp: 'Ayer, 07:15 AM',
      type: 'TRAFFIC',
    ),
  ];

  static final ValueNotifier<List<SafetyAlert>> sharedAlertsNotifier =
      ValueNotifier<List<SafetyAlert>>(List.from(_initialAlerts));

  static void addAlert({
    required String title,
    required String message,
    required String type,
  }) {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final newAlert = SafetyAlert(
      id: 'alt-${now.millisecondsSinceEpoch}',
      title: title,
      message: message,
      timestamp: 'Hoy, $hour:$minute',
      type: type,
    );
    sharedAlertsNotifier.value = [newAlert, ...sharedAlertsNotifier.value];
  }

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
