import 'package:flutter/material.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/session_manager.dart';
import 'features/auth/presentation/login_screen.dart';
import 'main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionManager = await SessionManager.create();

  runApp(RouteGuardCrossApp(sessionManager: sessionManager));
}

class RouteGuardCrossApp extends StatefulWidget {
  final SessionManager sessionManager;

  const RouteGuardCrossApp({super.key, required this.sessionManager});

  @override
  State<RouteGuardCrossApp> createState() => _RouteGuardCrossAppState();
}

class _RouteGuardCrossAppState extends State<RouteGuardCrossApp> {
  late bool _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = widget.sessionManager.isAuthenticated;
  }

  void _onAuthenticated() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _onSignedOut() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppStrings.currentLanguage,
      builder: (context, _, _) {
        return MaterialApp(
          title: AppStrings.tr('app_title'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: _isAuthenticated
              ? MainShell(
                  sessionManager: widget.sessionManager,
                  onSignedOut: _onSignedOut,
                )
              : LoginScreen(
                  sessionManager: widget.sessionManager,
                  onAuthenticated: _onAuthenticated,
                ),
        );
      },
    );
  }
}
