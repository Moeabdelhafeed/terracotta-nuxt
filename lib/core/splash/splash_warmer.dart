import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

import 'splash_models.dart';

/// Pre-warm video / image assets before the splash mounts so the
/// first frame doesn't stutter while codecs spin up and bytes load.
///
/// Lifecycle:
/// 1. **bootstrap()** calls [warmupVideo] for the configured hero.
/// 2. The warmer opens a `Player`, awaits the first `duration`
///    emission, and parks the video paused at frame 0.
/// 3. **`SplashPage` build()** calls [takePlayer] — receives the
///    already-buffered player, attaches a `Video` widget, calls
///    `play()`. First frame paints immediately.
/// 4. **`SplashPage` dispose()** disposes the handed-off player so
///    it doesn't leak.
///
/// Singleton because the splash is unique per app launch. Reset
/// safely in tests via [reset].
class SplashWarmer {
  SplashWarmer._();
  static final SplashWarmer instance = SplashWarmer._();

  /// Resolves when bootstrap finishes its async tail (RC fetch,
  /// language preload, etc). `SplashPage` `await`s this when
  /// `SplashOptions.waitForBootstrap` is true so deferred work
  /// overlaps the splash hold.
  final Completer<void> _bootstrapDone = Completer<void>();
  Future<void> get bootstrapDone => _bootstrapDone.future;
  void signalBootstrapDone() {
    if (!_bootstrapDone.isCompleted) _bootstrapDone.complete();
  }

  Player? _player;
  Duration? _warmedDuration;

  /// Pre-warmed player for the configured video hero. `null` until
  /// [warmupVideo] resolves.
  Player? get player => _player;

  /// Duration reported by the player during warm-up. Used by the
  /// orchestrator to compute total splash time (duration × minLoops
  /// + minDuration + extraDelay).
  Duration? get warmedDuration => _warmedDuration;

  /// Opens a [Player] for [hero], primes the codec + buffer, and
  /// resolves once `state.duration` emits a non-zero value. Safe to
  /// call multiple times — subsequent calls are no-ops while a
  /// player is already warm.
  ///
  /// For `.network` sources, the URL is opened directly. To cut
  /// first-launch network latency, adopters should download the
  /// video once via `DownloadService`, persist it to app docs, and
  /// pass [SplashVideoSource.file] instead.
  Future<void> warmupVideo(SplashVideoHero hero) async {
    if (_player != null) return;
    final player = Player();
    _player = player;
    try {
      final mediaPath = _resolveMedia(hero.source);
      await player.open(Media(mediaPath), play: false);
      if (hero.muted) await player.setVolume(0);
      // Wait for duration to settle. media_kit's `open` returns
      // before metadata is fully parsed on some codecs — block on
      // the first non-zero duration emission with a hard ceiling.
      _warmedDuration = await _firstDuration(player).timeout(
        const Duration(seconds: 6),
        onTimeout: () => Duration.zero,
      );
    } catch (e, st) {
      debugPrint('[SplashWarmer] warmup failed: $e');
      debugPrintStack(stackTrace: st);
      await player.dispose();
      _player = null;
    }
  }

  /// Pre-decode a bundled image so the first paint is instant.
  /// Caller hands the same key into `Image.asset` later — Flutter's
  /// image cache returns the cached frame.
  Future<void> precacheSplashImage(
    String assetPath,
    BuildContext? context,
  ) async {
    if (context != null && context.mounted) {
      await precacheImage(AssetImage(assetPath), context);
    } else {
      // No context yet — at least force the bytes into the bundle
      // cache so `Image.asset` doesn't block on rootBundle later.
      try {
        await rootBundle.load(assetPath);
      } catch (_) {}
    }
  }

  /// Hand the warmed player to the orchestrator. After this returns,
  /// the warmer no longer owns the player — caller must dispose.
  Player? takePlayer() {
    final p = _player;
    _player = null;
    return p;
  }

  /// Release without handing off (e.g. tap-to-skip before video
  /// even shows, or hot reload).
  Future<void> release() async {
    final p = _player;
    _player = null;
    _warmedDuration = null;
    if (p != null) {
      try {
        await p.dispose();
      } catch (_) {}
    }
  }

  /// Test-only — reset singleton state.
  @visibleForTesting
  void reset() {
    _player?.dispose();
    _player = null;
    _warmedDuration = null;
  }

  String _resolveMedia(SplashVideoSource source) => switch (source) {
    SplashVideoAsset(:final path) => 'asset:///$path',
    SplashVideoFile(:final path) => path,
    SplashVideoNetwork(:final url) => url,
  };

  Future<Duration> _firstDuration(Player player) async {
    final completer = Completer<Duration>();
    final sub = player.stream.duration.listen((d) {
      if (d > Duration.zero && !completer.isCompleted) {
        completer.complete(d);
      }
    });
    final result = await completer.future;
    await sub.cancel();
    return result;
  }
}
