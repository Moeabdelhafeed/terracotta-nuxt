import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/loggers/logger.dart';
import 'connectivity_cubit.dart';
import 'connectivity_state.dart';
import 'offline_action.dart';

/// Persistent FIFO queue of mutations that failed offline. Drains
/// automatically when [ConnectivityCubit] reports recovery, and on
/// demand via [flush].
///
/// Caller flow:
/// 1. Register replayers per kind on boot:
///    `queue.registerReplayer('http.post', myPostReplayer)`
/// 2. When a network call fails offline, call
///    `queue.enqueue(OfflineAction(kind: 'http.post', payload: ...))`
/// 3. On reconnect the queue auto-drains. Each action is run through
///    its registered replayer; the [ReplayResult] decides keep / drop.
///
/// Persistence: JSON file at `<appDocs>/offline_queue.json`. Survives
/// cold start. Corrupt file is logged and cleared on next boot.
class OfflineActionQueue {
  OfflineActionQueue({required this.cubit});

  final ConnectivityCubit cubit;

  final List<OfflineAction> _items = [];
  final Map<String, OfflineActionReplayer> _replayers = {};

  StreamSubscription<ConnectivityState>? _sub;
  bool _started = false;
  bool _draining = false;
  File? _file;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _loadFromDisk();
    _publishCount();
    _sub = cubit.stream.listen((state) {
      if (state.justRecovered || state.online && _items.isNotEmpty) {
        unawaited(flush());
      }
    });
  }

  void registerReplayer(String kind, OfflineActionReplayer replayer) {
    _replayers[kind] = replayer;
  }

  /// Append an action to the queue. Idempotent on `id` — re-enqueuing
  /// the same id no-ops (handy when callers retry their own catch
  /// blocks).
  Future<void> enqueue(OfflineAction action) async {
    if (_items.any((a) => a.id == action.id)) return;
    _items.add(
      action.copyWith(
        attempts: action.attempts,
      ),
    );
    _publishCount();
    await _persist();
    Logger.m.d('[OfflineQueue] enqueued ${action.kind} (${action.id})');
  }

  /// Manually drain the queue. Returns the number of actions that
  /// finished (success or drop). Safe to call when offline — replayers
  /// will see the failure and return retry, leaving the queue intact.
  Future<int> flush() async {
    if (_draining) return 0;
    if (_items.isEmpty) return 0;
    _draining = true;
    var finished = 0;
    try {
      // Iterate over a snapshot so we can mutate the list as we go.
      final snapshot = List<OfflineAction>.from(_items);
      for (final action in snapshot) {
        final replayer = _replayers[action.kind];
        if (replayer == null) {
          Logger.m.w('[OfflineQueue] no replayer for ${action.kind}; dropping');
          _items.removeWhere((a) => a.id == action.id);
          finished++;
          continue;
        }
        try {
          final outcome = await replayer(action);
          switch (outcome) {
            case ReplayResult.success:
              _items.removeWhere((a) => a.id == action.id);
              finished++;
            case ReplayResult.drop:
              _items.removeWhere((a) => a.id == action.id);
              finished++;
            case ReplayResult.retry:
              final idx = _items.indexWhere((a) => a.id == action.id);
              if (idx == -1) break;
              final next = _items[idx].copyWith(
                attempts: _items[idx].attempts + 1,
              );
              if (next.attempts >= next.maxAttempts) {
                _items.removeAt(idx);
                finished++;
                Logger.m.w(
                  '[OfflineQueue] giving up on ${action.kind} (${action.id}) '
                  'after ${next.attempts} attempts',
                );
              } else {
                _items[idx] = next;
              }
          }
        } catch (e, st) {
          Logger.m.e('[OfflineQueue] replayer threw', error: e, stackTrace: st);
          // Treat as retry; the next reconnect will try again.
        }
      }
    } finally {
      _publishCount();
      await _persist();
      _draining = false;
    }
    return finished;
  }

  /// Drop everything — used by logout / "forget me" flows.
  Future<void> clear() async {
    _items.clear();
    _publishCount();
    await _persist();
  }

  int get length => _items.length;
  List<OfflineAction> snapshot() => List.unmodifiable(_items);

  // ─── Persistence ──────────────────────────────────────────

  Future<File> _resolveFile() async {
    final cached = _file;
    if (cached != null) return cached;
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/offline_queue.json');
    _file = f;
    return f;
  }

  Future<void> _loadFromDisk() async {
    // Web: no `dart:io` File access. Queue stays in-memory only —
    // entries are lost on tab close. Acceptable trade-off — alternative
    // would be IndexedDB, out of scope for the template.
    if (kIsWeb) return;
    try {
      final f = await _resolveFile();
      if (!await f.exists()) return;
      final raw = await f.readAsString();
      if (raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _items
        ..clear()
        ..addAll(
          decoded.whereType<Map<String, dynamic>>().map(OfflineAction.fromJson),
        );
      Logger.m.d('[OfflineQueue] loaded ${_items.length} pending');
    } catch (e, st) {
      Logger.m.e(
        '[OfflineQueue] load failed — clearing',
        error: e,
        stackTrace: st,
      );
      // Corrupt JSON on disk — wipe so we don't loop on every boot.
      try {
        final f = await _resolveFile();
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    if (kIsWeb) return; // see _loadFromDisk
    try {
      final f = await _resolveFile();
      final encoded = jsonEncode(_items.map((a) => a.toJson()).toList());
      await f.writeAsString(encoded, flush: true);
    } catch (e, st) {
      Logger.m.e('[OfflineQueue] persist failed', error: e, stackTrace: st);
    }
  }

  void _publishCount() {
    cubit.setQueuedActions(_items.length);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }
}
