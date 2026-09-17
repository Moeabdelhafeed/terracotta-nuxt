import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/bidi.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/theme/app_text_strut.dart';
import '../../../core/tokens/extensions.dart';
import '../marquee/global_marquee.dart';
import 'text_models.dart';
import 'text_theme_ext.dart';

// `marquee:` is part of this widget's API, so its config types travel
// with it — callers should not need a second import for a parameter on
// GlobalText. The marquee WIDGET is deliberately not re-exported.
export '../marquee/marquee_models.dart';
export 'text_models.dart';
export 'text_theme_ext.dart';

/// A highly customizable text widget with support for gradients, highlights,
/// icons, rich segments, selectable text, auto-sizing, and typewriter animation.
class GlobalText extends StatelessWidget {
  /// The text to display.
  final String text;

  /// Predefined typography preset. Overridden by [style] properties.
  final TextPreset? preset;

  /// Custom styling.
  final GlobalTextStyle textStyle;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Maximum number of lines. Null = unlimited.
  final int? maxLines;

  /// How to handle overflow.
  final TextOverflow? overflow;

  /// Whether the text is selectable (long-press to select and copy).
  /// Uses SelectableText wrapped in TapRegion for proper dismiss-on-outside-tap.
  /// For page-wide selection, prefer wrapping with SelectionArea instead.
  final bool selectable;

  /// Whether to auto-size the text to fit its container.
  final bool autoSize;

  /// Minimum font size when auto-sizing.
  final double autoSizeMinFontSize;

  /// Step size for auto-sizing.
  final double autoSizeStepGranularity;

  /// When true, the widget's `textDirection` is derived from [text]'s
  /// first strong Unicode character via [AppBidi.detect] — an English
  /// paragraph renders LTR, an Arabic paragraph renders RTL, regardless
  /// of the ambient [Directionality]. Leave false to inherit direction
  /// from the widget tree (Flutter default).
  ///
  /// Use for user-generated / backend-sourced content where the
  /// language isn't known at build time (chat messages, bios, user
  /// paste). Fixes the common "Arabic text left-aligned with the
  /// period on the wrong side" look.
  final bool autoDetectDirection;

  /// Scroll the text when it OVERFLOWS instead of truncating it.
  ///
  /// Null (default) keeps the normal [overflow] behaviour. Set a
  /// [MarqueeStyle] — `const MarqueeStyle()` for the defaults — and an
  /// overflowing label scrolls with faded edges; one that fits is left
  /// completely alone, with no scroll view and no animation.
  ///
  /// Implies a single line. Requires a BOUNDED width: inside an
  /// unbounded Row the text can always "fit", so it would never scroll.
  /// Under reduced motion it falls back to truncation — a permanently
  /// moving label is exactly what that setting exists to stop.
  final MarqueeStyle? marquee;

  const GlobalText(
    this.text, {
    super.key,
    this.preset,
    this.textStyle = const GlobalTextStyle(),
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.selectable = false,
    this.autoSize = false,
    this.autoSizeMinFontSize = 8,
    this.autoSizeStepGranularity = 1,
    this.autoDetectDirection = false,
    this.marquee,
  }) : assert(
         marquee == null || !autoSize,
         'marquee and autoSize are contradictory: one scrolls overflowing '
         'text, the other shrinks it until it fits. Pick one.',
       ),
       assert(
         marquee == null || !selectable,
         'marquee and selectable conflict: selecting moving text is '
         'hostile, and the marquee swallows the drag anyway.',
       );

  // ─── Convenience factories ─────────────────────────────────

  /// Heading text.
  factory GlobalText.heading(
    String text, {
    Key? key,
    GlobalTextStyle? textStyle,
    TextAlign? textAlign,
    int? maxLines,
  }) => GlobalText(
    text,
    key: key,
    preset: TextPreset.headlineMedium,
    textStyle: textStyle ?? const GlobalTextStyle(fontWeight: FontWeight.w700),
    textAlign: textAlign,
    maxLines: maxLines,
  );

  /// Title text.
  factory GlobalText.title(
    String text, {
    Key? key,
    GlobalTextStyle? textStyle,
    TextAlign? textAlign,
    int? maxLines,
  }) => GlobalText(
    text,
    key: key,
    preset: TextPreset.titleLarge,
    textStyle: textStyle ?? const GlobalTextStyle(fontWeight: FontWeight.w600),
    textAlign: textAlign,
    maxLines: maxLines,
  );

  /// Body text.
  factory GlobalText.body(
    String text, {
    Key? key,
    GlobalTextStyle? textStyle,
    TextAlign? textAlign,
    int? maxLines,
  }) => GlobalText(
    text,
    key: key,
    preset: TextPreset.bodyMedium,
    textStyle: textStyle ?? const GlobalTextStyle(),
    textAlign: textAlign,
    maxLines: maxLines,
  );

  /// Caption / small text.
  factory GlobalText.caption(
    String text, {
    Key? key,
    GlobalTextStyle? textStyle,
    TextAlign? textAlign,
  }) => GlobalText(
    text,
    key: key,
    preset: TextPreset.bodySmall,
    textStyle: textStyle ?? const GlobalTextStyle(),
    textAlign: textAlign,
  );

  /// Label text.
  factory GlobalText.label(
    String text, {
    Key? key,
    GlobalTextStyle? textStyle,
    TextAlign? textAlign,
  }) => GlobalText(
    text,
    key: key,
    preset: TextPreset.labelLarge,
    textStyle: textStyle ?? const GlobalTextStyle(fontWeight: FontWeight.w600),
    textAlign: textAlign,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Materialize once per build: caller > GlobalTextTheme > defaults >
    // context palette/tokens. Everything below reads `st` and never
    // re-derives a fallback.
    final st = textStyle.resolve(context);
    final baseStyle = _resolveBaseStyle(theme, st);

    Widget result;

    if (marquee != null) {
      return _buildMarquee(context, baseStyle, st);
    }

    if (autoSize) {
      result = _buildAutoSized(baseStyle, st);
    } else {
      result = _buildText(baseStyle, st);
    }

    // Stroke / outline
    if (st.hasStroke) {
      final strokeStyle = baseStyle.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = st.strokeWidth
          ..color = st.strokeColor ?? Colors.black,
      );
      Widget strokeText = Text(
        text,
        style: strokeStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: autoDetectDirection ? AppBidi.detect(text) : null,
      );
      if (st.strokeGradient != null) {
        strokeText = ShaderMask(
          shaderCallback: (bounds) => st.strokeGradient!.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: strokeText,
        );
      }
      result = Stack(children: [strokeText, result]);
    }

    // Gradient
    if (st.gradient != null) {
      result = ShaderMask(
        shaderCallback: (bounds) => st.gradient!.createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: result,
      );
    }

    // Highlight decoration
    if (st.decoration == TextDecorationType.highlight) {
      result = Container(
        padding: st.highlightPadding,
        decoration: BoxDecoration(
          color: st.highlightColor,
          borderRadius: st.highlightBorderRadius,
        ),
        child: result,
      );
    }

    // Leading / trailing icons
    if (st.leadingIcon != null || st.trailingIcon != null) {
      final iconColor = st.iconColor ?? st.color ?? context.textColors.primary;
      result = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (st.leadingIcon != null) ...[
            // Decorative: the adjacent text already carries the meaning,
            // so announcing the glyph only adds noise.
            ExcludeSemantics(
              child: Icon(st.leadingIcon, size: st.iconSize, color: iconColor),
            ),
            SizedBox(width: st.iconSpacing),
          ],
          Flexible(child: result),
          if (st.trailingIcon != null) ...[
            SizedBox(width: st.iconSpacing),
            ExcludeSemantics(
              child: Icon(st.trailingIcon, size: st.iconSize, color: iconColor),
            ),
          ],
        ],
      );
    }

    return result;
  }

  /// Marquee path: one line, no wrapping, and the decoration stack
  /// (gradient / stroke / highlight / icons) deliberately does NOT
  /// apply — those wrap the text in boxes that would be scrolled along
  /// with it. Keep the marquee for plain labels.
  Widget _buildMarquee(
    BuildContext context,
    TextStyle baseStyle,
    ResolvedGlobalTextStyle st,
  ) {
    final line = Text(
      text,
      style: baseStyle,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      textDirection: autoDetectDirection ? AppBidi.detect(text) : null,
    );

    // Reduced motion: truncate rather than scroll, and skip the scroll
    // view entirely so nothing animates.
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        softWrap: false,
        overflow: overflow ?? TextOverflow.ellipsis,
        textAlign: textAlign,
        textDirection: autoDetectDirection ? AppBidi.detect(text) : null,
      );
    }

    return GlobalMarquee(
      style: marquee!,
      // The full string stays readable to a screen reader even though
      // only a slice of it is on screen at any moment.
      semanticLabel: text,
      child: line,
    );
  }

  TextStyle _resolveBaseStyle(ThemeData theme, ResolvedGlobalTextStyle st) {
    var base =
        _presetStyle(theme) ?? theme.textTheme.bodyMedium ?? const TextStyle();

    return base.copyWith(
      color: st.gradient != null ? Colors.white : (st.color ?? base.color),
      fontFamily: st.fontFamily ?? base.fontFamily,
      fontSize: st.fontSize ?? base.fontSize,
      fontWeight: st.fontWeight ?? base.fontWeight,
      fontStyle: st.fontStyle,
      letterSpacing: st.letterSpacing,
      wordSpacing: st.wordSpacing,
      height: st.height,
      shadows: st.shadow,
      decoration: _resolveDecoration(st),
      decorationColor: st.decorationColor,
    );
  }

  TextStyle? _presetStyle(ThemeData theme) {
    if (preset == null) return null;
    final tt = theme.textTheme;
    return switch (preset!) {
      TextPreset.displayLarge => tt.displayLarge,
      TextPreset.displayMedium => tt.displayMedium,
      TextPreset.displaySmall => tt.displaySmall,
      TextPreset.headlineLarge => tt.headlineLarge,
      TextPreset.headlineMedium => tt.headlineMedium,
      TextPreset.headlineSmall => tt.headlineSmall,
      TextPreset.titleLarge => tt.titleLarge,
      TextPreset.titleMedium => tt.titleMedium,
      TextPreset.titleSmall => tt.titleSmall,
      TextPreset.bodyLarge => tt.bodyLarge,
      TextPreset.bodyMedium => tt.bodyMedium,
      TextPreset.bodySmall => tt.bodySmall,
      TextPreset.labelLarge => tt.labelLarge,
      TextPreset.labelMedium => tt.labelMedium,
      TextPreset.labelSmall => tt.labelSmall,
    };
  }

  TextDecoration? _resolveDecoration(ResolvedGlobalTextStyle st) {
    return switch (st.decoration) {
      TextDecorationType.none => null,
      TextDecorationType.underline => TextDecoration.underline,
      TextDecorationType.strikethrough => TextDecoration.lineThrough,
      TextDecorationType.highlight => null, // handled via Container
      TextDecorationType.doubleUnderline => TextDecoration.underline,
    };
  }

  Widget _buildText(TextStyle baseStyle, ResolvedGlobalTextStyle st) {
    final resolvedStyle = baseStyle.copyWith(
      decorationStyle: st.decoration == TextDecorationType.doubleUnderline
          ? TextDecorationStyle.double
          : null,
    );

    final effectiveDirection = autoDetectDirection
        ? AppBidi.detect(text)
        : null;

    // Standardized line metrics — see AppTextStrut. Without it the same
    // preset occupies a different baseline position per font, so layouts
    // shift when the locale changes.
    final strut = AppTextStrut.forStyle(resolvedStyle);

    if (selectable) {
      return AppTextStrut.nudge(
        style: resolvedStyle,
        child: SelectionArea(
          child: Text(
            text,
            style: resolvedStyle,
            strutStyle: strut,
            textAlign: textAlign,
            maxLines: maxLines,
            textDirection: effectiveDirection,
          ),
        ),
      );
    }

    return AppTextStrut.nudge(
      style: resolvedStyle,
      child: Text(
        text,
        style: resolvedStyle,
        strutStyle: strut,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
        textDirection: effectiveDirection,
      ),
    );
  }

  Widget _buildAutoSized(TextStyle baseStyle, ResolvedGlobalTextStyle st) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        var currentSize = baseStyle.fontSize ?? 14;
        var fitted = baseStyle.copyWith(fontSize: currentSize);

        while (currentSize > autoSizeMinFontSize) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: fitted),
            maxLines: maxLines ?? 1,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: maxWidth);

          if (!tp.didExceedMaxLines && tp.width <= maxWidth) break;
          currentSize -= autoSizeStepGranularity;
          fitted = baseStyle.copyWith(fontSize: currentSize);
        }

        final effectiveDirection = autoDetectDirection
            ? AppBidi.detect(text)
            : null;
        if (selectable) {
          return SelectionArea(
            child: Text(
              text,
              style: fitted,
              textAlign: textAlign,
              maxLines: maxLines,
              textDirection: effectiveDirection,
            ),
          );
        }
        return Text(
          text,
          style: fitted,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          textDirection: effectiveDirection,
        );
      },
    );
  }
}

/// A rich text widget that renders multiple [TextSegment]s with different styles.
class GlobalRichText extends StatelessWidget {
  /// The segments to render.
  final List<TextSegment> segments;

  /// Base preset for the overall text.
  final TextPreset? preset;

  /// Base style applied to all segments (segments override specific properties).
  final GlobalTextStyle textStyle;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Maximum lines.
  final int? maxLines;

  /// Overflow behavior.
  final TextOverflow? overflow;

  const GlobalRichText({
    super.key,
    required this.segments,
    this.preset,
    this.textStyle = const GlobalTextStyle(),
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final st = textStyle;

    var base = theme.textTheme.bodyMedium ?? const TextStyle();
    if (preset != null) {
      base = _presetStyle(theme, preset!) ?? base;
    }
    base = base.copyWith(
      color: st.color ?? base.color,
      fontSize: st.fontSize ?? base.fontSize,
      fontWeight: st.fontWeight ?? base.fontWeight,
      fontStyle: st.fontStyle,
      letterSpacing: st.letterSpacing,
      height: st.height,
    );

    final spans = segments.map((seg) {
      final spanStyle = base.copyWith(
        color: seg.color ?? base.color,
        fontWeight: seg.fontWeight ?? base.fontWeight,
        fontStyle: seg.fontStyle,
        fontSize: seg.fontSize ?? base.fontSize,
        decoration: seg.decoration,
        decorationColor: seg.decorationColor ?? seg.color,
      );

      if (seg.onTap != null) {
        return TextSpan(
          text: seg.text,
          style: spanStyle,
          recognizer: TapGestureRecognizer()..onTap = seg.onTap,
        );
      }
      return TextSpan(text: seg.text, style: spanStyle);
    }).toList();

    Widget result = RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow:
          overflow ??
          (maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip),
    );

    // Gradient on rich text
    if (st.gradient != null) {
      result = ShaderMask(
        shaderCallback: (bounds) => st.gradient!.createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: result,
      );
    }

    // Icons
    if (st.leadingIcon != null || st.trailingIcon != null) {
      final iconColor = st.iconColor ?? st.color ?? theme.colorScheme.onSurface;
      result = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (st.leadingIcon != null) ...[
            Icon(st.leadingIcon, size: st.iconSize, color: iconColor),
            SizedBox(width: st.iconSpacing),
          ],
          Flexible(child: result),
          if (st.trailingIcon != null) ...[
            SizedBox(width: st.iconSpacing),
            Icon(st.trailingIcon, size: st.iconSize, color: iconColor),
          ],
        ],
      );
    }

    return result;
  }

  TextStyle? _presetStyle(ThemeData theme, TextPreset p) {
    final tt = theme.textTheme;
    return switch (p) {
      TextPreset.displayLarge => tt.displayLarge,
      TextPreset.displayMedium => tt.displayMedium,
      TextPreset.displaySmall => tt.displaySmall,
      TextPreset.headlineLarge => tt.headlineLarge,
      TextPreset.headlineMedium => tt.headlineMedium,
      TextPreset.headlineSmall => tt.headlineSmall,
      TextPreset.titleLarge => tt.titleLarge,
      TextPreset.titleMedium => tt.titleMedium,
      TextPreset.titleSmall => tt.titleSmall,
      TextPreset.bodyLarge => tt.bodyLarge,
      TextPreset.bodyMedium => tt.bodyMedium,
      TextPreset.bodySmall => tt.bodySmall,
      TextPreset.labelLarge => tt.labelLarge,
      TextPreset.labelMedium => tt.labelMedium,
      TextPreset.labelSmall => tt.labelSmall,
    };
  }
}

/// A text widget that reveals characters one by one (typewriter effect).
class GlobalTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final bool autoStart;
  final VoidCallback? onComplete;
  final TextAlign? textAlign;

  const GlobalTypewriterText(
    this.text, {
    super.key,
    this.style,
    this.charDuration = kTypewriterCharDuration,
    this.autoStart = true,
    this.onComplete,
    this.textAlign,
  });

  @override
  State<GlobalTypewriterText> createState() => GlobalTypewriterTextState();
}

class GlobalTypewriterTextState extends State<GlobalTypewriterText> {
  int _charCount = 0;
  bool _running = false;
  bool _started = false;

  /// Read in didChangeDependencies, NOT in the tick: inherited widgets
  /// cannot be looked up before initState has completed, and the first
  /// tick fires from the auto-start.
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Auto-start lives here rather than initState so the very first tick
    // already knows whether motion is allowed.
    if (widget.autoStart && !_started) {
      _started = true;
      start();
    }
  }

  void start() {
    if (_running) return;
    _running = true;
    _charCount = 0;
    _tick();
  }

  void _tick() {
    if (!mounted || !_running) return;
    // Reduced motion: a character-by-character reveal is decorative,
    // and for some vestibular/attention conditions actively hostile.
    // Jump to the finished string and report completion.
    if (_reduceMotion) {
      setState(() => _charCount = widget.text.length);
      _running = false;
      widget.onComplete?.call();
      return;
    }
    if (_charCount >= widget.text.length) {
      _running = false;
      widget.onComplete?.call();
      return;
    }
    setState(() => _charCount++);
    Future.delayed(widget.charDuration, _tick);
  }

  void reset() {
    _running = false;
    setState(() => _charCount = 0);
  }

  void restart() {
    reset();
    start();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? Theme.of(context).textTheme.bodyMedium;
    return Text(
      widget.text.substring(0, _charCount),
      style: style,
      textAlign: widget.textAlign,
    );
  }
}

// ---------------------------------------------------------------------------
// Animated counter text — counts up/down to a target number
// ---------------------------------------------------------------------------

/// A text widget that animates a number from [begin] to [end] with easing.
///
/// Useful for stats, prices, scores, dashboards.
class GlobalCounterText extends StatefulWidget {
  /// Starting value.
  final double begin;

  /// Target value.
  final double end;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Number of decimal places.
  final int decimals;

  /// Prefix (e.g. "$", "€").
  final String prefix;

  /// Suffix (e.g. "%", "km", "+").
  final String suffix;

  /// Use thousands separator (1,234).
  final bool separator;

  /// Custom formatter. Overrides decimals/prefix/suffix/separator.
  final String Function(double)? formatter;

  /// Text style.
  final TextStyle? style;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Auto-start on mount.
  final bool autoStart;

  /// Called when animation completes.
  final VoidCallback? onComplete;

  const GlobalCounterText({
    super.key,
    this.begin = 0,
    required this.end,
    this.duration = kCounterRollDuration,
    this.curve = Curves.easeOutCubic,
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
    this.separator = true,
    this.formatter,
    this.style,
    this.textAlign,
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<GlobalCounterText> createState() => GlobalCounterTextState();
}

class GlobalCounterTextState extends State<GlobalCounterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete?.call();
    });
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Same reason as the typewriter: the reduced-motion check needs an
    // inherited lookup, which initState cannot do.
    if (widget.autoStart && !_started) {
      _started = true;
      _runOrSettle();
    }
  }

  /// Reduced motion lands on the final value instead of rolling to it.
  /// The NUMBER is the information; the count-up is decoration.
  void _runOrSettle({double from = 0}) {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
      widget.onComplete?.call();
    } else {
      _ctrl.forward(from: from);
    }
  }

  @override
  void didUpdateWidget(GlobalCounterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end || oldWidget.begin != widget.begin) {
      _anim = Tween<double>(
        begin: widget.begin,
        end: widget.end,
      ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
      _runOrSettle();
    }
  }

  void start() => _runOrSettle();
  void reset() => _ctrl.reset();
  void restart() {
    _ctrl.reset();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(double v) {
    if (widget.formatter != null) return widget.formatter!(v);
    String num;
    if (widget.decimals == 0) {
      num = v.round().toString();
    } else {
      num = v.toStringAsFixed(widget.decimals);
    }
    if (widget.separator && widget.decimals == 0) {
      num = _addSeparator(num);
    }
    return '${widget.prefix}$num${widget.suffix}';
  }

  String _addSeparator(String n) {
    final neg = n.startsWith('-');
    if (neg) n = n.substring(1);
    final buf = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write(',');
      buf.write(n[i]);
    }
    return neg ? '-${buf.toString()}' : buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Text(
        _format(_anim.value),
        style:
            widget.style ??
            Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
        textAlign: widget.textAlign,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable text — "Read more / Read less"
// ---------------------------------------------------------------------------

/// A text widget that truncates to [maxLines] with a "Read more" toggle.
class GlobalExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String? expandText;
  final String? collapseText;
  final Color? toggleColor;
  final bool initiallyExpanded;

  const GlobalExpandableText(
    this.text, {
    super.key,
    this.maxLines = 3,
    this.style,
    this.textAlign,
    this.expandText,
    this.collapseText,
    this.toggleColor,
    this.initiallyExpanded = false,
  });

  @override
  State<GlobalExpandableText> createState() => GlobalExpandableTextState();
}

class GlobalExpandableTextState extends State<GlobalExpandableText> {
  bool _expanded = false;
  bool _hasOverflow = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void toggle() => setState(() => _expanded = !_expanded);
  void expand() => setState(() => _expanded = true);
  void collapse() => setState(() => _expanded = false);

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();
    final toggleColor =
        widget.toggleColor ?? Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if text overflows
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        _hasOverflow = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedCrossFade(
              duration: AppDurations.quick,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                widget.text,
                style: style,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
                textAlign: widget.textAlign,
              ),
              secondChild: Text(
                widget.text,
                style: style,
                textAlign: widget.textAlign,
              ),
            ),
            if (_hasOverflow)
              Semantics(
                button: true,
                // Says what the tap DOES; the visible label already says
                // which state you are in.
                label: _expanded
                    ? (widget.collapseText ?? TextStrings.readLess)
                    : (widget.expandText ?? TextStrings.readMore),
                child: GestureDetector(
                  onTap: toggle,
                  child: Padding(
                    padding: EdgeInsets.only(top: context.spacing.xs),
                    child: Text(
                      _expanded
                          ? (widget.collapseText ?? TextStrings.readLess)
                          : (widget.expandText ?? TextStrings.readMore),
                      style: TextStyle(
                        color: toggleColor,
                        fontSize: (style.fontSize ?? 14) - 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Animated text — built-in entrance animations
// ---------------------------------------------------------------------------

/// A text widget with configurable entrance animations.
///
/// Supports 17 animation types including fade, slide, scale, rotate, bounce,
/// elastic, flip, and blur effects. All are configurable via duration, curve,
/// and delay.
class GlobalAnimatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextAnimation animation;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool autoStart;
  final VoidCallback? onComplete;
  final double slideDistance;

  const GlobalAnimatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.animation = TextAnimation.fadeIn,
    this.duration = AppDurations.slowest,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.autoStart = true,
    this.onComplete,
    this.slideDistance = 30,
  });

  @override
  State<GlobalAnimatedText> createState() => GlobalAnimatedTextState();
}

class GlobalAnimatedTextState extends State<GlobalAnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete?.call();
    });
    if (widget.autoStart) {
      if (widget.delay == Duration.zero) {
        _ctrl.forward();
        _started = true;
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) {
            _ctrl.forward();
            _started = true;
          }
        });
      }
    }
  }

  void start() {
    if (_started && _ctrl.isCompleted) _ctrl.reset();
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
      _started = true;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _ctrl.forward();
          _started = true;
        }
      });
    }
  }

  void reset() {
    _ctrl.reset();
    _started = false;
  }

  void restart() {
    reset();
    start();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? Theme.of(context).textTheme.bodyMedium;
    final child = Text(widget.text, style: style, textAlign: widget.textAlign);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final t = _anim.value;
        return _applyAnimation(child, t);
      },
    );
  }

  Widget _applyAnimation(Widget child, double t) {
    final dist = widget.slideDistance;

    switch (widget.animation) {
      case TextAnimation.fadeIn:
        return Opacity(opacity: t, child: child);

      case TextAnimation.fadeOut:
        return Opacity(opacity: 1 - t, child: child);

      case TextAnimation.slideLeft:
        return Transform.translate(
          offset: Offset(dist * (1 - t), 0),
          child: child,
        );

      case TextAnimation.slideRight:
        return Transform.translate(
          offset: Offset(-dist * (1 - t), 0),
          child: child,
        );

      case TextAnimation.slideUp:
        return Transform.translate(
          offset: Offset(0, dist * (1 - t)),
          child: child,
        );

      case TextAnimation.slideDown:
        return Transform.translate(
          offset: Offset(0, -dist * (1 - t)),
          child: child,
        );

      case TextAnimation.scaleUp:
        return Transform.scale(scale: t, child: child);

      case TextAnimation.scaleDown:
        return Transform.scale(scale: 2 - t, child: child);

      case TextAnimation.rotate:
        return Transform.rotate(
          angle: (1 - t) * 2 * math.pi,
          child: Opacity(opacity: t, child: child),
        );

      case TextAnimation.fadeSlideUp:
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, dist * (1 - t)),
            child: child,
          ),
        );

      case TextAnimation.fadeSlideDown:
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -dist * (1 - t)),
            child: child,
          ),
        );

      case TextAnimation.fadeScale:
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
        );

      case TextAnimation.bounce:
        // Overshoot then settle
        final bounce = t < 0.5
            ? 4 * t * t * t
            : 1 - ((-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2)) / 2;
        return Transform.scale(scale: bounce, child: child);

      case TextAnimation.elastic:
        final elastic = t == 0 || t == 1
            ? t
            : -math.pow(2, 10 * t - 10) *
                  math.sin((t * 10 - 10.75) * (2 * math.pi / 3));
        final scale = (1 + elastic * (1 - t)).clamp(0.0, 2.0);
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: t, child: child),
        );

      case TextAnimation.flipH:
        final angle = (1 - t) * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: Opacity(opacity: t > 0.5 ? 1 : t * 2, child: child),
        );

      case TextAnimation.flipV:
        final angle = (1 - t) * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(angle),
          child: Opacity(opacity: t > 0.5 ? 1 : t * 2, child: child),
        );

      case TextAnimation.blur:
        final sigma = 10 * (1 - t);
        return ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
            tileMode: TileMode.decal,
          ),
          child: Opacity(opacity: t, child: child),
        );
    }
  }
}
