part of 'global_container.dart';

// The container's SIBLINGS: the animated border, the selectable frame
// and the dismissible row. Each is its own widget that happens to build
// a `GlobalContainer` inside — they are not modes of it.

/// A container with animated border (rotate, pulse, or shimmer effect).
class GlobalAnimatedBorderContainer extends StatefulWidget {
  const GlobalAnimatedBorderContainer({
    super.key,
    this.child,
    this.borderColors = const [
      Colors.purple,
      Colors.blue,
      Colors.cyan,
      Colors.purple,
    ],
    this.type = AnimatedBorderType.rotate,
    this.borderWidth = 2.0,
    this.borderRadius,
    this.duration,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.respectReducedMotion = true,
  });

  /// Whether "reduce motion" stops the border moving.
  ///
  /// ON. A border that rotates forever is the clearest case the setting
  /// has. Turn it off only where the motion IS the content.
  final bool respectReducedMotion;

  final Widget? child;
  final List<Color> borderColors;
  final AnimatedBorderType type;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final Duration? duration;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  State<GlobalAnimatedBorderContainer> createState() =>
      _GlobalAnimatedBorderContainerState();
}

class _GlobalAnimatedBorderContainerState
    extends State<GlobalAnimatedBorderContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final dur =
        widget.duration ??
        (widget.type == AnimatedBorderType.pulse
            ? ContainerDefaults.pulseDuration
            : ContainerDefaults.animatedBorderDuration);
    _ctrl = AnimationController(vsync: this, duration: dur);
  }

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A border that rotates FOREVER is the clearest case the setting
    // has. It is stopped, not shortened: a zero-length repeat still
    // rebuilds every frame on the way to nowhere, and it is held at the
    // start rather than left wherever it happened to be.
    final reduce =
        widget.respectReducedMotion && MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduceMotion && _ctrl.isAnimating != reduce) return;
    _reduceMotion = reduce;
    if (reduce) {
      _ctrl
        ..stop()
        ..value = 0;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: widget.type == AnimatedBorderType.pulse);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(ContainerDefaults.radius);
    // The palette's CONTAINER role, like every other box in this module.
    // It was `isDark ? colorScheme.surfaceContainerHigh : surface` —
    // Material's scheme, plus a brightness branch the palette does.
    final bg = widget.backgroundColor ?? context.backgroundColors.container;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        Gradient gradient;
        switch (widget.type) {
          case AnimatedBorderType.rotate:
            gradient = SweepGradient(
              transform: GradientRotation(_ctrl.value * 2 * math.pi),
              colors: widget.borderColors,
            );
          case AnimatedBorderType.pulse:
            final t = _ctrl.value;
            gradient = LinearGradient(
              colors: [
                Color.lerp(
                  widget.borderColors.first,
                  widget.borderColors.last,
                  t,
                )!,
                Color.lerp(
                  widget.borderColors.last,
                  widget.borderColors.first,
                  t,
                )!,
              ],
            );
          case AnimatedBorderType.shimmer:
            // The band starts and ends fully OFF the box. It used to
            // sweep from `begin: -1` — which is the left edge, already
            // visible — to `begin: 2`, so every lap the highlight
            // vanished off the right and then popped back into view at
            // the left instead of arriving from outside it.
            //
            // And it sweeps toward the reading END: a highlight that
            // always runs left-to-right runs backwards in Arabic. Same
            // reason `GlobalShimmer` takes its direction from the
            // ambient `Directionality` rather than defaulting to `ltr`.
            final stop = _ctrl.value;
            final dir = Directionality.of(context) == TextDirection.rtl
                ? -1.0
                : 1.0;
            gradient = LinearGradient(
              begin: Alignment(dir * (-2.0 + stop * 4), 0),
              end: Alignment(dir * (-1.5 + stop * 4), 0),
              colors: [
                widget.borderColors.first.withValues(alpha: 0.2),
                widget.borderColors.last,
                widget.borderColors.first.withValues(alpha: 0.2),
              ],
            );
        }

        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(gradient: gradient, borderRadius: radius),
          child: Container(
            margin: EdgeInsets.all(widget.borderWidth),
            padding:
                widget.padding ??
                const EdgeInsets.all(ContainerDefaults.padding),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius.subtract(
                BorderRadius.all(Radius.circular(widget.borderWidth)),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Selectable container
// ═══════════════════════════════════════════════════════════════

/// A container with toggleable selected/unselected state.
/// A container that shows whether it is SELECTED.
///
/// It could only do one thing before — a two-point border, a five per
/// cent wash and a corner tick — which is quiet on a busy page and
/// invisible on a card that already has a border and a fill of its own.
/// [effect] picks how the state reads; see [ContainerSelectionEffect].
class GlobalSelectableContainer extends StatelessWidget {
  const GlobalSelectableContainer({
    super.key,
    required this.selected,
    required this.onToggle,
    this.child,
    this.style = const ContainerStyle(),
    this.selectedBorderColor,
    this.selectedBorderWidth = ContainerDefaults.selectedBorderWidth,
    this.selectedBackgroundColor,
    this.checkmark = true,
    this.effect = ContainerSelectionEffect.outline,
    this.mark,
    this.respectReducedMotion = true,
  });

  final bool selected;
  final VoidCallback onToggle;
  final Widget? child;
  final ContainerStyle style;
  final Color? selectedBorderColor;
  final double selectedBorderWidth;
  final Color? selectedBackgroundColor;

  /// Kept for the callers that already say `checkmark: false`. [mark]
  /// wins when both are given.
  final bool checkmark;

  /// How the selected state READS.
  final ContainerSelectionEffect effect;

  /// Where the tick goes. Null follows [checkmark].
  final ContainerSelectionMark? mark;

  /// Whether "reduce motion" makes the state change ARRIVE rather than
  /// ease. The lift is the part this matters for.
  final bool respectReducedMotion;

  bool get _showsMark =>
      (mark ??
          (checkmark
              ? ContainerSelectionMark.corner
              : ContainerSelectionMark.none)) ==
      ContainerSelectionMark.corner;

  bool get _lifts =>
      effect == ContainerSelectionEffect.lift ||
      effect == ContainerSelectionEffect.outlineLift;

  bool get _outlines =>
      effect == ContainerSelectionEffect.outline ||
      effect == ContainerSelectionEffect.outlineLift;

  @override
  Widget build(BuildContext context) {
    // The palette's primary, not Material's scheme.
    final selColor = selectedBorderColor ?? context.primaryColors.primary;
    final reduce =
        respectReducedMotion && MediaQuery.disableAnimationsOf(context);
    final motion = reduce ? Duration.zero : ContainerDefaults.selectionDuration;

    final wash = effect == ContainerSelectionEffect.fill
        ? ContainerDefaults.selectedWashStrong
        : ContainerDefaults.selectedWash;

    Widget frame = AnimatedContainer(
      duration: motion,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: selected
            ? (selectedBackgroundColor ?? selColor.withValues(alpha: wash))
            : null,
        borderRadius:
            style.borderRadius ??
            BorderRadius.circular(ContainerDefaults.radius),
        border: Border.all(
          color: selected && _outlines ? selColor : Colors.transparent,
          width: selectedBorderWidth,
        ),
        // A LIFT is the one effect that survives a card with its own
        // border and its own fill, because it changes the card's
        // relationship to the page rather than its own decoration.
        boxShadow: selected && _lifts
            ? [
                BoxShadow(
                  color: selColor.withValues(
                    alpha: ContainerDefaults.selectedElevationOpacity,
                  ),
                  blurRadius: ContainerDefaults.selectedElevationBlur,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          GlobalContainer(style: style.withoutOuterDecoration(), child: child),
          if (selected && _showsMark)
            Positioned(
              top: ContainerDefaults.checkmarkOffset,
              right: ContainerDefaults.checkmarkOffset,
              child: Container(
                width: ContainerDefaults.checkmarkSize,
                height: ContainerDefaults.checkmarkSize,
                decoration: BoxDecoration(
                  color: selColor,
                  shape: BoxShape.circle,
                ),
                // What reads ON the selection fill. It was `Colors.white`,
                // which vanishes the moment that fill is a light colour.
                child: Icon(
                  Icons.check_rounded,
                  size: ContainerDefaults.checkmarkIconSize,
                  color: context.textColors.onAccent,
                ),
              ),
            ),
        ],
      ),
    );

    if (_lifts) {
      frame = AnimatedScale(
        duration: motion,
        curve: Curves.easeOutCubic,
        scale: selected ? ContainerDefaults.selectedScale : 1,
        child: frame,
      );
    }

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      onTap: onToggle,
      child: GestureDetector(onTap: onToggle, child: frame),
    );
  }
}
