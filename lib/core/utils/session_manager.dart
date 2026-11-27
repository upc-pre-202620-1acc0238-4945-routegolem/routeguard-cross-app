import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/alerts/models/safety_alert.dart';
import '../localization/app_strings.dart';

class SupportTicketEntry {
  final String ticketId;
  final String categoryKey;
  final String subject;
  final String message;
  final String createdAt;

  const SupportTicketEntry({
    required this.ticketId,
    required this.categoryKey,
    required this.subject,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'ticketId': ticketId,
        'categoryKey': categoryKey,
        'subject': subject,
        'message': message,
        'createdAt': createdAt,
      };

  factory SupportTicketEntry.fromJson(Map<String, dynamic> json) => SupportTicketEntry(
        ticketId: json['ticketId']?.toString() ?? '#RG-0000',
        categoryKey: json['categoryKey']?.toString() ?? 'support_cat_gps',
        subject: json['subject']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyFullName = 'full_name';
  static const String _keyEmail = 'email';
  static const String _keyRole = 'role';
  static const String _keyOrganizationId = 'organization_id';
  static const String _keyProfileId = 'profile_id';
  static const String _keyCacheOwner = 'cache_owner';
  static const String _keySeenTutorialPrefix = 'seen_tutorial_';
  static const String _keyAvatarPath = 'avatar_path';
  static const String _keyLanguage = 'app_language';
  static const String _keySupportTickets = 'support_tickets';

  static final ValueNotifier<String> activeRoleNotifier = ValueNotifier<String>('PARENT');
  static final ValueNotifier<String?> avatarPathNotifier = ValueNotifier<String?>(null);
  static final ValueNotifier<List<SupportTicketEntry>> supportTicketsNotifier =
      ValueNotifier<List<SupportTicketEntry>>([]);

  final SharedPreferences _prefs;

  SessionManager(this._prefs) {
    activeRoleNotifier.value = normalizeRole(_prefs.getString(_keyRole) ?? 'PARENT');
    avatarPathNotifier.value = _prefs.getString(_keyAvatarPath);
    supportTicketsNotifier.value = _loadSupportTickets();
    final savedLang = _prefs.getString(_keyLanguage);
    if (savedLang != null && savedLang.isNotEmpty) {
      AppStrings.setLanguageCode(savedLang);
    }
  }

  List<SupportTicketEntry> _loadSupportTickets() {
    final raw = _prefs.getString(_keySupportTickets);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SupportTicketEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<SupportTicketEntry> addSupportTicket({
    required String categoryKey,
    required String subject,
    required String message,
  }) async {
    final code = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
    final entry = SupportTicketEntry(
      ticketId: '#RG-$code',
      categoryKey: categoryKey,
      subject: subject,
      message: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    final updated = [entry, ...supportTicketsNotifier.value];
    supportTicketsNotifier.value = updated;
    await _prefs.setString(
      _keySupportTickets,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    return entry;
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
    String? profileId,
  }) async {
    final normalizedRole = normalizeRole(role);
    await _prefs.setString(_keyToken, token);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyFullName, fullName);
    await _prefs.setString(_keyEmail, email);
    await _prefs.setString(_keyRole, normalizedRole);
    await _prefs.setString(_keyOrganizationId, organizationId);
    if (profileId != null && profileId.isNotEmpty) {
      await _prefs.setString(_keyProfileId, profileId);
    } else {
      await _prefs.remove(_keyProfileId);
    }
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
  String get fullName => _prefs.getString(_keyFullName) ?? AppStrings.tr('profile_default_user');
  String get email => _prefs.getString(_keyEmail) ?? '';
  String get role => normalizeRole(_prefs.getString(_keyRole) ?? 'PARENT');
  String get organizationId => _prefs.getString(_keyOrganizationId) ?? 'org_school_01';
  String? get profileId => _prefs.getString(_keyProfileId);
  String? get cacheOwner => _prefs.getString(_keyCacheOwner);
  String get languageCode => _prefs.getString(_keyLanguage) ?? AppStrings.languageCode;

  Future<void> setProfileId(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_keyProfileId);
    } else {
      await _prefs.setString(_keyProfileId, value);
    }
  }

  Future<void> setCacheOwner(String userId) async {
    await _prefs.setString(_keyCacheOwner, userId);
  }

  Future<void> setLanguage(AppLanguage language) async {
    AppStrings.setLanguage(language);
    await _prefs.setString(_keyLanguage, AppStrings.languageCode);
  }

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
    await _prefs.remove(_keyProfileId);
    SafetyAlert.resetDefaults();
    activeRoleNotifier.value = 'PARENT';
  }
}
