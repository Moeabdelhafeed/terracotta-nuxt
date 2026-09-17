import 'dart:async';

import 'package:media_kit/media_kit.dart';

import '../../../core/utils/loggers/logger.dart';

/// Singleton that manages all active [Player] instances across the app.
///
/// Enforces a maximum number of concurrently playing videos to avoid
/// resource exhaustion, and provides central dispose-all capability.
class VideoPlayerManager {
  VideoPlayerManager._();
  static final VideoPlayerManager instance = VideoPlayerManager._();

  /// Maximum number of videos that can play simultaneously.
  /// Oldest playing video is paused when this limit is exceeded.
  int maxConcurrentPlayers = 1;

  /// All registered player entries (both playing and paused).
  final List<_PlayerEntry> _entries = [];

  /// Register a player when a GlobalVideo widget is created.
  void register(Player player) {
    final sub = player.stream.playing.listen((playing) {
      if (playing) _onPlayerStarted(player);
    });
    _entries.add(_PlayerEntry(player: player, subscription: sub));
  }

  /// Unregister a player when a GlobalVideo widget is disposed.
  void unregister(Player player) {
    final idx = _entries.indexWhere((e) => e.player == player);
    if (idx != -1) {
      _entries[idx].subscription.cancel();
      _entries.removeAt(idx);
    }
  }

  /// Called when any player starts playing.
  void _onPlayerStarted(Player player) {
    // Find entry — if not found (already unregistered), bail out
    final idx = _entries.indexWhere((e) => e.player == player);
    if (idx == -1) return;

    _entries[idx].lastPlayedAt = DateTime.now();

    // Get all currently playing entries
    final playing = _entries.where((e) {
      try {
        return e.player.state.playing;
      } catch (_) {
        return false;
      }
    }).toList();

    if (playing.length > maxConcurrentPlayers) {
      playing.sort((a, b) => a.lastPlayedAt.compareTo(b.lastPlayedAt));

      final toStop = playing.length - maxConcurrentPlayers;
      for (var i = 0; i < toStop; i++) {
        final target = playing[i].player;
        if (target != player) {
          Logger.m.d('[Video] paused a player to stay within the cap');
          try {
            target.pause();
          } catch (_) {}
        }
      }
    }
  }

  /// Pause all playing videos. Useful when navigating away from a screen.
  void pauseAll() {
    for (final entry in _entries) {
      try {
        if (entry.player.state.playing) entry.player.pause();
      } catch (_) {}
    }
  }

  /// Dispose all registered players. Call on app shutdown or major navigation.
  void disposeAll() {
    for (final entry in List.of(_entries)) {
      try {
        entry.subscription.cancel();
        entry.player.dispose();
      } catch (_) {}
    }
    _entries.clear();
  }

  /// Number of currently registered players.
  int get registeredCount => _entries.length;

  /// Number of currently playing players.
  int get playingCount {
    var count = 0;
    for (final entry in _entries) {
      try {
        if (entry.player.state.playing) count++;
      } catch (_) {}
    }
    return count;
  }
}

class _PlayerEntry {
  _PlayerEntry({required this.player, required this.subscription})
    : lastPlayedAt = DateTime.now();

  final Player player;
  final StreamSubscription<bool> subscription;
  DateTime lastPlayedAt;
}
