import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/localization/app_strings.dart';
import 'package:routeguard_cross_app/features/monitor/presentation/live_monitor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LiveMonitorScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AppStrings.setLanguage(AppLanguage.spanish);
    });

    testWidgets('renders LiveMonitorScreen with active trips list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveMonitorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Supervisión de Flota en Vivo'), findsOneWidget);

      // Verify Active Routes
      expect(find.text('Ruta 01 - Primaria San Borja'), findsOneWidget);
      expect(find.text('Ruta 02 - Turno Mañana Miraflores'), findsOneWidget);

      // Verify Fleet telemetries
      expect(find.textContaining('Carlos Ramírez'), findsOneWidget);
      expect(find.textContaining('estudiantes a bordo'), findsWidgets);
    });
  });
}
