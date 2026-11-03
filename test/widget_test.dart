import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/utils/session_manager.dart';
import 'package:routeguard_cross_app/features/auth/presentation/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('LoginScreen renders brand elements and inputs', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sessionManager = SessionManager(prefs);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          sessionManager: sessionManager,
          onAuthenticated: () {},
        ),
      ),
    );

    // Verify brand title
    expect(find.text('RouteGuard'), findsOneWidget);
    expect(find.text('Portal Multiplataforma para Apoderados'), findsOneWidget);

    // Verify inputs & button
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });
}
