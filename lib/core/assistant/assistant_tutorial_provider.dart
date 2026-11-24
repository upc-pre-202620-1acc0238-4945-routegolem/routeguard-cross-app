import 'assistant_step.dart';

class AssistantTutorialProvider {
  static List<AssistantStep> stepsFor(String role) {
    final normalized = role.trim().toUpperCase();

    if (normalized == 'ADMINISTRATOR' || normalized == 'ADMIN') {
      return const [
        AssistantStep(
          titleKey: 'assistant_title_admin_welcome',
          messageKey: 'assistant_msg_admin_welcome',
          targetTabIndex: null,
        ),
        AssistantStep(
          titleKey: 'assistant_title_admin_people',
          messageKey: 'assistant_msg_admin_people',
          targetTabIndex: 0,
        ),
        AssistantStep(
          titleKey: 'assistant_title_admin_routes',
          messageKey: 'assistant_msg_admin_routes',
          targetTabIndex: 1,
        ),
        AssistantStep(
          titleKey: 'assistant_title_admin_live',
          messageKey: 'assistant_msg_admin_live',
          targetTabIndex: 2,
        ),
        AssistantStep(
          titleKey: 'assistant_title_admin_plans',
          messageKey: 'assistant_msg_admin_plans',
          targetTabIndex: 3,
        ),
        AssistantStep(
          titleKey: 'assistant_title_admin_profile',
          messageKey: 'assistant_msg_admin_profile',
          targetTabIndex: 4,
        ),
      ];
    } else if (normalized == 'DRIVER') {
      return const [
        AssistantStep(
          titleKey: 'assistant_title_driver_welcome',
          messageKey: 'assistant_msg_driver_welcome',
          targetTabIndex: null,
        ),
        AssistantStep(
          titleKey: 'assistant_title_driver_trip',
          messageKey: 'assistant_msg_driver_trip',
          targetTabIndex: 0,
        ),
        AssistantStep(
          titleKey: 'assistant_title_driver_alerts',
          messageKey: 'assistant_msg_driver_alerts',
          targetTabIndex: 1,
        ),
        AssistantStep(
          titleKey: 'assistant_title_driver_profile',
          messageKey: 'assistant_msg_driver_profile',
          targetTabIndex: 2,
        ),
      ];
    } else {
      // PARENT
      return const [
        AssistantStep(
          titleKey: 'assistant_title_parent_welcome',
          messageKey: 'assistant_msg_parent_welcome',
          targetTabIndex: null,
        ),
        AssistantStep(
          titleKey: 'assistant_title_parent_tracking',
          messageKey: 'assistant_msg_parent_tracking',
          targetTabIndex: 0,
        ),
        AssistantStep(
          titleKey: 'assistant_title_parent_alerts',
          messageKey: 'assistant_msg_parent_alerts',
          targetTabIndex: 1,
        ),
        AssistantStep(
          titleKey: 'assistant_title_parent_profile',
          messageKey: 'assistant_msg_parent_profile',
          targetTabIndex: 2,
        ),
      ];
    }
  }
}
