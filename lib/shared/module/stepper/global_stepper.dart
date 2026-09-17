import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/stepper_strings.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_outlined_button.dart';
import '../text/global_text.dart';
import 'stepper_models.dart';
import 'stepper_style.dart';
import 'theme/stepper_theme.dart';

export 'stepper_models.dart';
export 'stepper_style.dart';
export 'theme/stepper_theme.dart';

// ─── Keyboard intents ───────────────────────────────────────
// Each carries the step it was raised FROM: `FocusableActionDetector`
// installs one action map per step, and the handler has to know which
// of them fired without the state reading focus back out of the tree.

/// Enter / Space on a step.
class _StepActivateIntent extends Intent {
  const _StepActivateIntent(this.index);
  final int index;
}

/// An arrow: move the keyboard by [delta] steps.
class _StepMoveIntent extends Intent {
  const _StepMoveIntent(this.index, this.delta);
  final int index;
  final int delta;
}

/// Home / End.
class _StepEdgeIntent extends Intent {
  const _StepEdgeIntent({required this.last});
  final bool last;
}

/// A highly customizable stepper with horizontal, vertical, timeline, and
/// alternating layouts. Supports progress connectors, connector labels,
/// step actions, collapsible completed steps, custom indicators, error states,
/// and animated transitions.
class GlobalStepper extends StatefulWidget {
  const GlobalStepper({
    super.key,
    required this.steps,
    this.currentStep = 0,
    this.orientation = StepperOrientation.horizontal,
    this.style,
    this.onStepTapped,
    this.onStepContinue,
    this.onStepCancel,
    this.stepBuilder,
  });

  final List<GlobalStepItem> steps;
  final int currentStep;
  final StepperOrientation orientation;

  /// The caller's half of `caller > GlobalStepperTheme.style >
  /// StepperStyle.defaults`.
  final StepperStyle? style;
  final ValueChanged<int>? onStepTapped;

  /// Called when the user presses Continue on the active step.
  final VoidCallback? onStepContinue;

  /// Called when the user presses Cancel on the active step.
  final VoidCallback? onStepCancel;

  /// Custom step builder. Overrides the default indicator + title rendering.
  /// Receives (context, step, index, isActive, isCompleted).
  final Widget Function(
    BuildContext context,
    GlobalStepItem step,
    int index,
    bool isActive,
    bool isCompleted,
  )?
  stepBuilder;

  @override
  State<GlobalStepper> createState() => _GlobalStepperState();
}

class _GlobalStepperState extends State<GlobalStepper> {
  int _prevStep = 0;

  /// Resolved once per build and read by every layout below.
  late ResolvedStepperStyle style;

  /// Drives a `scrollable` horizontal run.
  ///
  /// Built LAZILY: attaching a controller to a scroll view that is not
  /// there is harmless, but disposing one that was never created is
  /// noise — and most steppers are not scrollable.
  ScrollController? _scrollController;

  ScrollController get _scroll => _scrollController ??= ScrollController();

  /// One node per step, so a keyboard can walk the run.
  ///
  /// A stepper is a row of related controls, like a tab bar: TAB
  /// reaches the run, ARROWS move inside it. Giving every step its own
  /// tab stop would make a five-step checkout five stops on the way to
  /// the form under it.
  final List<FocusNode> _nodes = [];

  /// Whether the opening scroll has already been queued.
  bool _revealed = false;

  /// Which step TAB lands on, or -1 for "wherever the current step is".
  ///
  /// A roving tab stop, like a radio group: the run is ONE stop on the
  /// way through a form, and the arrows move inside it. Every step
  /// being its own stop puts five presses between a keyboard reader
  /// and the field under a five-step checkout.
  int _roving = -1;

  /// Which step the KEYBOARD is on, or -1.
  ///
  /// Not the same as having focus — a tap focuses too, and a ring on a
  /// tapped step reads as "still focused" long after the reader has
  /// moved on.
  int _focusVisible = -1;

  @override
  void initState() {
    super.initState();
    _prevStep = widget.currentStep;
    _syncNodes();
  }

  /// Brings the active step into view.
  ///
  /// The one case `scrollable` exists for — eight steps in a phone's
  /// width — is the case where moving to step seven put it off the end
  /// and nothing brought it back.
  ///
  /// It CENTRES rather than scrolling the minimum distance, so the
  /// steps either side stay visible and the run still reads as a run.
  /// The offset is measured from the START of the scroll view, which
  /// is the right edge in Arabic — the same number works both ways.
  void _revealCurrentStep() {
    if (!style.scrollable) return;
    final index = currentStep.clamp(0, steps.length - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      final target =
          (style.scrollableStepWidth * (index + 0.5) -
                  position.viewportDimension / 2)
              .clamp(
                position.minScrollExtent,
                position.maxScrollExtent,
              );
      if ((position.pixels - target).abs() < 1) return;

      final duration = _animDuration;
      if (duration == Duration.zero) {
        position.jumpTo(target);
      } else {
        position.animateTo(target, duration: duration, curve: Curves.easeOut);
      }
    });
  }

  @override
  void didUpdateWidget(GlobalStepper old) {
    super.didUpdateWidget(old);
    if (old.currentStep != widget.currentStep) {
      _prevStep = old.currentStep;
      // However the step moved — a tap here, a caller's Next button,
      // the keyboard — the run follows it.
      _revealCurrentStep();
    }
    if (old.steps.length != widget.steps.length) _syncNodes();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Grows or shrinks the node list to match the steps.
  void _syncNodes() {
    while (_nodes.length < widget.steps.length) {
      _nodes.add(FocusNode(debugLabel: 'GlobalStepper step ${_nodes.length}'));
    }
    while (_nodes.length > widget.steps.length) {
      _nodes.removeLast().dispose();
    }
  }

  /// Compute sequential delay for a connector at [connectorIndex].
  /// Only delays when jumping multiple steps. Single step = no delay.
  /// Forward: connector 0 fills first, then 1, then 2...
  /// Reverse: last connector empties first, then previous...
  Duration _connectorDelay(int connectorIndex) {
    if (!style.sequentialAnimation) return Duration.zero;
    final from = _prevStep;
    final to = currentStep;
    final stepDelta = (to - from).abs();
    if (stepDelta <= 1) return Duration.zero; // single step = no delay

    // Overlap factor: 0.75 means each connector starts when the previous is ~75% done.
    // This ensures near-continuous flow — the next connector begins just before the previous finishes.
    const overlapFactor = 0.75;

    if (to > from) {
      final firstChanging = from;
      final offset = connectorIndex - firstChanging;
      return offset > 0
          ? _animDuration * offset * overlapFactor
          : Duration.zero;
    } else {
      final lastChanging = from - 1;
      final offset = lastChanging - connectorIndex;
      return offset > 0
          ? _animDuration * offset * overlapFactor
          : Duration.zero;
    }
  }

  // Delegate accessors
  List<GlobalStepItem> get steps => widget.steps;
  int get currentStep => widget.currentStep;
  ValueChanged<int>? get onStepTapped => widget.onStepTapped;

  @override
  Widget build(BuildContext context) {
    style = (widget.style ?? const StepperStyle()).resolve(context);
    // An INHERITED read, so it cannot happen in `initState`.
    _reduceMotion = MediaQuery.disableAnimationsOf(context);

    // The FIRST frame too: a stepper built at step six — a form
    // resumed, a deep link into the middle of a flow — opens with that
    // step off the end otherwise.
    if (!_revealed) {
      _revealed = true;
      _revealCurrentStep();
    }

    switch (widget.orientation) {
      case StepperOrientation.horizontal:
        return _buildHorizontal(context);
      case StepperOrientation.vertical:
        return _buildVertical(context);
      case StepperOrientation.timeline:
        return _buildTimeline(context);
      case StepperOrientation.alternating:
        return _buildAlternating(context);
    }
  }

  // ─── Colors ───────────────────────────────────────────────

  Color _stepColor(int index) {
    final step = steps[index];
    if (step.isDisabled) return style.disabledColor;
    if (step.isError) return style.errorColor;
    if (step.isCompleted || index < currentStep) return style.completedColor;
    if (step.isActive || index == currentStep) return style.activeColor;
    return style.inactiveColor;
  }

  /// What a connector is painted with — its filled part and its track.
  ///
  /// A caller who colours the connector colours BOTH: the track is the
  /// same colour worn down, so a coloured line still reads as one line
  /// rather than a coloured half joined to a grey one.
  (Color active, Color track) _connectorColors() {
    final explicit = style.connectorColor;
    if (explicit == null) return (style.completedColor, style.inactiveColor);
    return (
      explicit,
      explicit.withValues(alpha: StepperDefaults.connectorTrackOpacity),
    );
  }

  bool _isCompleted(int index) =>
      steps[index].isCompleted || index < currentStep;

  /// Resolved title style for a step.
  TextStyle _titleStyle(int index) {
    final base = index == currentStep
        ? style.activeTitleStyle
        : style.titleStyle;
    return base.copyWith(color: base.color ?? _stepColor(index));
  }

  /// Resolved subtitle style for a step.
  TextStyle _subtitleStyle(int index) => style.subtitleStyle.copyWith(
    color:
        style.subtitleStyle.color ??
        _stepColor(index).withValues(alpha: StepperDefaults.subtitleOpacity),
  );

  /// Whether the READER asked for no motion.
  ///
  /// Not the same question as `style.animated`, which is what the
  /// CALLER asked for. A stepper that animates its indicators,
  /// connectors and content through a system-wide reduce-motion
  /// setting is the one control on the page still moving.
  bool _reduceMotion = false;

  /// Zero when either of them said no.
  Duration get _animDuration =>
      _reduceMotion ? Duration.zero : style.effectiveDuration;

  // ─── The connector label ──────────────────────────────────

  /// A word ON the line — "2 hours", "3 days".
  ///
  /// It STROKES itself in the page's own colour rather than painting a
  /// pill behind the text: a pill has edges, and a pill on a dashed
  /// line looks like a missing dash.
  Widget _connectorLabel(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    child: GlobalText(
      label,
      textStyle: GlobalTextStyle(
        fontSize: style.connectorLabelStyle.fontSize,
        strokeWidth: StepperDefaults.connectorLabelStroke,
        strokeColor: style.surfaceColor,
        fontWeight: style.connectorLabelStyle.fontWeight,
        color: style.connectorLabelStyle.color,
      ),
    ),
  );

  // ─── Keyboard ─────────────────────────────────────────────

  /// Whether a step can be reached at all.
  ///
  /// No `onStepTapped` means the stepper is a REPORT, not a control —
  /// and a report must not take focus, or every keyboard user tabs
  /// through a progress read-out on the way to the form under it.
  /// It BOUNDS-CHECKS, because `currentStep` is a caller's number and
  /// may point past the end: a run of three steps whose caller says
  /// "step 4" is the everything-is-done state, and one shared control
  /// driving several steppers of different lengths hits it constantly.
  /// Comparisons still see the raw value — `index < currentStep` is
  /// what makes every step read as completed there — but nothing may
  /// INDEX with it.
  bool _isReachable(int index) =>
      index >= 0 &&
      index < steps.length &&
      onStepTapped != null &&
      !steps[index].isDisabled;

  /// Where TAB enters the run: the step the reader is ON, unless the
  /// arrows have since moved the keyboard somewhere else.
  int get _tabStopIndex {
    if (_roving >= 0 && _roving < steps.length && _isReachable(_roving)) {
      return _roving;
    }
    if (_isReachable(currentStep)) return currentStep;
    for (var i = 0; i < steps.length; i++) {
      if (_isReachable(i)) return i;
    }
    return -1;
  }

  /// What Enter, Space and a screen reader's tap do.
  void _activate(int index) {
    if (!_isReachable(index)) return;
    if (style.enableHaptic) HapticFeedback.selectionClick();
    onStepTapped!(index);
  }

  /// Moves the KEYBOARD, not the step.
  ///
  /// Arrows walk the run and Enter commits, the way a tab bar behaves.
  /// Moving the step on arrow instead would fire `onStepTapped` for
  /// every step passed through — and in a wizard that is a page
  /// transition each time.
  void _moveFocus(int from, int delta) {
    var i = from + delta;
    while (i >= 0 && i < steps.length) {
      if (_isReachable(i)) {
        setState(() => _roving = i);
        _nodes[i].requestFocus();
        return;
      }
      i += delta;
    }
  }

  void _focusEdge({required bool last}) {
    final order = last
        ? List.generate(steps.length, (i) => steps.length - 1 - i)
        : List.generate(steps.length, (i) => i);
    for (final i in order) {
      if (_isReachable(i)) {
        setState(() => _roving = i);
        _nodes[i].requestFocus();
        return;
      }
    }
  }

  /// Which arrows walk this layout.
  ///
  /// The horizontal run answers to left/right and MIRRORS: in Arabic
  /// the first step is on the right, so the key that moves forward is
  /// the one that points at the next step, not the one named "next".
  Map<ShortcutActivator, Intent> _shortcutsFor(int index) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward = _StepMoveIntent(index, rtl ? -1 : 1);
    final backward = _StepMoveIntent(index, rtl ? 1 : -1);

    return {
      const SingleActivator(LogicalKeyboardKey.enter): _StepActivateIntent(
        index,
      ),
      const SingleActivator(LogicalKeyboardKey.space): _StepActivateIntent(
        index,
      ),
      const SingleActivator(LogicalKeyboardKey.home): const _StepEdgeIntent(
        last: false,
      ),
      const SingleActivator(LogicalKeyboardKey.end): const _StepEdgeIntent(
        last: true,
      ),
      if (widget.orientation == StepperOrientation.horizontal) ...{
        const SingleActivator(LogicalKeyboardKey.arrowRight): forward,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): backward,
      } else ...{
        const SingleActivator(LogicalKeyboardKey.arrowDown): _StepMoveIntent(
          index,
          1,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowUp): _StepMoveIntent(
          index,
          -1,
        ),
      },
    };
  }

  /// One step's tap + focus target.
  ///
  /// Wraps whatever the layout was going to put there — an indicator, a
  /// title column — so the ring, the semantics and the keys are the
  /// same in all four layouts rather than four near-copies.
  Widget _stepTarget({
    required int index,
    required Widget child,
    bool ring = false,
  }) {
    final reachable = _isReachable(index);
    final step = steps[index];

    Widget target = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: reachable ? () => _activate(index) : null,
      child: ring ? _focusRing(index, child) : child,
    );

    if (reachable) {
      // Everything but the tab stop is REACHABLE but not TABBABLE:
      // `skipTraversal` keeps it out of the tab order while leaving it
      // able to take focus when an arrow hands it over.
      _nodes[index].skipTraversal = index != _tabStopIndex;
      target = FocusableActionDetector(
        focusNode: _nodes[index],
        // Only the FIRST reachable step is a tab stop; the arrows do
        // the rest. Five steps that are five tab stops is a wall
        // between the reader and the form under them.
        descendantsAreFocusable: false,
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (visible) {
          final next = visible ? index : (_focusVisible == index ? -1 : null);
          if (next == null || _focusVisible == next) return;
          setState(() => _focusVisible = next);
        },
        shortcuts: _shortcutsFor(index),
        actions: {
          _StepActivateIntent: CallbackAction<_StepActivateIntent>(
            onInvoke: (intent) {
              _activate(intent.index);
              return null;
            },
          ),
          _StepMoveIntent: CallbackAction<_StepMoveIntent>(
            onInvoke: (intent) {
              _moveFocus(intent.index, intent.delta);
              return null;
            },
          ),
          _StepEdgeIntent: CallbackAction<_StepEdgeIntent>(
            onInvoke: (intent) {
              _focusEdge(last: intent.last);
              return null;
            },
          ),
        },
        child: target,
      );
    }

    // The whole step reads as ONE thing, whichever piece is being
    // wrapped: "Step 2 of 4, Details, current".
    return Semantics(
      button: reachable,
      enabled: !step.isDisabled,
      selected: index == currentStep,
      label: _semanticLabelFor(index),
      onTap: reachable ? () => _activate(index) : null,
      child: ExcludeSemantics(child: target),
    );
  }

  /// A SECOND surface for the same step — the title under a horizontal
  /// indicator, the heading beside a vertical one.
  ///
  /// It taps but does not focus: one `FocusNode` can be attached to one
  /// widget, and two focusables per step would make the arrows walk
  /// half-steps and a screen reader read every step twice.
  Widget _tapOnly(int index, Widget child) => GestureDetector(
    // Through `_activate`, not `_onTap`: the title and the indicator
    // are the same step, and one of them used to buzz.
    onTap: _isReachable(index) ? () => _activate(index) : null,
    child: ExcludeSemantics(child: child),
  );

  String _semanticLabelFor(int index) {
    final step = steps[index];
    final state = switch (0) {
      _ when step.isError => StepperStrings.error,
      _ when step.isDisabled => StepperStrings.disabled,
      _ when index == currentStep => StepperStrings.current,
      _ when _isCompleted(index) => StepperStrings.completed,
      _ => StepperStrings.upcoming,
    };
    return [
      StepperStrings.stepOf(index + 1, steps.length),
      step.title,
      if (step.subtitle != null) step.subtitle!,
      state,
    ].join(', ');
  }

  /// The ring the keyboard draws around an indicator.
  ///
  /// It sits OUTSIDE the circle, in a `Stack` that does not clip, so a
  /// filled indicator and an outlined one show the same ring and
  /// neither grows the row when it takes focus.
  Widget _focusRing(int index, Widget child) {
    final visible = _focusVisible == index;
    final gap = StepperDefaults.focusRingGap + style.focusRingWidth;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          left: -gap,
          top: -gap,
          right: -gap,
          bottom: -gap,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: _animDuration,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: visible ? style.focusColor : Colors.transparent,
                  width: style.focusRingWidth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HORIZONTAL
  // ═══════════════════════════════════════════════════════════

  Widget _buildHorizontal(BuildContext context) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicator row: connectors as a line behind, indicators on top
        SizedBox(
          height: style.indicatorExtent,
          child: Stack(
            children: [
              // Connector line layer — positioned to span between indicator edges
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final stepWidth = totalWidth / steps.length;
                    final connectorStart = stepWidth / 2;
                    final connectorEnd = totalWidth - stepWidth / 2;
                    final connectorCount = steps.length - 1;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: connectorStart,
                        right: totalWidth - connectorEnd,
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < connectorCount; i++)
                            Expanded(
                              child: Padding(
                                // The lane is centre-to-centre, so half
                                // an indicator at each end sits UNDER
                                // the circle. An opaque one hides it; a
                                // translucent custom indicator shows
                                // the line running through it.
                                padding: EdgeInsets.symmetric(
                                  horizontal: style.connectorStart,
                                ),
                                child: _buildRawConnector(i),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Indicator layer
              Row(
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Expanded(
                      child: Center(
                        child: Opacity(
                          opacity: steps[i].isDisabled
                              ? style.disabledOpacity
                              : 1.0,
                          child: _stepTarget(
                            index: i,
                            ring: true,
                            child: _buildIndicator(
                              i,
                              steps[i],
                              _stepColor(i),
                              i == currentStep,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: StepperDefaults.horizontalTitleGap),
        // Title row — aligned with indicators
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: _tapOnly(
                  i,
                  Opacity(
                    opacity: steps[i].isDisabled ? style.disabledOpacity : 1.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: _animDuration,
                          style: _titleStyle(i),
                          child: Text(
                            steps[i].title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (steps[i].subtitle != null) ...[
                          const SizedBox(height: StepperDefaults.subtitleGap),
                          Text(
                            steps[i].subtitle!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _subtitleStyle(i),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    if (style.scrollable) {
      return SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: steps.length * style.scrollableStepWidth,
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildRawConnector(int fromIndex) {
    // `none` draws nothing at all. It used to fall through to the solid
    // branch, so the one value whose whole job was to remove the line
    // was the one that did not.
    if (style.connectorStyle == StepperConnectorStyle.none &&
        style.connectorBuilder == null) {
      return const SizedBox.shrink();
    }
    final fromCompleted = _isCompleted(fromIndex);
    final (activeColor, trackColor) = _connectorColors();
    final explicitProgress = style.connectorProgress?[fromIndex];
    final progress = explicitProgress ?? (fromCompleted ? 1.0 : 0.0);
    final step = steps[fromIndex];
    Widget connector;

    if (style.connectorBuilder != null) {
      // Custom connector widget with animated clip reveal
      connector = _AnimatedCustomConnector(
        progress: progress,
        duration: _animDuration,
        delay: _connectorDelay(fromIndex),
        axis: Axis.horizontal,
        child: style.connectorBuilder!(
          context,
          fromIndex,
          progress,
          activeColor,
          trackColor,
        ),
      );
    } else {
      Widget connectorLine = SizedBox(
        height: style.connectorThickness,
        child: _DelayedProgressBar(
          progress: progress,
          activeColor: activeColor,
          trackColor: trackColor,
          gradient: fromCompleted ? style.connectorGradient : null,
          duration: _animDuration,
          delay: _connectorDelay(fromIndex),
          lineStyle: style.connectorStyle,
          dashWidth: style.connectorDashWidth,
          dashGap: style.connectorDashGap,
        ),
      );

      // Centered vertically in the indicator row
      connector = Center(child: connectorLine);
    }

    // Connector label — centered ON the connector with bg stroke to cover it
    if (step.connectorLabel != null) {
      connector = Stack(
        children: [
          connector,
          Positioned.fill(
            child: Center(
              child: _connectorLabel(step.connectorLabel!),
            ),
          ),
        ],
      );
    }

    return connector;
  }

  // ═══════════════════════════════════════════════════════════
  // VERTICAL
  // ═══════════════════════════════════════════════════════════

  Widget _buildVertical(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) _buildVerticalStep(i),
      ],
    );
  }

  Widget _buildVerticalStep(int index) {
    final step = steps[index];
    final color = _stepColor(index);
    final isActive = index == currentStep;
    final isLast = index == steps.length - 1;
    final completed = _isCompleted(index);
    final collapsed = style.collapsible && completed && !isActive;

    final indicatorW = style.indicatorExtent;
    final connectorProgress =
        style.connectorProgress?[index] ?? (_isCompleted(index) ? 1.0 : 0.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Connector line behind content
        if (!isLast && style.connectorBuilder != null)
          PositionedDirectional(
            // DIRECTIONAL, all of it: the indicator column is laid out
            // by a `Row`, which mirrors, and every one of these used a
            // raw `left` — so in Arabic the lines stayed on the left
            // while the circles they join moved to the right.
            start: 0,
            // The line meets the RESTING edge of the circle. The
            // active one is drawn larger and covers the last two
            // points of it, which is what makes the run read as one
            // line with a bead on it.
            top: style.connectorTop,
            bottom: 0,
            width: indicatorW,
            child: _AnimatedCustomConnector(
              progress: connectorProgress,
              duration: _animDuration,
              delay: _connectorDelay(index),
              axis: Axis.vertical,
              child: style.connectorBuilder!(
                context,
                index,
                connectorProgress,
                _connectorColors().$1,
                _connectorColors().$2,
              ),
            ),
          )
        else if (!isLast)
          PositionedDirectional(
            start: indicatorW / 2 - style.connectorThickness / 2,
            // The line meets the RESTING edge of the circle. The
            // active one is drawn larger and covers the last two
            // points of it, which is what makes the run read as one
            // line with a bead on it.
            top: style.connectorTop,
            bottom: 0,
            width: style.connectorThickness,
            child: _VerticalConnectorPaint(
              progress: connectorProgress,
              activeColor: _connectorColors().$1,
              trackColor: _connectorColors().$2,
              thickness: style.connectorThickness,
              duration: _animDuration,
              delay: _connectorDelay(index),
              lineStyle: style.connectorStyle,
              dashWidth: style.connectorDashWidth,
              dashGap: style.connectorDashGap,
            ),
          ),
        // Connector label (vertical) — centered ON the connector line with bg to cover it
        if (!isLast && step.connectorLabel != null)
          PositionedDirectional(
            // Centred on the line, which is centred on the column.
            start: indicatorW / 2 - StepperDefaults.verticalLabelWidth / 2,
            width: StepperDefaults.verticalLabelWidth,
            // The line meets the RESTING edge of the circle. The
            // active one is drawn larger and covers the last two
            // points of it, which is what makes the run read as one
            // line with a bead on it.
            top: style.connectorTop,
            bottom: 0,
            child: Center(
              child: _connectorLabel(step.connectorLabel!),
            ),
          ),
        Opacity(
          opacity: step.isDisabled ? style.disabledOpacity : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicator column
              SizedBox(
                width: indicatorW,
                child: _stepTarget(
                  index: index,
                  ring: true,
                  child: _buildIndicator(index, step, color, isActive),
                ),
              ),
              const SizedBox(width: StepperDefaults.verticalIndicatorGap),
              // Title + content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tapOnly(
                      index,
                      Padding(
                        padding: EdgeInsets.only(
                          top:
                              (style.indicatorSize -
                                  StepperDefaults.titleFontSize) /
                              2.5,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.title, style: _titleStyle(index)),
                            if (step.subtitle != null)
                              AnimatedSize(
                                duration: _animDuration,
                                curve: Curves.easeInOut,
                                child: collapsed
                                    ? const SizedBox.shrink()
                                    : Text(
                                        step.subtitle!,
                                        style: _subtitleStyle(index),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Content — with transition animation
                    if (step.content != null)
                      _buildContentTransition(
                        isVisible: isActive && !collapsed,
                        child: Padding(
                          padding: style.contentPadding,
                          child: step.content!,
                        ),
                      ),
                    // Actions — built-in continue/cancel or custom actions
                    _buildActions(step, isActive),
                    if (!isLast)
                      SizedBox(
                        height: collapsed
                            ? 8
                            : StepperDefaults.contentPadBottom + style.spacing,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ), // close Opacity + Row
      ],
    ); // close Stack
  }

  // ═══════════════════════════════════════════════════════════
  // TIMELINE
  // ═══════════════════════════════════════════════════════════

  Widget _buildTimeline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) _buildTimelineStep(i, context),
      ],
    );
  }

  Widget _buildTimelineStep(int index, BuildContext context) {
    final step = steps[index];
    final color = _stepColor(index);
    final isActive = index == currentStep;
    final isLast = index == steps.length - 1;
    final completed = _isCompleted(index);
    final collapsed = style.collapsible && completed && !isActive;

    final indicatorW = style.indicatorExtent;
    final connectorStart =
        StepperDefaults.timelineTimestampWidth +
        StepperDefaults.verticalIndicatorGap +
        indicatorW / 2 -
        style.connectorThickness / 2;
    final connectorProgress =
        style.connectorProgress?[index] ?? (_isCompleted(index) ? 1.0 : 0.0);

    return Stack(
      children: [
        // Connector — custom or default
        if (!isLast && style.connectorBuilder != null)
          PositionedDirectional(
            start:
                StepperDefaults.timelineTimestampWidth +
                StepperDefaults.verticalIndicatorGap,
            // The line meets the RESTING edge of the circle. The
            // active one is drawn larger and covers the last two
            // points of it, which is what makes the run read as one
            // line with a bead on it.
            top: style.connectorTop,
            bottom: 0,
            width: indicatorW,
            child: _AnimatedCustomConnector(
              progress: connectorProgress,
              duration: _animDuration,
              delay: _connectorDelay(index),
              axis: Axis.vertical,
              child: style.connectorBuilder!(
                context,
                index,
                connectorProgress,
                _connectorColors().$1,
                _connectorColors().$2,
              ),
            ),
          )
        else if (!isLast)
          PositionedDirectional(
            start: connectorStart,
            // The line meets the RESTING edge of the circle. The
            // active one is drawn larger and covers the last two
            // points of it, which is what makes the run read as one
            // line with a bead on it.
            top: style.connectorTop,
            bottom: 0,
            width: style.connectorThickness,
            child: _VerticalConnectorPaint(
              progress: connectorProgress,
              activeColor: _connectorColors().$1,
              trackColor: _connectorColors().$2,
              thickness: style.connectorThickness,
              duration: _animDuration,
              delay: _connectorDelay(index),
              lineStyle: style.connectorStyle,
              dashWidth: style.connectorDashWidth,
              dashGap: style.connectorDashGap,
            ),
          ),
        Opacity(
          opacity: step.isDisabled ? style.disabledOpacity : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: StepperDefaults.timelineTimestampWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    top:
                        (style.indicatorSize -
                            StepperDefaults.timestampFontSize) /
                        2.5,
                  ),
                  child: Text(
                    step.timestamp ?? '',
                    textAlign: TextAlign.right,
                    // The ACTIVE row's timestamp takes the step's own
                    // colour: in a timeline the time IS the content,
                    // and a grey one under a live step reads as stale.
                    style: isActive
                        ? style.timestampStyle.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          )
                        : style.timestampStyle,
                  ),
                ),
              ),
              const SizedBox(width: StepperDefaults.verticalIndicatorGap),
              SizedBox(
                width: indicatorW,
                child: _stepTarget(
                  index: index,
                  ring: true,
                  child: _buildIndicator(index, step, color, isActive),
                ),
              ),
              const SizedBox(width: StepperDefaults.verticalIndicatorGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top:
                            (style.indicatorSize -
                                StepperDefaults.titleFontSize) /
                            2.5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.title, style: _titleStyle(index)),
                          if (step.subtitle != null && !collapsed)
                            Text(step.subtitle!, style: _subtitleStyle(index)),
                        ],
                      ),
                    ),
                    if (step.content != null)
                      _buildContentTransition(
                        isVisible: isActive && !collapsed,
                        child: Padding(
                          padding: style.contentPadding,
                          child: step.content!,
                        ),
                      ),
                    _buildActions(step, isActive),
                    if (!isLast)
                      SizedBox(
                        height: collapsed
                            ? 8
                            : StepperDefaults.contentPadBottom + style.spacing,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ALTERNATING
  // ═══════════════════════════════════════════════════════════

  Widget _buildAlternating(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) _buildAlternatingStep(i),
      ],
    );
  }

  Widget _buildAlternatingStep(int index) {
    final step = steps[index];
    final color = _stepColor(index);
    final isActive = index == currentStep;
    final isLast = index == steps.length - 1;
    final isLeft = index.isEven;

    Widget contentCol = Column(
      crossAxisAlignment: isLeft
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: (style.indicatorSize - StepperDefaults.titleFontSize) / 2.5,
          ),
          child: Column(
            crossAxisAlignment: isLeft
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(step.title, style: _titleStyle(index)),
              if (step.subtitle != null)
                Text(step.subtitle!, style: _subtitleStyle(index)),
            ],
          ),
        ),
        if (step.content != null)
          _buildContentTransition(
            isVisible: isActive,
            child: Padding(
              padding: style.contentPadding,
              child: step.content!,
            ),
          ),
        if (!isLast)
          SizedBox(height: StepperDefaults.contentPadBottom + style.spacing),
      ],
    );

    Widget emptyCol = SizedBox(
      height: StepperDefaults.contentPadBottom + style.spacing,
    );

    final indicatorW = style.indicatorExtent;
    final connectorProgress =
        style.connectorProgress?[index] ?? (_isCompleted(index) ? 1.0 : 0.0);

    return LayoutBuilder(
      builder: (_, constraints) {
        final halfWidth = constraints.maxWidth / 2;
        final connectorStart = halfWidth - style.connectorThickness / 2;

        return Stack(
          children: [
            // Connector — custom or default
            if (!isLast && style.connectorBuilder != null)
              PositionedDirectional(
                start: halfWidth - indicatorW / 2,
                // The line meets the RESTING edge of the circle. The
                // active one is drawn larger and covers the last two
                // points of it, which is what makes the run read as one
                // line with a bead on it.
                top: style.connectorTop,
                bottom: 0,
                width: indicatorW,
                child: _AnimatedCustomConnector(
                  progress: connectorProgress,
                  duration: _animDuration,
                  delay: _connectorDelay(index),
                  axis: Axis.vertical,
                  child: style.connectorBuilder!(
                    context,
                    index,
                    connectorProgress,
                    _connectorColors().$1,
                    _connectorColors().$2,
                  ),
                ),
              )
            else if (!isLast)
              PositionedDirectional(
                start: connectorStart,
                // The line meets the RESTING edge of the circle. The
                // active one is drawn larger and covers the last two
                // points of it, which is what makes the run read as one
                // line with a bead on it.
                top: style.connectorTop,
                bottom: 0,
                width: style.connectorThickness,
                child: _VerticalConnectorPaint(
                  progress: connectorProgress,
                  activeColor: _connectorColors().$1,
                  trackColor: _connectorColors().$2,
                  thickness: style.connectorThickness,
                  duration: _animDuration,
                  delay: _connectorDelay(index),
                ),
              ),
            Opacity(
              opacity: step.isDisabled ? style.disabledOpacity : 1.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: isLeft ? contentCol : emptyCol),
                  const SizedBox(width: StepperDefaults.verticalIndicatorGap),
                  SizedBox(
                    width: indicatorW,
                    child: _stepTarget(
                      index: index,
                      ring: true,
                      child: _buildIndicator(index, step, color, isActive),
                    ),
                  ),
                  const SizedBox(width: StepperDefaults.verticalIndicatorGap),
                  Expanded(child: isLeft ? emptyCol : contentCol),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTENT TRANSITION + ACTIONS
  // ═══════════════════════════════════════════════════════════

  /// Wraps step content with the configured transition animation.
  Widget _buildContentTransition({
    required bool isVisible,
    required Widget child,
  }) {
    final transition = style.contentTransition;
    if (transition == StepContentTransition.none) {
      return AnimatedSize(
        duration: _animDuration,
        curve: Curves.easeInOut,
        child: isVisible ? child : const SizedBox.shrink(),
      );
    }

    return AnimatedSize(
      duration: _animDuration,
      curve: Curves.easeInOut,
      child: isVisible
          ? AnimatedSwitcher(
              duration: _animDuration,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) {
                switch (transition) {
                  case StepContentTransition.fade:
                    return FadeTransition(opacity: anim, child: child);
                  case StepContentTransition.slide:
                    return SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    );
                  case StepContentTransition.fadeSlide:
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    );
                  case StepContentTransition.scale:
                    return FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    );
                  case StepContentTransition.none:
                    return child;
                }
              },
              child: KeyedSubtree(
                key: ValueKey('content-$currentStep'),
                child: child,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Builds the action row for a step — combines custom actions with
  /// built-in Continue/Cancel buttons from onStepContinue/onStepCancel.
  Widget _buildActions(GlobalStepItem step, bool isActive) {
    final hasContinue = widget.onStepContinue != null;
    final hasCancel = widget.onStepCancel != null;
    final hasCustomActions = step.actions != null && step.actions!.isNotEmpty;

    if (!isActive || (!hasContinue && !hasCancel && !hasCustomActions)) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: _animDuration,
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(top: StepperDefaults.actionsPadTop),
        child: Row(
          children: [
            // Custom actions first
            if (hasCustomActions)
              for (var j = 0; j < step.actions!.length; j++) ...[
                if (j > 0) const SizedBox(width: 8),
                step.actions![j],
              ],
            // Built-in Continue/Cancel
            if (hasContinue && !hasCustomActions)
              GlobalFilledButton(
                text: CommonStrings.continueLabel,
                onPressed: widget.onStepContinue,
                enabled: !step.isDisabled,
                shrinkWidth: true,
              ),
            if (hasCancel && !hasCustomActions) ...[
              const SizedBox(width: 8),
              GlobalOutlinedButton(
                text: CommonStrings.cancel,
                onPressed: widget.onStepCancel,
                enabled: !step.isDisabled,
                shrinkWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INDICATOR (improved design)
  // ═══════════════════════════════════════════════════════════

  Widget _buildIndicator(
    int index,
    GlobalStepItem step,
    Color color,
    bool isActive,
  ) {
    final size = style.indicatorSize;
    final isCompleted = step.isCompleted || index < currentStep;
    final isError = step.isError;

    // Custom builder
    if (widget.stepBuilder != null) {
      return widget.stepBuilder!(context, step, index, isActive, isCompleted);
    }

    if (step.customIndicator != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: step.customIndicator),
      );
    }

    final filled =
        style.filledIndicator && (isActive || isCompleted || isError);
    final iconColor = filled ? Colors.white : color;

    Widget content;
    if (isError) {
      content = Icon(
        Icons.close_rounded,
        size: StepperDefaults.errorIconSize,
        color: iconColor,
      );
    } else if (isCompleted && style.showCheckmark) {
      content = Icon(
        Icons.check_rounded,
        size: StepperDefaults.checkmarkSize,
        color: iconColor,
      );
    } else if (step.icon != null) {
      content = Icon(
        step.icon,
        size: StepperDefaults.indicatorIconSize,
        color: iconColor,
      );
    } else if (style.showStepNumber) {
      content = Text(
        // Through `AppNumbers`, or Arabic reads 1 2 3 while every
        // other number on the page reads ١ ٢ ٣.
        AppNumbers.decimal(index + 1),
        style: TextStyle(
          fontSize: StepperDefaults.indicatorFontSize,
          fontWeight: FontWeight.w700,
          color: iconColor,
        ),
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Builder(
      builder: (ctx) {
        final scaffoldBg = Theme.of(ctx).scaffoldBackgroundColor;
        final activeSize = isActive
            ? size * StepperDefaults.activeIndicatorScale
            : size;
        final hasGradientBorder = style.indicatorGradient != null && !filled;

        Widget indicator;
        if (hasGradientBorder) {
          // Gradient border via nested containers
          indicator = AnimatedContainer(
            duration: _animDuration,
            curve: Curves.easeInOut,
            width: activeSize,
            height: activeSize,
            decoration: BoxDecoration(
              gradient: style.indicatorGradient,
              shape: BoxShape.circle,
              boxShadow: [
                if (isActive || isCompleted)
                  BoxShadow(
                    color: color.withValues(
                      alpha: StepperDefaults.indicatorShadowOpacity,
                    ),
                    blurRadius: StepperDefaults.indicatorShadowBlur,
                    spreadRadius: isActive ? 1 : 0,
                  ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(style.indicatorBorderWidth),
              decoration: BoxDecoration(
                color: scaffoldBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: _animDuration,
                  switchInCurve: Curves.easeOut,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('$index-$isCompleted-$isActive-$isError'),
                    child: content,
                  ),
                ),
              ),
            ),
          );
        } else {
          indicator = AnimatedContainer(
            duration: _animDuration,
            curve: Curves.easeInOut,
            width: activeSize,
            height: activeSize,
            decoration: BoxDecoration(
              color: filled ? color : scaffoldBg,

              shape: BoxShape.circle,
              border: filled
                  ? null
                  : Border.all(color: color, width: style.indicatorBorderWidth),
              boxShadow: [
                if (isActive || isCompleted)
                  BoxShadow(
                    color: color.withValues(
                      alpha: StepperDefaults.indicatorShadowOpacity,
                    ),
                    blurRadius: StepperDefaults.indicatorShadowBlur,
                    spreadRadius: isActive ? 1 : 0,
                  ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: _animDuration,
                switchInCurve: Curves.easeOut,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey('$index-$isCompleted-$isActive-$isError'),
                  child: content,
                ),
              ),
            ),
          );
        }

        return indicator;
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Delayed progress bar — horizontal, with sequential delay support
// ═══════════════════════════════════════════════════════════════

class _DelayedProgressBar extends StatefulWidget {
  const _DelayedProgressBar({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    this.gradient,
    required this.duration,
    this.delay = Duration.zero,
    this.lineStyle = StepperConnectorStyle.solid,
    this.dashWidth = 4.0,
    this.dashGap = 3.0,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final Gradient? gradient;
  final Duration duration;
  final Duration delay;
  final StepperConnectorStyle lineStyle;
  final double dashWidth;
  final double dashGap;

  @override
  State<_DelayedProgressBar> createState() => _DelayedProgressBarState();
}

class _DelayedProgressBarState extends State<_DelayedProgressBar> {
  double _targetProgress = 0;

  /// The sequential-jump delay, held so it can be CANCELLED.
  Timer? _pending;

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _targetProgress = widget.progress;
  }

  @override
  void didUpdateWidget(_DelayedProgressBar old) {
    super.didUpdateWidget(old);
    if (widget.progress != old.progress) {
      if (widget.delay > Duration.zero) {
        _targetProgress = old.progress;
        // A cancellable Timer, not a bare `Future.delayed`: the delayed
        // one outlives the widget, so a stepper torn down mid-jump left
        // a pending callback a test binding reports and a real app
        // pays for.
        _pending?.cancel();
        _pending = Timer(widget.delay, () {
          if (mounted) setState(() => _targetProgress = widget.progress);
        });
      } else {
        _targetProgress = widget.progress;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(2.0);
    final isDashed =
        widget.lineStyle == StepperConnectorStyle.dashed ||
        widget.lineStyle == StepperConnectorStyle.dotted;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _targetProgress),
      duration: widget.duration,
      curve: Curves.easeInOut,
      builder: (_, value, _) => Stack(
        children: [
          // Track — solid or dashed/dotted
          if (isDashed)
            CustomPaint(
              size: Size(double.infinity, widget.trackColor.a > 0 ? 2 : 0),
              painter: _HorizontalDashPainter(
                color: widget.trackColor,
                thickness: 2,
                dashWidth: widget.lineStyle == StepperConnectorStyle.dotted
                    ? 2
                    : widget.dashWidth,
                dashGap: widget.dashGap,
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: widget.trackColor,
                borderRadius: radius,
              ),
            ),
          // Fill — matches track style (dashed/dotted/solid)
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: isDashed
                ? CustomPaint(
                    size: const Size(double.infinity, 2),
                    painter: _HorizontalDashPainter(
                      color: widget.activeColor,
                      thickness: 2,
                      dashWidth:
                          widget.lineStyle == StepperConnectorStyle.dotted
                          ? 2
                          : widget.dashWidth,
                      dashGap: widget.dashGap,
                      gradient: widget.gradient,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: widget.gradient == null
                          ? widget.activeColor
                          : null,
                      gradient: widget.gradient,
                      borderRadius: radius,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated custom connector — clips a custom widget with animated reveal
// ═══════════════════════════════════════════════════════════════

class _AnimatedCustomConnector extends StatefulWidget {
  const _AnimatedCustomConnector({
    required this.progress,
    required this.duration,
    this.delay = Duration.zero,
    this.axis = Axis.horizontal,
    required this.child,
  });

  final double progress;
  final Duration duration;
  final Duration delay;
  final Axis axis;
  final Widget child;

  @override
  State<_AnimatedCustomConnector> createState() =>
      _AnimatedCustomConnectorState();
}

class _AnimatedCustomConnectorState extends State<_AnimatedCustomConnector> {
  double _targetProgress = 0;

  /// The sequential-jump delay, held so it can be CANCELLED.
  Timer? _pending;

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _targetProgress = widget.progress;
  }

  @override
  void didUpdateWidget(_AnimatedCustomConnector old) {
    super.didUpdateWidget(old);
    if (widget.progress != old.progress) {
      if (widget.delay > Duration.zero) {
        _targetProgress = old.progress;
        // A cancellable Timer, not a bare `Future.delayed`: the delayed
        // one outlives the widget, so a stepper torn down mid-jump left
        // a pending callback a test binding reports and a real app
        // pays for.
        _pending?.cancel();
        _pending = Timer(widget.delay, () {
          if (mounted) setState(() => _targetProgress = widget.progress);
        });
      } else {
        _targetProgress = widget.progress;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _targetProgress),
      duration: widget.duration,
      curve: Curves.easeInOut,
      builder: (_, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Stack(
          // EXPAND, or the two layers take loose constraints, shrink to
          // their natural size and sit at the top-start corner — which
          // put a vertical connector's glyphs against the left edge of
          // the indicator column instead of down its middle.
          fit: StackFit.expand,
          children: [
            // Inactive layer (full, dimmed)
            Opacity(opacity: 0.25, child: child!),
            // Active layer (clipped by progress)
            ClipRect(
              clipper: _ProgressClipper(clampedValue, widget.axis),
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Clips to reveal a fraction of the child along the given axis.
class _ProgressClipper extends CustomClipper<Rect> {
  const _ProgressClipper(this.progress, this.axis);
  final double progress;
  final Axis axis;

  @override
  Rect getClip(Size size) {
    if (axis == Axis.horizontal) {
      return Rect.fromLTWH(0, 0, size.width * progress, size.height);
    } else {
      return Rect.fromLTWH(0, 0, size.width, size.height * progress);
    }
  }

  @override
  bool shouldReclip(_ProgressClipper old) => progress != old.progress;
}

// ═══════════════════════════════════════════════════════════════
// Vertical connector paint — fills parent height via CustomPaint
// ═══════════════════════════════════════════════════════════════

class _VerticalConnectorPaint extends StatefulWidget {
  const _VerticalConnectorPaint({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.thickness,
    this.duration = AppDurations.normal,
    this.delay = Duration.zero,
    this.lineStyle = StepperConnectorStyle.solid,
    this.dashWidth = 4.0,
    this.dashGap = 3.0,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double thickness;
  final Duration duration;
  final Duration delay;
  final StepperConnectorStyle lineStyle;
  final double dashWidth;
  final double dashGap;

  @override
  State<_VerticalConnectorPaint> createState() =>
      _VerticalConnectorPaintState();
}

class _VerticalConnectorPaintState extends State<_VerticalConnectorPaint> {
  double _targetProgress = 0;

  /// The sequential-jump delay, held so it can be CANCELLED.
  Timer? _pending;

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _targetProgress = widget.progress;
  }

  @override
  void didUpdateWidget(_VerticalConnectorPaint old) {
    super.didUpdateWidget(old);
    if (widget.progress != old.progress && widget.delay > Duration.zero) {
      _targetProgress = old.progress;
      _pending?.cancel();
      _pending = Timer(widget.delay, () {
        if (mounted) setState(() => _targetProgress = widget.progress);
      });
    } else {
      _targetProgress = widget.progress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _targetProgress),
      duration: widget.duration,
      curve: Curves.easeInOut,
      builder: (_, animatedProgress, _) => CustomPaint(
        painter: _VerticalConnectorPainter(
          progress: animatedProgress,
          activeColor: widget.activeColor,
          trackColor: widget.trackColor,
          thickness: widget.thickness,
          lineStyle: widget.lineStyle,
          dashWidth: widget.dashWidth,
          dashGap: widget.dashGap,
        ),
      ),
    );
  }
}

class _VerticalConnectorPainter extends CustomPainter {
  const _VerticalConnectorPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.thickness,
    this.lineStyle = StepperConnectorStyle.solid,
    this.dashWidth = 4.0,
    this.dashGap = 3.0,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double thickness;
  final StepperConnectorStyle lineStyle;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = thickness / 2;
    final isDashed =
        lineStyle == StepperConnectorStyle.dashed ||
        lineStyle == StepperConnectorStyle.dotted;
    final dw = lineStyle == StepperConnectorStyle.dotted
        ? thickness
        : dashWidth;

    // Track
    if (isDashed) {
      final paint = Paint()
        ..color = trackColor
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      final cx = thickness / 2;
      var pos = 0.0;
      while (pos < size.height) {
        final end = (pos + dw).clamp(0.0, size.height);
        canvas.drawLine(Offset(cx, pos), Offset(cx, end), paint);
        pos += dw + dashGap;
      }
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, thickness, size.height),
          Radius.circular(radius),
        ),
        Paint()..color = trackColor,
      );
    }
    // Fill — matches track style (dashed/dotted/solid)
    if (progress > 0) {
      final fillHeight = size.height * progress.clamp(0.0, 1.0);
      if (isDashed) {
        final paint = Paint()
          ..color = activeColor
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round;
        final cx = thickness / 2;
        var pos = 0.0;
        while (pos < fillHeight) {
          final end = (pos + dw).clamp(0.0, fillHeight);
          canvas.drawLine(Offset(cx, pos), Offset(cx, end), paint);
          pos += dw + dashGap;
        }
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, thickness, fillHeight),
            Radius.circular(radius),
          ),
          Paint()..color = activeColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_VerticalConnectorPainter old) =>
      progress != old.progress ||
      activeColor != old.activeColor ||
      lineStyle != old.lineStyle;
}

class _HorizontalDashPainter extends CustomPainter {
  const _HorizontalDashPainter({
    required this.color,
    required this.thickness,
    required this.dashWidth,
    required this.dashGap,
    this.gradient,
  });
  final Color color;
  final double thickness;
  final double dashWidth;
  final double dashGap;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    if (gradient != null) {
      paint.shader = gradient!.createShader(Offset.zero & size);
    } else {
      paint.color = color;
    }
    var pos = 0.0;
    while (pos < size.width) {
      final end = (pos + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(pos, size.height / 2),
        Offset(end, size.height / 2),
        paint,
      );
      pos += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_HorizontalDashPainter old) =>
      color != old.color || gradient != old.gradient;
}
