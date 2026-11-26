import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:routeguard_cross_app/core/database/local_database.dart';
import 'package:routeguard_cross_app/core/localization/app_strings.dart';
import 'package:routeguard_cross_app/core/utils/session_manager.dart';
import 'package:routeguard_cross_app/features/alerts/models/safety_alert.dart';
import 'package:routeguard_cross_app/features/auth/presentation/login_screen.dart';
import 'package:routeguard_cross_app/features/driver/presentation/driver_trip_screen.dart';
import 'package:routeguard_cross_app/features/monitor/data/monitor_repository.dart';
import 'package:routeguard_cross_app/features/monitor/presentation/live_monitor_screen.dart';
import 'package:routeguard_cross_app/features/profile/presentation/profile_screen.dart';
import 'package:routeguard_cross_app/features/stakeholders/data/stakeholder_repository.dart';
import 'package:routeguard_cross_app/features/stakeholders/presentation/stakeholders_screen.dart';
import 'package:routeguard_cross_app/features/tracking/data/tracking_repository.dart';
import 'package:routeguard_cross_app/features/tracking/presentation/live_tracking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('New User Stories (US-09 to US-29) Tests', () {
    setUp(() {
      LocalDatabase.instance.clearMemoryForTesting();
      AppStrings.setLanguage(AppLanguage.spanish);
    });

    testWidgets('US-19: Forgot Password prefills email, validates, and shows confirmation',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final sessionManager = SessionManager(prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(sessionManager: sessionManager, onAuthenticated: () {}),
        ),
      );

      // Type custom email on login screen
      await tester.enterText(find.byType(TextFormField).first, 'laura.gomez@colegio.pe');
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();

      // Dialog should be open and prefilled
      expect(find.text('Recuperar contraseña'), findsOneWidget);
      expect(find.text('laura.gomez@colegio.pe'), findsWidgets);

      // Clear email to test validation
      final dialogEmailField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(dialogEmailField, 'correo-invalido');
      await tester.tap(find.text('Enviar instrucciones'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);

      // Enter valid email and submit
      await tester.enterText(dialogEmailField, 'madre@routeguard.pe');
      await tester.tap(find.text('Enviar instrucciones'));
      await tester.pumpAndSettle();

      expect(
        find.text('Instrucciones de recuperación enviadas a madre@routeguard.pe.'),
        findsOneWidget,
      );
    });

    testWidgets('US-18 & US-23: ProfileScreen FAQ has 5 tiles and Support Ticket creates #RG-XXXX',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({'role': 'PARENT', 'auth_token': 'tok'});
      final prefs = await SharedPreferences.getInstance();
      final sessionManager = SessionManager(prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(sessionManager: sessionManager, onSignedOut: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Help & Support card
      await tester.scrollUntilVisible(find.text('Centro de Ayuda y Soporte'), 300);
      expect(find.text('Centro de Ayuda y Soporte'), findsOneWidget);

      // US-18: Open FAQ and verify 5 ExpansionTiles
      await tester.tap(find.text('Preguntas Frecuentes'));
      await tester.pumpAndSettle();
      expect(find.text('Preguntas Frecuentes (FAQ)'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNWidgets(5));

      await tester.tap(find.text('¿Cómo funciona el seguimiento GPS en vivo?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('transmite su ubicación y velocidad'), findsOneWidget);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      // US-23: Open Support Ticket and submit
      await tester.tap(find.text('Enviar Ticket de Soporte'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Ticket de Soporte'), findsOneWidget);
      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(dialogFields.at(0), 'Mapa sin actualizar');
      await tester.enterText(dialogFields.at(1), 'El marcador lleva 5 min fijo en Av. Brasil.');
      await tester.tap(find.text('Enviar Ticket'));
      await tester.pumpAndSettle();

      expect(find.textContaining('#RG-'), findsWidgets);
    });

    test('US-15: TrackingRepository fetches trips when connected and falls back offline', () async {
      final onlineRepo = TrackingRepository(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/trips/history') || request.url.path.endsWith('/trips')) {
            return http.Response(
              jsonEncode([
                {
                  'tripId': 'TRP-API-1',
                  'routeName': 'Ruta API 01',
                  'driverName': 'Conductor API',
                  'vehiclePlate': 'XYZ-111',
                  'dateEs': 'Hoy, 07:45 AM',
                  'dateEn': 'Today, 07:45 AM',
                  'boardedCount': 10,
                  'totalStudents': 10,
                  'status': 'COMPLETED',
                },
              ]),
              200,
            );
          }
          return http.Response('Not found', 404);
        }),
      );

      final apiHistory = await onlineRepo.getTripHistory('tok');
      expect(apiHistory.length, 1);
      expect(apiHistory.first.tripId, 'TRP-API-1');
      expect(apiHistory.first.routeName, 'Ruta API 01');

      LocalDatabase.instance.clearMemoryForTesting();
      final offlineRepo = TrackingRepository(
        client: MockClient((_) async => throw Exception('No network')),
      );
      final fallbackHistory = await offlineRepo.getTripHistory('tok');
      expect(fallbackHistory.length, greaterThanOrEqualTo(3));
      expect(fallbackHistory.any((t) => t.isCancelled), isTrue);
    });

    testWidgets('US-15, US-12, US-09, US-14: LiveTrackingScreen Parent flows work offline',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({'role': 'PARENT', 'auth_token': 'tok'});
      final prefs = await SharedPreferences.getInstance();
      final sessionManager = SessionManager(prefs);

      final mockRepo = TrackingRepository(
        client: MockClient((_) async => http.Response('offline', 503)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LiveTrackingScreen(
            sessionManager: sessionManager,
            repository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // US-12: SOAT & License chip + Verify Docs dialog
      expect(find.textContaining('SOAT Vigente 12/2026'), findsOneWidget);
      await tester.tap(find.text('Ver / Verificar Docs'));
      await tester.pumpAndSettle();
      expect(find.text('Documentación y Vigencia'), findsOneWidget);
      await tester.tap(find.text('Verificar vigencia'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Documentación verificada'), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      // US-15: Trip History modal
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();
      expect(find.text('Historial de Viajes'), findsOneWidget);
      expect(find.text('Ruta 02 - Turno Mañana'), findsOneWidget);
      expect(find.text('CANCELADO'), findsOneWidget);
      // Close bottom sheet by tapping outside (top area)
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // US-09: Report Early Absence
      final initialAlertsCount = SafetyAlert.sharedAlertsNotifier.value.length;
      await tester.tap(find.text('Reportar ausencia hoy'));
      await tester.pumpAndSettle();
      expect(find.text('Reportar Ausencia Temprana'), findsOneWidget);
      await tester.tap(find.text('Confirmar Ausencia'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ausencia activa hoy: Mateo Gómez'), findsOneWidget);
      expect(SafetyAlert.sharedAlertsNotifier.value.length, initialAlertsCount + 1);

      // US-14: Rate Service
      await tester.tap(find.text('Calificar servicio'));
      await tester.pumpAndSettle();
      expect(find.text('Calificar Servicio de Movilidad'), findsOneWidget);
      await tester.tap(find.byTooltip('4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar Calificación'));
      await tester.pumpAndSettle();

      expect(find.text('Calificado: ★ 4/5'), findsOneWidget);
    });

    testWidgets('US-12: StakeholdersScreen driver card shows SOAT & opens Verify Docs dialog',
        (WidgetTester tester) async {
      final mockStakeholderRepo = StakeholderRepository(
        client: MockClient((_) async => http.Response('offline', 503)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StakeholdersScreen(repository: mockStakeholderRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('SOAT Vigente 12/2026'), findsWidgets);
      await tester.tap(find.text('Ver / Verificar Docs').first);
      await tester.pumpAndSettle();

      expect(find.text('Documentación y Vigencia'), findsOneWidget);
      expect(find.textContaining('A-IIIa'), findsWidgets);
    });

    testWidgets('US-29, US-21, US-17: DriverTripScreen roadblock, force majeure cancel, and CSV attendance report',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final postedUrls = <String>[];
      final mockRepo = TrackingRepository(
        client: MockClient((request) async {
          postedUrls.add(request.url.path);
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
      );

      String? copiedClipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedClipboardText = (methodCall.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DriverTripScreen(repository: mockRepo),
        ),
      );
      await tester.pumpAndSettle();

      // US-17: Attendance Report & Copy CSV
      await tester.tap(find.text('Reporte de Asistencia'));
      await tester.pumpAndSettle();
      expect(find.text('Reporte de Asistencia'), findsWidgets);
      expect(find.text('20%'), findsOneWidget);
      await tester.tap(find.text('Copiar Reporte CSV'));
      await tester.pumpAndSettle();
      expect(copiedClipboardText, isNotNull);
      expect(copiedClipboardText, contains('Mateo Gómez'));
      expect(find.text('Reporte CSV copiado al portapapeles.'), findsOneWidget);

      // US-29: Report Roadblock with 30 min delay
      await tester.tap(find.text('Bloqueo de vía'));
      await tester.pumpAndSettle();
      expect(find.text('Reportar Incidencia en Ruta'), findsOneWidget);
      await tester.tap(find.text('30 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notificar a los Padres de Familia'));
      await tester.pumpAndSettle();

      expect(postedUrls.any((p) => p.contains('/incidents')), isTrue);
      expect(find.textContaining('Incidencia activa: Bloqueo de vía (+30 min)'), findsOneWidget);

      // US-21: Force Majeure Cancellation
      await tester.scrollUntilVisible(find.text('Cancelar por fuerza mayor'), 200);
      await tester.tap(find.text('Cancelar por fuerza mayor'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar Viaje (Fuerza Mayor)'), findsOneWidget);
      // Select mandatory reason
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Falla mecánica grave').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar Cancelación'));
      await tester.pumpAndSettle();

      expect(postedUrls.any((p) => p.contains('/cancel') || p.contains('/panic')), isTrue);
      // Scroll back up to header card to verify CANCELADO badge
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.text('CANCELADO'), findsOneWidget);

      // Boarding buttons must now be disabled
      final subioBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Subió').first);
      expect(subioBtn.onPressed, isNull);
    });

    testWidgets('US-17: LiveMonitorScreen opens Attendance Report dialog',
        (WidgetTester tester) async {
      final mockMonitorRepo = MonitorRepository(
        client: MockClient((_) async => http.Response('offline', 503)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LiveMonitorScreen(repository: mockMonitorRepo),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reporte de Asistencia').first);
      await tester.pumpAndSettle();

      expect(find.text('Copiar Reporte CSV'), findsOneWidget);
    });
  });
}
