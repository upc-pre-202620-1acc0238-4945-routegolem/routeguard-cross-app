import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/localization/app_strings.dart';
import 'package:routeguard_cross_app/features/fleet/presentation/routes_screen.dart';

void main() {
  group('RoutesScreen Widget Tests', () {
    setUp(() {
      AppStrings.setLanguage(AppLanguage.spanish);
    });

    testWidgets('renders RoutesScreen with title, input, and existing routes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RoutesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Planificador de Rutas'), findsOneWidget);

      // Verify Define Route input & button
      expect(find.text('Definir Nueva Ruta Escolar'), findsOneWidget);
      expect(find.text('Definir ruta'), findsOneWidget);

      // Verify Existing Routes
      expect(find.text('Ruta 01 - Primaria San Borja'), findsOneWidget);
      expect(find.text('Ruta 02 - Turno Mañana Miraflores'), findsOneWidget);
    });

    testWidgets('creating a new route adds it to the list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RoutesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter new route name
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'Ruta 05 - Turno Especial');

      // Tap Definir ruta button
      final btnFinder = find.widgetWithText(ElevatedButton, 'Definir ruta');
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      // Route detail screen or list should show new route name
      expect(find.text('Ruta 05 - Turno Especial'), findsWidgets);
    });
  });
}
