import 'package:flutter/material.dart';

import '../buttons/button_internals.dart';
import '../buttons/global_icon_button.dart';

/// A control glyph.
///
/// `GlobalIconButton`, not the icon module's tap affordance, for two
/// reasons that both turned out to matter more than the palette
/// argument that kept it out at first:
///
/// - It CROSSFADES when the glyph changes, which is what a play button
///   toggling to a pause button should do. (That was broken until this
///   module asked for it — the switcher's child carried a constant key,
///   so `morphDuration` could never fire for an icon swap.)
/// - It enforces a 48dp touch target. These are small glyphs over film
///   and were easy to miss; a missed tap on the play button fell
///   through to the player's own double-tap handler and seeked ten
///   seconds instead.
///
/// The palette objection is answered by passing the colours EXPLICITLY:
/// `ButtonStateStyle` takes `foregroundColor` and `backgroundColor`, so
/// the button wears white-on-scrim like everything else here rather
/// than `context.primaryColors`.
///
/// [label] is REQUIRED. Every one of these is a bare icon on top of
/// film — there is no text anywhere near it for a reader to fall back
/// on, so a control that forgot to name itself announces nothing at
/// all. Making it required is what stops that happening again the next
/// time one is added.
class VideoControlButton extends StatelessWidget {
  const VideoControlButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.label,
    this.onTap,
    this.background,
    this.enabled,
    this.compactTarget = false,
    this.iconWidget,
  });

  /// Drawn instead of [icon], for a glyph that animates ITSELF.
  ///
  /// The play control uses it to carry an `AnimatedIcon`: a crossfade
  /// between two similar shapes reads as a flicker, where play folding
  /// into pause reads as the same control changing its mind.
  final Widget? iconWidget;

  final IconData icon;
  final double size;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final Color? background;

  /// Defaults to "has a callback". A popup ANCHOR sets this true with
  /// no `onTap` of its own: the popup owns the gesture, but the glyph
  /// must not dull itself as though nothing will happen.
  final bool? enabled;

  /// Gives up the 48dp touch target and lays out at the painted size.
  ///
  /// A DELIBERATE accessibility trade, taken only for the controls in
  /// the corners and along the edges. `MinTouchTarget` reserves 48dp in
  /// layout, and four of those across a bar over a small player is most
  /// of its width — the bar read as mostly empty space. The centre
  /// transport keeps its full target, because that is the group people
  /// actually aim at in a hurry and the group whose mis-taps fell
  /// through to the double-tap seek.
  final bool compactTarget;

  @override
  Widget build(BuildContext context) => GlobalIconButton(
    iconData: iconWidget == null ? icon : null,
    iconWidget: iconWidget,
    iconSize: size,
    onPressed: onTap,
    enabled: enabled ?? onTap != null,
    semanticLabel: label,
    enforceMinTouchTarget: !compactTarget,
    style: ButtonStateStyle(
      foregroundColor: color,
      backgroundColor: background ?? Colors.transparent,
      borderRadius: BorderRadius.circular(size),
      // Sized to the GLYPH, not to the touch target.
      //
      // Left unset, the painted box falls back to `kMinTouchTarget` —
      // measured, 48x48 around a 20pt gear — so the ink circle and the
      // scrim disc stood a long way off the icon they belonged to. The
      // 48dp target is not lost by shrinking this: `MinTouchTarget`
      // expands the HIT area without stretching what is painted, which
      // is the whole reason it exists.
      width: size * (background != null ? discFactor : bareFactor),
      height: size * (background != null ? discFactor : bareFactor),
    ),
  );

  /// A glyph on a scrim needs room for the disc to read as a disc.
  static const discFactor = 1.5;

  /// A bare glyph only needs enough for its own ink.
  ///
  /// Public because the adaptive bar has to know how wide one of these
  /// is BEFORE laying it out — a fit computed against a guessed width
  /// is a fit that drifts the moment this changes.
  static const bareFactor = 1.35;
}

/// The transport's play control, which MORPHS rather than crossfading.
///
/// A crossfade between play and pause reads as a flicker: the two
/// glyphs occupy the same space with similar mass, so 200ms of one
/// fading into the other looks like a redraw rather than a change.
/// `AnimatedIcons.play_pause` folds the triangle into the bars, which
/// is the same control visibly changing its mind.
///
/// Replay is NOT part of that pair — Material has no play-to-replay
/// morph, and inventing one would mean drawing it. After the end the
/// button crossfades to the replay glyph instead, which is honest: it
/// is a different control, not the same one in another state.
class VideoPlayPauseButton extends StatefulWidget {
  const VideoPlayPauseButton({
    required this.playing,
    required this.completed,
    required this.replayIcon,
    required this.size,
    required this.color,
    required this.label,
    required this.onTap,
    this.background,
    this.compactTarget = false,
    super.key,
  });

  final bool playing;

  /// After the end the control is a REPLAY button, not a play button.
  final bool completed;

  final IconData replayIcon;
  final double size;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final Color? background;

  /// Gives up the 48dp reservation, like every other control in a bar.
  ///
  /// It was missing here, so the inline transport had one button
  /// holding 48 points of layout while its neighbours held 32 — which
  /// is the gap that made the row look padded out.
  final bool compactTarget;

  @override
  State<VideoPlayPauseButton> createState() => _VideoPlayPauseButtonState();
}

class _VideoPlayPauseButtonState extends State<VideoPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: kMorphDuration,
    // Starts AT its state rather than animating to it — a player that
    // is already playing when it appears should not fold into pause on
    // its first frame.
    value: widget.playing ? 1 : 0,
  );

  @override
  void didUpdateWidget(VideoPlayPauseButton old) {
    super.didUpdateWidget(old);
    if (widget.playing == old.playing) return;
    widget.playing ? _morph.forward() : _morph.reverse();
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce motion means no moving CHROME. The film keeps playing;
    // this is a glyph.
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) _morph.value = widget.playing ? 1 : 0;

    return VideoControlButton(
      icon: widget.replayIcon,
      size: widget.size,
      color: widget.color,
      label: widget.label,
      onTap: widget.onTap,
      background: widget.background,
      compactTarget: widget.compactTarget,
      iconWidget: widget.completed
          ? null
          : AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _morph,
              size: widget.size,
              color: widget.color,
            ),
    );
  }
}

/// A control whose VALUE is the thing worth showing.
///
/// Playback speed is the case: `1.5x` says what a glyph cannot, and a
/// speed control that shows a stopwatch makes the reader open it to
/// find out where they are. Sized and coloured like the glyphs beside
/// it so the bar keeps one weight.
class VideoTextControl extends StatelessWidget {
  const VideoTextControl({
    required this.text,
    required this.label,
    required this.color,
    required this.fontSize,
    required this.onTap,
    super.key,
  });

  final String text;

  /// What a screen reader hears — the value alone ("1.5x") does not say
  /// what it is the speed OF.
  final String label;

  final Color color;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    value: text,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Matches what a compact glyph control takes, so the bar's
        // rhythm survives one of these appearing in it.
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.4),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            // Otherwise the bar twitches as 1x becomes 1.25x.
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ),
  );
}
