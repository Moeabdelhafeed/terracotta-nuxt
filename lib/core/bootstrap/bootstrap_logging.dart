import 'package:flutter/foundation.dart';

import '../flavor/flavor.dart';
import '../flavor/flavor_config.dart';
import '../utils/loggers/logger.dart';

/// Apply the per-flavor logger config and emit the boot banner. Throws
/// in a production release if the flavor is missing required dart-defines.
void setupLogging(Flavor flavor, FlavorConfig config) {
  // Quieter, release-safe logger config in release builds — or whenever
  // the flavor disabled verbose logs.
  if (kReleaseMode || !config.enableLogs) {
    Logger.configureWithConfig(LoggerConfig.production());
  }

  Logger.m.i(
    '[bootstrap] flavor=${flavor.displayName} '
    'api=${config.apiBaseUrl.isEmpty ? '<unset>' : config.apiBaseUrl} '
    'lock=${flavor.requiresBuildLock ? 'required' : 'off'}',
  );

  final missing = config.missingRequiredFields;
  if (missing.isNotEmpty) {
    final msg =
        '[bootstrap] missing required dart-define values for '
        '${flavor.displayName}: ${missing.join(', ')}. '
        'Did you forget --dart-define-from-file=config/${flavor.name}.json?';
    if (kReleaseMode && flavor.isProduction) {
      throw StateError(msg);
    }
    Logger.m.w(msg);
  }
}

/// Reroute Flutter's `debugPrint` through the project logger so every
/// stray `print()` lands in the same stream as `Logger.m`.
///
/// `FlutterError.onError` is installed by `GlobalErrorHandler.install`,
/// not here — see `lib/core/error/error_boundary.dart`.
void setupDebugPrintRedirect() {
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null || isLogNoise(message)) return;
    Logger.m.i(message);
  };
}

/// Lines a DEPENDENCY prints on every frame of ordinary operation.
///
/// Shared by BOTH doors into the log. `debugPrint` is one; the zone's
/// `print` hook in `bootstrap_zone.dart` is the other, and it used to
/// have no filter at all — the same noise arrived twice and only one
/// copy was caught.
///
/// `debugPrint` is a package's way of talking to whoever is watching,
/// and most of them use it sparingly. media_kit_video does not: it
/// echoes every method call and every argument map across its platform
/// channel, so a page of players emits a `VideoOutput.Resize`, a
/// texture id and a raw `{handle: …, rect: …}` map for each one, twice
/// — once at mount and once when the real dimensions arrive. That is
/// four lines per player before anything has happened, and it buries
/// what the app itself is saying.
///
/// Dropped rather than demoted to debug, because they carry nothing:
/// the texture id is meaningless outside the plugin and the rect is
/// always either `0x0` or the video's own size. An mpv WARNING or
/// error is not matched here and still comes through.
bool isLogNoise(String message) {
  // A `print` with nothing in it, or with a bare null in it.
  //
  // Every logging call site in this app is tagged — `[Auth]`,
  // `[Image]`, `[bootstrap]` — so a line reading exactly `null` cannot
  // have come from one. It is some dependency printing a variable that
  // happened to be null, which says nothing and names nobody: no tag,
  // no value, and no way to tell from the log which package emitted
  // it. Scrolling a grid of network images produced a stream of them.
  final trimmed = message.trim();
  if (trimmed.isEmpty || trimmed == 'null') return true;

  // media_kit_video's platform-channel echo.
  if (message.startsWith('VideoOutput.')) return true;
  if (message.startsWith('NativeVideoController: Texture ID:')) return true;
  // The argument map that follows each of those, printed bare.
  if (message.startsWith('{') &&
      message.contains('handle:') &&
      message.contains('rect:')) {
    return true;
  }
  return false;
}
