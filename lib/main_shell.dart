import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/session_manager.dart';
import 'features/alerts/presentation/notifications_screen.dart';
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      LiveTrackingScreen(sessionManager: widget.sessionManager),
      const NotificationsScreen(),
      ProfileScreen(
        sessionManager: widget.sessionManager,
        onSignedOut: widget.onSignedOut,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on, color: AppTheme.primaryNavy),
            label: 'Seguimiento',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryNavy),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle, color: AppTheme.primaryNavy),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
