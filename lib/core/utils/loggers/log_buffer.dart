import 'dart:async';

import 'package:flutter/services.dart';

import '../../constants/enums/app/log_level.dart';

/// One captured log entry — the structured shape used by [LogBuffer] and
/// by `LogCapture.setCallback`. Holds everything the pretty console printer
/// emits, but without ANSI codes or box drawing — so it's safe to render
/// as a Flutter widget, copy to clipboard, or forward to a crash reporter.
class LogEntry {
  LogEntry({
    required this.seq,
    required this.time,
    required this.level,
    required this.name,
    required this.message,
  });

  /// Monotonic sequence number — matches the `[#N]` counter in the top bar.
  final int seq;

  /// When the log was emitted.
  final DateTime time;

  /// Log level.
  final LogLevel level;

  /// Source name (e.g. `APP`, `API`, a custom tag).
  final String name;

  /// Raw log message — unformatted, no ANSI, no box art.
  final String message;

  /// Human-readable one-liner — good default for copy-paste.
  /// Example: `10:35:24.021 INFO  [API] GET /users 200 312ms`
  String toPlain() {
    final ts = _formatTime(time);
    final lvl = level.name.toUpperCase().padRight(5);
    return '$ts $lvl [$name] $message';
  }

  /// Compact shape for bandwidth-constrained contexts (AI chats, SMS).
  /// Example: `I 10:35:24.021 API GET /users 200 312ms`
  String toCompact() {
    final ts = _formatTime(time);
    final lvl = level.name[0].toUpperCase();
    return '$lvl $ts $name $message';
  }
}

String _formatTime(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  String three(int n) => n.toString().padLeft(3, '0');
  return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}.${three(l.millisecond)}';
}

/// In-memory ring buffer of recent log entries.
///
/// Populated automatically every time a log is emitted (see [BaseLogger.log]).
/// Always on, cheap, and independent of `kDebugMode` so release-mode crash
/// reports or in-app bug-report flows can still pull recent history.
///
/// This is the data source designed to feed a future debug overlay / log
/// viewer page. The [onAdd] stream lets a UI rebuild live as entries arrive.
///
/// ```dart
/// // Copy the last 50 logs to the clipboard (e.g. from a debug shortcut):
/// await LogBuffer.copyRecentToClipboard();
///
/// // Live-update a log viewer widget:
/// final sub = LogBuffer.onAdd.listen((entry) => setState(() {}));
/// ```
class LogBuffer {
  LogBuffer._();

  /// Maximum number of entries retained. Older entries are dropped FIFO.
  /// Tweak at runtime — `LogBuffer.maxSize = 1000;`
  static int maxSize = 500;

  static final List<LogEntry> _entries = <LogEntry>[];
  static final StreamController<LogEntry> _controller =
      StreamController<LogEntry>.broadcast();

  /// Fires every time a new entry is appended. UIs subscribe to refresh.
  static Stream<LogEntry> get onAdd => _controller.stream;

  /// Immutable snapshot of the current buffer (oldest → newest).
  static List<LogEntry> get all => List.unmodifiable(_entries);

  /// Current number of retained entries.
  static int get length => _entries.length;

  /// Empty the buffer.
  static void clear() => _entries.clear();

  /// Append a new entry — invoked by [BaseLogger.log].
  /// Not meant to be called from app code.
  static void append(LogEntry entry) {
    _entries.add(entry);
    while (_entries.length > maxSize) {
      _entries.removeAt(0);
    }
    if (_controller.hasListener) _controller.add(entry);
  }

  /// Most recent [count] entries, newest first.
  /// Optional [minLevel] / [nameContains] filters for log-viewer UIs.
  static List<LogEntry> recent({
    int count = 50,
    LogLevel? minLevel,
    String? nameContains,
  }) {
    var it = _entries.reversed.where((_) => true);
    if (minLevel != null) {
      it = it.where((e) => e.level.index >= minLevel.index);
    }
    if (nameContains != null && nameContains.isNotEmpty) {
      final needle = nameContains.toLowerCase();
      it = it.where((e) => e.name.toLowerCase().contains(needle));
    }
    return it.take(count).toList();
  }

  ///32 Recent entries rendered as plain text — one line per entry.
  /// Pass `compact: true` for the short "AI-friendly" shape.
  static String recentPlain({
    int count = 50,
    LogLevel? minLevel,
    String? nameContains,
    bool compact = false,
  }) {
    final list = recent(
      count: count,
      minLevel: minLevel,
      nameContains: nameContains,
    );
    final b = StringBuffer();
    for (final e in list) {
      b.writeln(compact ? e.toCompact() : e.toPlain());
    }
    return b.toString();
  }

  /// Copy [recentPlain] output to the system clipboard.
  /// Returns the number of entries copied.
  static Future<int> copyRecentToClipboard({
    int count = 50,
    LogLevel? minLevel,
    String? nameContains,
    bool compact = false,
  }) async {
    final snapshot = recent(
      count: count,
      minLevel: minLevel,
      nameContains: nameContains,
    );
    final text = snapshot.reversed
        .map((e) => compact ? e.toCompact() : e.toPlain())
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    return snapshot.length;
  }
}
