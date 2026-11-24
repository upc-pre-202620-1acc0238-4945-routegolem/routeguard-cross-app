import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyFullName = 'full_name';
  static const String _keyEmail = 'email';
  static const String _keyRole = 'role';
  static const String _keyOrganizationId = 'organization_id';
  static const String _keySeenTutorialPrefix = 'seen_tutorial_';
  static const String _keyAvatarPath = 'avatar_path';

  static final ValueNotifier<String> activeRoleNotifier = ValueNotifier<String>('PARENT');
  static final ValueNotifier<String?> avatarPathNotifier = ValueNotifier<String?>(null);

  final SharedPreferences _prefs;

  SessionManager(this._prefs) {
    activeRoleNotifier.value = normalizeRole(_prefs.getString(_keyRole) ?? 'PARENT');
    avatarPathNotifier.value = _prefs.getString(_keyAvatarPath);
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
    final normalizedRole = normalizeRole(role);
    await _prefs.setString(_keyToken, token);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyFullName, fullName);
    await _prefs.setString(_keyEmail, email);
    await _prefs.setString(_keyRole, normalizedRole);
    await _prefs.setString(_keyOrganizationId, organizationId);
    activeRoleNotifier.value = normalizedRole;
  }

  static String normalizeRole(String role) {
    final upper = role.trim().toUpperCase();
    if (upper == 'ADMIN' || upper == 'ADMINISTRATOR') return 'ADMINISTRATOR';
    if (upper == 'DRIVER') return 'DRIVER';
    return 'PARENT';
  }

  String? get token => _prefs.getString(_keyToken);
  String? get userId => _prefs.getString(_keyUserId);
  String get fullName => _prefs.getString(_keyFullName) ?? 'Usuario RouteGuard';
  String get email => _prefs.getString(_keyEmail) ?? '';
  String get role => normalizeRole(_prefs.getString(_keyRole) ?? 'PARENT');
  String get organizationId => _prefs.getString(_keyOrganizationId) ?? 'org_school_01';

  bool get isAuthenticated => token != null && token!.isNotEmpty;
  bool get isAdmin => role == 'ADMINISTRATOR';
  bool get isDriver => role == 'DRIVER';
  bool get isParent => role == 'PARENT';

  bool hasSeenTutorial(String userId) {
    return _prefs.getBool('$_keySeenTutorialPrefix$userId') ?? false;
  }

  Future<void> setTutorialSeen(String userId, bool seen) async {
    await _prefs.setBool('$_keySeenTutorialPrefix$userId', seen);
  }

  String? get avatarPath => _prefs.getString(_keyAvatarPath);

  Future<void> setAvatarPath(String? path) async {
    if (path == null) {
      await _prefs.remove(_keyAvatarPath);
    } else {
      await _prefs.setString(_keyAvatarPath, path);
    }
    avatarPathNotifier.value = path;
  }

  Future<void> setRole(String newRole) async {
    final normalized = normalizeRole(newRole);
    await _prefs.setString(_keyRole, normalized);
    activeRoleNotifier.value = normalized;
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
