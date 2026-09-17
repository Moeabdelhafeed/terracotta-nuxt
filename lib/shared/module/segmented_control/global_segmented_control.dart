import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/painters/gradient_border_painter.dart';
import '../popup/popup.dart';
import '../text_field/text_field.dart' show FieldMessage, FieldMessagesColumn;
// The overflow layout and its coordinating scope live with the toggle
// group because that is where they were needed first. The two modules
// are a documented PAIR — same look, one sliding indicator apart — so
// sharing the one piece of machinery beats a second copy that drifts.
import '../toggle_group/global_toggle_group.dart';
import '../tooltip/global_tooltip.dart';
import 'segmented_control_models.dart';

export '../text_field/text_field.dart' show FieldMessage, FieldMessageType;
export 'segmented_control_models.dart';
export 'theme/segmented_control_theme.dart';

// ---------------------------------------------------------------------------
// GlobalSegmentedControl
// ---------------------------------------------------------------------------

/// Sliding-indicator SINGLE-select control (iOS-style) with
/// drag-to-select and arrow-key navigation. For multi-select or the
/// bordered button-set look use `GlobalToggleGroup` instead; that split
/// is the module boundary.
///
/// Fully controlled — displays [value] as passed, reports via
/// [onChanged]. Visuals come from the themeable [SegmentedStyle] bag
/// (`caller > GlobalSegmentedControlTheme > defaults > context
/// colors`); haptics gate on the resolved `enableHaptic` (default
/// true). RTL flips the indicator, drag mapping and arrow keys.
class GlobalSegmentedControl<T> extends StatefulWidget {
  const GlobalSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.variant = SegmentedVariant.filled,
    this.style = const SegmentedStyle(),
    this.enabled = true,
    this.tooltip,
    this.errorText,
    this.messages = const [],
    this.semanticLabel,
    this.overflow = ToggleGroupOverflow.collapse,
    this.coordinateOverflow = true,
  });

  /// What happens when the segments do not fit.
  ///
  /// Only reaches anything when `expandEqual` is OFF: with it on the
  /// segments fill the track and cannot overflow it, which is also the
  /// mode the sliding indicator needs.
  final ToggleGroupOverflow overflow;

  /// Whether it narrows in step with the toggle groups and segmented
  /// controls around it. Needs a [ToggleGroupOverflowScope] above.
  final bool coordinateOverflow;

  /// Available segments.
  final List<SegmentItem<T>> segments;

  /// Currently selected value.
  final T value;

  /// Called when selection changes.
  final ValueChanged<T>? onChanged;

  /// Visual variant.
  final SegmentedVariant variant;

  /// Themeable styling — see [SegmentedStyle.resolve] for the merge
  /// order.
  final SegmentedStyle style;

  /// Whether the entire control is interactive.
  final bool enabled;

  /// Tooltip on the entire control.
  final String? tooltip;

  /// Error shown below — rendered in the shared [FieldMessagesColumn]
  /// (icon + status color), like every field.
  final String? errorText;

  /// Status rows below, stacked with [errorText].
  final List<FieldMessage> messages;

  /// Accessibility label.
  final String? semanticLabel;

  @override
  State<GlobalSegmentedControl<T>> createState() =>
      _GlobalSegmentedControlState<T>();
}

class _GlobalSegmentedControlState<T> extends State<GlobalSegmentedControl<T>> {
  bool _isFocused = false;

  /// Identity in the overflow scope's register.
  final Object _id = Object();

  /// How many segments the row last said it could fit.
  int _fits = -1;

  /// Kept rather than looked up — deregistering happens in `dispose`.
  ToggleGroupOverflowRegistration _scope =
      const ToggleGroupOverflowRegistration.none();

  // Cached layout width from LayoutBuilder — used by drag handler
  double _trackWidth = 0;
  double _indicatorPad = 0;

  @override
  void dispose() {
    _scope.forget(_id);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = toggleGroupOverflowRegistration(context);
  }

  /// How many segments are on the track, after the scope has spoken.
  int get _visibleCount {
    final fits = _fits < 0 ? widget.segments.length : _fits;
    final cap = widget.coordinateOverflow ? _scope.cap : null;
    final visible = cap != null && cap + 1 < fits ? cap + 1 : fits;
    return visible.clamp(0, widget.segments.length);
  }

  /// The "+N" segment, and the panel behind it.
  ///
  /// The panel is a VERTICAL toggle group rather than a vertical
  /// segmented control, because a segmented control has no vertical
  /// mode: its whole identity is one sliding indicator along a track,
  /// and a track turned on its side is a different control. The button
  /// set IS that control's other face — the module boundary says so.
  Widget _buildOverflowSegment(BuildContext context) {
    final shown = _visibleCount;
    final hidden = widget.segments.sublist(shown);
    final holdsSelection = hidden.any((s) => s.value == widget.value);

    return GlobalPopup.panel(
      anchor: Semantics(
        button: true,
        label: ToggleGroupStrings.overflowSemanticLabel(hidden.length),
        child: ExcludeSemantics(
          child: _SegmentButton<T>(
            segment: SegmentItem<T>(
              value: widget.value,
              label: '+${hidden.length}',
            ),
            isSelected: holdsSelection,
            isEnabled: widget.enabled,
            rs: _rs,
            duration: _duration,
            // A no-op: a segment is a `GestureDetector`, which takes
            // no focus and consumes no key, so the popup around it
            // still owns both the pointer and the keyboard.
            onTap: () {},
          ),
        ),
      ),
      options: const GlobalPopupOptions(
        placement: GlobalPopupPlacement.bottomEnd,
        // Clear of the track, and with no surface of its own: the
        // group inside already draws the border and the radius, and a
        // popup card around that is a frame within a frame.
        // The same gap two neighbouring segments have.
        gap: 1,
        surfaceStyle: GlobalPopupSurfaceStyle(
          color: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          borderWidth: 0,
          shadow: [],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.backgroundColors.container,
          borderRadius: _rs.borderRadius,
        ),
        child: GlobalToggleGroup<T>.single(
          items: [
            for (final s in hidden)
              ToggleGroupItem<T>(
                value: s.value,
                label: s.label,
                icon: s.icon,
                enabled: s.enabled,
              ),
          ],
          value: widget.value,
          orientation: Axis.vertical,
          // The track's own colours and corner, so what opens reads as
          // the control stood on its end rather than a different widget.
          style: ToggleGroupStyle(
            selectedColor: _rs.selectedColor,
            selectedForegroundColor: _rs.selectedForegroundColor,
            unselectedForegroundColor: _rs.unselectedForegroundColor,
            borderRadius: _rs.borderRadius,
            height: _rs.height,
            expandEqual: false,
          ),
          onChanged: (v) => widget.onChanged?.call(v),
        ),
      ),
    );
  }

  /// Resolved style — materialized once per build (see build()).
  late ResolvedSegmentedStyle _rs;
  bool _reduceMotion = false;

  bool get _isDisabled => !widget.enabled || widget.onChanged == null;

  Duration get _duration =>
      _reduceMotion ? Duration.zero : _rs.animationDuration;

  void _selectSegment(SegmentItem<T> segment) {
    if (_isDisabled || !segment.enabled) return;
    if (segment.value == widget.value) return;
    if (_rs.enableHaptic) HapticFeedback.lightImpact();
    widget.onChanged!(segment.value);
  }

  int get _selectedIndex {
    for (var i = 0; i < widget.segments.length; i++) {
      if (widget.segments[i].value == widget.value) return i;
    }
    return 0;
  }

  // ─── Keyboard navigation ───────────────────────────────────

  void _selectNext() {
    if (_isDisabled) return;
    final segments = widget.segments;
    final idx = _selectedIndex;
    for (var i = 1; i < segments.length; i++) {
      final next = (idx + i) % segments.length;
      if (segments[next].enabled) {
        _selectSegment(segments[next]);
        return;
      }
    }
  }

  void _selectPrevious() {
    if (_isDisabled) return;
    final segments = widget.segments;
    final idx = _selectedIndex;
    for (var i = 1; i < segments.length; i++) {
      final prev = (idx - i + segments.length) % segments.length;
      if (segments[prev].enabled) {
        _selectSegment(segments[prev]);
        return;
      }
    }
  }

  // ─── Drag-to-select ────────────────────────────────────────

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDisabled) return;
    final segmentCount = widget.segments.length;
    if (segmentCount == 0 || _trackWidth <= 0) return;

    final localX = details.localPosition.dx - _indicatorPad;
    final segmentWidth = _trackWidth / segmentCount;
    if (segmentWidth <= 0) return;

    var idx = (localX / segmentWidth).floor().clamp(0, segmentCount - 1);
    // Physical x → logical index: RTL lays segment 0 at the RIGHT edge.
    if (Directionality.of(context) == TextDirection.rtl) {
      idx = segmentCount - 1 - idx;
    }
    final segment = widget.segments[idx];
    if (segment.enabled && segment.value != widget.value) {
      _selectSegment(segment);
    }
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Materialize the themeable bag once per build (resolved-style
    // invariant).
    _rs = widget.style.resolve(context, variant: widget.variant);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);

    final isDisabled = _isDisabled;
    final radius = _rs.borderRadius;
    final height = _rs.height;
    final indicatorPad = _rs.indicatorPadding;
    // Clamp indicator radius so it can't go negative
    final indicatorRadius = BorderRadius.circular(
      math.max(0, radius.topLeft.x - indicatorPad),
    );
    final selectedIndex = _selectedIndex;

    // Track decoration
    final trackDecoration = BoxDecoration(
      color: _rs.backgroundGradient == null ? _rs.backgroundColor : null,
      gradient: _rs.backgroundGradient,
      borderRadius: radius,
      border: _rs.borderGradient == null && _rs.borderColor != null
          ? Border.all(color: _rs.borderColor!, width: _rs.borderWidth)
          : null,
      boxShadow: _rs.shadow,
    );

    // Build segments
    final segmentWidgets = <Widget>[];
    for (var i = 0; i < widget.segments.length; i++) {
      final segment = widget.segments[i];
      final isSelected = i == selectedIndex;
      final isSegmentEnabled = widget.enabled && segment.enabled;

      segmentWidgets.add(
        _SegmentButton<T>(
          segment: segment,
          isSelected: isSelected,
          isEnabled: isSegmentEnabled,
          rs: _rs,
          duration: _duration,
          onTap: () => _selectSegment(segment),
        ),
      );
    }

    // Indicator decoration
    final indicatorDecoration = BoxDecoration(
      color: _rs.selectedGradient == null ? _rs.selectedColor : null,
      gradient: _rs.selectedGradient,
      borderRadius: indicatorRadius,
      border: widget.variant == SegmentedVariant.outlined
          ? Border.all(color: _rs.outlineAccent, width: _rs.borderWidth)
          : null,
      boxShadow:
          _rs.indicatorShadow ??
          (widget.variant == SegmentedVariant.filled
              // Neutral elevation shadow — black by Material convention.
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null),
    );

    // Only attach drag gesture when expandEqual (segment widths are
    // calculable). Reduced motion keeps drag — the indicator just snaps.
    final enableDrag = _rs.expandEqual && !isDisabled;

    Widget control = AnimatedOpacity(
      opacity: isDisabled ? kSegmentedDisabledOpacity : 1.0,
      duration: _duration,
      child: GestureDetector(
        onHorizontalDragUpdate: enableDrag ? _handleDragUpdate : null,
        child: Container(
          height: height,
          decoration: trackDecoration,
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(indicatorPad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentCount = widget.segments.length;
              if (segmentCount == 0) return const SizedBox.shrink();

              final trackWidth = constraints.maxWidth;
              final segmentWidth = _rs.expandEqual
                  ? trackWidth / segmentCount
                  : null;

              // Cache for drag handler
              _trackWidth = trackWidth;
              _indicatorPad = indicatorPad;

              return Stack(
                children: [
                  // Sliding indicator — directional so RTL lands it on
                  // the visually-correct segment.
                  if (segmentWidth != null)
                    AnimatedPositionedDirectional(
                      duration: _duration,
                      curve: _rs.animationCurve,
                      start: selectedIndex * segmentWidth,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(decoration: indicatorDecoration),
                    ),
                  // Segments row.
                  //
                  // `expandEqual` fills the track, so nothing can
                  // overflow it and there is nothing to collapse —
                  // that is also the mode the sliding indicator needs,
                  // since it is positioned by segment WIDTH. Without
                  // it the segments take their natural size and the
                  // row can run off the end, which is what the toggle
                  // group's overflow layout is for.
                  if (segmentWidth != null)
                    Row(children: segmentWidgets)
                  else
                    ToggleOverflowRow(
                      textDirection: Directionality.of(context),
                      // Collapsed segments stay in the tree so the row
                      // can measure them, and are taken out of the
                      // FOCUS tree by hand — Tab was walking through
                      // segments nobody could see.
                      slots: [
                        for (var i = 0; i < segmentWidgets.length; i++)
                          ExcludeFocus(
                            excluding: i >= _visibleCount,
                            child: segmentWidgets[i],
                          ),
                      ],
                      overflow: ExcludeFocus(
                        excluding: _visibleCount >= widget.segments.length,
                        child: _buildOverflowSegment(context),
                      ),
                      maxVisible: widget.coordinateOverflow ? _scope.cap : null,
                      onFits: (fits) {
                        if (_fits == fits || !mounted) return;
                        setState(() => _fits = fits);
                        if (widget.coordinateOverflow) {
                          _scope.report(_id, fits);
                        }
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Gradient border
    if (_rs.borderGradient != null) {
      control = CustomPaint(
        foregroundPainter: GradientBorderPainter(
          gradient: _rs.borderGradient!,
          borderRadius: radius,
          borderWidth: _rs.borderWidth,
        ),
        child: control,
      );
    }

    // Keyboard navigation + focus ring (overlay — no layout shift)
    control = _buildKeyboardWrapper(control, isDisabled, radius);

    // Error + status rows — the shared message column.
    if (widget.errorText != null || widget.messages.isNotEmpty) {
      control = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          control,
          FieldMessagesColumn(
            errorText: widget.errorText,
            messages: widget.messages,
          ),
        ],
      );
    }

    // Tooltip
    if (widget.tooltip != null) {
      control = GlobalTooltip(message: widget.tooltip!, child: control);
    }

    // Semantics
    return Semantics(
      label: widget.semanticLabel ?? SegmentedControlStrings.semanticLabel,
      enabled: !isDisabled,
      onTap: isDisabled ? null : _selectNext,
      excludeSemantics: true,
      child: control,
    );
  }

  // ─── Keyboard + Focus ──────────────────────────────────────

  Widget _buildKeyboardWrapper(
    Widget child,
    bool isDisabled,
    BorderRadius radius,
  ) {
    // Physical arrows → logical direction: in RTL, arrowRight moves
    // BACKWARD through the list (the list renders right→left).
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Actions(
      actions: <Type, Action<Intent>>{
        _NextSegmentIntent: CallbackAction<_NextSegmentIntent>(
          onInvoke: (_) {
            _selectNext();
            return null;
          },
        ),
        _PrevSegmentIntent: CallbackAction<_PrevSegmentIntent>(
          onInvoke: (_) {
            _selectPrevious();
            return null;
          },
        ),
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowRight): isRtl
              ? const _PrevSegmentIntent()
              : const _NextSegmentIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): isRtl
              ? const _NextSegmentIntent()
              : const _PrevSegmentIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _NextSegmentIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _PrevSegmentIntent(),
          const SingleActivator(LogicalKeyboardKey.enter):
              const _NextSegmentIntent(),
          const SingleActivator(LogicalKeyboardKey.space):
              const _NextSegmentIntent(),
        },
        child: Focus(
          canRequestFocus: !isDisabled,
          onFocusChange: (v) => setState(() => _isFocused = v),
          // Use Stack overlay so focus ring doesn't cause layout shift
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (_isFocused && !isDisabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: _rs.focusRingColor,
                          width: kSegmentedFocusRingWidth,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Keyboard intents ────────────────────────────────────────

class _NextSegmentIntent extends Intent {
  const _NextSegmentIntent();
}

class _PrevSegmentIntent extends Intent {
  const _PrevSegmentIntent();
}

// ---------------------------------------------------------------------------
// Individual segment button
// ---------------------------------------------------------------------------

class _SegmentButton<T> extends StatefulWidget {
  const _SegmentButton({
    required this.segment,
    required this.isSelected,
    required this.isEnabled,
    required this.rs,
    required this.duration,
    required this.onTap,
  });

  final SegmentItem<T> segment;
  final bool isSelected;
  final bool isEnabled;
  final ResolvedSegmentedStyle rs;
  final Duration duration;
  final VoidCallback onTap;

  @override
  State<_SegmentButton<T>> createState() => _SegmentButtonState<T>();
}

class _SegmentButtonState<T> extends State<_SegmentButton<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final rs = widget.rs;
    final fg = !widget.isEnabled
        ? (rs.disabledColor ?? rs.disabledForegroundColor)
        : widget.isSelected
        ? rs.selectedForegroundColor
        : rs.unselectedForegroundColor;

    final textStyle =
        (widget.isSelected ? rs.selectedTextStyle : rs.unselectedTextStyle)
            ?.copyWith(color: fg);

    final hasIcon =
        widget.segment.icon != null || widget.segment.iconWidget != null;
    final trailing = widget.segment.trailing;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasIcon) ...[
          widget.segment.iconWidget ??
              Icon(widget.segment.icon, size: rs.iconSize, color: fg),
          SizedBox(width: rs.iconSpacing),
        ],
        // FLEXIBLE, and it ellipsizes.
        //
        // `expandEqual` hands every segment a tight width, and this
        // Row is `mainAxisSize.min` — so a label wider than its share
        // overflowed the segment rather than shortening. "Archived" in
        // a four-up control on a phone did exactly that, and the
        // striped bar went right across the card. The buttons module
        // learned the same thing: its label is always `Flexible`.
        Flexible(
          child: AnimatedDefaultTextStyle(
            duration: widget.duration,
            style: textStyle ?? TextStyle(color: fg),
            child: Text(
              widget.segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: rs.iconSpacing),
          trailing,
        ],
      ],
    );

    if (rs.segmentPadding != null) {
      content = Padding(padding: rs.segmentPadding!, child: content);
    }

    Widget button = GestureDetector(
      onTap: widget.isEnabled ? widget.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: widget.duration,
          color: _isHovered && widget.isEnabled && !widget.isSelected
              ? fg.withValues(alpha: kSegmentedHoverOpacity)
              : Colors.transparent,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (rs.expandEqual) {
      return Expanded(child: button);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSegmentedDefaultPaddingH,
      ),
      child: button,
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient border painter
// ---------------------------------------------------------------------------
