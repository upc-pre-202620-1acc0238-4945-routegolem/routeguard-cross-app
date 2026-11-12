import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyFullName = 'full_name';
  static const String _keyEmail = 'email';
  static const String _keyRole = 'role';
  static const String _keyOrganizationId = 'organization_id';

  static final ValueNotifier<String> activeRoleNotifier = ValueNotifier<String>('PARENT');

  final SharedPreferences _prefs;

  SessionManager(this._prefs) {
    activeRoleNotifier.value = _prefs.getString(_keyRole) ?? 'PARENT';
  }

  static Future<SessionManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionManager(prefs);
  }

  Future<void> saveSession({
    required String token,
    required String userId,
    required String fullName,
    required String email,
    required String role,
    required String organizationId,
  }) async {
    await _prefs.setString(_keyToken, token);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyFullName, fullName);
    await _prefs.setString(_keyEmail, email);
    await _prefs.setString(_keyRole, role);
    await _prefs.setString(_keyOrganizationId, organizationId);
    activeRoleNotifier.value = role;
  }

  String? get token => _prefs.getString(_keyToken);
  String? get userId => _prefs.getString(_keyUserId);
  String get fullName => _prefs.getString(_keyFullName) ?? 'Padre de Familia';
  String get email => _prefs.getString(_keyEmail) ?? '';
  String get role => _prefs.getString(_keyRole) ?? 'PARENT';
  String get organizationId => _prefs.getString(_keyOrganizationId) ?? 'org_school_01';

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  Future<void> setRole(String newRole) async {
    await _prefs.setString(_keyRole, newRole);
    activeRoleNotifier.value = newRole;
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyFullName);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyRole);
    await _prefs.remove(_keyOrganizationId);
    activeRoleNotifier.value = 'PARENT';
  }
}
