import 'package:flutter/material.dart';
import 'core/assistant/assistant_guide_overlay.dart';
import 'core/assistant/assistant_step.dart';
import 'core/assistant/assistant_tutorial_provider.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/session_manager.dart';
import 'features/alerts/presentation/notifications_screen.dart';
import 'features/driver/presentation/driver_trip_screen.dart';
import 'features/fleet/presentation/routes_screen.dart';
import 'features/monitor/presentation/live_monitor_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/stakeholders/presentation/stakeholders_screen.dart';
import 'features/subscription/presentation/subscription_screen.dart';
import 'features/tracking/presentation/live_tracking_screen.dart';

class ShellDestination {
  final Widget screen;
  final Widget icon;
  final Widget selectedIcon;
  final String labelKey;

  const ShellDestination({
    required this.screen,
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });
}

class MainShell extends StatefulWidget {
  final SessionManager sessionManager;
  final VoidCallback onSignedOut;

  const MainShell({
    super.key,
    required this.sessionManager,
    required this.onSignedOut,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String _lastRole = '';

  // Mascot Interactive Tutorial State
  bool _showTutorial = false;
  int _tutorialStepIndex = 0;
  List<AssistantStep> _tutorialSteps = [];

  void _startTutorial(String role) {
    setState(() {
      _tutorialSteps = AssistantTutorialProvider.stepsFor(role);
      _tutorialStepIndex = 0;
      _showTutorial = true;
      _applyTutorialStep(0);
    });
  }

  void _applyTutorialStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _tutorialSteps.length) {
      final targetTab = _tutorialSteps[stepIndex].targetTabIndex;
      if (targetTab != null) {
        setState(() {
          _currentIndex = targetTab;
        });
      }
    }
  }

  void _onNextTutorialStep() {
    if (_tutorialStepIndex < _tutorialSteps.length - 1) {
      setState(() {
        _tutorialStepIndex++;
        _applyTutorialStep(_tutorialStepIndex);
      });
    } else {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  void _onPreviousTutorialStep() {
    if (_tutorialStepIndex > 0) {
      setState(() {
        _tutorialStepIndex--;
        _applyTutorialStep(_tutorialStepIndex);
      });
    }
  }

  void _onDismissTutorial() {
    setState(() {
      _showTutorial = false;
    });
  }

  List<ShellDestination> _buildDestinationsForRole(String role) {
    final normalized = SessionManager.normalizeRole(role);

    if (normalized == 'ADMINISTRATOR') {
      return [
        const ShellDestination(
          screen: StakeholdersScreen(),
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt, color: AppTheme.primaryNavy),
          labelKey: 'nav_people',
        ),
        const ShellDestination(
          screen: RoutesScreen(),
          icon: Icon(Icons.alt_route_outlined),
          selectedIcon: Icon(Icons.alt_route, color: AppTheme.primaryNavy),
          labelKey: 'nav_routes',
        ),
        const ShellDestination(
          screen: LiveMonitorScreen(),
          icon: Icon(Icons.sensors_outlined),
          selectedIcon: Icon(Icons.sensors, color: AppTheme.primaryNavy),
          labelKey: 'nav_live',
        ),
        const ShellDestination(
          screen: SubscriptionScreen(),
          icon: Icon(Icons.workspace_premium_outlined),
          selectedIcon: Icon(Icons.workspace_premium, color: AppTheme.primaryNavy),
          labelKey: 'nav_plans',
        ),
        ShellDestination(
          screen: ProfileScreen(
            sessionManager: widget.sessionManager,
            onSignedOut: widget.onSignedOut,
            onLaunchTutorial: () => _startTutorial(normalized),
          ),
          icon: const Icon(Icons.account_circle_outlined),
          selectedIcon: const Icon(Icons.account_circle, color: AppTheme.primaryNavy),
          labelKey: 'nav_profile',
        ),
      ];
    } else if (normalized == 'DRIVER') {
      return [
        const ShellDestination(
          screen: DriverTripScreen(),
          icon: Icon(Icons.checklist_rtl),
          selectedIcon: Icon(Icons.checklist_rtl, color: AppTheme.primaryNavy),
          labelKey: 'nav_driver',
        ),
        const ShellDestination(
          screen: NotificationsScreen(),
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryNavy),
          labelKey: 'nav_alerts',
        ),
        ShellDestination(
          screen: ProfileScreen(
            sessionManager: widget.sessionManager,
            onSignedOut: widget.onSignedOut,
            onLaunchTutorial: () => _startTutorial(normalized),
          ),
          icon: const Icon(Icons.account_circle_outlined),
          selectedIcon: const Icon(Icons.account_circle, color: AppTheme.primaryNavy),
          labelKey: 'nav_profile',
        ),
      ];
    } else {
      // PARENT
      return [
        ShellDestination(
          screen: LiveTrackingScreen(sessionManager: widget.sessionManager),
          icon: const Icon(Icons.location_on_outlined),
          selectedIcon: const Icon(Icons.location_on, color: AppTheme.primaryNavy),
          labelKey: 'nav_tracking',
        ),
        const ShellDestination(
          screen: NotificationsScreen(),
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryNavy),
          labelKey: 'nav_alerts',
        ),
        ShellDestination(
          screen: ProfileScreen(
            sessionManager: widget.sessionManager,
            onSignedOut: widget.onSignedOut,
            onLaunchTutorial: () => _startTutorial(normalized),
          ),
          icon: const Icon(Icons.account_circle_outlined),
          selectedIcon: const Icon(Icons.account_circle, color: AppTheme.primaryNavy),
          labelKey: 'nav_profile',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SessionManager.activeRoleNotifier,
      builder: (context, activeRole, _) {
        final normalizedRole = SessionManager.normalizeRole(activeRole);
        if (_lastRole != normalizedRole) {
          _lastRole = normalizedRole;
          _currentIndex = 0;
          _showTutorial = false;
        }

        final destinations = _buildDestinationsForRole(normalizedRole);
        if (_currentIndex >= destinations.length) {
          _currentIndex = 0;
        }

        return ValueListenableBuilder<AppLanguage>(
          valueListenable: AppStrings.currentLanguage,
          builder: (context, lang, _) {
            return Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: destinations.map((d) => d.screen).toList(),
                    ),
                  ),
                  if (_showTutorial)
                    AssistantGuideOverlay(
                      steps: _tutorialSteps,
                      currentStepIndex: _tutorialStepIndex,
                      onNext: _onNextTutorialStep,
                      onPrevious: _onPreviousTutorialStep,
                      onDismiss: _onDismissTutorial,
                    ),
                ],
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: destinations.length <= 3 ? 380 : 560,
                      ),
                      child: NavigationBar(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (index) {
                          if (!_showTutorial) {
                            setState(() {
                              _currentIndex = index;
                            });
                          }
                        },
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        indicatorColor: AppTheme.primaryNavy.withValues(alpha: 0.15),
                        destinations: destinations.map((d) {
                          return NavigationDestination(
                            icon: d.icon,
                            selectedIcon: d.selectedIcon,
                            label: AppStrings.tr(d.labelKey),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
