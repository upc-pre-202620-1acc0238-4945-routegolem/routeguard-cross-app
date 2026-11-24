import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/localization/app_strings.dart';
import 'package:routeguard_cross_app/core/utils/session_manager.dart';
import 'package:routeguard_cross_app/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MainShell Multi-Role Widget Tests', () {
    setUp(() {
      AppStrings.setLanguage(AppLanguage.spanish);
    });

    testWidgets('MainShell under ADMINISTRATOR role renders 5 tabs',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'role': 'ADMINISTRATOR',
        'auth_token': 'mock-admin-token',
        'full_name': 'Carlos Mendoza (Admin)',
      });
      final prefs = await SharedPreferences.getInstance();
      final sessionManager = SessionManager(prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            sessionManager: sessionManager,
            onSignedOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the 5 navigation destinations exist
      expect(find.text('Personas'), findsWidgets);
      expect(find.text('Rutas'), findsWidgets);
      expect(find.text('En vivo'), findsWidgets);
      expect(find.text('Planes'), findsWidgets);
      expect(find.text('Perfil'), findsWidgets);
    });

    testWidgets('MainShell under DRIVER role renders 3 tabs',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'role': 'DRIVER',
        'auth_token': 'mock-driver-token',
        'full_name': 'Carlos Ramírez (Conductor)',
      });
      final prefs = await SharedPreferences.getInstance();
      final sessionManager = SessionManager(prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            sessionManager: sessionManager,
            onSignedOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Driver's 3 tabs
      expect(find.text('Recorrido'), findsWidgets);
      expect(find.text('Alertas'), findsWidgets);
      expect(find.text('Perfil'), findsWidgets);

      // Verify Admin-only tabs are NOT visible
      expect(find.text('Personas'), findsNothing);
      expect(find.text('Planes'), findsNothing);
    });

    testWidgets('MainShell under PARENT role renders 3 tabs',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'role': 'PARENT',
        'auth_token': 'mock-parent-token',
        'full_name': 'Laura Gómez (Apoderada)',
      });
      final prefs = await SharedPreferences.getInstance();
      final sessionManager = SessionManager(prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            sessionManager: sessionManager,
            onSignedOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Parent's 3 tabs
      expect(find.text('Seguimiento'), findsWidgets);
      expect(find.text('Alertas'), findsWidgets);
      expect(find.text('Perfil'), findsWidgets);

      // Verify Driver & Admin specific tabs are NOT visible
      expect(find.text('Recorrido'), findsNothing);
      expect(find.text('Personas'), findsNothing);
    });

    testWidgets('switching tabs updates active screen',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'role': 'DRIVER',
        'auth_token': 'mock-driver-token',
      });
      final prefs = await SharedPreferences.getInstance();
      final sessionManager = SessionManager(prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            sessionManager: sessionManager,
            onSignedOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Alertas tab
      final alertsTab = find.text('Alertas');
      expect(alertsTab, findsWidgets);
      await tester.tap(alertsTab.first);
      await tester.pumpAndSettle();

      // Verify notifications screen is in the tree
      expect(find.text('Notificaciones y Avisos'), findsOneWidget);
    });
  });
}
