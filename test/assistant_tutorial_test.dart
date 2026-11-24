import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/assistant/assistant_tutorial_provider.dart';

void main() {
  group('Assistant Tutorial Provider Tests', () {
    test('Administrator tutorial contains 6 bounded context steps', () {
      final steps = AssistantTutorialProvider.stepsFor('ADMINISTRATOR');
      expect(steps.length, 6);

      // Welcome
      expect(steps[0].titleKey, 'assistant_title_admin_welcome');
      expect(steps[0].targetTabIndex, isNull);

      // Personas
      expect(steps[1].titleKey, 'assistant_title_admin_people');
      expect(steps[1].targetTabIndex, 0);

      // Rutas
      expect(steps[2].titleKey, 'assistant_title_admin_routes');
      expect(steps[2].targetTabIndex, 1);

      // Flota en vivo
      expect(steps[3].titleKey, 'assistant_title_admin_live');
      expect(steps[3].targetTabIndex, 2);

      // Planes
      expect(steps[4].titleKey, 'assistant_title_admin_plans');
      expect(steps[4].targetTabIndex, 3);

      // Perfil
      expect(steps[5].titleKey, 'assistant_title_admin_profile');
      expect(steps[5].targetTabIndex, 4);
    });

    test('Driver tutorial contains 4 operational steps', () {
      final steps = AssistantTutorialProvider.stepsFor('DRIVER');
      expect(steps.length, 4);

      expect(steps[0].titleKey, 'assistant_title_driver_welcome');
      expect(steps[1].titleKey, 'assistant_title_driver_trip');
      expect(steps[1].targetTabIndex, 0);
      expect(steps[2].titleKey, 'assistant_title_driver_alerts');
      expect(steps[2].targetTabIndex, 1);
      expect(steps[3].titleKey, 'assistant_title_driver_profile');
      expect(steps[3].targetTabIndex, 2);
    });

    test('Parent tutorial contains 4 peace-of-mind tracking steps', () {
      final steps = AssistantTutorialProvider.stepsFor('PARENT');
      expect(steps.length, 4);

      expect(steps[0].titleKey, 'assistant_title_parent_welcome');
      expect(steps[1].titleKey, 'assistant_title_parent_tracking');
      expect(steps[1].targetTabIndex, 0);
      expect(steps[2].titleKey, 'assistant_title_parent_alerts');
      expect(steps[2].targetTabIndex, 1);
      expect(steps[3].titleKey, 'assistant_title_parent_profile');
      expect(steps[3].targetTabIndex, 2);
    });
  });
}
