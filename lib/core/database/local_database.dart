import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Structured SQLite relational offline cache & sync queue (sqflite),
/// while lightweight preferences (theme mode, language, session flags)
/// continue using SharedPreferences via SessionManager.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;
  bool _unavailable = false;
  final Map<String, List<Map<String, Object?>>> _memoryFallback = {};

  Future<Database?> get database async {
    if (_db != null) return _db;
    if (_unavailable) return null;
    try {
      if (kIsWeb) {
        _unavailable = true;
        return null;
      }
      final dbPath = await getDatabasesPath();
      final fullPath = p.join(dbPath, 'routeguard_local.db');
      _db = await openDatabase(
        fullPath,
        version: 1,
        onCreate: _onCreate,
      );
      return _db;
    } catch (_) {
      // Widget test bindings without sqflite_ffi fall back cleanly to in-memory rows.
      _unavailable = true;
      return null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_avatar_cache (
        user_id TEXT PRIMARY KEY,
        photo_data TEXT,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicle_docs_cache (
        id TEXT PRIMARY KEY,
        plate TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        soat_policy TEXT NOT NULL,
        soat_insurer TEXT NOT NULL,
        soat_expires_at TEXT NOT NULL,
        soat_valid INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS authorized_caregivers (
        id TEXT PRIMARY KEY,
        parent_id TEXT,
        full_name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        created_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS support_tickets (
        id TEXT PRIMARY KEY,
        ticket_code TEXT NOT NULL,
        category TEXT NOT NULL,
        subject TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trip_ratings (
        trip_id TEXT PRIMARY KEY,
        stars INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS absence_reports (
        id TEXT PRIMARY KEY,
        child_id TEXT,
        child_name TEXT NOT NULL,
        route_id TEXT,
        absence_date TEXT NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicle_maintenances (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT,
        vehicle_plate TEXT NOT NULL,
        maintenance_type TEXT NOT NULL,
        description TEXT NOT NULL,
        workshop TEXT NOT NULL,
        cost REAL NOT NULL,
        odometer_km INTEGER NOT NULL,
        performed_at TEXT NOT NULL,
        next_due_date TEXT,
        status TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS operational_expenses (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT,
        vehicle_plate TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS route_announcements (
        id TEXT PRIMARY KEY,
        route_id TEXT,
        author_name TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        priority TEXT NOT NULL,
        created_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pickup_change_requests (
        id TEXT PRIMARY KEY,
        child_id TEXT,
        child_name TEXT NOT NULL,
        route_id TEXT,
        target_date TEXT NOT NULL,
        new_address TEXT NOT NULL,
        reason TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        route_id TEXT,
        sender_user_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        sender_role TEXT NOT NULL,
        message TEXT NOT NULL,
        sent_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trip_history_cache (
        trip_id TEXT PRIMARY KEY,
        route_id TEXT,
        route_name TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        vehicle_plate TEXT NOT NULL,
        status TEXT NOT NULL,
        boarded_count INTEGER NOT NULL,
        total_students INTEGER NOT NULL,
        start_time TEXT,
        end_time TEXT,
        my_rating INTEGER,
        cancellation_reason TEXT
      )
    ''');
  }

  Future<void> upsertRow(String table, Map<String, Object?> values, {String pk = 'id'}) async {
    final db = await database;
    if (db != null) {
      await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }
    final list = _memoryFallback.putIfAbsent(table, () => []);
    final keyVal = values[pk];
    list.removeWhere((row) => row[pk] == keyVal);
    list.add(Map<String, Object?>.from(values));
  }

  Future<void> replaceSyncedRows(
    String table,
    List<Map<String, Object?>> rows, {
    String pk = 'id',
    bool hasPendingSync = true,
  }) async {
    final db = await database;
    if (db != null) {
      await db.transaction((txn) async {
        if (hasPendingSync) {
          await txn.delete(table, where: 'pending_sync = ?', whereArgs: [0]);
        } else {
          await txn.delete(table);
        }
        for (final r in rows) {
          await txn.insert(table, r, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
      return;
    }
    final list = _memoryFallback.putIfAbsent(table, () => []);
    if (hasPendingSync) {
      list.removeWhere((row) => (row['pending_sync'] ?? 0) == 0);
    } else {
      list.clear();
    }
    for (final r in rows) {
      final keyVal = r[pk];
      list.removeWhere((row) => row[pk] == keyVal);
      list.add(Map<String, Object?>.from(r));
    }
  }

  Future<List<Map<String, Object?>>> queryAll(String table, {String? orderBy}) async {
    final db = await database;
    if (db != null) {
      return db.query(table, orderBy: orderBy);
    }
    return List<Map<String, Object?>>.from(_memoryFallback[table] ?? const []);
  }

  Future<List<Map<String, Object?>>> queryPending(String table) async {
    final db = await database;
    if (db != null) {
      return db.query(table, where: 'pending_sync = ?', whereArgs: [1]);
    }
    return (_memoryFallback[table] ?? const [])
        .where((row) => (row['pending_sync'] ?? 0) == 1)
        .toList();
  }

  void clearMemoryForTesting() => _memoryFallback.clear();

  Future<void> deleteById(String table, String id, {String pk = 'id'}) async {
    final db = await database;
    if (db != null) {
      await db.delete(table, where: '$pk = ?', whereArgs: [id]);
      return;
    }
    _memoryFallback[table]?.removeWhere((row) => row[pk] == id);
  }
}
