import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/localization/app_strings.dart';
import 'package:routeguard_cross_app/core/utils/session_manager.dart';
import 'package:routeguard_cross_app/features/alerts/presentation/notifications_screen.dart';
import 'package:routeguard_cross_app/features/auth/presentation/login_screen.dart';
import 'package:routeguard_cross_app/features/subscription/presentation/subscription_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Bilingual Localization (i18n) Tests', () {
    setUp(() {
      AppStrings.setLanguage(AppLanguage.spanish);
    });

    test('default language is Spanish', () {
      expect(AppStrings.currentLanguage.value, AppLanguage.spanish);
      expect(AppStrings.isSpanish, isTrue);
      expect(AppStrings.tr('profile_title'), 'Mi Perfil');
      expect(AppStrings.tr('nav_tracking'), 'Seguimiento');
      expect(AppStrings.tr('driver_status_boarded'), 'Subió');
    });

    test('toggling language switches dynamically to English', () {
      AppStrings.toggleLanguage();

      expect(AppStrings.currentLanguage.value, AppLanguage.english);
      expect(AppStrings.isSpanish, isFalse);
      expect(AppStrings.tr('profile_title'), 'My Profile');
      expect(AppStrings.tr('nav_tracking'), 'Live Tracking');
      expect(AppStrings.tr('driver_status_boarded'), 'Boarded');
    });

    test('switching back to Spanish restores native translations', () {
      AppStrings.setLanguage(AppLanguage.english);
      expect(AppStrings.tr('profile_sign_out'), 'Sign Out');

      AppStrings.setLanguage(AppLanguage.spanish);
      expect(AppStrings.tr('profile_sign_out'), 'Cerrar sesión');
    });

    test('unknown key falls back gracefully', () {
      expect(AppStrings.tr('unknown_key_xyz'), 'unknown_key_xyz');
    });

    test('Spanish and English dictionaries have 100% key parity', () {
      final esKeys = AppStrings.keysFor(AppLanguage.spanish);
      final enKeys = AppStrings.keysFor(AppLanguage.english);

      expect(esKeys, isNotEmpty);
      expect(esKeys.difference(enKeys), isEmpty, reason: 'Keys missing in English');
      expect(enKeys.difference(esKeys), isEmpty, reason: 'Keys missing in Spanish');
    });

    testWidgets('LoginScreen, NotificationsScreen, and SubscriptionScreen render in English',
        (WidgetTester tester) async {
      AppStrings.setLanguage(AppLanguage.english);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final sessionManager = SessionManager(prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(sessionManager: sessionManager, onAuthenticated: () {}),
        ),
      );
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot your password?'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
      expect(find.text('Notification Center'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SubscriptionScreen()));
      expect(find.text('Subscription Plans'), findsOneWidget);
      expect(find.text('Available Plans'), findsOneWidget);
    });
  });
}
