import 'package:flutter/material.dart';

import 'divider_models.dart';
import 'divider_painter.dart';
import 'theme/divider_theme.dart';

export 'divider_models.dart';
export 'divider_painter.dart';
export 'global_expandable_divider.dart';
export 'theme/divider_theme.dart';

/// Marks the entrance wrapper, so a test can find it without matching on
/// `FractionallySizedBox` — the progress rail mounts one too.
const kDividerEntranceKey = ValueKey<String>('divider-entrance');

// ---------------------------------------------------------------------------
// GlobalDivider
// ---------------------------------------------------------------------------

/// A rule: plain, dashed, dotted, wavy, or with a label in the middle.
///
/// ```dart
/// const GlobalDivider()      // a plain rule
/// GlobalDivider.text('OR')   // label in the middle
/// ```
///
/// It does NOT report a value. A rule carrying a progress bar lived
/// here for a while and was a weaker copy of `GlobalProgress` — see the
/// module's CLAUDE.md.
///
/// Visual configuration is the themeable bag [DividerStyle]; what the
/// divider IS — its line style, its content, its orientation — stays as
/// named parameters.
class GlobalDivider extends StatelessWidget {
  const GlobalDivider({
    super.key,
    this.style = const DividerStyle(),
    this.lineStyle = DividerLineStyle.solid,
    this.text,
    this.icon,
    this.badge,
    this.isVertical = false,
    this.doubleLine = false,
    this.animate = false,
    this.animateTextFade = false,
    this.onTap,
    this.semanticLabel,
  }) : assert(
         !isVertical || (text == null && icon == null && badge == null),
         'a vertical rule has no room for centre content — it was '
         'silently dropped',
       );

  /// Themeable style bag. Merges over `GlobalDividerTheme`.
  final DividerStyle style;

  /// How the line is drawn. Named `lineStyle` because `style` is the
  /// bag — the same split every other module makes.
  final DividerLineStyle lineStyle;

  // ─── Centre content ────────────────────────────────────────

  final String? text;
  final IconData? icon;
  final Widget? badge;

  // ─── Orientation ───────────────────────────────────────────

  final bool isVertical;

  /// Two parallel rules instead of one.
  final bool doubleLine;

  // ─── Animation ─────────────────────────────────────────────

  /// Draws the rule out from the centre on first build.
  final bool animate;

  /// Fades the centre label in over the tail of that entrance.
  final bool animateTextFade;

  // ─── Interaction ───────────────────────────────────────────

  /// Makes the rule a target — a "show more" seam, usually.
  final VoidCallback? onTap;

  /// Spoken when [onTap] or [text] gives the rule something to say.
  final String? semanticLabel;

  bool get _hasCentre => text != null || icon != null || badge != null;

  // ─── Convenience factories ─────────────────────────────────

  factory GlobalDivider.dashed({
    Key? key,
    DividerStyle style = const DividerStyle(),
  }) => GlobalDivider(
    key: key,
    lineStyle: DividerLineStyle.dashed,
    style: style,
  );

  factory GlobalDivider.dotted({
    Key? key,
    DividerStyle style = const DividerStyle(),
  }) => GlobalDivider(
    key: key,
    lineStyle: DividerLineStyle.dotted,
    // A dot is a dash of no length, so the rhythm comes from the gap.
    style: const DividerStyle(
      dashWidth: DividerDefaults.dottedWidth,
      dashGap: DividerDefaults.dottedGap,
    ).mergedWith(style),
  );

  factory GlobalDivider.text(
    String label, {
    Key? key,
    DividerStyle style = const DividerStyle(),
    DividerLineStyle lineStyle = DividerLineStyle.solid,
    bool animateTextFade = false,
  }) => GlobalDivider(
    key: key,
    text: label,
    lineStyle: lineStyle,
    style: style,
    animateTextFade: animateTextFade,
  );

  factory GlobalDivider.icon(
    IconData iconData, {
    Key? key,
    DividerStyle style = const DividerStyle(),
    DividerLineStyle lineStyle = DividerLineStyle.solid,
  }) => GlobalDivider(
    key: key,
    icon: iconData,
    lineStyle: lineStyle,
    style: style,
  );

  factory GlobalDivider.gradient({
    required Gradient gradient,
    Key? key,
    DividerStyle style = const DividerStyle(),
    DividerLineStyle lineStyle = DividerLineStyle.solid,
  }) => GlobalDivider(
    key: key,
    lineStyle: lineStyle,
    style: DividerStyle(gradient: gradient).mergedWith(style),
  );

  factory GlobalDivider.vertical({
    Key? key,
    DividerStyle style = const DividerStyle(),
  }) => GlobalDivider(key: key, isVertical: true, style: style);

  factory GlobalDivider.wave({
    Key? key,
    DividerStyle style = const DividerStyle(),
  }) => GlobalDivider(
    key: key,
    lineStyle: DividerLineStyle.wave,
    style: const DividerStyle(
      thickness: DividerDefaults.waveThickness,
    ).mergedWith(style),
  );

  factory GlobalDivider.zigzag({
    Key? key,
    DividerStyle style = const DividerStyle(),
  }) => GlobalDivider(
    key: key,
    lineStyle: DividerLineStyle.zigzag,
    style: const DividerStyle(
      thickness: DividerDefaults.waveThickness,
      waveFrequency: DividerDefaults.zigzagFrequency,
    ).mergedWith(style),
  );

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rs = style.resolve(
      context,
      disableAnimations: MediaQuery.disableAnimationsOf(context),
    );

    // The centre's fade has to reach the LABEL, so the divider is built
    // inside the entrance rather than handed to it — see
    // `animateTextFade` below.
    Widget content(Animation<double>? centreFade) =>
        isVertical ? _vertical(rs) : _horizontal(rs, centreFade);

    final wantsEntrance = animate || animateTextFade;
    // Under reduced motion the rule is simply there. Running the
    // entrance at zero duration would still mount a FractionallySizedBox
    // that reports a different size for one frame.
    final divider = wantsEntrance && rs.animationDuration > Duration.zero
        ? _DividerEntrance(
            key: kDividerEntranceKey,
            duration: rs.animationDuration,
            axis: isVertical ? Axis.vertical : Axis.horizontal,
            // `animate` draws the rule out; `animateTextFade` alone
            // fades only the label and leaves the rule where it is.
            expand: animate,
            fadeCentre: animateTextFade && _hasCentre,
            builder: content,
          )
        : content(null);

    return _wrap(context, divider, rs);
  }

  Widget _horizontal(ResolvedDividerStyle rs, Animation<double>? centreFade) {
    var divider = _hasCentre ? _withCentre(rs, centreFade) : _line(rs);

    // The second rule takes the same indents as the first — it used to
    // be built without them and sat wider than the line above it.
    if (doubleLine) {
      divider = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          divider,
          SizedBox(height: rs.doubleLineGap),
          _line(rs),
        ],
      );
    }
    return divider;
  }

  /// Shadow, entrance, spacing, tap target and semantics, in the order
  /// they have to nest.
  Widget _wrap(
    BuildContext context,
    Widget divider,
    ResolvedDividerStyle rs,
  ) {
    var result = divider;

    if (rs.shadow != null) {
      result = DecoratedBox(
        decoration: BoxDecoration(boxShadow: [rs.shadow!]),
        child: result,
      );
    }

    if (rs.spacing > 0) {
      result = Padding(
        padding: isVertical
            ? EdgeInsets.symmetric(horizontal: rs.spacing)
            : EdgeInsets.symmetric(vertical: rs.spacing),
        child: result,
      );
    }

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // A 1dp line is not a 1dp target.
          padding: EdgeInsets.symmetric(vertical: rs.tapPadding),
          child: result,
        ),
      );
    }

    // A plain rule is DECORATION and says nothing; a labelled or
    // tappable one is the exception, and only then does it earn a node.
    final label = semanticLabel ?? text;
    if (onTap != null) {
      return Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: result,
      );
    }
    if (label == null) return ExcludeSemantics(child: result);
    return Semantics(label: label, excludeSemantics: true, child: result);
  }

  // ─── Simple line ───────────────────────────────────────────

  Widget _line(ResolvedDividerStyle rs) {
    if (!rs.needsPainter(lineStyle)) {
      return Container(
        height: rs.thickness,
        margin: EdgeInsetsDirectional.only(
          start: rs.indent,
          end: rs.endIndent,
        ),
        color: rs.color,
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(start: rs.indent, end: rs.endIndent),
      child: CustomPaint(
        size: Size(double.infinity, rs.extentFor(lineStyle)),
        painter: DividerPainter(rs: rs, lineStyle: lineStyle),
      ),
    );
  }

  Widget _halfLine(ResolvedDividerStyle rs) {
    if (!rs.needsPainter(lineStyle)) {
      return Container(height: rs.thickness, color: rs.color);
    }
    return CustomPaint(
      size: Size(double.infinity, rs.extentFor(lineStyle)),
      painter: DividerPainter(rs: rs, lineStyle: lineStyle),
    );
  }

  // ─── Line with something in the middle ─────────────────────

  Widget _withCentre(ResolvedDividerStyle rs, Animation<double>? fade) {
    final Widget centre;
    if (badge != null) {
      centre = Padding(padding: rs.textPadding, child: badge!);
    } else if (text != null) {
      centre = Padding(
        padding: rs.textPadding,
        child: Text(text!, style: rs.textStyle),
      );
    } else {
      centre = Padding(
        padding: rs.textPadding,
        child: Icon(icon, size: rs.iconSize, color: rs.iconColor),
      );
    }

    return Row(
      children: [
        if (rs.indent > 0) SizedBox(width: rs.indent),
        Expanded(child: _halfLine(rs)),
        // Only the CENTRE fades. It used to be an Opacity over the whole
        // rule, so `animateTextFade` faded the lines in with the label —
        // which is not what the name says, and left nothing on screen at
        // the start of a rule that is supposed to be drawing itself out.
        if (fade != null)
          FadeTransition(opacity: fade, child: centre)
        else
          centre,
        Expanded(child: _halfLine(rs)),
        if (rs.endIndent > 0) SizedBox(width: rs.endIndent),
      ],
    );
  }

  // ─── Vertical ──────────────────────────────────────────────

  Widget _vertical(ResolvedDividerStyle rs) {
    final Widget line;
    if (!rs.needsPainter(lineStyle)) {
      line = Container(
        width: rs.thickness,
        height: rs.verticalHeight,
        color: rs.color,
      );
    } else {
      line = CustomPaint(
        size: Size(rs.extentFor(lineStyle), rs.verticalHeight),
        painter: DividerPainter(rs: rs, lineStyle: lineStyle, isVertical: true),
      );
    }

    // The flag was read on the horizontal path only, so `doubleLine`
    // on a vertical rule drew one line.
    var result = line;
    if (doubleLine) {
      result = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          result,
          SizedBox(width: rs.doubleLineGap),
          line,
        ],
      );
    }

    // A vertical rule's indents run along ITS axis, which is the one
    // the horizontal path spells start/end. They were ignored entirely
    // — `indent` on a vertical divider did nothing at all.
    if (rs.indent > 0 || rs.endIndent > 0) {
      return Padding(
        padding: EdgeInsets.only(top: rs.indent, bottom: rs.endIndent),
        child: result,
      );
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Entrance
// ---------------------------------------------------------------------------

/// Draws the rule out on first build, then fades the centre in over the
/// tail of it.
class _DividerEntrance extends StatefulWidget {
  const _DividerEntrance({
    required this.duration,
    required this.axis,
    required this.builder,
    super.key,
    this.expand = true,
    this.fadeCentre = false,
  });

  final Duration duration;

  /// A vertical rule grows along its own axis. It used to grow its
  /// WIDTH whichever way it ran, so `animate` did nothing visible on a
  /// vertical divider.
  final Axis axis;

  /// Builds the rule, taking the animation its CENTRE should fade on —
  /// null when nothing is fading.
  final Widget Function(Animation<double>? centreFade) builder;

  /// Whether the rule draws itself out. False fades the label alone.
  final bool expand;

  final bool fadeCentre;

  @override
  State<_DividerEntrance> createState() => _DividerEntranceState();
}

class _DividerEntranceState extends State<_DividerEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _extent;
  late final Animation<double> _centreOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _extent = CurvedAnimation(
      parent: _controller,
      curve: DividerDefaults.animExpandInterval,
    );
    _centreOpacity = CurvedAnimation(
      parent: _controller,
      curve: DividerDefaults.animFadeInterval,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Built ONCE: the centre's FadeTransition drives itself, so only the
    // expansion needs a per-frame rebuild.
    final child = widget.builder(widget.fadeCentre ? _centreOpacity : null);
    if (!widget.expand) return child;

    return AnimatedBuilder(
      animation: _extent,
      builder: (context, inner) => FractionallySizedBox(
        widthFactor: widget.axis == Axis.horizontal ? _extent.value : null,
        heightFactor: widget.axis == Axis.vertical ? _extent.value : null,
        child: inner,
      ),
      child: child,
    );
  }
}
