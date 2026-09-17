import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What a key press means.
///
/// An intent rather than a direct callback so the shortcuts can be
/// declared `const` — a map rebuilt every frame would re-register the
/// lot on each one.
@immutable
class VideoShortcutIntent extends Intent {
  const VideoShortcutIntent(this.command);

  final VideoCommand command;
}

enum VideoCommand {
  playPause,
  seekBack,
  seekForward,
  volumeUp,
  volumeDown,
  mute,
  fullscreen,
  exitFullscreen,
}

/// The keys a player answers to.
///
///
/// `FocusableActionDetector` rather than a bare `Shortcuts`, because
/// shortcuts only fire for a subtree that HAS focus — and a video is
/// not a text field, so nothing would ever give it any. It takes
/// focus when the pointer enters, which is what makes the keys work
/// on the player being looked at when a page holds several.
class VideoShortcuts extends StatelessWidget {
  const VideoShortcuts({
    required this.enabled,
    required this.autofocus,
    required this.onCommand,
    required this.child,
    super.key,
  });

  final bool enabled;

  /// Take focus on arrival. True for a fullscreen page, which IS the
  /// screen, and false for a player sharing a page with other things.
  final bool autofocus;

  /// The only thing this needs from the player. Everything a key does
  /// is a decision about playback, and playback is not this widget's
  /// business — one callback keeps it that way rather than handing it
  /// nine.
  final ValueChanged<VideoCommand> onCommand;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return FocusableActionDetector(
      autofocus: autofocus,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): VideoShortcutIntent(
          VideoCommand.playPause,
        ),
        SingleActivator(LogicalKeyboardKey.keyK): VideoShortcutIntent(
          VideoCommand.playPause,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): VideoShortcutIntent(
          VideoCommand.seekBack,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight): VideoShortcutIntent(
          VideoCommand.seekForward,
        ),
        SingleActivator(LogicalKeyboardKey.arrowUp): VideoShortcutIntent(
          VideoCommand.volumeUp,
        ),
        SingleActivator(LogicalKeyboardKey.arrowDown): VideoShortcutIntent(
          VideoCommand.volumeDown,
        ),
        SingleActivator(LogicalKeyboardKey.keyM): VideoShortcutIntent(
          VideoCommand.mute,
        ),
        SingleActivator(LogicalKeyboardKey.keyF): VideoShortcutIntent(
          VideoCommand.fullscreen,
        ),
        SingleActivator(LogicalKeyboardKey.escape): VideoShortcutIntent(
          VideoCommand.exitFullscreen,
        ),
      },
      actions: <Type, Action<Intent>>{
        VideoShortcutIntent: CallbackAction<VideoShortcutIntent>(
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
