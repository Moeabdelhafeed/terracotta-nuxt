import 'package:flutter/foundation.dart';

/// Whether this DEVICE can play sound at all.
///
/// mpv reports "Could not open/initialize audio device" when there is
/// no output — routinely on a simulator, and on a desktop with no
/// default device. It is a property of the machine, not of one clip,
/// and modelling it as widget state got three things wrong:
///
/// - **The warning was logged once per PLAYER.** Five on a page meant
///   five identical warnings, and the whole point of the de-duplication
///   was that this failure repeats forever.
/// - **Fullscreen and PiP never heard about it.** The flag lived on the
///   inline widget's state and was passed to its own controls only, so
///   the same mute button was guarded in one place and live in the
///   other two — and the inline state may not even exist any more by
///   then, having handed its player over.
/// - **Only the button was guarded.** A volume SWIPE moved a bar that
///   could not change anything.
///
/// One flag for the app, and everything that offers a volume control
/// reads it.
class VideoAudioOutput {
  const VideoAudioOutput._();

  /// True once any player has found there is nowhere to send sound.
  ///
  /// A `ValueNotifier` rather than a bare bool because the discovery
  /// arrives asynchronously, up to a second after a player starts —
  /// controls already built have to hear about it.
  static final ValueNotifier<bool> unavailable = ValueNotifier(false);

  /// Records that there is no output device.
  ///
  /// Returns true only the FIRST time, which is what keeps one warning
  /// in the log instead of one per player.
  static bool report() {
    if (unavailable.value) return false;
    unavailable.value = true;
    return true;
  }

  /// Forgets it, so one test cannot decide the next one's answer.
  @visibleForTesting
  static void reset() => unavailable.value = false;
}
