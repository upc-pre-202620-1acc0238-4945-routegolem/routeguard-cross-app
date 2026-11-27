import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/session_manager.dart';
import '../models/safety_alert.dart';

class NotificationsRepository {
  final http.Client _client;
  final LocalDatabase _db;

  NotificationsRepository({http.Client? client, LocalDatabase? db})
      : _client = client ?? http.Client(),
        _db = db ?? LocalDatabase.instance;

  bool _isLiveToken(String token) =>
      token.isNotEmpty &&
      !token.startsWith('mock_') &&
      !token.startsWith('mock-') &&
      !token.startsWith('demo-');

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  /// Fetches live notifications for the signed-in account (parent-scoped on backend for PARENT,
  /// organization-scoped for DRIVER/ADMIN) and syncs the local sqflite cache.
  Future<List<SafetyAlert>> getNotifications({
    required String token,
    SessionManager? sessionManager,
    String? userId,
    String? role,
    String? profileId,
  }) async {
    final resolvedRole = SessionManager.normalizeRole(role ?? sessionManager?.role ?? 'PARENT');
    final resolvedUserId = userId ?? sessionManager?.userId;
    var resolvedProfileId = profileId ?? sessionManager?.profileId;

    if (resolvedUserId != null &&
        resolvedUserId.isNotEmpty &&
        sessionManager != null &&
        sessionManager.cacheOwner != resolvedUserId) {
      await _db.clearUserScopedCaches();
      await sessionManager.setCacheOwner(resolvedUserId);
    }

    if (_isLiveToken(token)) {
      if (resolvedRole == 'PARENT' && (resolvedProfileId == null || resolvedProfileId.isEmpty)) {
        resolvedProfileId = await _resolveParentProfileId(token, resolvedUserId);
        if (resolvedProfileId != null && sessionManager != null) {
          await sessionManager.setProfileId(resolvedProfileId);
        }
      }

      final query = (resolvedRole == 'PARENT' &&
              resolvedProfileId != null &&
              resolvedProfileId.isNotEmpty)
          ? '?parentId=$resolvedProfileId'
          : '';
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notificationsEndpoint}$query');

      try {
        final response = await _client
            .get(uri, headers: _headers(token))
            .timeout(ApiConstants.timeout);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            final parsed = decoded
                .whereType<Map<String, dynamic>>()
                .map(SafetyAlert.fromJson)
                .toList()
              ..sort((a, b) {
                final ad = a.sentAtDate;
                final bd = b.sentAtDate;
                if (ad != null && bd != null) return bd.compareTo(ad);
                return 0;
              });

            await _db.replaceSyncedRows(
              'notifications_cache',
              parsed
                  .map((a) => <String, Object?>{
                        'id': a.id,
                        'trip_id': a.tripId ?? '',
                        'type': a.type,
                        'status': a.status,
                        'title': a.title,
                        'title_en': a.titleEn,
                        'message': a.message,
                        'sent_at': a.sentAtDate?.toUtc().toIso8601String() ?? a.timestamp,
                        'has_panic': a.hasPanicAlert ? 1 : 0,
                      })
                  .toList(),
              hasPendingSync: false,
            );
            SafetyAlert.setAlerts(parsed);
            return parsed;
          }
        }
      } catch (_) {
        // Fall back to local cache below
      }
    }

    final cachedRows = await _db.queryAll('notifications_cache');
    if (cachedRows.isNotEmpty) {
      final cached = cachedRows.map((row) {
        final sentAtStr = row['sent_at']?.toString();
        final parsedDate = sentAtStr != null ? DateTime.tryParse(sentAtStr) : null;
        final (tsEs, tsEn) = parsedDate != null
            ? SafetyAlert.formatSentAt(parsedDate)
            : (sentAtStr ?? 'Hoy', sentAtStr ?? 'Today');
        return SafetyAlert(
          id: row['id']?.toString() ?? '',
          tripId: row['trip_id']?.toString(),
          type: row['type']?.toString() ?? 'GENERAL',
          status: row['status']?.toString() ?? 'DELIVERED',
          title: row['title']?.toString() ?? '',
          titleEn: row['title_en']?.toString(),
          message: row['message']?.toString() ?? '',
          timestamp: tsEs,
          timestampEn: tsEn,
          hasPanicAlert: (row['has_panic'] as num?)?.toInt() == 1,
          sentAtDate: parsedDate,
        );
      }).toList()
        ..sort((a, b) {
          final ad = a.sentAtDate;
          final bd = b.sentAtDate;
          if (ad != null && bd != null) return bd.compareTo(ad);
          return 0;
        });
      SafetyAlert.setAlerts(cached);
      return cached;
    }

    if (!_isLiveToken(token)) {
      return List<SafetyAlert>.from(SafetyAlert.sharedAlertsNotifier.value);
    }
    return const [];
  }

  Future<Set<String>> markDelivered(String token, List<SafetyAlert> alerts) async {
    if (!_isLiveToken(token)) {
      return alerts.map((a) => a.id).toSet();
    }
    final confirmed = <String>{};
    for (final alert in alerts) {
      if (alert.isDelivered || alert.id.isEmpty || alert.id.startsWith('alt-')) continue;
      try {
        final uri = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.notificationsEndpoint}/${alert.id}/delivered',
        );
        final res = await _client
            .post(uri, headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          confirmed.add(alert.id);
        }
      } catch (_) {}
    }
    if (confirmed.isNotEmpty) {
      final updated = SafetyAlert.sharedAlertsNotifier.value.map((a) {
        if (confirmed.contains(a.id)) {
          return SafetyAlert(
            id: a.id,
            tripId: a.tripId,
            title: a.title,
            titleEn: a.titleEn,
            message: a.message,
            messageEn: a.messageEn,
            timestamp: a.timestamp,
            timestampEn: a.timestampEn,
            type: a.type,
            status: 'DELIVERED',
            hasPanicAlert: a.hasPanicAlert,
            sentAtDate: a.sentAtDate,
          );
        }
        return a;
      }).toList();
      SafetyAlert.setAlerts(updated);
    }
    return confirmed;
  }

  Future<int?> triggerPanic(String token, {String? tripId}) async {
    if (!_isLiveToken(token)) return null;
    final resolvedTripId = tripId ?? await _resolveActiveDriverTripId(token);
    if (resolvedTripId == null || resolvedTripId.isEmpty) return null;

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$resolvedTripId/panic',
      );
      final res = await _client
          .post(uri, headers: _headers(token))
          .timeout(ApiConstants.timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          return (data['notified'] as num?)?.toInt();
        }
        return 1;
      }
    } catch (_) {}
    return null;
  }

  Future<int?> sendBroadcast(String token, String message, {String? tripId}) async {
    if (!_isLiveToken(token)) return null;
    final resolvedTripId = tripId ?? await _resolveActiveDriverTripId(token);
    if (resolvedTripId == null || resolvedTripId.isEmpty) return null;

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}/$resolvedTripId/broadcast',
      );
      final res = await _client
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({'message': message.trim()}),
          )
          .timeout(ApiConstants.timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          return (data['notified'] as num?)?.toInt();
        }
        return 1;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveParentProfileId(String token, String? userId) async {
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.parentsEndpoint}'),
            headers: _headers(token),
          )
          .timeout(ApiConstants.timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final uid = (item['userId'] ?? item['UserId'])?.toString();
              if (userId != null && uid == userId) {
                return (item['id'] ?? item['Id'])?.toString();
              }
            }
          }
          if (decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
            return (decoded.first['id'] ?? decoded.first['Id'])?.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveActiveDriverTripId(String token) async {
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tripsEndpoint}'),
            headers: _headers(token),
          )
          .timeout(ApiConstants.timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final st = (item['tripState'] ?? item['status'] ?? item['state'] ?? '')
                  .toString()
                  .toUpperCase();
              if (st == 'IN_PROGRESS') {
                return (item['id'] ?? item['tripId'])?.toString();
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
