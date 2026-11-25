import 'package:flutter/foundation.dart';
import '../../../core/localization/app_strings.dart';

class SafetyAlert {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final String type; // 'PANIC', 'BOARDING', 'ARRIVED', 'TRAFFIC', 'INFO'
  final String? titleEn;
  final String? messageEn;
  final String? timestampEn;

  SafetyAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.titleEn,
    this.messageEn,
    this.timestampEn,
  });

  String get localizedTitle =>
      AppStrings.isSpanish ? title : (titleEn ?? title);

  String get localizedMessage =>
      AppStrings.isSpanish ? message : (messageEn ?? message);

  String get localizedTimestamp =>
      AppStrings.isSpanish ? timestamp : (timestampEn ?? timestamp);

  static final List<SafetyAlert> _initialAlerts = [
    SafetyAlert(
      id: 'alt-01',
      title: 'Abordaje Confirmado',
      titleEn: 'Boarding Confirmed',
      message: 'Tu hijo Mateo Gómez ha subido a la unidad de transporte en Parada Javier Prado Este 2450.',
      messageEn: 'Your child Mateo Gómez boarded the school transport at Javier Prado Este 2450 Stop.',
      timestamp: 'Hoy, 07:25 AM',
      timestampEn: 'Today, 07:25 AM',
      type: 'BOARDING',
    ),
    SafetyAlert(
      id: 'alt-02',
      title: 'Inicio de Recorrido Escolar',
      titleEn: 'School Route Started',
      message: 'El conductor Luis Johnny inició la Ruta 02 hacia el Colegio San Juan.',
      messageEn: 'Driver Luis Johnny started Route 02 toward San Juan School.',
      timestamp: 'Hoy, 07:10 AM',
      timestampEn: 'Today, 07:10 AM',
      type: 'INFO',
    ),
    SafetyAlert(
      id: 'alt-03',
      title: 'Llegada Segura al Colegio',
      titleEn: 'Safe Arrival at School',
      message: 'Ayer todos los estudiantes fueron entregados en la puerta principal del colegio sin incidentes.',
      messageEn: 'Yesterday all students were safely dropped off at the main school gate without incidents.',
      timestamp: 'Ayer, 07:52 AM',
      timestampEn: 'Yesterday, 07:52 AM',
      type: 'ARRIVED',
    ),
    SafetyAlert(
      id: 'alt-04',
      title: 'Aviso de Tránsito Matutino',
      titleEn: 'Morning Traffic Notice',
      message: 'Congestión moderada reportada en Av. Javier Prado. Tiempo estimado de retraso: +5 minutos.',
      messageEn: 'Moderate traffic reported on Av. Javier Prado. Estimated delay: +5 minutes.',
      timestamp: 'Ayer, 07:15 AM',
      timestampEn: 'Yesterday, 07:15 AM',
      type: 'TRAFFIC',
    ),
  ];

  static final ValueNotifier<List<SafetyAlert>> sharedAlertsNotifier =
      ValueNotifier<List<SafetyAlert>>(List.from(_initialAlerts));

  static void addAlert({
    required String title,
    required String message,
    required String type,
    String? titleEn,
    String? messageEn,
  }) {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final newAlert = SafetyAlert(
      id: 'alt-${now.millisecondsSinceEpoch}',
      title: title,
      titleEn: titleEn,
      message: message,
      messageEn: messageEn,
      timestamp: 'Hoy, $hour:$minute',
      timestampEn: 'Today, $hour:$minute',
      type: type,
    );
    sharedAlertsNotifier.value = [newAlert, ...sharedAlertsNotifier.value];
  }

  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    return SafetyAlert(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? (AppStrings.isSpanish ? 'Aviso escolar' : 'School notice'),
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? (AppStrings.isSpanish ? 'Hoy 07:25 AM' : 'Today 07:25 AM'),
      type: json['type'] ?? 'INFO',
    );
  }
}
