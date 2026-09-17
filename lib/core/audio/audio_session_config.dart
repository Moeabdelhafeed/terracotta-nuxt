import 'package:audio_session/audio_session.dart';

/// Configure the iOS [AVAudioSession] so the app's audio:
///   * plays through the speaker (not earpiece) by default,
///   * ducks other apps' audio instead of stopping them,
///   * survives the lock screen (combined with `UIBackgroundModes:
///     audio` in Info.plist).
///
/// Idempotent — first caller wins; subsequent calls return the same
/// already-configured session.
Future<AudioSession> configureAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ),
  );
  return session;
}
