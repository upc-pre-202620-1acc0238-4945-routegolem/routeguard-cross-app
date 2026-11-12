import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/localization/app_strings.dart';
import 'package:routeguard_cross_app/features/driver/presentation/driver_trip_screen.dart';

void main() {
  group('DriverTripScreen Widget Tests', () {
    setUp(() {
      AppStrings.setLanguage(AppLanguage.spanish);
    });

    testWidgets('DriverTripScreen renders route header and passenger list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DriverTripScreen(),
        ),
      );

      // Verify route header
      expect(find.text('Ruta 02 - Turno Mañana'), findsAtLeastNWidgets(1));
      expect(find.text('Colegio San Juan • Van Escolar ABC-789'), findsOneWidget);
      expect(find.text('EN CURSO'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Reportar Incidencia'), findsOneWidget);
      expect(find.text('Finalizar Recorrido'), findsOneWidget);

      // Verify passenger names from initial roster
      expect(find.text('Mateo Gómez'), findsOneWidget);
      expect(find.text('Luciana Nery'), findsOneWidget);
    });

    testWidgets('tapping Subió updates boarding status', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DriverTripScreen(),
        ),
      );

      // Tap on the first 'Subió' button
      final boardedButtons = find.widgetWithText(ElevatedButton, 'Subió');
      expect(boardedButtons, findsWidgets);

      await tester.tap(boardedButtons.first);
      await tester.pumpAndSettle();

      // Verify snackbar feedback
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
