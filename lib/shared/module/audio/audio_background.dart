import 'package:flutter/foundation.dart';

import 'audio_models.dart';

/// What a player is currently playing, for whatever shows it outside
/// the app.
@immutable
class AudioNowPlaying {
  const AudioNowPlaying({
    required this.id,
    this.title,
    this.artist,
    this.artUri,
    this.duration,
  });

  /// Distinguishes one player from another. The source string, usually.
  final String id;

  final String? title;
  final String? artist;
  final String? artUri;
  final Duration? duration;
}

/// The controls a lock screen offers back.
@immutable
class AudioRemoteControls {
  const AudioRemoteControls({
    required this.play,
    required this.pause,
    required this.seek,
    this.skipForward,
    this.skipBackward,
  });

  final Future<void> Function() play;
  final Future<void> Function() pause;
  final Future<void> Function(Duration position) seek;
  final Future<void> Function()? skipForward;
  final Future<void> Function()? skipBackward;
}

/// The seam between a player and the lock screen.
///
/// An audio player that stops when the phone locks is not an audio
/// player — which is the one gap that separates this module from a
/// real one. What it needs, though, is a foreground service on Android
/// and a background mode on iOS, both declared in native config, plus
/// an `AudioHandler` that outlives every widget.
///
/// None of that belongs in `lib/shared/module`, which may not reach
/// the service layer at all. So the module ANNOUNCES and an app wires:
/// set [attach] and [detach] in `bootstrap` against `audio_service`,
/// or leave them null and the module stays exactly as it was.
///
/// The same shape as `VideoWakelock`, and for the same reason: an
/// un-wired seam is inert, which is also what keeps a widget test off
/// a platform channel.
///
/// Native setup an adopter has to do:
///
/// * **Android** — `AudioServiceActivity` as the launch activity, plus
///   the `foregroundServiceType="mediaPlayback"` service and its
///   permission in the manifest.
/// * **iOS** — the `audio` background mode in `Info.plist`.
///
/// Without those the OS stops the app the moment it is backgrounded,
/// and no amount of Dart makes it continue.
class AudioBackground {
  const AudioBackground._();

  /// Called when a player starts, with a way to control it.
  ///
  /// Returns a token the module hands back to [detach]. Null when
  /// nothing is wired, which is the default.
  static Object? Function(AudioNowPlaying, AudioRemoteControls)? attach;

  /// Called when that player goes away.
  static void Function(Object token)? detach;

  /// Called as playback moves, so the lock screen's scrubber can
  /// follow. Throttled by the caller — this is not a per-frame hook.
  static void Function(Object token, Duration position, bool playing)? report;

  /// Whether an app has wired any of this.
  static bool get isWired => attach != null;

  /// Forgets the wiring, so one test cannot decide the next one's
  /// answer.
  @visibleForTesting
  static void reset() {
    attach = null;
    detach = null;
    report = null;
  }
}

/// One player's hold on the lock screen.
///
/// Kept per player rather than globally: a page holds several, and the
/// one that goes away must release only its own.
class AudioBackgroundLink {
  Object? _token;
  bool? _lastPlaying;
  Duration? _lastPosition;

  /// Whether this player currently holds the lock screen.
  bool get isAttached => _token != null;

  /// Claims it, if an app wired anything and the caller said what is
  /// playing. Nothing to show is a reason not to show anything.
  void attach({
    required AudioNowPlaying? nowPlaying,
    required AudioRemoteControls controls,
  }) {
    if (_token != null || nowPlaying == null) return;
    _token = AudioBackground.attach?.call(nowPlaying, controls);
  }

  /// Moves the lock screen's scrubber. Throttled the same way
  /// `onPositionChanged` is — a play/pause flip always goes through,
  /// because that one changes a GLYPH rather than a number.
  void report(Duration position, {required bool playing}) {
    final token = _token;
    if (token == null) return;
    final last = _lastPosition;
    if (playing == _lastPlaying &&
        last != null &&
        (position - last).abs() < AudioDefaults.positionReportInterval) {
      return;
    }
    _lastPlaying = playing;
    _lastPosition = position;
    AudioBackground.report?.call(token, position, playing);
  }

  /// Releases it. Idempotent — `dispose` and an error path both call
  /// this.
  void detach() {
    final token = _token;
    if (token == null) return;
    _token = null;
    _lastPlaying = null;
    _lastPosition = null;
    AudioBackground.detach?.call(token);
  }
}
