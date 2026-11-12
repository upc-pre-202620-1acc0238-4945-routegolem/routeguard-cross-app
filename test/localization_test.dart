import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/localization/app_strings.dart';

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
  });
}
