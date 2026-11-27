import 'package:flutter/foundation.dart';
import '../../../core/localization/app_strings.dart';

class SafetyAlert {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final String type; // 'PANIC_ALERT', 'PANIC', 'STUDENT_BOARDED', 'BOARDING', 'GEOFENCE_BREACHED', 'ARRIVED', 'INCIDENT_REPORTED', 'TRAFFIC', 'TRIP_STARTED', 'ANNOUNCEMENT', 'INFO'
  final String status; // 'PENDING', 'DISPATCHED', 'DELIVERED'
  final bool hasPanicAlert;
  final String? tripId;
  final DateTime? sentAtDate;
  final String? titleEn;
  final String? messageEn;
  final String? timestampEn;

  SafetyAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.status = 'DELIVERED',
    this.hasPanicAlert = false,
    this.tripId,
    this.sentAtDate,
    this.titleEn,
    this.messageEn,
    this.timestampEn,
  });

  bool get isPanic =>
      hasPanicAlert ||
      type.toUpperCase() == 'PANIC' ||
      type.toUpperCase() == 'PANIC_ALERT';

  bool get isDelivered => status.toUpperCase() == 'DELIVERED';

  bool get isHighPriority =>
      isPanic ||
      type.toUpperCase() == 'INCIDENT_REPORTED' ||
      type.toUpperCase() == 'TRAFFIC';

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

  static List<SafetyAlert> get fallbackAlerts => List<SafetyAlert>.from(_initialAlerts);

  static final ValueNotifier<List<SafetyAlert>> sharedAlertsNotifier =
      ValueNotifier<List<SafetyAlert>>(List.from(_initialAlerts));

  static void setAlerts(List<SafetyAlert> alerts) {
    sharedAlertsNotifier.value = List<SafetyAlert>.from(alerts);
  }

  static void resetDefaults() {
    sharedAlertsNotifier.value = List<SafetyAlert>.from(_initialAlerts);
  }

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
      sentAtDate: now,
    );
    sharedAlertsNotifier.value = [newAlert, ...sharedAlertsNotifier.value];
  }

  static (String, String) titlesForCategory(String category, String message) {
    final normalized = category.trim().toUpperCase();
    final lowerMsg = message.toLowerCase();
    if (normalized == 'GEOFENCE_BREACHED' &&
        (lowerMsg.contains('llegada al colegio') || lowerMsg.contains('school arrival'))) {
      return ('Llegada al colegio', 'Arrived at school');
    }
    switch (normalized) {
      case 'PANIC_ALERT':
      case 'PANIC':
        return ('¡Alerta de pánico!', 'Panic alert!');
      case 'TRIP_STARTED':
        return ('Viaje iniciado', 'Trip started');
      case 'GEOFENCE_BREACHED':
        return ('El vehículo está cerca', 'Vehicle approaching');
      case 'ARRIVED':
        return ('Llegada al colegio', 'Arrived at school');
      case 'STUDENT_BOARDED':
      case 'BOARDING':
        return ('Estudiante a bordo', 'Student boarded');
      case 'INCIDENT_REPORTED':
      case 'TRAFFIC':
        return ('Incidencia en el viaje', 'Route incident');
      case 'ANNOUNCEMENT':
        return ('Aviso del conductor', 'Driver announcement');
      default:
        return ('Notificación', 'Notification');
    }
  }

  static (String, String) formatSentAt(DateTime? parsed) {
    if (parsed == null) return ('Hoy', 'Today');
    final local = parsed.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes >= 0 && diff.inMinutes < 1) {
      return ('Ahora', 'Now');
    }
    if (diff.inMinutes >= 1 && diff.inMinutes < 60) {
      return ('Hace ${diff.inMinutes} min', '${diff.inMinutes}m ago');
    }
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    if (sameDay) {
      return ('Hoy, $hh:$mm', 'Today, $hh:$mm');
    }
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final formatted = '$dd/$mo/${local.year} · $hh:$mm';
    return (formatted, formatted);
  }

  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? json['type'] ?? 'GENERAL').toString().toUpperCase();
    final message = (json['message'] ?? json['body'] ?? '').toString();
    final (defaultEsTitle, defaultEnTitle) = titlesForCategory(category, message);
    final rawSentAt = (json['sentAt'] ?? json['createdAt'] ?? json['timestamp'])?.toString();
    final parsedDate = rawSentAt != null ? DateTime.tryParse(rawSentAt) : null;
    final (tsEs, tsEn) = parsedDate != null
        ? formatSentAt(parsedDate)
        : (rawSentAt ?? 'Hoy', rawSentAt ?? 'Today');

    final alertsList = json['alerts'];
    final hasPanic = json['hasPanicAlert'] == true ||
        (alertsList is List && alertsList.any((a) => a is Map && a['panic'] == true));

    return SafetyAlert(
      id: (json['id'] ?? json['notificationId'] ?? '').toString(),
      tripId: json['tripId']?.toString(),
      title: json['title']?.toString() ?? defaultEsTitle,
      titleEn: json['titleEn']?.toString() ?? defaultEnTitle,
      message: message,
      timestamp: tsEs,
      timestampEn: tsEn,
      type: category,
      status: (json['deliveryState'] ?? json['status'] ?? 'DELIVERED').toString().toUpperCase(),
      hasPanicAlert: hasPanic,
      sentAtDate: parsedDate,
    );
  }
}
