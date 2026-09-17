import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/strings/common_strings.dart';
import '../../../core/painters/gradient_border_painter.dart';
import '../buttons/global_text_button.dart';
import '../icon/global_icon.dart';
import '../progress/global_progress.dart';
import '../text/global_text.dart';
import '../toast/global_toast.dart';
import 'banner_models.dart';
import 'theme/banner_theme.dart';

export 'banner_models.dart';
export 'theme/banner_theme.dart';

// ---------------------------------------------------------------------------
// GlobalBanner
// ---------------------------------------------------------------------------

/// A persistent inline info bar for announcements, warnings, and status messages.
/// Unlike toast (ephemeral overlay), this sits in the widget tree and stays
/// until dismissed or programmatically hidden.
class GlobalBanner extends StatefulWidget {
  const GlobalBanner({
    super.key,
    required this.title,
    this.message,
    this.type = BannerType.info,
    this.style = const BannerStyle(),
    this.icon,
    this.iconWidget,
    this.show = true,
    this.dismissible = true,
    this.onDismiss,
    this.onUndo,
    this.onShow,
    this.actions,
    this.leading,
    this.autoDismissDuration,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.swipeToDismiss = true,
    this.semanticLabel,
  });

  /// Title text.
  final String title;

  /// Optional description/message below the title.
  final String? message;

  /// Banner type — determines default icon and colors.
  final BannerType type;

  /// Styling configuration.
  final BannerStyle style;

  /// Custom icon. Overrides type-based default.
  final IconData? icon;

  /// Custom icon widget. Takes priority over [icon].
  final Widget? iconWidget;

  /// Whether the banner is visible. Animated entrance/exit.
  final bool show;

  /// Whether the user can dismiss the banner via close button.
  final bool dismissible;

  /// Called when dismissed by the user or auto-dismiss.
  final VoidCallback? onDismiss;

  /// How to put the banner back after a SWIPE dismissed it.
  ///
  /// Supplying this is what turns the undo on: a swipe then raises a
  /// toast offering it, and tapping it runs this. Null means no toast,
  /// because a module cannot know how to reverse a decision its owner
  /// made — [onDismiss] has usually already flipped some `show` flag,
  /// and restoring the banner from inside would only fight it.
  ///
  /// Only the swipe. The ✕ is deliberate and precise, and an
  /// auto-dismiss expires on its own; a swipe is the one that happens
  /// by accident, and the only one whose target you cannot see.
  final VoidCallback? onUndo;

  /// Called when the banner becomes visible (entrance animation completes).
  final VoidCallback? onShow;

  /// What the banner offers to do about the notice, laid out along its
  /// bottom edge.
  ///
  /// Declared rather than passed in as widgets — see [BannerAction].
  final List<BannerAction>? actions;

  /// Custom leading widget. Overrides icon entirely.
  final Widget? leading;

  /// Auto-dismiss after this duration. Null = stays until manually dismissed.
  final Duration? autoDismissDuration;

  /// When true, message is collapsible — only title shows when collapsed.
  final bool collapsible;

  /// Whether the collapsible message starts expanded.
  final bool initiallyExpanded;

  /// Whether a horizontal drag dismisses it.
  ///
  /// A strip with one small ✕ in the corner is a small target; a swipe
  /// is what people try first. Ignored when [dismissible] is false —
  /// a banner that cannot be closed cannot be swiped away either.
  final bool swipeToDismiss;

  /// Accessibility label.
  final String? semanticLabel;

  @override
  State<GlobalBanner> createState() => _GlobalBannerState();
}

class _GlobalBannerState extends State<GlobalBanner>
        // THREE controllers now — entrance, the message's reveal and the
        // auto-dismiss countdown — so the single-ticker mixin no longer
        // fits.
        with
        TickerProviderStateMixin,
        WidgetsBindingObserver {
  late AnimationController _animController;

  /// The box opening and closing — the FIRST half of the controller.
  CurvedAnimation? _sizeAnim;

  /// Everything that paints — the SECOND half, so it never runs while
  /// the height that clips it is moving.
  CurvedAnimation? _visualAnim;

  /// The whole range, for `expand` — where the height IS the animation
  /// and there is no second half to hand over to.
  CurvedAnimation? _wholeAnim;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<Offset> _slideFadeAnim;
  late Animation<double> _scaleAnim;

  bool _dismissed = false;
  bool _expanded = true;

  /// Drives the message's line-by-line reveal. A crossfade swapped the
  /// whole block at once, which reads as a flicker rather than as text
  /// folding away.
  late final AnimationController _expandController;

  /// Runs for the auto-dismiss duration, so the countdown line can
  /// show what is left.
  AnimationController? _countdown;

  /// How far a swipe has carried the banner, and whether a finger is
  /// still on it. While a finger is down the offset IS this value —
  /// implicit animation would put a frame between the two. Once it
  /// lifts, [_swipeReturn] takes over and brings it home.
  double _swipe = 0;
  bool _dragging = false;
  late final AnimationController _swipeController;
  Animation<double>? _swipeReturn;

  Timer? _autoDismissTimer;

  /// When the running auto-dismiss was started, and how long it was
  /// for — enough to work out what is LEFT when the app comes back.
  DateTime? _autoDismissStartedAt;
  Duration? _autoDismissRemaining;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _animController = AnimationController(
      vsync: this,
      duration: widget.style.animationDuration ?? BannerDefaults.animDuration,
      value: widget.show ? 1.0 : 0.0,
    );
    _animController.addStatusListener(_onAnimationStatus);
    _buildAnimations();
    _expandController = AnimationController(
      vsync: this,
      duration: widget.style.animationDuration ?? BannerDefaults.animDuration,
      value: _expanded ? 1 : 0,
    );
    _swipeController = AnimationController(
      vsync: this,
      duration: widget.style.animationDuration ?? BannerDefaults.animDuration,
    );
    WidgetsBinding.instance.addObserver(this);
    _startAutoDismiss();
  }

  // A banner set to five seconds used to expire while the phone was in
  // a pocket: the timer kept running with the app in the background, so
  // the notice was gone before anyone saw it. It pauses and resumes
  // with whatever is left instead.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _resumeAutoDismiss();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pauseAutoDismiss();
    }
  }

  void _pauseAutoDismiss() {
    _countdown?.stop();
    final started = _autoDismissStartedAt;
    final total = _autoDismissRemaining;
    if (_autoDismissTimer == null || started == null || total == null) return;

    final spent = DateTime.now().difference(started);
    _autoDismissRemaining = total - spent;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
  }

  void _resumeAutoDismiss() {
    final remaining = _autoDismissRemaining;
    if (remaining == null || _autoDismissTimer != null || _dismissed) return;
    if (remaining <= Duration.zero) {
      _dismiss();
      return;
    }
    _autoDismissStartedAt = DateTime.now();
    _autoDismissTimer = Timer(remaining, _dismiss);
    _countdown?.forward();
  }

  /// The two phases of the entrance, which do NOT overlap.
  ///
  /// One shared range meant the banner was sliding, fading or scaling
  /// while its own height was still moving — and the height clips. So
  /// every entrance was watched through a shutter closing over it, and
  /// the nicer the motion the worse it looked. The box moves first and
  /// alone; the banner paints only once the box has stopped.
  void _buildAnimations() {
    _sizeAnim?.dispose();
    _visualAnim?.dispose();
    _wholeAnim?.dispose();
    final curve = widget.style.animationCurve ?? Curves.easeOutCubic;

    _wholeAnim = CurvedAnimation(parent: _animController, curve: curve);
    _sizeAnim = CurvedAnimation(
      parent: _animController,
      curve: Interval(0, BannerDefaults.sizePhaseEnd, curve: curve),
    );
    _visualAnim = CurvedAnimation(
      parent: _animController,
      curve: Interval(BannerDefaults.visualPhaseBegin, 1, curve: curve),
    );

    _fadeAnim = _visualAnim!;
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(_visualAnim!);
    _slideFadeAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(_visualAnim!);
    _scaleAnim = Tween<double>(
      begin: BannerDefaults.scaleFrom,
      end: 1,
    ).animate(_visualAnim!);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_dismissed) {
      widget.onShow?.call();
    }
  }

  @override
  void didUpdateWidget(GlobalBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset dismissed state when show toggles back to true
    if (widget.show && !oldWidget.show) {
      _dismissed = false;
    }

    if (oldWidget.show != widget.show && !_dismissed) {
      widget.show ? _animController.forward() : _animController.reverse();
    }
    if (oldWidget.style.animationDuration != widget.style.animationDuration) {
      _animController.duration = widget.style.animationDuration;
    }
    if (oldWidget.style.animationCurve != widget.style.animationCurve) {
      _buildAnimations();
    }
    // Re-showing a banner restarts its clock. It used to start once, in
    // `initState`, so a banner shown again after an auto-dismiss stayed
    // on screen for good.
    if (oldWidget.autoDismissDuration != widget.autoDismissDuration ||
        (widget.show && !oldWidget.show)) {
      _autoDismissTimer?.cancel();
      _autoDismissTimer = null;
      _startAutoDismiss();
    }
    if (oldWidget.style.animationDuration != widget.style.animationDuration) {
      _expandController.duration =
          widget.style.animationDuration ?? BannerDefaults.animDuration;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _swipeController.dispose();
    _expandController.dispose();
    _countdown?.dispose();
    _autoDismissTimer?.cancel();
    _animController.removeStatusListener(_onAnimationStatus);
    _sizeAnim?.dispose();
    _visualAnim?.dispose();
    _wholeAnim?.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _startAutoDismiss() {
    final duration = widget.autoDismissDuration;
    if (duration == null || !widget.show || _dismissed) return;
    _autoDismissRemaining = duration;
    _autoDismissStartedAt = DateTime.now();
    _autoDismissTimer = Timer(duration, _dismiss);

    _countdown?.dispose();
    _countdown = AnimationController(vsync: this, duration: duration)
      ..forward();
  }

  void _dismiss({bool bySwipe = false}) {
    if (_dismissed) return;
    _dismissed = true;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _autoDismissRemaining = null;
    _animController.reverse().then((_) {
      if (mounted) widget.onDismiss?.call();
    });
    if (bySwipe) _offerUndo();
  }

  /// Raises the toast that offers the swipe back.
  ///
  /// A swipe is the one dismissal that happens by accident — there is
  /// no target to have meant to hit — and until now it took the notice
  /// with it for good. The toast is the standard answer and the module
  /// already ships one, so this is a call rather than a mechanism.
  void _offerUndo() {
    final undo = widget.onUndo;
    if (undo == null) return;
    GlobalToast.info(
      CommonStrings.dismissed,
      // WHICH notice went. Two banners can be on a page, and "Dismissed"
      // on its own does not say which one you lost.
      description: widget.title,
      actionLabel: CommonStrings.undo,
      onAction: undo,
    );
  }

  void _toggleExpanded() {
    if (!widget.collapsible) return;
    setState(() => _expanded = !_expanded);
    _expanded ? _expandController.forward() : _expandController.reverse();
  }

  // ─── Swipe ─────────────────────────────────────────────────

  bool get _canSwipe => widget.dismissible && widget.swipeToDismiss;

  void _onSwipeStart(DragStartDetails d) => setState(() => _dragging = true);

  /// The finger's own travel, before resistance. Kept separately so the
  /// mapping stays invertible: damping the accumulated offset in place
  /// would make dragging back a different curve from dragging out.
  double _dragged = 0;

  void _onSwipeUpdate(DragUpdateDetails d, double width) {
    _dragged += d.delta.dx;
    setState(() => _swipe = _damped(_dragged, _threshold(width)));
  }

  double _threshold(double width) =>
      width * BannerDefaults.swipeDismissFraction;

  /// Follows the finger exactly up to the point of commitment, then
  /// only a quarter of it. The drag going heavy is what says the
  /// threshold is behind you.
  double _damped(double travel, double limit) {
    if (limit <= 0 || travel.abs() <= limit) return travel;
    final past = travel.abs() - limit;
    return travel.sign * (limit + past * BannerDefaults.swipeResistance);
  }

  /// How committed the swipe is, 0 to 1 at the dismiss threshold.
  double _swipeProgress(double dx, double width) {
    final limit = _threshold(width);
    return limit <= 0 ? 0 : (dx.abs() / limit).clamp(0.0, 1.0);
  }

  void _onSwipeEnd(DragEndDetails d, double width) {
    final flung =
        d.velocity.pixelsPerSecond.dx.abs() > BannerDefaults.swipeFlingVelocity;
    final far = _swipe.abs() >= _threshold(width);
    // Home either way. A banner that kept the finger's offset while it
    // dismissed was flying off the side of whatever bounded it — a
    // card, a padded list — so it read as being scissored rather than
    // as leaving. It slides back and fades out on the spot instead.
    _settleSwipe();
    if (flung || far) _dismiss(bySwipe: true);
  }

  /// Brings the banner back to its place, animated.
  void _settleSwipe() {
    setState(() => _dragging = false);
    _dragged = 0;
    if (_swipe == 0) return;
    _swipeReturn = Tween<double>(begin: _swipe, end: 0).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );
    _swipe = 0;
    _swipeController.forward(from: 0);
  }

  /// The glyph for this banner's type, unless the caller named one.
  IconData _resolveIcon() {
    if (widget.icon != null) return widget.icon!;
    return switch (widget.type) {
      BannerType.info => Icons.info_rounded,
      BannerType.success => Icons.check_circle_rounded,
      BannerType.warning => Icons.warning_rounded,
      BannerType.error => Icons.error_rounded,
      BannerType.custom => Icons.info_outline_rounded,
    };
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rs = widget.style.resolve(
      context,
      type: widget.type,
      disableAnimations: MediaQuery.disableAnimationsOf(context),
    );

    Widget banner = DecoratedBox(
      decoration: BoxDecoration(
        color: rs.backgroundGradient == null ? rs.backgroundColor : null,
        gradient: rs.backgroundGradient,
        borderRadius: rs.borderRadius,
        // A gradient border is PAINTED on top; a solid one underneath it
        // would draw a second line.
        border: rs.borderGradient == null
            ? Border.all(color: rs.borderColor, width: rs.borderWidth)
            : null,
        boxShadow: rs.shadow,
      ),
      child: ClipRRect(
        borderRadius: rs.borderRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: _contentPadding(context, rs),
              child: _buildContent(rs),
            ),
            if (_countdown != null && rs.autoDismissProgress)
              _buildCountdown(rs),
          ],
        ),
      ),
    );

    if (rs.borderGradient != null) {
      banner = CustomPaint(
        foregroundPainter: GradientBorderPainter(
          gradient: rs.borderGradient!,
          borderRadius: rs.borderRadius,
          borderWidth: rs.borderWidth,
        ),
        child: banner,
      );
    }

    if (_canSwipe) banner = _wrapSwipe(banner, rs);

    banner = _buildAnimation(banner, rs);

    return Semantics(
      label:
          widget.semanticLabel ?? '${widget.type.name} banner: ${widget.title}',
      liveRegion: true,
      // NOT excluded: the close button, the chevron and any actions are
      // controls in their own right, and a wrapper that swallowed them
      // would announce a notice nobody could act on.
      explicitChildNodes: true,
      child: banner,
    );
  }

  /// `Row(icon, Column(Row(title, controls), message, actions))`.
  ///
  /// The actions used to share the title's line, where a short button
  /// squeezed the title and a long title squeezed the button. They run
  /// along the BOTTOM edge now, under the description, which is the one
  /// place in the box whose width nothing else is competing for.
  ///
  /// `IntrinsicHeight` is what lets the glyph sit anywhere between the
  /// top of the text block and its middle: with `stretch`, the leading
  /// column is as tall as the row and its `Align` can place the glyph
  /// continuously, driven by the same controller as the message. The
  /// row's own `crossAxisAlignment` could only ever SNAP between two
  /// positions, which is why the glyph jumped while everything around
  /// it was still moving.
  ///
  /// The `LayoutBuilder` must stay OUTSIDE the `IntrinsicHeight` — one
  /// inside cannot answer an intrinsic query and throws.
  Widget _buildContent(ResolvedBannerStyle rs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = _textWidth(rs, constraints.maxWidth);
        final wraps = _wrapsWhenShown(context, rs, textWidth);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment(0, _leadingY(wraps)),
                // The `Align` fills the row so it has somewhere to
                // place the glyph, and hands the glyph that height as a
                // LOOSE bound — which a `GlobalIcon` with a container
                // behind it happily takes all of, ending up a
                // paragraph tall and centred whatever the alignment
                // said. A min-height column gives it back its own size.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildLeading(rs)],
                ),
              ),
              SizedBox(width: rs.iconSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTitleRow(rs),
                    if (widget.message != null) _buildMessage(rs, textWidth),
                    if (widget.actions?.isNotEmpty ?? false) _buildActions(rs),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Width the text block actually gets — everything left after the
  /// leading glyph and its gap.
  double _textWidth(ResolvedBannerStyle rs, double available) =>
      available -
      rs.iconSize -
      BannerDefaults.iconPadding.horizontal -
      rs.iconSpacing;

  /// Whether a trailing control is present, which decides the trailing
  /// inset — see [_contentPadding].
  bool get _hasTrailingControl =>
      widget.dismissible || (widget.collapsible && widget.message != null);

  /// The banner's inset, less the trailing control's own.
  ///
  /// The controls carry an inset of their own so their ripple has a
  /// circle to fill, and that inset is invisible — so with the full
  /// padding behind it the ✕ sat a control's-worth further from the
  /// edge than the glyph on the other side, and a long title left a
  /// conspicuous hole after it. Trimming the box by the control's inset
  /// puts the two glyphs the same distance from their edges.
  EdgeInsets _contentPadding(BuildContext context, ResolvedBannerStyle rs) {
    if (!_hasTrailingControl) return rs.padding;
    final trim = BannerDefaults.controlPadding.right;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    double back(double side) => (side - trim).clamp(0.0, double.infinity);
    return EdgeInsets.only(
      top: rs.padding.top,
      bottom: rs.padding.bottom,
      left: ltr ? rs.padding.left : back(rs.padding.left),
      right: ltr ? back(rs.padding.right) : rs.padding.right,
    );
  }

  /// Where the leading glyph sits on the row's vertical axis: `-1` at
  /// the top, `0` centred.
  ///
  /// CONSTANT, deliberately. Interpolating it toward the centre as the
  /// message folded away made the glyph drift down and come back: the
  /// offset from the top is `(rowHeight - glyph) × (1 + y) / 2`, and
  /// with both terms moving at once that product peaks in the middle
  /// and returns to zero at both ends. It never needed to move —
  /// collapsed, the row is the glyph's own height and the alignment
  /// stops mattering.
  ///
  /// Top whenever the block is more than one line's worth: a wrapping
  /// message, or an action row under it. Centred otherwise — a glyph
  /// pinned to the top of a short block sits visibly high.
  double _leadingY(bool wraps) =>
      wraps || (widget.actions?.isNotEmpty ?? false) ? -1.0 : 0.0;

  /// Whether the message would run to more than one line at [width].
  ///
  /// Measured rather than guessed, and measured for the message SHOWN —
  /// a target that changed halfway through a collapse would move the
  /// glyph twice. One line of description still leaves a short block,
  /// and a glyph pinned to the top of that sits visibly high.
  bool _wrapsWhenShown(
    BuildContext context,
    ResolvedBannerStyle rs,
    double width,
  ) {
    final message = widget.message;
    if (message == null || !width.isFinite || width <= 0) return false;

    final painter = TextPainter(
      text: TextSpan(text: message, style: rs.messageStyle),
      textDirection: Directionality.of(context),
    )..layout(maxWidth: width);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    return lines > 1;
  }

  Widget _buildTitleRow(ResolvedBannerStyle rs) {
    return Row(
      children: [
        Expanded(child: _buildTitle(rs)),
        if (widget.dismissible) ...[
          const SizedBox(width: BannerDefaults.actionSpacing),
          GlobalIcon(
            icon: Icons.close_rounded,
            semanticLabel: CommonStrings.dismiss,
            onTap: _dismiss,
            style: IconStyle(
              size: BannerDefaults.closeIconSize,
              color: rs.controlColor,
              // A bare glyph has no container, so its ripple takes the
              // glyph's SQUARE box. The circle is what makes a splash
              // read as a button.
              containerShape: IconContainerShape.circle,
              padding: BannerDefaults.controlPadding,
            ),
          ),
        ],
        if (widget.collapsible && widget.message != null) ...[
          const SizedBox(width: BannerDefaults.chevronSpacing),
          // A `GestureDetector` around a bare `Icon` before: the control
          // that hides half the banner's text was invisible to a screen
          // reader and had no name.
          AnimatedRotation(
            turns: _expanded ? 0 : BannerDefaults.chevronCollapsedTurns,
            duration: rs.animationDuration,
            curve: rs.animationCurve,
            child: GlobalIcon(
              icon: Icons.keyboard_arrow_down_rounded,
              semanticLabel: _expanded
                  ? CommonStrings.collapse
                  : CommonStrings.expand,
              onTap: _toggleExpanded,
              style: IconStyle(
                size: BannerDefaults.chevronSize,
                color: rs.controlColor,
                containerShape: IconContainerShape.circle,
                padding: BannerDefaults.controlPadding,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitle(ResolvedBannerStyle rs) {
    if (!rs.marqueeTitle) {
      return Text(
        widget.title,
        style: rs.titleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    // The title shares its line with both controls, so it is the first
    // thing to run out of room — and a cut-off notice is a notice you
    // cannot read.
    return GlobalText(
      widget.title,
      textStyle: GlobalTextStyle(
        color: rs.titleStyle.color,
        fontSize: rs.titleStyle.fontSize,
        fontWeight: rs.titleStyle.fontWeight,
      ),
      maxLines: 1,
      // Pause-on-touch is FORCED off. It installs a pan recognizer,
      // which wins the gesture arena against the banner's own
      // swipe-to-dismiss — so with the marquee on by default, no banner
      // could be swiped away at all. `GlobalTextButton` forces it off
      // for the same reason.
      marquee: const MarqueeStyle(pauseOnTouch: false),
    );
  }

  /// The actions, along the bottom edge, in the banner's own colour.
  Widget _buildActions(ResolvedBannerStyle rs) {
    final actions = widget.actions!;
    return Padding(
      padding: const EdgeInsets.only(top: BannerDefaults.actionTopSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: BannerDefaults.actionSpacing),
            _buildAction(rs, actions[i]),
          ],
        ],
      ),
    );
  }

  /// One action, as a LINK.
  ///
  /// A filled or outlined button inside a notice competes with the
  /// page's own primary action; a ruled label reads as "more about
  /// this", which is what a banner offers.
  ///
  /// The 48dp touch floor is OFF, which is the one real cost here: the
  /// row is a link's height, so the target is the label's box and not a
  /// square inch. That is the shape asked for, and the trade is
  /// deliberate — a banner always has a second, full-size path to the
  /// same place (the page it is talking about), and its ✕ keeps its
  /// own full target.
  Widget _buildAction(ResolvedBannerStyle rs, BannerAction action) {
    return GlobalTextButton(
      text: action.label,
      icon: action.icon,
      shrinkWidth: true,
      size: ButtonSize.small,
      link: true,
      underline: LinkUnderline.onHover,
      enforceMinTouchTarget: false,
      onPressed: action.onPressed,
      enabled: action.onPressed != null,
      style: ButtonStateStyle(
        padding: BannerDefaults.actionPadding,
        backgroundColor: Colors.transparent,
        foregroundColor: rs.foregroundColor,
        textStyle: rs.actionStyle,
        borderRadius: BorderRadius.circular(BannerDefaults.actionRadius),
      ),
    );
  }

  /// The message, folded away a LINE at a time rather than crossfaded.
  ///
  /// A crossfade swapped the whole block at once, which reads as a
  /// flicker. Uncovering it with a single height factor was better but
  /// still one gesture — the text was a curtain. Each line now has its
  /// own slice of the controller and its own slide back toward the
  /// start, so the paragraph funnels away from the bottom up and
  /// arrives the same way.
  Widget _buildMessage(ResolvedBannerStyle rs, double width) {
    final message = Padding(
      padding: const EdgeInsets.only(top: BannerDefaults.messageSpacing),
      child: Text(widget.message!, style: rs.messageStyle),
    );
    if (!widget.collapsible) return message;

    return AnimatedBuilder(
      animation: _expandController,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_expandController.value);
        if (t == 0) return const SizedBox.shrink();
        // Fully open is the plain paragraph — identical to the
        // non-collapsible case, and one text run instead of many.
        if (t == 1) return message;
        return _FunnellingText(
          text: widget.message!,
          style: rs.messageStyle,
          width: width,
          progress: t,
          topSpacing: BannerDefaults.messageSpacing,
        );
      },
    );
  }

  /// The line that runs out as the auto-dismiss does.
  Widget _buildCountdown(ResolvedBannerStyle rs) {
    return AnimatedBuilder(
      animation: _countdown!,
      builder: (context, _) => SizedBox(
        height: rs.progressHeight,
        child: GlobalProgress.linear(
          value: 1 - _countdown!.value,
          style: ProgressStyle(
            thickness: rs.progressHeight,
            color: rs.controlColor,
            trackColor: rs.progressTrackColor,
            capStyle: ProgressCapStyle.flat,
            animated: false,
          ),
        ),
      ),
    );
  }

  Widget _wrapSwipe(Widget banner, ResolvedBannerStyle rs) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        // OUT of the semantics tree. A drag detector publishes a node
        // with scroll actions and swallows everything under it into it:
        // the title, the close button and the chevron all merged into
        // one unnamed scrollable, so the banner had no controls left.
        // The swipe is a convenience for pointers; the ✕ is the
        // accessible path and keeps its own node.
        excludeFromSemantics: true,
        onHorizontalDragStart: _onSwipeStart,
        onHorizontalDragUpdate: (d) => _onSwipeUpdate(d, constraints.maxWidth),
        onHorizontalDragEnd: (d) => _onSwipeEnd(d, constraints.maxWidth),
        onHorizontalDragCancel: _settleSwipe,
        // The finger's offset EXACTLY while it is down — an implicit
        // animation would put a frame between the two — and an animated
        // return once it lifts.
        child: AnimatedBuilder(
          animation: _swipeController,
          builder: (context, child) {
            final dx = _dragging ? _swipe : (_swipeReturn?.value ?? _swipe);
            // Keyed to the THRESHOLD, not the banner's width. Against
            // the width it was still at two-thirds opacity when the
            // swipe was already far enough to dismiss, so nothing on
            // screen said the decision had been made. It stops short of
            // invisible, because a swipe released below the threshold
            // has to look recoverable.
            final progress = _swipeProgress(dx, constraints.maxWidth);
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(
                scale: 1 - BannerDefaults.swipeShrink * progress,
                child: Opacity(
                  opacity: 1 - BannerDefaults.swipeFade * progress,
                  child: child,
                ),
              ),
            );
          },
          child: banner,
        ),
      ),
    );
  }

  Widget _buildLeading(ResolvedBannerStyle rs) {
    if (widget.leading != null) return widget.leading!;
    if (widget.iconWidget != null) return widget.iconWidget!;

    return GlobalIcon(
      icon: _resolveIcon(),
      style: IconStyle(
        size: rs.iconSize,
        color: rs.foregroundColor,
        backgroundColor: rs.iconDiscColor,
        containerShape: IconContainerShape.rounded,
        padding: BannerDefaults.iconPadding,
      ),
    );
  }

  Widget _buildAnimation(Widget child, ResolvedBannerStyle rs) {
    final inner = switch (rs.animation) {
      BannerAnimation.slide => SlideTransition(
        position: _slideAnim,
        child: child,
      ),
      BannerAnimation.fade => FadeTransition(opacity: _fadeAnim, child: child),
      BannerAnimation.slideFade => FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(position: _slideFadeAnim, child: child),
      ),
      BannerAnimation.scale => FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(scale: _scaleAnim, child: child),
      ),
      BannerAnimation.expand || BannerAnimation.none => child,
    };

    if (rs.animation.isNone) return inner;

    // Every kind collapses its own height. A hidden banner used to keep
    // its box — faded to nothing but still holding a gap in the page,
    // which reads as a layout bug rather than as a dismissal.
    //
    // `expand` gets the WHOLE range: the height is the animation there,
    // so half of it would leave the second half doing nothing at all.
    return SizeTransition(
      sizeFactor: rs.animation == BannerAnimation.expand
          ? _wholeAnim!
          : _sizeAnim!,
      alignment: Alignment.topCenter,
      child: inner,
    );
  }
}

// ---------------------------------------------------------------------------
// _FunnellingText
// ---------------------------------------------------------------------------

/// A paragraph that folds away one line at a time, from the bottom up.
///
/// [progress] is 1 for the whole paragraph and 0 for none of it. Each
/// line gets an equal slice of that range — the last line's slice is
/// the highest, so it is the first to go — and inside its own slice a
/// line loses its height, its opacity and its place at once, sliding
/// back toward the start as it closes.
///
/// Takes an explicit [width] rather than measuring one: it renders
/// inside an `IntrinsicHeight`, and a `LayoutBuilder` in there cannot
/// answer an intrinsic query.
class _FunnellingText extends StatelessWidget {
  const _FunnellingText({
    required this.text,
    required this.style,
    required this.width,
    required this.progress,
    required this.topSpacing,
  });

  final String text;
  final TextStyle style;
  final double width;
  final double progress;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final lines = _splitLines(text, style, width, direction);
    final span = 1 / lines.length;
    final away = direction == TextDirection.ltr
        ? -BannerDefaults.messageFunnel
        : BannerDefaults.messageFunnel;

    // The gap above the paragraph belongs to its first line, so it
    // closes with it instead of leaving a stray band behind.
    final head = _slice(0, span);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: topSpacing * head),
        for (var i = 0; i < lines.length; i++)
          _line(lines[i], _slice(i, span), away),
      ],
    );
  }

  /// How much of line [i] is left. Line 0 empties last.
  double _slice(int i, double span) =>
      ((progress - i * span) / span).clamp(0.0, 1.0);

  Widget _line(String line, double t, double away) {
    if (t == 0) return const SizedBox.shrink();
    return ClipRect(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        heightFactor: t,
        child: Transform.translate(
          offset: Offset(away * (1 - t), 0),
          child: Opacity(
            opacity: t,
            child: SizedBox(
              width: width,
              child: Text(
                line,
                style: style,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Where the paragraph breaks at [width], so each line can be drawn —
  /// and animated — on its own.
  static List<String> _splitLines(
    String text,
    TextStyle style,
    double width,
    TextDirection direction,
  ) {
    if (width <= 0 || !width.isFinite) return <String>[text];

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
    )..layout(maxWidth: width);

    final lines = <String>[];
    var offset = 0;
    // Bounded on both counts: a boundary that fails to advance ends the
    // walk, and the ceiling covers whatever a future engine does with a
    // pathological string. Neither is a normal exit.
    while (offset < text.length &&
        lines.length < BannerDefaults.maxMessageLines) {
      final boundary = painter.getLineBoundary(TextPosition(offset: offset));
      if (boundary.end <= offset) break;
      lines.add(text.substring(offset, boundary.end));
      offset = boundary.end;
    }
    painter.dispose();

    if (offset < text.length) lines.add(text.substring(offset));
    return lines.isEmpty ? <String>[text] : lines;
  }
}
