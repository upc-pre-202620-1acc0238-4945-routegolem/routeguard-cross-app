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
      'app_subtitle': 'Movilidad escolar segura',
      // Nav destinations
      'nav_people': 'Personas',
      'nav_routes': 'Rutas',
      'nav_live': 'En vivo',
      'nav_plans': 'Planes',
      'nav_tracking': 'Seguimiento',
      'nav_alerts': 'Alertas',
      'nav_profile': 'Perfil',
      'nav_driver': 'Recorrido',
      // Profile
      'profile_title': 'Mi Perfil',
      'profile_role_admin': 'Administrador de Transporte',
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
      'profile_guide_action': 'Ver Guía Interactiva',
      'profile_guide_desc': 'Repasa las funciones de la app con nuestro asistente.',
      // Subscriptions
      'subscription_card_title': 'Planes y Suscripción',
      'subscription_card_subtitle': 'Plan Familiar Activo • S/ 89/mes',
      'language_card_title': 'Idioma del sistema',
      'language_spanish': 'Español',
      'language_english': 'English',
      // Role Switcher
      'driver_mode_toggle': 'Modo de Operación / Rol',
      'driver_mode_parent': 'Vista: Padre de Familia',
      'driver_mode_driver': 'Vista: Conductor',
      'driver_mode_admin': 'Vista: Administrador',
      // Driver Trip
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
      // Alerts
      'alerts_title': 'Centro de Notificaciones',
      'alerts_mark_all_read': 'Marcar todo leído',
      // Tracking
      'tracking_status_active': 'Monitoreo en tiempo real activo',
      'tracking_van_plate': 'Placa: ABC-789 (Mercedes Sprinter)',
      'tracking_driver_name': 'Conductor: Carlos Ramírez',
      'tracking_eta': 'Tiempo estimado de llegada',
      // Stakeholders (Admin)
      'stakeholders_title': 'Conductores, Padres y Grupos',
      'tab_drivers': 'Conductores',
      'tab_parents': 'Padres',
      'tab_groups': 'Grupos',
      'btn_register_driver': 'Registrar conductor',
      'btn_register_parent': 'Registrar padre',
      'btn_register_child': 'Registrar estudiante',
      'btn_create_group': 'Crear grupo',
      'driver_reg_title': 'Registrar Conductor',
      'driver_reg_firstname': 'Nombres',
      'driver_reg_lastname': 'Apellidos',
      'driver_reg_phone': 'Teléfono',
      'driver_reg_license': 'N.º de Licencia',
      'driver_reg_email': 'Correo electrónico',
      'parent_reg_title': 'Registrar Padre / Apoderado',
      'child_reg_title': 'Registrar Estudiante',
      'group_create_title': 'Crear Grupo Escolar',
      // Routes (Admin)
      'routes_title': 'Planificador de Rutas',
      'btn_define_route': 'Definir ruta',
      'route_define_heading': 'Definir Nueva Ruta Escolar',
      'route_name_hint': 'Nombre de la nueva ruta',
      'route_detail_title': 'Detalle de Ruta',
      'route_not_found': 'Ruta no encontrada',
      'route_stops_heading': 'Paradas del Recorrido',
      'route_no_stops': 'No hay paradas definidas aún. Agrega la primera parada abajo.',
      'route_add_stop_title': 'Agregar Nueva Parada',
      'route_add_stop_instruction': 'Toca el mapa arriba para posicionar el marcador o escribe los datos:',
      'route_stop_name_label': 'Nombre de la parada (ej. Parada Av. Angamos)',
      'route_stop_address_label': 'Dirección o referencia',
      'route_stop_time_label': 'Hora programada (ej. 07:30 AM)',
      'route_btn_add_stop': 'Agregar Parada',
      'route_btn_activate': 'Activar Ruta para Operación',
      'route_activated_msg': '¡Ruta activada para inicio de operaciones!',
      'route_stop_added_msg': '¡Parada agregada con éxito!',
      'route_status_draft': 'Borrador',
      'route_status_active': 'Activa',
      'route_status_inactive': 'Inactiva',
      // Live Monitor (Admin)
      'monitor_title': 'Supervisión de Flota en Vivo',
      'monitor_no_trips': 'Sin viajes en curso',
      'monitor_no_trips_desc':
          'Cuando un conductor inicie su ruta, verás aquí su vehículo en el mapa.',
      // Assistant Tutorial
      'assistant_step_counter': 'Paso %d de %d',
      'assistant_btn_skip': 'Omitir',
      'assistant_btn_back': 'Atrás',
      'assistant_btn_next': 'Siguiente',
      'assistant_btn_finish': '¡Entendido!',
      // Admin Assistant
      'assistant_title_admin_welcome': '¡Bienvenido a RouteGuard!',
      'assistant_msg_admin_welcome':
          'Soy tu asistente RouteGuard. Te guiaré brevemente por las funciones principales de tu panel administrativo.',
      'assistant_title_admin_people': 'Gestión de Personas',
      'assistant_msg_admin_people':
          'Aquí puedes registrar y administrar transportistas, padres de familia y asociar estudiantes a sus movilidades.',
      'assistant_title_admin_routes': 'Planificador de Rutas',
      'assistant_msg_admin_routes':
          'Traza recorridos óptimos, asigna paradas escolares y visualiza las rutas activas de tu flota.',
      'assistant_title_admin_live': 'Monitoreo en Vivo',
      'assistant_msg_admin_live':
          'Sigue la ubicación de los vehículos escolares en tiempo real con alertas y telemetría de ruta.',
      'assistant_title_admin_plans': 'Suscripciones y Pagos',
      'assistant_msg_admin_plans':
          'Administra los planes contratados para tus colegios con pasarela segura Stripe y renueva tu membresía.',
      'assistant_title_admin_profile': 'Mi Perfil y Ajustes',
      'assistant_msg_admin_profile':
          'Aquí puedes consultar tus datos de usuario, volver a iniciar esta guía cuando desees y cerrar tu sesión de forma segura.',
      // Driver Assistant
      'assistant_title_driver_welcome': '¡Hola, Conductor!',
      'assistant_msg_driver_welcome':
          'Te ayudaré a conocer tu herramienta de trabajo diario para viajes seguros.',
      'assistant_title_driver_trip': 'Tu Viaje en Curso',
      'assistant_msg_driver_trip':
          'Inicia tu recorrido, consulta la lista de estudiantes por recoger y confirma su abordaje con un solo toque.',
      'assistant_title_driver_alerts': 'Notificaciones y Alertas',
      'assistant_msg_driver_alerts':
          'Recibe avisos inmediatos ante incidentes viales, retrasos o comunicaciones del colegio.',
      'assistant_title_driver_profile': 'Mi Perfil y Cuenta',
      'assistant_msg_driver_profile':
          'Consulta tus credenciales de conductor, accede a la guía de ayuda y gestiona el cierre seguro de tu sesión.',
      // Parent Assistant
      'assistant_title_parent_welcome': '¡Bienvenido, Padre de Familia!',
      'assistant_msg_parent_welcome':
          'RouteGuard te brinda tranquilidad en el traslado escolar de tus hijos.',
      'assistant_title_parent_tracking': 'Seguimiento en Tiempo Real',
      'assistant_msg_parent_tracking':
          'Observa en el mapa la ubicación exacta del transporte escolar y conoce el tiempo estimado de llegada.',
      'assistant_title_parent_alerts': 'Avisos y Llegadas',
      'assistant_msg_parent_alerts':
          'Recibe notificaciones automáticas cuando tu hijo aborde el vehículo y cuando llegue seguro a su destino.',
      'assistant_title_parent_profile': 'Mi Perfil Familiar',
      'assistant_msg_parent_profile':
          'Revisa tu cuenta de apoderado, vuelve a activar la guía de usuario y cierra sesión cuando lo requieras.',
    },
    AppLanguage.english: {
      'app_title': 'RouteGuard',
      'app_subtitle': 'Safe School Mobility',
      // Nav destinations
      'nav_people': 'People',
      'nav_routes': 'Routes',
      'nav_live': 'Live Fleet',
      'nav_plans': 'Plans',
      'nav_tracking': 'Live Tracking',
      'nav_alerts': 'Alerts',
      'nav_profile': 'Profile',
      'nav_driver': 'Trip Check',
      // Profile
      'profile_title': 'My Profile',
      'profile_role_admin': 'Transport Administrator',
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
      'profile_guide_action': 'View Interactive Guide',
      'profile_guide_desc': 'Review app features with our guide mascot.',
      // Subscriptions
      'subscription_card_title': 'Plans & Subscription',
      'subscription_card_subtitle': 'Family Plan Active • S/ 89/mo',
      'language_card_title': 'System Language',
      'language_spanish': 'Español',
      'language_english': 'English',
      // Role Switcher
      'driver_mode_toggle': 'Operating Mode / Role',
      'driver_mode_parent': 'View: Parent Mode',
      'driver_mode_driver': 'View: Driver Mode',
      'driver_mode_admin': 'View: Administrator Mode',
      // Driver Trip
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
      // Alerts
      'alerts_title': 'Notification Center',
      'alerts_mark_all_read': 'Mark all as read',
      // Tracking
      'tracking_status_active': 'Real-time GPS tracking active',
      'tracking_van_plate': 'Plate: ABC-789 (Mercedes Sprinter)',
      'tracking_driver_name': 'Driver: Carlos Ramírez',
      'tracking_eta': 'Estimated time of arrival',
      // Stakeholders (Admin)
      'stakeholders_title': 'Drivers, Parents & Groups',
      'tab_drivers': 'Drivers',
      'tab_parents': 'Parents',
      'tab_groups': 'Groups',
      'btn_register_driver': 'Register driver',
      'btn_register_parent': 'Register parent',
      'btn_register_child': 'Register student',
      'btn_create_group': 'Create group',
      'driver_reg_title': 'Register Driver',
      'driver_reg_firstname': 'First Name',
      'driver_reg_lastname': 'Last Name',
      'driver_reg_phone': 'Phone',
      'driver_reg_license': 'Driver License Number',
      'driver_reg_email': 'Email Address',
      'parent_reg_title': 'Register Parent / Guardian',
      'child_reg_title': 'Register Student',
      'group_create_title': 'Create Student Group',
      // Routes (Admin)
      'routes_title': 'Route Planner',
      'btn_define_route': 'Define route',
      'route_define_heading': 'Define New School Route',
      'route_name_hint': 'New route name',
      'route_detail_title': 'Route Details',
      'route_not_found': 'Route not found',
      'route_stops_heading': 'Route Stops',
      'route_no_stops': 'No stops defined yet. Add the first stop below.',
      'route_add_stop_title': 'Add New Stop',
      'route_add_stop_instruction': 'Tap the map above to place marker or enter details:',
      'route_stop_name_label': 'Stop name (e.g. Angamos Ave Stop)',
      'route_stop_address_label': 'Address or reference',
      'route_stop_time_label': 'Scheduled time (e.g. 07:30 AM)',
      'route_btn_add_stop': 'Add Stop',
      'route_btn_activate': 'Activate Route for Operation',
      'route_activated_msg': 'Route activated for operations!',
      'route_stop_added_msg': 'Stop added successfully!',
      'route_status_draft': 'Draft',
      'route_status_active': 'Active',
      'route_status_inactive': 'Inactive',
      // Live Monitor (Admin)
      'monitor_title': 'Live Fleet Monitoring',
      'monitor_no_trips': 'No active trips',
      'monitor_no_trips_desc':
          'When a driver starts a route, you will see their vehicle here on the map.',
      // Assistant Tutorial
      'assistant_step_counter': 'Step %d of %d',
      'assistant_btn_skip': 'Skip',
      'assistant_btn_back': 'Back',
      'assistant_btn_next': 'Next',
      'assistant_btn_finish': 'Got it!',
      // Admin Assistant
      'assistant_title_admin_welcome': 'Welcome to RouteGuard!',
      'assistant_msg_admin_welcome':
          'I am your RouteGuard assistant. I will briefly guide you through the main features of your administrative dashboard.',
      'assistant_title_admin_people': 'Stakeholder Management',
      'assistant_msg_admin_people':
          'Here you can register and manage drivers, parents, and assign students to school vehicles.',
      'assistant_title_admin_routes': 'Route Planner',
      'assistant_msg_admin_routes':
          'Map optimal trips, assign school stops, and visualize active routes across your fleet.',
      'assistant_title_admin_live': 'Live Monitoring',
      'assistant_msg_admin_live':
          'Track school vehicle locations in real time with alerts and route telemetry.',
      'assistant_title_admin_plans': 'Subscriptions & Billing',
      'assistant_msg_admin_plans':
          'Manage contracted plans for your schools with secure Stripe checkout and renew membership.',
      'assistant_title_admin_profile': 'My Profile & Settings',
      'assistant_msg_admin_profile':
          'Here you can view your user account details, restart this guide anytime, and safely sign out.',
      // Driver Assistant
      'assistant_title_driver_welcome': 'Hello, Driver!',
      'assistant_msg_driver_welcome':
          'I will help you explore your daily work tool for safe journeys.',
      'assistant_title_driver_trip': 'Your Ongoing Trip',
      'assistant_msg_driver_trip':
          'Start your route, consult the student boarding roster, and confirm pickup with a single tap.',
      'assistant_title_driver_alerts': 'Notifications & Alerts',
      'assistant_msg_driver_alerts':
          'Receive instant updates on traffic incidents, delays, or school announcements.',
      'assistant_title_driver_profile': 'My Driver Profile',
      'assistant_msg_driver_profile':
          'Check your driver credentials, access the helper guide, and securely sign out.',
      // Parent Assistant
      'assistant_title_parent_welcome': 'Welcome, Parent!',
      'assistant_msg_parent_welcome':
          'RouteGuard provides peace of mind during your children’s school transport.',
      'assistant_title_parent_tracking': 'Real-Time Tracking',
      'assistant_msg_parent_tracking':
          'See the school transport exact location on the map and check the estimated arrival time.',
      'assistant_title_parent_alerts': 'Arrivals & Alerts',
      'assistant_msg_parent_alerts':
          'Receive automatic notifications when your child boards the vehicle and safely reaches school.',
      'assistant_title_parent_profile': 'Family Profile',
      'assistant_msg_parent_profile':
          'Review your guardian account, reactivate user guide, and sign out when needed.',
    },
  };

  static String tr(String key) {
    final lang = currentLanguage.value;
    return _localizedValues[lang]?[key] ?? _localizedValues[AppLanguage.spanish]?[key] ?? key;
  }
}
