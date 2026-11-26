import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../database/local_database.dart';
import '../utils/session_manager.dart';

class PlatformFeaturesRepository {
  final http.Client _client;
  final LocalDatabase _db;

  PlatformFeaturesRepository({http.Client? client, LocalDatabase? db})
      : _client = client ?? http.Client(),
        _db = db ?? LocalDatabase.instance;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  String _todayIso() => DateTime.now().toIso8601String().substring(0, 10);
  String _nowIso() => DateTime.now().toUtc().toIso8601String();
  String _localId() => 'local_${DateTime.now().microsecondsSinceEpoch}';

  // ---- Profile Photo & Language ----

  Future<String?> loadMyPhoto(String token, String userId) async {
    final cachedRows = await _db.queryAll('user_avatar_cache');
    final mine = cachedRows.where((r) => r['user_id'] == userId).toList();
    final cached = mine.isNotEmpty ? mine.first : null;

    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .get(Uri.parse('${ApiConstants.baseUrl}/users/me'), headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final remotePhoto = json['photoData']?.toString();
          final pending = (cached?['pending_sync'] ?? 0) == 1;
          final resolved = pending ? cached!['photo_data']?.toString() : remotePhoto;
          await _db.upsertRow(
            'user_avatar_cache',
            {
              'user_id': userId,
              'photo_data': resolved,
              'pending_sync': pending ? 1 : 0,
            },
            pk: 'user_id',
          );
          return resolved;
        }
      } catch (_) {}
    }
    return cached?['photo_data']?.toString();
  }

  Future<bool> saveMyPhoto(String token, String userId, String? photoData) async {
    await _db.upsertRow(
      'user_avatar_cache',
      {'user_id': userId, 'photo_data': photoData, 'pending_sync': 1},
      pk: 'user_id',
    );
    if (token.isEmpty || token.startsWith('mock_')) return false;
    try {
      final res = await _client
          .put(
            Uri.parse('${ApiConstants.baseUrl}/users/me/photo'),
            headers: _headers(token),
            body: jsonEncode({'photoData': photoData}),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _db.upsertRow(
          'user_avatar_cache',
          {'user_id': userId, 'photo_data': photoData, 'pending_sync': 0},
          pk: 'user_id',
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> syncLanguage(String token, String langCode) async {
    if (token.isEmpty || token.startsWith('mock_')) return;
    try {
      await _client
          .put(
            Uri.parse('${ApiConstants.baseUrl}/users/me/language'),
            headers: _headers(token),
            body: jsonEncode({'language': langCode}),
          )
          .timeout(ApiConstants.timeout);
    } catch (_) {}
  }

  // ---- US-19: Password Recovery ----

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final res = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}/users/forgot-password'),
            headers: _headers(''),
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'sent': true, 'email': email.trim()};
  }

  Future<bool> confirmPasswordReset(String email, String code, String newPassword) async {
    try {
      final res = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}/users/reset-password'),
            headers: _headers(''),
            body: jsonEncode({
              'email': email.trim(),
              'code': code.trim(),
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ---- US-12: Vehicle & SOAT Docs ----

  Future<Map<String, Object?>> loadPrimaryVehicleDocs(String token) async {
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .get(Uri.parse('${ApiConstants.baseUrl}/vehicles'), headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode == 200) {
          final items = (jsonDecode(res.body) as List<dynamic>).whereType<Map<String, dynamic>>().toList();
          final rows = items
              .map((v) => <String, Object?>{
                    'id': v['id']?.toString() ?? '',
                    'plate': v['plate']?.toString() ?? 'ABC-123',
                    'brand': v['brand']?.toString() ?? 'Mercedes-Benz',
                    'model': v['model']?.toString() ?? 'Mercedes-Benz Sprinter 416',
                    'capacity': (v['capacity'] as num?)?.toInt() ?? 20,
                    'soat_policy': v['soatPolicy']?.toString() ?? 'SOAT-2026-88412',
                    'soat_insurer': v['soatInsurer']?.toString() ?? 'Rímac Seguros',
                    'soat_expires_at': v['soatExpiresAt']?.toString() ?? '2026-12-15',
                    'soat_valid': (v['soatValid'] == false) ? 0 : 1,
                  })
              .toList();
          if (rows.isNotEmpty) {
            await _db.replaceSyncedRows('vehicle_docs_cache', rows, hasPendingSync: false);
          }
        }
      } catch (_) {}
    }
    final cached = await _db.queryAll('vehicle_docs_cache', orderBy: 'plate ASC');
    if (cached.isNotEmpty) return cached.first;
    return {
      'plate': 'ABC-123',
      'brand': 'Mercedes-Benz',
      'model': 'Mercedes-Benz Sprinter 416',
      'capacity': 20,
      'soat_policy': 'SOAT-2026-88412',
      'soat_insurer': 'Rímac Seguros',
      'soat_expires_at': '2026-12-15',
      'soat_valid': 1,
    };
  }

  // ---- Authorized Caregivers ----

  Future<List<Map<String, Object?>>> getCaregivers(String token) async {
    await _syncPendingCaregivers(token);
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .get(Uri.parse('${ApiConstants.baseUrl}/caregivers'), headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode == 200) {
          final list = (jsonDecode(res.body) as List<dynamic>).whereType<Map<String, dynamic>>().toList();
          final rows = list
              .map((c) => <String, Object?>{
                    'id': c['id']?.toString() ?? '',
                    'parent_id': c['parentId']?.toString() ?? '',
                    'full_name': c['fullName']?.toString() ?? '',
                    'relationship': c['relationship']?.toString() ?? '',
                    'phone_number': c['phoneNumber']?.toString() ?? '',
                    'created_at': c['createdAt']?.toString() ?? _nowIso(),
                    'pending_sync': 0,
                  })
              .toList();
          await _db.replaceSyncedRows('authorized_caregivers', rows);
        }
      } catch (_) {}
    }
    return _db.queryAll('authorized_caregivers', orderBy: 'created_at ASC');
  }

  Future<void> addCaregiver(String token, String fullName, String relationship, String phone) async {
    final id = _localId();
    final row = <String, Object?>{
      'id': id,
      'parent_id': '',
      'full_name': fullName.trim(),
      'relationship': relationship.trim(),
      'phone_number': phone.trim(),
      'created_at': _nowIso(),
      'pending_sync': 1,
    };
    await _db.upsertRow('authorized_caregivers', row);
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}/caregivers'),
              headers: _headers(token),
              body: jsonEncode({
                'fullName': fullName.trim(),
                'relationship': relationship.trim(),
                'phoneNumber': phone.trim(),
              }),
            )
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final c = jsonDecode(res.body) as Map<String, dynamic>;
          await _db.deleteById('authorized_caregivers', id);
          await _db.upsertRow('authorized_caregivers', {
            'id': c['id']?.toString() ?? id,
            'parent_id': c['parentId']?.toString() ?? '',
            'full_name': c['fullName']?.toString() ?? fullName.trim(),
            'relationship': c['relationship']?.toString() ?? relationship.trim(),
            'phone_number': c['phoneNumber']?.toString() ?? phone.trim(),
            'created_at': c['createdAt']?.toString() ?? _nowIso(),
            'pending_sync': 0,
          });
        }
      } catch (_) {}
    }
  }

  Future<void> deleteCaregiver(String token, String id) async {
    await _db.deleteById('authorized_caregivers', id);
    if (!id.startsWith('local_') && token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        await _client.delete(Uri.parse('${ApiConstants.baseUrl}/caregivers/$id'), headers: _headers(token));
      } catch (_) {}
    }
  }

  // ---- US-23: Support Tickets ----

  Future<List<SupportTicketEntry>> getSupportTickets(String token) async {
    await _syncPendingTickets(token);
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .get(Uri.parse('${ApiConstants.baseUrl}/support-tickets'), headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode == 200) {
          final list = (jsonDecode(res.body) as List<dynamic>).whereType<Map<String, dynamic>>().toList();
          final rows = list
              .map((t) => <String, Object?>{
                    'id': t['id']?.toString() ?? '',
                    'ticket_code': t['ticketCode']?.toString() ?? '#RG-0000',
                    'category': t['category']?.toString() ?? 'GENERAL',
                    'subject': t['subject']?.toString() ?? '',
                    'message': t['message']?.toString() ?? '',
                    'status': t['status']?.toString() ?? 'OPEN',
                    'created_at': t['createdAt']?.toString() ?? _nowIso(),
                    'pending_sync': 0,
                  })
              .toList();
          await _db.replaceSyncedRows('support_tickets', rows);
        }
      } catch (_) {}
    }
    final all = await _db.queryAll('support_tickets', orderBy: 'created_at DESC');
    return all
        .map((r) => SupportTicketEntry(
              ticketId: r['ticket_code']?.toString() ?? '#RG-0000',
              categoryKey: r['category']?.toString() ?? 'GENERAL',
              subject: r['subject']?.toString() ?? '',
              message: r['message']?.toString() ?? '',
              createdAt: r['created_at']?.toString() ?? '',
            ))
        .toList();
  }

  Future<SupportTicketEntry> createSupportTicket(
    String token, {
    required String category,
    required String subject,
    required String message,
  }) async {
    final id = _localId();
    final code = '#RG-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';
    final created = _nowIso();
    await _db.upsertRow('support_tickets', {
      'id': id,
      'ticket_code': code,
      'category': category,
      'subject': subject.trim(),
      'message': message.trim(),
      'status': 'OPEN',
      'created_at': created,
      'pending_sync': 1,
    });
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}/support-tickets'),
              headers: _headers(token),
              body: jsonEncode({'category': category, 'subject': subject.trim(), 'message': message.trim()}),
            )
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final remote = jsonDecode(res.body) as Map<String, dynamic>;
          await _db.deleteById('support_tickets', id);
          final syncedCode = remote['ticketCode']?.toString() ?? code;
          await _db.upsertRow('support_tickets', {
            'id': remote['id']?.toString() ?? id,
            'ticket_code': syncedCode,
            'category': remote['category']?.toString() ?? category,
            'subject': remote['subject']?.toString() ?? subject.trim(),
            'message': remote['message']?.toString() ?? message.trim(),
            'status': remote['status']?.toString() ?? 'OPEN',
            'created_at': remote['createdAt']?.toString() ?? created,
            'pending_sync': 0,
          });
          return SupportTicketEntry(
            ticketId: syncedCode,
            categoryKey: category,
            subject: subject.trim(),
            message: message.trim(),
            createdAt: created,
          );
        }
      } catch (_) {}
    }
    return SupportTicketEntry(
      ticketId: code,
      categoryKey: category,
      subject: subject.trim(),
      message: message.trim(),
      createdAt: created,
    );
  }

  // ---- US-20: Vehicle Maintenances ----

  Future<List<Map<String, Object?>>> getMaintenances(String token) async {
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .get(Uri.parse('${ApiConstants.baseUrl}/maintenances'), headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode == 200) {
          final list = (jsonDecode(res.body) as List<dynamic>).whereType<Map<String, dynamic>>().toList();
          final rows = list
              .map((m) => <String, Object?>{
                    'id': m['id']?.toString() ?? '',
                    'vehicle_id': m['vehicleId']?.toString() ?? '',
                    'vehicle_plate': m['vehiclePlate']?.toString() ?? '',
                    'maintenance_type': m['maintenanceType']?.toString() ?? '',
                    'description': m['description']?.toString() ?? '',
                    'workshop': m['workshop']?.toString() ?? '',
                    'cost': (m['cost'] as num?)?.toDouble() ?? 0.0,
                    'odometer_km': (m['odometerKm'] as num?)?.toInt() ?? 0,
                    'performed_at': m['performedAt']?.toString() ?? _todayIso(),
                    'next_due_date': m['nextDueDate']?.toString() ?? '',
                    'status': m['status']?.toString() ?? 'COMPLETED',
                    'pending_sync': 0,
                  })
              .toList();
          await _db.replaceSyncedRows('vehicle_maintenances', rows);
        }
      } catch (_) {}
    }
    return _db.queryAll('vehicle_maintenances', orderBy: 'performed_at DESC');
  }

  Future<void> addMaintenance(
    String token, {
    required String plate,
    required String type,
    required String workshop,
    required double cost,
  }) async {
    final id = _localId();
    await _db.upsertRow('vehicle_maintenances', {
      'id': id,
      'vehicle_id': '',
      'vehicle_plate': plate.trim(),
      'maintenance_type': type.trim(),
      'description': type.trim(),
      'workshop': workshop.trim(),
      'cost': cost,
      'odometer_km': 45000,
      'performed_at': _todayIso(),
      'next_due_date': '',
      'status': 'COMPLETED',
      'pending_sync': 1,
    });
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}/maintenances'),
              headers: _headers(token),
              body: jsonEncode({
                'vehiclePlate': plate.trim(),
                'maintenanceType': type.trim(),
                'description': type.trim(),
                'workshop': workshop.trim(),
                'cost': cost,
                'odometerKm': 45000,
              }),
            )
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final remote = jsonDecode(res.body) as Map<String, dynamic>;
          await _db.deleteById('vehicle_maintenances', id);
          await _db.upsertRow('vehicle_maintenances', {
            'id': remote['id']?.toString() ?? id,
            'vehicle_id': remote['vehicleId']?.toString() ?? '',
            'vehicle_plate': remote['vehiclePlate']?.toString() ?? plate.trim(),
            'maintenance_type': remote['maintenanceType']?.toString() ?? type.trim(),
            'description': remote['description']?.toString() ?? type.trim(),
            'workshop': remote['workshop']?.toString() ?? workshop.trim(),
            'cost': (remote['cost'] as num?)?.toDouble() ?? cost,
            'odometer_km': (remote['odometerKm'] as num?)?.toInt() ?? 45000,
            'performed_at': remote['performedAt']?.toString() ?? _todayIso(),
            'next_due_date': remote['nextDueDate']?.toString() ?? '',
            'status': remote['status']?.toString() ?? 'COMPLETED',
            'pending_sync': 0,
          });
        }
      } catch (_) {}
    }
  }

  // ---- US-26: Operational Expenses ----

  Future<List<Map<String, Object?>>> getExpenses(String token) async {
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .get(Uri.parse('${ApiConstants.baseUrl}/expenses'), headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode == 200) {
          final list = (jsonDecode(res.body) as List<dynamic>).whereType<Map<String, dynamic>>().toList();
          final rows = list
              .map((e) => <String, Object?>{
                    'id': e['id']?.toString() ?? '',
                    'vehicle_id': e['vehicleId']?.toString() ?? '',
                    'vehicle_plate': e['vehiclePlate']?.toString() ?? '',
                    'driver_name': e['driverName']?.toString() ?? '',
                    'category': e['category']?.toString() ?? 'FUEL',
                    'description': e['description']?.toString() ?? '',
                    'amount': (e['amount'] as num?)?.toDouble() ?? 0.0,
                    'expense_date': e['expenseDate']?.toString() ?? _todayIso(),
                    'pending_sync': 0,
                  })
              .toList();
          await _db.replaceSyncedRows('operational_expenses', rows);
        }
      } catch (_) {}
    }
    return _db.queryAll('operational_expenses', orderBy: 'expense_date DESC');
  }

  Future<void> addExpense(
    String token, {
    required String plate,
    required String category,
    required String description,
    required double amount,
  }) async {
    final id = _localId();
    await _db.upsertRow('operational_expenses', {
      'id': id,
      'vehicle_id': '',
      'vehicle_plate': plate.trim(),
      'driver_name': '',
      'category': category,
      'description': description.trim(),
      'amount': amount,
      'expense_date': _todayIso(),
      'pending_sync': 1,
    });
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}/expenses'),
              headers: _headers(token),
              body: jsonEncode({
                'vehiclePlate': plate.trim(),
                'category': category,
                'description': description.trim(),
                'amount': amount,
              }),
            )
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final remote = jsonDecode(res.body) as Map<String, dynamic>;
          await _db.deleteById('operational_expenses', id);
          await _db.upsertRow('operational_expenses', {
            'id': remote['id']?.toString() ?? id,
            'vehicle_id': remote['vehicleId']?.toString() ?? '',
            'vehicle_plate': remote['vehiclePlate']?.toString() ?? plate.trim(),
            'driver_name': remote['driverName']?.toString() ?? '',
            'category': remote['category']?.toString() ?? category,
            'description': remote['description']?.toString() ?? description.trim(),
            'amount': (remote['amount'] as num?)?.toDouble() ?? amount,
            'expense_date': remote['expenseDate']?.toString() ?? _todayIso(),
            'pending_sync': 0,
          });
        }
      } catch (_) {}
    }
  }

  // ---- US-24: Driver Announcements ----

  Future<List<Map<String, Object?>>> getAnnouncements(String token) async {
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .get(Uri.parse('${ApiConstants.baseUrl}/announcements'), headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode == 200) {
          final list = (jsonDecode(res.body) as List<dynamic>).whereType<Map<String, dynamic>>().toList();
          final rows = list
              .map((a) => <String, Object?>{
                    'id': a['id']?.toString() ?? '',
                    'route_id': a['routeId']?.toString() ?? '',
                    'author_name': a['authorName']?.toString() ?? '',
                    'title': a['title']?.toString() ?? '',
                    'message': a['message']?.toString() ?? '',
                    'priority': a['priority']?.toString() ?? 'NORMAL',
                    'created_at': a['createdAt']?.toString() ?? _nowIso(),
                    'pending_sync': 0,
                  })
              .toList();
          await _db.replaceSyncedRows('route_announcements', rows);
        }
      } catch (_) {}
    }
    return _db.queryAll('route_announcements', orderBy: 'created_at DESC');
  }

  Future<void> publishAnnouncement(
    String token, {
    required String title,
    required String message,
    String priority = 'NORMAL',
    String? routeId,
  }) async {
    final id = _localId();
    await _db.upsertRow('route_announcements', {
      'id': id,
      'route_id': routeId ?? '',
      'author_name': '',
      'title': title.trim(),
      'message': message.trim(),
      'priority': priority,
      'created_at': _nowIso(),
      'pending_sync': 1,
    });
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}/announcements'),
              headers: _headers(token),
              body: jsonEncode({'routeId': routeId, 'title': title.trim(), 'message': message.trim(), 'priority': priority}),
            )
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final remote = jsonDecode(res.body) as Map<String, dynamic>;
          await _db.deleteById('route_announcements', id);
          await _db.upsertRow('route_announcements', {
            'id': remote['id']?.toString() ?? id,
            'route_id': remote['routeId']?.toString() ?? '',
            'author_name': remote['authorName']?.toString() ?? '',
            'title': remote['title']?.toString() ?? title.trim(),
            'message': remote['message']?.toString() ?? message.trim(),
            'priority': remote['priority']?.toString() ?? priority,
            'created_at': remote['createdAt']?.toString() ?? _nowIso(),
            'pending_sync': 0,
          });
        }
      } catch (_) {}
    }
  }

  // ---- US-27 & US-28: Pickup Changes & Stop Reassignment ----

  Future<List<Map<String, Object?>>> getPickupChanges(String token) async {
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .get(Uri.parse('${ApiConstants.baseUrl}/pickup-changes'), headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode == 200) {
          final list = (jsonDecode(res.body) as List<dynamic>).whereType<Map<String, dynamic>>().toList();
          final rows = list
              .map((p) => <String, Object?>{
                    'id': p['id']?.toString() ?? '',
                    'child_id': p['childId']?.toString() ?? '',
                    'child_name': p['childName']?.toString() ?? '',
                    'route_id': p['routeId']?.toString() ?? '',
                    'target_date': p['targetDate']?.toString() ?? _todayIso(),
                    'new_address': p['newAddress']?.toString() ?? '',
                    'reason': p['reason']?.toString() ?? '',
                    'status': p['status']?.toString() ?? 'PENDING',
                    'created_at': p['createdAt']?.toString() ?? _nowIso(),
                    'pending_sync': 0,
                  })
              .toList();
          await _db.replaceSyncedRows('pickup_change_requests', rows);
        }
      } catch (_) {}
    }
    return _db.queryAll('pickup_change_requests', orderBy: 'created_at DESC');
  }

  Future<void> requestPickupChange(
    String token, {
    required String childName,
    required String newAddress,
    required String reason,
    String? routeId,
  }) async {
    final id = _localId();
    await _db.upsertRow('pickup_change_requests', {
      'id': id,
      'child_id': '',
      'child_name': childName.trim(),
      'route_id': routeId ?? '',
      'target_date': _todayIso(),
      'new_address': newAddress.trim(),
      'reason': reason.trim(),
      'status': 'PENDING',
      'created_at': _nowIso(),
      'pending_sync': 1,
    });
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}/pickup-changes'),
              headers: _headers(token),
              body: jsonEncode({
                'childName': childName.trim(),
                'routeId': routeId,
                'targetDate': _todayIso(),
                'newAddress': newAddress.trim(),
                'reason': reason.trim(),
              }),
            )
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final remote = jsonDecode(res.body) as Map<String, dynamic>;
          await _db.deleteById('pickup_change_requests', id);
          await _db.upsertRow('pickup_change_requests', {
            'id': remote['id']?.toString() ?? id,
            'child_id': remote['childId']?.toString() ?? '',
            'child_name': remote['childName']?.toString() ?? childName.trim(),
            'route_id': remote['routeId']?.toString() ?? '',
            'target_date': remote['targetDate']?.toString() ?? _todayIso(),
            'new_address': remote['newAddress']?.toString() ?? newAddress.trim(),
            'reason': remote['reason']?.toString() ?? reason.trim(),
            'status': remote['status']?.toString() ?? 'PENDING',
            'created_at': remote['createdAt']?.toString() ?? _nowIso(),
            'pending_sync': 0,
          });
        }
      } catch (_) {}
    }
  }

  Future<void> reviewPickupChange(String token, String id, String status) async {
    if (token.isEmpty || token.startsWith('mock_') || id.startsWith('local_')) return;
    try {
      await _client
          .patch(
            Uri.parse('${ApiConstants.baseUrl}/pickup-changes/$id/status'),
            headers: _headers(token),
            body: jsonEncode({'status': status}),
          )
          .timeout(ApiConstants.timeout);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getOptimizedStops(String token, String routeId) async {
    if (token.isEmpty || token.startsWith('mock_')) return null;
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}/routes/$routeId/optimized-stops?date=${_todayIso()}'),
            headers: _headers(token),
          )
          .timeout(ApiConstants.timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ---- US-30: Internal Route Chat ----

  Future<List<Map<String, Object?>>> getChatMessages(String token, {String? routeId}) async {
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final query = routeId != null && routeId.isNotEmpty ? '?routeId=$routeId' : '';
        final res = await _client
            .get(Uri.parse('${ApiConstants.baseUrl}/chat$query'), headers: _headers(token))
            .timeout(ApiConstants.timeout);
        if (res.statusCode == 200) {
          final list = (jsonDecode(res.body) as List<dynamic>).whereType<Map<String, dynamic>>().toList();
          final rows = list
              .map((m) => <String, Object?>{
                    'id': m['id']?.toString() ?? '',
                    'route_id': m['routeId']?.toString() ?? '',
                    'sender_user_id': m['senderUserId']?.toString() ?? '',
                    'sender_name': m['senderName']?.toString() ?? '',
                    'sender_role': m['senderRole']?.toString() ?? '',
                    'message': m['message']?.toString() ?? '',
                    'sent_at': m['sentAt']?.toString() ?? _nowIso(),
                    'pending_sync': 0,
                  })
              .toList();
          await _db.replaceSyncedRows('chat_messages', rows);
        }
      } catch (_) {}
    }
    return _db.queryAll('chat_messages', orderBy: 'sent_at ASC');
  }

  Future<void> sendChatMessage(
    String token, {
    required String senderUserId,
    required String senderName,
    required String senderRole,
    required String message,
    String? routeId,
  }) async {
    final id = _localId();
    await _db.upsertRow('chat_messages', {
      'id': id,
      'route_id': routeId ?? '',
      'sender_user_id': senderUserId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'message': message.trim(),
      'sent_at': _nowIso(),
      'pending_sync': 1,
    });
    if (token.isNotEmpty && !token.startsWith('mock_')) {
      try {
        final res = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}/chat'),
              headers: _headers(token),
              body: jsonEncode({'routeId': routeId, 'message': message.trim()}),
            )
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final remote = jsonDecode(res.body) as Map<String, dynamic>;
          await _db.deleteById('chat_messages', id);
          await _db.upsertRow('chat_messages', {
            'id': remote['id']?.toString() ?? id,
            'route_id': remote['routeId']?.toString() ?? '',
            'sender_user_id': remote['senderUserId']?.toString() ?? senderUserId,
            'sender_name': remote['senderName']?.toString() ?? senderName,
            'sender_role': remote['senderRole']?.toString() ?? senderRole,
            'message': remote['message']?.toString() ?? message.trim(),
            'sent_at': remote['sentAt']?.toString() ?? _nowIso(),
            'pending_sync': 0,
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _syncPendingCaregivers(String token) async {
    if (token.isEmpty || token.startsWith('mock_')) return;
    final pending = await _db.queryPending('authorized_caregivers');
    for (final row in pending) {
      try {
        final res = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}/caregivers'),
              headers: _headers(token),
              body: jsonEncode({
                'fullName': row['full_name'],
                'relationship': row['relationship'],
                'phoneNumber': row['phone_number'],
              }),
            )
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await _db.deleteById('authorized_caregivers', row['id'].toString());
        }
      } catch (_) {}
    }
  }

  Future<void> _syncPendingTickets(String token) async {
    if (token.isEmpty || token.startsWith('mock_')) return;
    final pending = await _db.queryPending('support_tickets');
    for (final row in pending) {
      try {
        final res = await _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}/support-tickets'),
              headers: _headers(token),
              body: jsonEncode({
                'category': row['category'],
                'subject': row['subject'],
                'message': row['message'],
              }),
            )
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await _db.deleteById('support_tickets', row['id'].toString());
        }
      } catch (_) {}
    }
  }
}
