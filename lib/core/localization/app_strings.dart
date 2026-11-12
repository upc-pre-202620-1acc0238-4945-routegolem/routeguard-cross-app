import 'package:flutter/foundation.dart';

enum AppLanguage { spanish, english }

class AppStrings {
  static final ValueNotifier<AppLanguage> currentLanguage =
      ValueNotifier<AppLanguage>(AppLanguage.spanish);

  static bool get isSpanish => currentLanguage.value == AppLanguage.spanish;

  static void setLanguage(AppLanguage language) {
    currentLanguage.value = language;
  }

  static void toggleLanguage() {
    currentLanguage.value = isSpanish ? AppLanguage.english : AppLanguage.spanish;
  }

  // Key-value dictionary
  static final Map<AppLanguage, Map<String, String>> _localizedValues = {
    AppLanguage.spanish: {
      'app_title': 'RouteGuard',
      'nav_tracking': 'Seguimiento',
      'nav_alerts': 'Alertas',
      'nav_profile': 'Perfil',
      'nav_driver': 'Recorrido',
      'profile_title': 'Mi Perfil',
      'profile_role_parent': 'Padre de Familia / Apoderado',
      'profile_role_driver': 'Conductor de Movilidad Escolar',
      'profile_email': 'Correo electrónico',
      'profile_institution': 'Institución',
      'profile_student': 'Estudiante vinculado',
      'profile_app_version': 'Versión de la aplicación',
      'profile_sign_out': 'Cerrar sesión',
      'profile_sign_out_confirm_title': '¿Cerrar sesión?',
      'profile_sign_out_confirm_msg':
          '¿Estás seguro de que deseas salir de tu cuenta en RouteGuard?',
      'profile_cancel': 'Cancelar',
      'subscription_card_title': 'Planes y Suscripción',
      'subscription_card_subtitle': 'Plan Familiar Activo • S/ 89/mes',
      'language_card_title': 'Idioma del sistema',
      'language_spanish': 'Español',
      'language_english': 'English',
      'driver_mode_toggle': 'Modo de Operación',
      'driver_mode_parent': 'Vista: Padre de Familia',
      'driver_mode_driver': 'Vista: Conductor',
      'driver_route_title': 'Ruta 02 - Turno Mañana',
      'driver_route_subtitle': 'Colegio San Juan • Van Escolar ABC-789',
      'driver_checklist_title': 'Control de Abordaje y Asistencia',
      'driver_status_pending': 'Pendiente',
      'driver_status_boarded': 'Subió',
      'driver_status_absent': 'No asistió',
      'driver_btn_incident': 'Reportar Incidencia',
      'driver_btn_finish': 'Finalizar Recorrido',
      'driver_finish_dialog_title': '¿Finalizar recorrido?',
      'driver_finish_dialog_msg':
          'Se notificará a todos los padres de familia que los estudiantes llegaron seguros al colegio.',
      'driver_finish_confirm': 'Sí, finalizar',
      'alerts_title': 'Centro de Notificaciones',
      'alerts_mark_all_read': 'Marcar todo leído',
      'tracking_status_active': 'Monitoreo en tiempo real activo',
      'tracking_van_plate': 'Placa: ABC-789 (Mercedes Sprinter)',
      'tracking_driver_name': 'Conductor: Carlos Ramírez',
      'tracking_eta': 'Tiempo estimado de llegada',
    },
    AppLanguage.english: {
      'app_title': 'RouteGuard',
      'nav_tracking': 'Live Tracking',
      'nav_alerts': 'Alerts',
      'nav_profile': 'Profile',
      'nav_driver': 'Trip Check',
      'profile_title': 'My Profile',
      'profile_role_parent': 'Parent / Legal Guardian',
      'profile_role_driver': 'School Van Driver',
      'profile_email': 'Email address',
      'profile_institution': 'Institution',
      'profile_student': 'Linked Student',
      'profile_app_version': 'Application Version',
      'profile_sign_out': 'Sign Out',
      'profile_sign_out_confirm_title': 'Sign Out?',
      'profile_sign_out_confirm_msg':
          'Are you sure you want to sign out of your RouteGuard account?',
      'profile_cancel': 'Cancel',
      'subscription_card_title': 'Plans & Subscription',
      'subscription_card_subtitle': 'Family Plan Active • S/ 89/mo',
      'language_card_title': 'System Language',
      'language_spanish': 'Español',
      'language_english': 'English',
      'driver_mode_toggle': 'Operating Mode',
      'driver_mode_parent': 'View: Parent Mode',
      'driver_mode_driver': 'View: Driver Mode',
      'driver_route_title': 'Route 02 - Morning Shift',
      'driver_route_subtitle': 'San Juan School • School Van ABC-789',
      'driver_checklist_title': 'Boarding & Attendance Checklist',
      'driver_status_pending': 'Pending',
      'driver_status_boarded': 'Boarded',
      'driver_status_absent': 'Absent',
      'driver_btn_incident': 'Report Incident',
      'driver_btn_finish': 'Finish Route',
      'driver_finish_dialog_title': 'Finish route?',
      'driver_finish_dialog_msg':
          'All parents will be notified that students arrived safely at school.',
      'driver_finish_confirm': 'Yes, finish',
      'alerts_title': 'Notification Center',
      'alerts_mark_all_read': 'Mark all as read',
      'tracking_status_active': 'Real-time GPS tracking active',
      'tracking_van_plate': 'Plate: ABC-789 (Mercedes Sprinter)',
      'tracking_driver_name': 'Driver: Carlos Ramírez',
      'tracking_eta': 'Estimated time of arrival',
    },
  };

  static String tr(String key) {
    final lang = currentLanguage.value;
    return _localizedValues[lang]?[key] ?? _localizedValues[AppLanguage.spanish]?[key] ?? key;
  }
}
