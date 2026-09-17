import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import 'button_internals.dart';
import 'button_models.dart';

export 'swipe_button_style.dart';

/// Puts a confirmed swipe button back.
///
/// Once the thumb has landed the control is spent — and an action that
/// turns out to be wrong, or a form that is being filled in again,
/// needs it back. The widget cannot know when that is, so the caller
/// says.
///
/// ```dart
/// final controller = GlobalSwipeButtonController();
/// ...
/// GlobalSwipeButton(controller: controller, ...);
/// ...
/// controller.reset();
/// ```
class GlobalSwipeButtonController extends ChangeNotifier {
  _GlobalSwipeButtonState? _state;

  /// Whether the thumb is at the end.
  bool get isConfirmed => _state?._confirmed ?? false;

  /// Sends the thumb home, running the travel backwards.
  Future<void> reset() async => _state?._reset();

  void _attach(_GlobalSwipeButtonState state) => _state = state;

  void _detach(_GlobalSwipeButtonState state) {
    // Ownership check: a controller handed to a new button while the
    // old one is still tearing down would otherwise be unhooked by the
    // corpse.
    if (identical(_state, state)) _state = null;
  }
}

/// Swipe to confirm.
///
/// A BUTTON, not a slider — which is the whole reason it lives here.
/// It has no value: one destination, and it reports an action. A
/// screen reader hears "button" and fires it with one activation; the
/// slider only lends it the mechanics of dragging something along a
/// track.
///
/// The friction exists for a thumb that might brush the screen, not as
/// a puzzle. Anything a pointer can do here, a keyboard and a screen
/// reader can do in one step — see [onConfirmed].
class GlobalSwipeButton extends StatefulWidget {
  const GlobalSwipeButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.confirmedLabel,
    this.icon = Icons.chevron_right_rounded,
    this.thumbBuilder,
    this.enabled = true,
    this.isLoading = false,
    this.result = ButtonResult.none,
    this.onResultShown,
    this.style,
    this.disabledStyle,
    this.loadingStyle,
    this.successStyle,
    this.errorStyle,
    this.completionDuration = const Duration(milliseconds: 1200),
    this.debounceDuration,
    this.enableHaptic,
    this.semanticLabel,
    this.controller,
    this.axis = Axis.horizontal,
    this.extent,
    this.confirmedIcon = Icons.check_rounded,
    this.resetAfter,
    this.onProgress,
    this.dragAnywhere = false,
  });

  /// What the track says at rest.
  final String label;

  /// What it says once it has been confirmed. Null keeps [label].
  final String? confirmedLabel;

  /// Fired ONCE, when a drag is released at or past the threshold.
  ///
  /// Also fired by Enter, by Space, and by a screen reader's tap: a
  /// drag gesture is a barrier for anyone who cannot make one, and a
  /// confirmation nobody can give is not a confirmation.
  final VoidCallback? onConfirmed;

  /// The glyph in the thumb. Ignored when [thumbBuilder] is given.
  final IconData icon;

  /// The glyph once it has been confirmed.
  ///
  /// Left as the chevron, a spent control still reads "swipe me" the
  /// moment the completion flash clears.
  final IconData confirmedIcon;

  /// Which way it travels.
  ///
  /// Vertical confirms UPWARDS — the same "up is more" the vertical
  /// slider follows. It does NOT mirror: only the horizontal one has a
  /// reading direction to follow.
  final Axis axis;

  /// How long a VERTICAL track is. Ignored when horizontal.
  ///
  /// A length rather than "fill the parent", for the reason the
  /// vertical slider's is: a button in a column has no natural height.
  final double? extent;

  /// Sends it home on its own, this long after confirming.
  ///
  /// For an action that re-arms — a refresh, a resend. The controller
  /// covers deliberate undo; this covers not having to hold one just
  /// to make the control usable twice.
  final Duration? resetAfter;

  /// Travel, 0..1, as it happens.
  ///
  /// For a caller who wants to drive something alongside it — a total
  /// turning red, a summary fading. Without it a drag is a black box
  /// until it commits.
  final ValueChanged<double>? onProgress;

  /// Whether the whole TRACK takes the drag, not just the thumb.
  ///
  /// Off by default, and it should stay off inside anything that
  /// scrolls: the track would swallow every horizontal drag that
  /// started on it, and a page view carrying one could not be swiped
  /// away. On is for a control that owns its row.
  final bool dragAnywhere;

  /// Full control of the thumb's contents.
  final Widget Function(BuildContext context, double progress)? thumbBuilder;

  final bool enabled;

  /// Parks the thumb at the end with an indicator in it.
  final bool isLoading;

  /// The completion flash, exactly as the other four buttons take it.
  /// An error springs the thumb back; a success leaves it where it is.
  final ButtonResult result;
  final VoidCallback? onResultShown;

  /// Per-call visual overrides.
  /// `caller > GlobalButtonsTheme.swipeStyle > SwipeButtonStyle.defaults`.
  final SwipeButtonStyle? style;

  final ButtonStateStyle? disabledStyle;
  final ButtonLoadingStyle? loadingStyle;
  final ButtonStateStyle? successStyle;
  final ButtonStateStyle? errorStyle;

  final Duration completionDuration;
  final Duration? debounceDuration;
  final bool? enableHaptic;

  /// Puts it back after it has been confirmed. See
  /// [GlobalSwipeButtonController].
  final GlobalSwipeButtonController? controller;

  /// What the control is CALLED, when the label says what to do rather
  /// than what it does — "Swipe to pay" is an instruction, and a
  /// reader who cannot swipe should still hear "Pay".
  final String? semanticLabel;

  @override
  State<GlobalSwipeButton> createState() => _GlobalSwipeButtonState();
}

class _GlobalSwipeButtonState extends State<GlobalSwipeButton>
    with TickerProviderStateMixin, ButtonBehaviorMixin<GlobalSwipeButton> {
  /// How far along the thumb is, 0..1.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1),
  );

  /// The shimmer that says the track can be dragged.
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: SwipeButtonDefaults.hintDuration,
  );

  ResolvedSwipeButtonStyle? _style;

  /// Whether a drag has already committed, so the callback fires once
  /// per swipe rather than once per frame past the threshold.
  bool _confirmed = false;

  /// Whether the threshold has been crossed during THIS drag, so the
  /// commit-point haptic fires on the crossing and not after it.
  bool _pastThreshold = false;

  /// The track's length along the axis it travels.
  double _trackLength = 0;

  /// Fires [GlobalSwipeButton.resetAfter].
  Timer? _autoReset;

  /// The last value handed to [GlobalSwipeButton.onProgress], so a
  /// caller is not woken for a frame that changed nothing.
  double _reported = 0;

  bool get _vertical => widget.axis == Axis.vertical;

  /// Whether the KEYBOARD is on it.
  ///
  /// `FocusableActionDetector` tells us when the highlight should
  /// show, which is not the same as having focus: a tap focuses it too,
  /// and a ring on a tapped control reads as "still focused" long
  /// after the reader has moved on.
  bool _focusVisible = false;

  @override
  void initState() {
    super.initState();
    syncButtonResult(
      result: widget.result,
      isLoading: widget.isLoading,
      completionDuration: widget.completionDuration,
      onResultShown: widget.onResultShown,
    );
    widget.controller?._attach(this);
    _progress.addListener(_reportProgress);
  }

  void _reportProgress() {
    final value = _progress.value;
    if ((value - _reported).abs() < 0.001) return;
    _reported = value;
    widget.onProgress?.call(value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion is an INHERITED read, so it cannot happen in
    // `initState` — and the hint loop asks for it on its first turn.
    _reduce = MediaQuery.disableAnimationsOf(context);
    _restartHint();
  }

  @override
  void didUpdateWidget(GlobalSwipeButton old) {
    super.didUpdateWidget(old);
    if (widget.result != old.result || widget.isLoading != old.isLoading) {
      syncButtonResult(
        result: widget.result,
        isLoading: widget.isLoading,
        completionDuration: widget.completionDuration,
        onResultShown: widget.onResultShown,
      );
    }
    // An error sends it home: the action did not happen, so the
    // control must be ready to be asked again.
    if (widget.result == ButtonResult.error &&
        old.result != ButtonResult.error) {
      _reset();
    }
    if (widget.enabled != old.enabled) _restartHint();
    if (widget.controller != old.controller) {
      old.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _autoReset?.cancel();
    _progress.removeListener(_reportProgress);
    _hintPause?.cancel();
    _hintRun++;
    _progress.dispose();
    _hint.dispose();
    disposeButtonBehavior();
    super.dispose();
  }

  // ─── The hint ──────────────────────────────────────────────

  bool _reduce = false;

  /// Which hint loop is the live one.
  ///
  /// Restarting has to CANCEL the loop already running, or every
  /// dependency change leaves another one turning and the shimmer
  /// speeds up with each.
  int _hintRun = 0;

  /// The wait between sweeps, held so it can be CANCELLED.
  ///
  /// A bare `Future.delayed` outlives the widget: the tree is torn
  /// down and the timer is still pending, which a test binding
  /// reports and a real app pays for.
  Timer? _hintPause;

  /// Sweeps, waits, sweeps again — a shimmer running non-stop reads as
  /// a loading bar rather than an invitation.
  Future<void> _restartHint() async {
    final run = ++_hintRun;
    _hint.stop();
    _hint.value = 0;
    if (_reduce) return;

    for (var i = 0; i < SwipeButtonDefaults.hintSweeps; i++) {
      if (!mounted || run != _hintRun || !widget.enabled || _confirmed) return;
      await _hint.forward(from: 0);
      if (!mounted || run != _hintRun) return;
      if (i < SwipeButtonDefaults.hintSweeps - 1) {
        await _wait(SwipeButtonDefaults.hintPause);
      }
    }
    // Rest at the far end rather than mid-sweep, so the label is left
    // whole instead of half-lit.
    if (mounted && run == _hintRun) _hint.value = 0;
  }

  bool get _reduceMotion => _reduce;

  /// A cancellable pause.
  Future<void> _wait(Duration duration) {
    final done = Completer<void>();
    _hintPause?.cancel();
    _hintPause = Timer(duration, () {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  // ─── The gesture ───────────────────────────────────────────

  bool get _interactive =>
      widget.enabled && widget.onConfirmed != null && !widget.isLoading;

  /// The travel available to the thumb.
  double _travel(ResolvedSwipeButtonStyle style) => math.max(
    1,
    _trackLength - style.trackHeight,
  );

  void _onDragStart() {
    if (!_interactive || _confirmed) return;
    _pastThreshold = false;
    if (_style?.enableHaptic ?? true) HapticFeedback.lightImpact();
  }

  void _onDragUpdate(Offset delta, ResolvedSwipeButtonStyle style) {
    if (!_interactive || _confirmed) return;
    // VERTICAL confirms upwards, so a negative dy is forward — the
    // same "up is more" the vertical slider follows. It does NOT
    // mirror: only the horizontal one has a reading direction.
    //
    // In Arabic the horizontal thumb starts at the RIGHT and travels
    // left, so the same physical drag is the opposite sign.
    final signed = _vertical ? -delta.dy : (_rtl ? -delta.dx : delta.dx);
    _progress.value = (_progress.value + signed / _travel(style)).clamp(
      0.0,
      1.0,
    );

    final past = _progress.value >= style.confirmThreshold;
    if (past != _pastThreshold) {
      _pastThreshold = past;
      // At the COMMIT POINT, so the reader feels it before letting go
      // rather than finding out afterwards.
      if (past && style.enableHaptic) HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(ResolvedSwipeButtonStyle style, Velocity velocity) {
    if (!_interactive || _confirmed) return;
    if (_progress.value >= style.confirmThreshold) {
      _commit(style);
      return;
    }
    // A FLING, when the caller has asked for one. Off by default: a
    // flick is the gesture most likely to happen without meaning, and
    // this control exists so that cannot fire anything.
    final fling = style.flingVelocity;
    if (fling != null && _progress.value > 0) {
      final speed = _vertical
          ? -velocity.pixelsPerSecond.dy
          : (_rtl ? -velocity.pixelsPerSecond.dx : velocity.pixelsPerSecond.dx);
      if (speed >= fling) {
        _commit(style);
        return;
      }
    }
    // Short of the mark: home, and nothing reported. Releasing IS the
    // deliberate act — committing on the crossing instead would let a
    // fast flick fire something nobody meant.
    _progress.animateTo(
      0,
      duration: _reduceMotion ? Duration.zero : style.returnDuration,
      curve: Curves.easeOut,
    );
    _pastThreshold = false;
  }

  void _commit(ResolvedSwipeButtonStyle style) {
    setState(() => _confirmed = true);
    _hint.stop();
    _progress.animateTo(
      1,
      duration: _reduceMotion ? Duration.zero : style.settleDuration,
      curve: Curves.easeOut,
    );
    if (style.enableHaptic) HapticFeedback.mediumImpact();
    _fire();

    final after = widget.resetAfter;
    _autoReset?.cancel();
    if (after != null) {
      _autoReset = Timer(after, () {
        if (mounted) unawaited(_reset());
      });
    }
  }

  /// Through the shared debounce, like every other button here.
  void _fire() {
    debouncedCallback(
      widget.onConfirmed,
      debounce: widget.debounceDuration,
      // The COMMIT haptic has already fired, at the moment the thumb
      // landed. A second one from the debounce wrapper on the same
      // gesture is a stutter.
      haptic: false,
    )?.call();
  }

  /// Sends the thumb home.
  ///
  /// It ANIMATES: an error that snapped the thumb back to the start
  /// looked like a different control appearing, and gave the reader no
  /// sense that what they did had been undone. Running the same travel
  /// backwards says it.
  Future<void> _reset({bool animate = true}) async {
    if (!mounted) return;
    _autoReset?.cancel();
    setState(() => _confirmed = false);
    _pastThreshold = false;
    final style = _style;
    if (animate && style != null && !_reduceMotion) {
      await _progress.animateTo(
        0,
        duration: style.returnDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _progress.value = 0;
    }
    // Deliberately not awaited: the hint loop runs for as long as the
    // control is idle, and nothing waits for it to finish.
    if (mounted) unawaited(_restartHint());
  }

  /// What Enter, Space and a screen reader's tap do.
  void _activate() {
    if (!_interactive || _confirmed) return;
    final style = _style;
    if (style == null) return;
    _commit(style);
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final style = _resolve(context);
    _style = style;

    final radius = BorderRadius.circular(style.trackRadius);
    final label = _confirmed
        ? (widget.confirmedLabel ?? widget.label)
        : widget.label;

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.semanticLabel ?? label,
      onTap: _interactive ? _activate : null,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: _interactive,
          mouseCursor: _interactive
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowFocusHighlight: (visible) {
            if (_focusVisible == visible) return;
            setState(() => _focusVisible = visible);
          },
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              _trackLength = _lengthFor(constraints, style);
              assert(
                _trackLength >=
                    style.trackHeight * SwipeButtonDefaults.minLengthFactor,
                'A swipe button needs room to swipe: ${_trackLength.round()} '
                'along the ${_vertical ? 'vertical' : 'horizontal'} axis '
                'leaves the thumb '
                '${(_trackLength - style.trackHeight).round()} to travel. '
                'Give it at least '
                '${(style.trackHeight * SwipeButtonDefaults.minLengthFactor).round()}, '
                'or use a GlobalButton — a control too short to swipe is a '
                'tap target that refuses taps.',
              );

              final sized = SizedBox(
                height: _vertical ? _trackLength : style.trackHeight,
                width: _vertical ? style.trackHeight : _trackLength,
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: <Type, GestureRecognizerFactory>{
                    // Claims the pointer the moment it lands ON THE
                    // THUMB, and declines it everywhere else. A plain
                    // `GestureDetector` loses a horizontal drag to an
                    // enclosing page view or scroll view — a swipe
                    // button lives in a checkout sheet, which is
                    // exactly the place that happens.
                    _SwipeThumbRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          _SwipeThumbRecognizer
                        >(() => _SwipeThumbRecognizer(), (r) {
                          // `dragAnywhere` takes the whole track,
                          // which is why it is off by default: the
                          // track would swallow every drag that
                          // started on it, and a page view carrying
                          // one could not be swiped away.
                          r.isOnThumb = (local) =>
                              widget.dragAnywhere || _hitsThumb(local, style);
                          r.onSwipeStart = _onDragStart;
                          r.onSwipeUpdate = (d) => _onDragUpdate(d, style);
                          r.onSwipeEnd = (v) => _onDragEnd(style, v);
                        }),
                  },
                  child: _buildTrack(context, style, radius, label),
                ),
              );

              return Opacity(
                opacity: widget.enabled ? 1 : style.disabledOpacity,
                // A vertical track keeps its OWN width: a tight
                // horizontal constraint — a column stretching it —
                // would otherwise smear the pill sideways and leave
                // the thumb rattling in a box it does not fill.
                child: _vertical
                    // Shrink-wrapped, or `Align` fills the loose box it
                    // was handed and the button reports a height it
                    // does not paint.
                    ? Align(widthFactor: 1, heightFactor: 1, child: sized)
                    : sized,
              );
            },
          ),
        ),
      ),
    );
  }

  /// How long the track is along the axis it travels.
  ///
  /// An unbounded constraint is the common case for the VERTICAL one —
  /// a column hands its children infinite height — so it falls back to
  /// [SwipeButtonDefaults.verticalExtent] rather than overflowing.
  double _lengthFor(
    BoxConstraints constraints,
    ResolvedSwipeButtonStyle style,
  ) {
    final given = widget.extent;
    if (given != null) return given;
    final available = _vertical ? constraints.maxHeight : constraints.maxWidth;
    if (available.isFinite) return available;
    return _vertical
        ? SwipeButtonDefaults.verticalExtent
        : style.trackHeight * 5;
  }

  /// The fill behind the thumb.
  ///
  /// It carries the thumb's own extent too, or the fill stops at the
  /// thumb's leading edge and a gap shows under it.
  Widget _buildFill(ResolvedSwipeButtonStyle style, double offset) {
    final radius = style.fillEndRadius;
    // Only the MOVING edge is rounded — the other end is pinned to the
    // track's own corner and takes its curve from the clip.
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: style.fillColor,
        borderRadius: _vertical
            ? BorderRadius.vertical(top: Radius.circular(radius))
            : BorderRadiusDirectional.horizontal(
                end: Radius.circular(radius),
              ),
      ),
    );

    if (_vertical) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: offset + style.trackHeight,
        child: child,
      );
    }
    return PositionedDirectional(
      start: 0,
      top: 0,
      bottom: 0,
      width: offset + style.trackHeight,
      child: child,
    );
  }

  /// Whether a local point is on the thumb.
  bool _hitsThumb(Offset local, ResolvedSwipeButtonStyle style) {
    final travel = _travel(style);
    final start = style.thumbInset + travel * _progress.value;
    // Measured from the END the thumb STARTS at: the bottom when
    // vertical, the right in Arabic.
    final x = _vertical
        ? _trackLength - local.dy
        : (_rtl ? _trackLength - local.dx : local.dx);
    final size = style.trackHeight - style.thumbInset * 2;
    // A GENEROUS reach: the thumb is the target, and a fingertip that
    // lands a few points off it should still take hold rather than
    // scrolling the page underneath.
    const slop = 12.0;
    return x >= start - slop && x <= start + size + slop;
  }

  Widget _buildTrack(
    BuildContext context,
    ResolvedSwipeButtonStyle style,
    BorderRadius radius,
    String label,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progress, _hint]),
      builder: (context, _) {
        final travel = _travel(style);
        final offset = travel * _progress.value;

        final track = ClipRRect(
          borderRadius: radius,
          // WITH a layer: a soft clip leaves a hairline of the fill
          // outside the curve, which is the bleed the toggle group's
          // corners had.
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.trackGradient == null ? style.trackColor : null,
              gradient: style.trackGradient,
            ),
            child: Stack(
              children: [
                if (style.fillTrack) _buildFill(style, offset),
                Positioned.fill(
                  child: Center(
                    child: _vertical
                        // Reads bottom-to-top, the way the thumb
                        // travels.
                        ? RotatedBox(
                            quarterTurns: 3,
                            child: _buildLabel(
                              context,
                              style,
                              label,
                              offset,
                              travel,
                            ),
                          )
                        : _buildLabel(context, style, label, offset, travel),
                  ),
                ),
                if (_vertical)
                  Positioned(
                    left: style.thumbInset,
                    right: style.thumbInset,
                    bottom: style.thumbInset + offset,
                    child: _buildThumb(context, style),
                  )
                else
                  PositionedDirectional(
                    start: style.thumbInset + offset,
                    top: style.thumbInset,
                    bottom: style.thumbInset,
                    child: _buildThumb(context, style),
                  ),
              ],
            ),
          ),
        );

        // The ring is ALWAYS in the tree and only its colour moves.
        // Adding and removing a wrapper changes the tree shape at this
        // slot and remounts the track under it, which restarts the
        // thumb's animation mid-travel.
        return Stack(
          children: [
            track,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: _reduceMotion
                      ? Duration.zero
                      : SwipeButtonDefaults.morphDuration,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: _focusVisible
                          ? style.focusRingColor
                          : Colors.transparent,
                      width: style.focusRingWidth,
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

  Widget _buildLabel(
    BuildContext context,
    ResolvedSwipeButtonStyle style,
    String label,
    double offset,
    double travel,
  ) {
    // It fades as the thumb covers it — a label still at full strength
    // under a thumb three-quarters of the way along reads as something
    // the control forgot to update.
    final fade = 1 - (offset / travel).clamp(0.0, 1.0);

    // Once it is done the label is the RESULT, so it sits at full
    // strength in a colour that reads on the fill. Fading it out like
    // an invitation nobody has taken up would leave a confirmed
    // control saying nothing.
    if (_confirmed) {
      return Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.labelStyle.copyWith(color: style.confirmedLabelColor),
      );
    }

    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style.labelStyle,
    );

    if (!style.showHint || _reduceMotion) {
      return Opacity(opacity: fade, child: text);
    }

    // A highlight sweeping across the words, in the direction the
    // reader is being asked to drag.
    return Opacity(
      opacity: fade,
      child: ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final t = _hint.value;
          final width = rect.width * SwipeButtonDefaults.hintWidthFactor;
          final centre = -width + (rect.width + width * 2) * t;
          return LinearGradient(
            // The rotation has already turned the vertical label's box,
            // so the sweep is left-to-right in ITS frame either way.
            begin: !_vertical && _rtl
                ? Alignment.centerRight
                : Alignment.centerLeft,
            end: !_vertical && _rtl
                ? Alignment.centerLeft
                : Alignment.centerRight,
            colors: [
              style.labelStyle.color ?? style.hintColor,
              style.hintColor,
              style.labelStyle.color ?? style.hintColor,
            ],
            stops: [
              ((centre - width) / rect.width).clamp(0.0, 1.0),
              (centre / rect.width).clamp(0.0, 1.0),
              ((centre + width) / rect.width).clamp(0.0, 1.0),
            ],
          ).createShader(rect);
        },
        child: text,
      ),
    );
  }

  Widget _buildThumb(BuildContext context, ResolvedSwipeButtonStyle style) {
    final size = style.trackHeight - style.thumbInset * 2;

    Widget content;
    if (widget.isLoading) {
      // The module's OWN indicator, like the other four variants use —
      // nothing here rolls its own Material spinner, and
      // `test/progress/progress_adoption_test.dart` says so.
      content = CircularIndicator(color: style.thumbForegroundColor);
    } else if (showingResult) {
      content = Icon(
        activeResult == ButtonResult.success
            ? Icons.check_rounded
            : Icons.close_rounded,
        color: style.thumbForegroundColor,
        size: size * 0.5,
      );
    } else if (_confirmed) {
      // Its own glyph once committed, so the thumb at the far end says
      // "done" rather than still pointing the way it came.
      content = Icon(
        widget.confirmedIcon,
        color: style.thumbForegroundColor,
        size: size * 0.6,
      );
    } else if (widget.thumbBuilder != null) {
      content = widget.thumbBuilder!(context, _progress.value);
    } else {
      content = Icon(
        widget.icon,
        color: style.thumbForegroundColor,
        size: size * 0.6,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.thumbColor,
          borderRadius: BorderRadius.circular(style.thumbRadius),
        ),
        child: Center(
          // One state MORPHS into the next. Swapped outright, the
          // thumb went empty for a frame between the chevron and the
          // spinner and read as a glitch.
          //
          // The key is the STATE, not the widget: two icons of the
          // same type are the same widget as far as the switcher is
          // concerned, so an icon-to-icon change would not animate at
          // all without it.
          child: AnimatedSwitcher(
            duration: _reduceMotion
                ? Duration.zero
                : SwipeButtonDefaults.morphDuration,
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: KeyedSubtree(
              key: ValueKey(_thumbStateFor(content)),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  /// What the thumb is showing, as a value the switcher can compare.
  ///
  /// A CUSTOM thumb contributes its own key. Two `Icon`s differ only by
  /// a field, so `Widget.canUpdate` calls them the same widget and the
  /// switcher does not animate — a `thumbBuilder` that swaps its glyph
  /// halfway along changed instantly while every built-in state
  /// morphed. Only the caller knows what "different" means for their
  /// widget, so they say it with a key.
  String _thumbStateFor(Widget content) {
    if (widget.isLoading) return 'loading';
    if (showingResult) return 'result-${activeResult.name}';
    if (_confirmed) return 'confirmed';
    return 'idle:${content.key}';
  }

  // ─── Resolution ────────────────────────────────────────────

  ResolvedSwipeButtonStyle _resolve(BuildContext context) {
    final theme = GlobalButtonsTheme.maybeOf(context);
    final merged = SwipeButtonStyle.defaults
        .mergedWith(theme?.swipeStyle)
        .mergedWith(widget.style);

    final primary = context.primaryColors.primary;
    final text = context.textColors;
    final bg = context.backgroundColors;
    final status = context.statusColors;

    final height = merged.trackHeight ?? SwipeButtonDefaults.trackHeight;
    final inset = merged.thumbInset ?? SwipeButtonDefaults.thumbInset;

    // The completion flash recolours the FILL, so the whole track says
    // what happened rather than a glyph the thumb happens to be over.
    final fill = switch (activeResult) {
      ButtonResult.success when showingResult => status.success,
      ButtonResult.error when showingResult => status.error,
      _ => merged.fillColor ?? primary,
    };

    return ResolvedSwipeButtonStyle(
      trackColor: merged.trackColor ?? primary.withValues(alpha: 0.12),
      trackGradient: merged.trackGradient,
      fillColor: fill,
      fillTrack: merged.fillTrack ?? true,
      trackHeight: height,
      // A pill, unless asked otherwise.
      trackRadius: merged.trackRadius ?? height / 2,
      thumbColor: merged.thumbColor ?? bg.surface,
      // What reads ON the thumb, never `Colors.black` — a dark glyph
      // on a dark-themed surface is invisible.
      thumbForegroundColor: merged.thumbForegroundColor ?? primary,
      thumbInset: inset,
      thumbRadius: merged.thumbRadius ?? (height - inset * 2) / 2,
      labelStyle:
          merged.labelStyle ??
          (context.textTheme.titleSmall ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w600,
            color: text.primary.withValues(
              alpha: SwipeButtonDefaults.labelOpacity,
            ),
          ),
      confirmThreshold:
          merged.confirmThreshold ?? SwipeButtonDefaults.confirmThreshold,
      showHint: merged.showHint ?? true,
      hintColor: merged.hintColor ?? primary,
      returnDuration:
          merged.returnDuration ?? SwipeButtonDefaults.returnDuration,
      settleDuration:
          merged.settleDuration ?? SwipeButtonDefaults.settleDuration,
      // The accent, so the ring reads on a filled track and an empty
      // one alike.
      focusRingColor: merged.focusRingColor ?? primary,
      focusRingWidth:
          merged.focusRingWidth ?? SwipeButtonDefaults.focusRingWidth,
      // The fill's MOVING edge. Square by default so the fill reads as
      // one surface with the track behind it; round it and the fill
      // becomes a capsule chasing the thumb.
      fillEndRadius: merged.fillEndRadius ?? 0,
      // Once confirmed the label sits ON the fill, so it takes the
      // fill's foreground — the resting label colour would vanish
      // into it.
      confirmedLabelColor:
          merged.confirmedLabelColor ??
          (merged.fillTrack ?? true ? bg.surface : text.primary),
      flingVelocity: merged.flingVelocity,
      enableHaptic: widget.enableHaptic ?? merged.enableHaptic ?? true,
      disabledOpacity:
          merged.disabledOpacity ?? SwipeButtonDefaults.disabledOpacity,
    );
  }
}

/// A horizontal drag that claims the pointer as soon as it lands on the
/// thumb.
///
/// The problem it solves is the gesture ARENA. A swipe button lives in
/// a checkout sheet or a page view, and a plain `GestureDetector` puts
/// its pan recognizer up against theirs — they win, and the thumb
/// stops responding. Winning unconditionally is worse: the whole track
/// would swallow every horizontal drag, and a page that has one in it
/// could not be swiped away.
class _SwipeThumbRecognizer extends OneSequenceGestureRecognizer {
  bool Function(Offset local)? isOnThumb;
  VoidCallback? onSwipeStart;
  ValueChanged<Offset>? onSwipeUpdate;
  ValueChanged<Velocity>? onSwipeEnd;

  int? _pointer;
  Offset? _last;

  /// A release is only a fling if the pointer was still MOVING, and
  /// only a tracker knows how fast.
  VelocityTracker? _velocity;

  @override
  String get debugDescription => 'swipe thumb';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (isOnThumb?.call(event.localPosition) != true) {
      // Not ours — hand it straight over rather than after a slop
      // threshold, so the sheet underneath scrolls without a stutter.
      resolve(GestureDisposition.rejected);
      return;
    }
    _pointer = event.pointer;
    _last = event.localPosition;
    _velocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onSwipeStart?.call();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      final last = _last ?? event.localPosition;
      _velocity?.addPosition(event.timeStamp, event.position);
      onSwipeUpdate?.call(event.localPosition - last);
      _last = event.localPosition;
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      onSwipeEnd?.call(_velocity?.getVelocity() ?? Velocity.zero);
      stopTrackingPointer(event.pointer);
      _pointer = null;
      _last = null;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
    _last = null;
    _velocity = null;
  }
}
