import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Singleton that tracks every active [AudioPlayer] in the app and
/// enforces a configurable cap on how many can play at once. Mirrors
/// [VideoPlayerManager] — when a new player starts and the cap is
/// exceeded, the oldest playing instance is paused.
///
/// Defaults to 1 (chat / list ergonomics). Music-app shells can bump
/// it via `AudioPlayerManager.instance.maxConcurrentPlayers = N`.
class AudioPlayerManager {
  AudioPlayerManager._();
  static final AudioPlayerManager instance = AudioPlayerManager._();

  /// Max simultaneous playing instances. New plays beyond this pause
  /// the oldest. Set to a high value for music-app scenarios.
  int maxConcurrentPlayers = 1;

  final List<_Entry> _entries = [];

  /// Register on widget mount. Manager subscribes to the player's
  /// state stream to react to play / pause edges.
  void register(AudioPlayer player) {
    if (_entries.any((e) => identical(e.player, player))) return;
    final entry = _Entry(player);
    entry.sub = player.playerStateStream.listen((state) {
      if (state.playing) _enforceCap(player);
    });
    _entries.add(entry);
  }

  /// Unregister on widget dispose. Cancels the listener so the manager
  /// doesn't keep a dead player alive.
  void unregister(AudioPlayer player) {
    final idx = _entries.indexWhere((e) => identical(e.player, player));
    if (idx < 0) return;
    _entries[idx].sub?.cancel();
    _entries.removeAt(idx);
  }

  /// Number of registered players (playing or paused).
  int get registeredCount => _entries.length;

  /// Pause every registered player. Useful on logout or major route
  /// transitions where the app wants silence regardless of intent.
  Future<void> pauseAll() async {
    for (final e in _entries) {
      if (e.player.playing) await e.player.pause();
    }
  }

  void _enforceCap(AudioPlayer trigger) {
    // Bump the trigger to "most recently played" so it isn't the one
    // we evict.
    final triggerIdx = _entries.indexWhere((e) => identical(e.player, trigger));
    if (triggerIdx >= 0) {
      final entry = _entries.removeAt(triggerIdx)
        ..lastStartedAt = DateTime.now();
      _entries.add(entry);
    }

    final playing = _entries.where((e) => e.player.playing).toList();
    if (playing.length <= maxConcurrentPlayers) return;

    // Sort by lastStartedAt asc; pause the oldest until we're in range.
    playing.sort((a, b) => a.lastStartedAt.compareTo(b.lastStartedAt));
    final toPause = playing.length - maxConcurrentPlayers;
    for (var i = 0; i < toPause; i++) {
      if (identical(playing[i].player, trigger)) continue;
      if (kDebugMode) {
        debugPrint(
          'AudioPlayerManager: pausing older player to stay within '
          'limit ($maxConcurrentPlayers).',
        );
      }
      playing[i].player.pause();
    }
  }
}

class _Entry {
  _Entry(this.player) : lastStartedAt = DateTime.now();

  final AudioPlayer player;
  StreamSubscription<PlayerState>? sub;
  DateTime lastStartedAt;
}
