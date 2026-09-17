import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Persisted notification row — one entry in the in-app inbox.
///
/// Colocated with the rest of the notifications data layer because
/// `NotificationHistoryService` is its only caller. If you add REST or
/// realtime variants later, consider splitting model from DB helper.
///
/// ## Why this model isn't Freezed
///
/// Every other model under `data/model/` uses Freezed +
/// `json_serializable` because their serialization target is the JSON
/// wire format. This model's serialization target is a **SQLite row**:
///
///  - `isRead` is persisted as `0/1` (int), not `true/false` (bool) —
///    Freezed's `toJson` would emit the wrong shape.
///  - `timestamp` is persisted as an ISO-8601 string, not a millis int.
///  - `data` is an opaque JSON-encoded blob stored in a single TEXT
///    column — Freezed can't represent "serialize to a string" cleanly.
///
/// Writing custom converters for every field to bridge Freezed's
/// `toJson` with SQLite's schema is more code than just hand-rolling
/// `toMap` / `fromMap` with `dart:convert`. The model stays small (~50
/// lines), is clear, and has no build-time dependency.
///
/// If you ever need this shape over the wire too, split: a Freezed
/// `NotificationDto` for JSON + this class for SQLite + a mapper.
class NotificationModel {
  const NotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  /// Arbitrary payload — serialized as a JSON string in the `data`
  /// column and decoded back on read.
  final Map<String, dynamic>? data;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'data': data == null ? null : jsonEncode(data),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: (map['isRead'] as int?) == 1,
      data: _decodeData(map['data']),
    );
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  static Map<String, dynamic>? _decodeData(dynamic raw) {
    if (raw == null) return null;
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (e) {
      debugPrint('[NotificationModel] data decode failed: $e');
    }
    return null;
  }
}

/// SQLite-backed persistence for [NotificationModel]. Hand-rolled
/// because the schema is tiny (one table, six columns) — a full ORM
/// would be overkill.
///
/// Thread-unsafe across isolates; in a normal Flutter app all DB
/// access happens on the UI isolate which is fine. Background FCM
/// isolate must not call these methods.
class NotificationDatabase {
  NotificationDatabase._();

  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'notifications.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE notifications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            body TEXT,
            timestamp TEXT,
            isRead INTEGER,
            data TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE notifications ADD COLUMN data TEXT');
        }
      },
    );
  }

  static Future<void> insertNotification(NotificationModel notification) async {
    final db = await database;
    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<NotificationModel>> getNotifications() async {
    final db = await database;
    final rows = await db.query('notifications', orderBy: 'timestamp DESC');
    return rows.map(NotificationModel.fromMap).toList();
  }

  static Future<void> markAsRead(int id) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> markAllAsRead() async {
    final db = await database;
    await db.update('notifications', {'isRead': 1});
  }

  static Future<void> deleteNotification(int id) async {
    final db = await database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAllNotifications() async {
    final db = await database;
    await db.delete('notifications');
  }

  static Future<int> getUnreadCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE isRead = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
