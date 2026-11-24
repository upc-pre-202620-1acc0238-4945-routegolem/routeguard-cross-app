import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/localization/app_strings.dart';
import 'package:routeguard_cross_app/features/stakeholders/presentation/stakeholders_screen.dart';

void main() {
  group('StakeholdersScreen Widget Tests', () {
    setUp(() {
      AppStrings.setLanguage(AppLanguage.spanish);
    });

    testWidgets('renders StakeholdersScreen with title and tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StakeholdersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Conductores, Padres y Grupos'), findsOneWidget);

      // Verify Choice Chips
      expect(find.text('Conductores'), findsOneWidget);
      expect(find.text('Padres'), findsOneWidget);
      expect(find.text('Grupos'), findsOneWidget);

      // Verify Conductores tab default view
      expect(find.text('Registrar conductor'), findsOneWidget);
      expect(find.text('Carlos Ramírez'), findsOneWidget);
    });

    testWidgets('tapping Padres tab switches view and displays parents & children',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StakeholdersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Padres chip
      await tester.tap(find.text('Padres'));
      await tester.pumpAndSettle();

      // Verify Padres action buttons & content
      expect(find.text('Registrar padre'), findsOneWidget);
      expect(find.text('Registrar estudiante'), findsOneWidget);
      expect(find.text('Laura Gómez'), findsOneWidget);
      expect(find.textContaining('Mateo Gómez'), findsOneWidget);
    });

    testWidgets('tapping Grupos tab switches view and displays groups',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StakeholdersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Grupos chip
      await tester.tap(find.text('Grupos'));
      await tester.pumpAndSettle();

      // Verify Grupos action buttons & content
      expect(find.text('Crear grupo'), findsOneWidget);
      expect(find.text('Grupo Primaria Sur'), findsOneWidget);
    });
  });
}
