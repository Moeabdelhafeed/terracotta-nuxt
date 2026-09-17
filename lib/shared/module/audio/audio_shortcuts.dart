import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What a key press means.
///
/// An intent rather than a direct callback so the map can be declared
/// `const` — one rebuilt every frame re-registers the lot on each one.
@immutable
class AudioShortcutIntent extends Intent {
  const AudioShortcutIntent(this.command);

  final AudioCommand command;
}

enum AudioCommand {
  playPause,
  skipBack,
  skipForward,
  previousTrack,
  nextTrack,
  speedUp,
  loop,
}

/// The keys a player answers to.
///
/// The same shape as the video module's, and the same reason for
/// `FocusableActionDetector` rather than a bare `Shortcuts`: shortcuts
/// only fire for a subtree that HAS focus, and a player is not a text
/// field, so nothing would ever give it any. Focus follows the
/// pointer, which is what makes the keys reach the player being
/// looked at when a page holds several.
///
/// The bindings are the ones a player is expected to have — space and
/// K for play, arrows for the skip, brackets for the queue. They are
/// deliberately NOT the media keys: those belong to the OS, and an app
/// that claimed them would take them from whatever is actually
/// playing.
class AudioShortcuts extends StatelessWidget {
  const AudioShortcuts({
    required this.enabled,
    required this.onCommand,
    required this.child,
    this.autofocus = false,
    super.key,
  });

  /// Off for a player in a list. A row of voice notes that each
  /// answered the space bar would answer it fifteen times.
  final bool enabled;

  /// Take focus on arrival. True for a player that IS the screen,
  /// false for one sharing a page.
  final bool autofocus;

  /// The only thing this needs from the player. Everything a key does
  /// is a decision about playback, and playback is not this widget's
  /// business — one callback keeps it that way rather than handing it
  /// seven.
  final ValueChanged<AudioCommand> onCommand;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return FocusableActionDetector(
      autofocus: autofocus,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): AudioShortcutIntent(
          AudioCommand.playPause,
        ),
        SingleActivator(LogicalKeyboardKey.keyK): AudioShortcutIntent(
          AudioCommand.playPause,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): AudioShortcutIntent(
          AudioCommand.skipBack,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight): AudioShortcutIntent(
          AudioCommand.skipForward,
        ),
        SingleActivator(LogicalKeyboardKey.bracketLeft): AudioShortcutIntent(
          AudioCommand.previousTrack,
        ),
        SingleActivator(LogicalKeyboardKey.bracketRight): AudioShortcutIntent(
          AudioCommand.nextTrack,
        ),
        SingleActivator(LogicalKeyboardKey.keyS): AudioShortcutIntent(
          AudioCommand.speedUp,
        ),
        SingleActivator(LogicalKeyboardKey.keyL): AudioShortcutIntent(
          AudioCommand.loop,
        ),
      },
      actions: <Type, Action<Intent>>{
        AudioShortcutIntent: CallbackAction<AudioShortcutIntent>(
          onInvoke: (intent) {
            onCommand(intent.command);
            return null;
          },
        ),
      },
      child: child,
    );
  }
}

/// What a command DOES, given a handle.
///
/// Pure dispatch, and separate from the widget for the reason the
/// video module's settings menu is: `GlobalAudioPlayer` cannot be
/// built under `flutter_test` at all, so a key map wired inside it
/// would have no coverage of any kind.
class AudioShortcutRunner {
  const AudioShortcutRunner._();

  /// Runs [command] against [handle]. [skipSeconds] comes from the
  /// resolved style, so the arrow keys move by the same amount the
  /// buttons do.
  static void run(
    AudioCommand command, {
    required AudioShortcutTarget handle,
    required int skipSeconds,
  }) {
    switch (command) {
      case AudioCommand.playPause:
        handle.toggle();
      case AudioCommand.skipBack:
        handle.skip(-skipSeconds);
      case AudioCommand.skipForward:
        handle.skip(skipSeconds);
      case AudioCommand.previousTrack:
        handle.previous();
      case AudioCommand.nextTrack:
        handle.next();
      case AudioCommand.speedUp:
        handle.cycleSpeed();
      case AudioCommand.loop:
        handle.toggleLoop();
    }
  }
}

/// The slice of the handle the keys touch.
///
/// Narrower than `AudioPlayerHandle` on purpose: a test can implement
/// seven methods, and implementing the whole handle — streams,
/// snapshots, scrub protocol — to prove that `]` means "next" would
/// be a fake bigger than the thing it checks.
abstract class AudioShortcutTarget {
  Future<void> toggle();
  Future<void> skip(int seconds);
  Future<void> previous();
  Future<void> next();
  Future<void> cycleSpeed();
  Future<void> toggleLoop();
}
