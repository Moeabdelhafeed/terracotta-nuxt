import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../progress/global_progress.dart';
import '../tooltip/global_tooltip.dart';
import 'audio_models.dart';

// The three control surfaces the chrome is built from. They left
// `global_audio.dart` because they are self-contained — no state, no
// knowledge of the player around them — and that file held two
// backend lifecycles as well.

// ─── Play / pause / loading button ────────────────────────────

class AudioPlayButton extends StatelessWidget {
  const AudioPlayButton({
    required this.playing,
    required this.loading,
    required this.errored,
    required this.color,
    required this.onTap,
    this.size = 40,
    this.gradient,
    this.shadow,
  });

  final bool playing;
  final bool loading;
  final bool errored;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;

  /// What a reader hears. The glyph is the only thing here, so a
  /// button that did not name itself would announce nothing at all.
  String get _label => errored
      ? AudioStrings.retry
      : loading
      ? AudioStrings.loading
      : (playing ? AudioStrings.pause : AudioStrings.play);

  @override
  Widget build(BuildContext context) {
    final iconSize = size * AudioDefaults.playGlyphRatio;
    // Pick fg from the gradient's first stop when present, else the
    // solid color — keeps contrast right under either path.
    final swatch = gradient is LinearGradient
        ? (gradient! as LinearGradient).colors.first
        : color;
    final fg = ThemeData.estimateBrightnessForColor(swatch) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    final inner = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: errored
            ? Icon(Icons.error_rounded, color: fg, size: iconSize)
            : loading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: GlobalProgress.loading(
                  type: ProgressType.circular,
                  style: ProgressStyle(thickness: 2, color: fg),
                ),
              )
            : Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: fg,
                size: iconSize,
              ),
      ),
    );

    // ONE node for the button, and the glyph inside it excluded — a
    // reader wants "Pause, button", not an icon announced beside it.
    Widget named(Widget child) => Semantics(
      button: true,
      enabled: !loading,
      label: _label,
      excludeSemantics: true,
      child: child,
    );

    // Gradient + shadow path: wrap in DecoratedBox first so the shape
    // / shadow renders below the ink, then add a Material+InkWell on
    // top for the splash. Material is transparent so the gradient
    // shows through.
    if (gradient != null || shadow != null) {
      return named(
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gradient == null ? color : null,
            gradient: gradient,
            boxShadow: shadow,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: inner,
            ),
          ),
        ),
      );
    }

    return named(
      Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: inner,
        ),
      ),
    );
  }
}

// ─── Circular icon button (skip ±10s) ─────────────────────────

class AudioCircleButton extends StatelessWidget {
  const AudioCircleButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.label,
    this.tooltip,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  /// REQUIRED, not optional. These are bare glyphs with no text near
  /// them, so one that forgot to name itself would announce nothing —
  /// and `tooltip` cannot stand in for it: a tooltip is what a POINTER
  /// discovers, and the readers who need this have no pointer.
  final String label;

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: AudioDefaults.circleButtonSize,
          height: AudioDefaults.circleButtonSize,
          child: Icon(
            icon,
            color: color.withValues(alpha: AudioDefaults.controlIconOpacity),
            size: AudioDefaults.circleIconSize,
          ),
        ),
      ),
    );
    final named = Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: btn,
    );
    return tooltip == null
        ? named
        : GlobalTooltip(message: tooltip!, child: named);
  }
}

// ─── Pill chip for speed / loop ───────────────────────────────

class AudioChipButton extends StatelessWidget {
  const AudioChipButton({
    required this.label,
    required this.semanticLabel,
    required this.active,
    required this.accent,
    required this.foreground,
    required this.onTap,
    this.icon,
  });

  /// What it SHOWS — `1.5×`, `Loop`.
  final String label;

  /// What it IS. `1.5×` is a value, not a name, and a reader hearing
  /// it alone has not been told what it is the speed OF.
  final String semanticLabel;

  final bool active;
  final Color accent;
  final Color foreground;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = active
        ? (ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
              ? Colors.white
              : Colors.black87)
        : foreground.withValues(alpha: AudioDefaults.controlIconOpacity);
    return Semantics(
      button: true,
      // A toggle, so it reports its STATE as well as its name — a
      // reader has no colour to tell them the loop is on.
      toggled: active,
      label: semanticLabel,
      value: label,
      excludeSemantics: true,
      child: Material(
        color: active
            ? accent
            : foreground.withValues(alpha: AudioDefaults.chipIdleOpacity),
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: AudioDefaults.chipPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AudioDefaults.chipIconSize, color: fg),
                  const SizedBox(width: AudioDefaults.gapXs),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AudioDefaults.chipFontSize,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    letterSpacing: AudioDefaults.chipLetterSpacing,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared variant chrome ────────────────────────────────────
//
// Both _AudioBackedAudioPlayerState and _VideoBackedAudioPlayerState
// drive this widget. It reads everything from the AudioPlayerHandle
// interface, so the visual layer is backend-agnostic.
