import 'package:flutter/material.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/session_manager.dart';
import 'features/alerts/presentation/notifications_screen.dart';
import 'features/driver/presentation/driver_trip_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/tracking/presentation/live_tracking_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SessionManager.activeRoleNotifier,
      builder: (context, activeRole, _) {
        final isDriver = activeRole == 'DRIVER';

        final screens = [
          isDriver
              ? const DriverTripScreen()
              : LiveTrackingScreen(sessionManager: widget.sessionManager),
          const NotificationsScreen(),
          ProfileScreen(
            sessionManager: widget.sessionManager,
            onSignedOut: widget.onSignedOut,
          ),
        ];

        return ValueListenableBuilder<AppLanguage>(
          valueListenable: AppStrings.currentLanguage,
          builder: (context, lang, _) {
            return Scaffold(
              body: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: Colors.white,
                indicatorColor: AppTheme.primaryNavy.withValues(alpha: 0.15),
                destinations: [
                  NavigationDestination(
                    icon: Icon(isDriver ? Icons.checklist_rtl : Icons.location_on_outlined),
                    selectedIcon: Icon(
                      isDriver ? Icons.checklist_rtl : Icons.location_on,
                      color: AppTheme.primaryNavy,
                    ),
                    label: isDriver
                        ? AppStrings.tr('nav_driver')
                        : AppStrings.tr('nav_tracking'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.notifications_outlined),
                    selectedIcon: const Icon(Icons.notifications, color: AppTheme.primaryNavy),
                    label: AppStrings.tr('nav_alerts'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.account_circle_outlined),
                    selectedIcon: const Icon(Icons.account_circle, color: AppTheme.primaryNavy),
                    label: AppStrings.tr('nav_profile'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
