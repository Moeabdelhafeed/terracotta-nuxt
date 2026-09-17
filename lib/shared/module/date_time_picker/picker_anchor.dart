import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/strings/date_field_strings.dart';
import 'date_time_picker_models.dart';
import 'date_time_picker_style.dart';

/// A trigger with a panel that opens against it.
///
/// Both pickers had their own copy of this — the link, the key, the
/// entry, the animation, the above/below arithmetic — and the copies
/// had drifted: one measured against the screen and the other against
/// the screen minus 30 points, so the same trigger flipped sides
/// depending on which widget owned it. Worse, both put the measuring
/// key on the DEFAULT trigger's inner container, so a custom
/// `triggerBuilder` left nothing to measure and the panel never opened.
class PickerAnchor extends StatefulWidget {
  const PickerAnchor({
    super.key,
    required this.style,
    required this.trigger,
    required this.panel,
    this.onOpenChanged,
  });

  final ResolvedDateTimePickerStyle style;

  /// Built with the current open state and the toggle.
  final Widget Function(BuildContext context, bool open, VoidCallback toggle)
  trigger;

  /// The panel's contents. [close] dismisses it.
  final Widget Function(BuildContext context, VoidCallback close) panel;

  final ValueChanged<bool>? onOpenChanged;

  @override
  State<PickerAnchor> createState() => _PickerAnchorState();
}

class _PickerAnchorState extends State<PickerAnchor>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();

  OverlayEntry? _entry;

  /// Where focus was before the panel took it, so Escape puts it back
  /// on the trigger rather than nowhere.
  FocusNode? _restoreFocus;
  final FocusScopeNode _panelFocus = FocusScopeNode(debugLabel: 'pickerPanel');
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _open = false;

  OverlayPlacement _placement = const OverlayPlacement(
    above: false,
    height: DateTimePickerDefaults.overlayMinHeight,
    offsetY: 0,
  );

  /// The panel's own height, once it has been laid out.
  ///
  /// The panel is measured and the placement recomputed, rather than
  /// the placement handing the panel a budget: a picker that loses two
  /// rows near the bottom of a screen cannot show the dates being asked
  /// for. It re-measures whenever the content changes size — a month
  /// with six rows is taller than one with five.
  double? _panelHeight;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: DateTimePickerDefaults.overlayDuration,
      vsync: this,
    );
    _scale =
        Tween<double>(
          begin: DateTimePickerDefaults.overlayScaleFrom,
          end: 1,
        ).animate(
          CurvedAnimation(parent: _anim, curve: Curves.easeOut),
        );
    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(PickerAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The panel is built into a LIVE overlay entry, which does not
    // rebuild when this widget's parent does. Forwarding the fresh
    // builder is what lets a `setState` on the page show through in a
    // panel already on screen.
    _refreshPanel();
  }

  /// Marks the panel dirty, whenever it is safe to.
  ///
  /// The entry lives in the ROOT overlay, so it is not a descendant of
  /// this widget — and marking a non-descendant dirty while the
  /// framework is mid-build throws. Which is exactly when this is
  /// called: `didUpdateWidget` runs during the parent's build, and the
  /// parent rebuilds because the panel reported a pick.
  void _refreshPanel() {
    final entry = _entry;
    if (entry == null) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entry?.markNeedsBuild();
      });
      return;
    }
    entry.markNeedsBuild();
  }

  @override
  void dispose() {
    // Let go of focus BEFORE the entry holding the scope is torn out.
    // Removing it first leaves the manager with a focused child whose
    // enclosing scope has gone, which it asserts on.
    if (_entry != null) {
      _panelFocus.unfocus();
      _entry!.remove();
      _entry = null;
    }
    _restoreFocus = null;
    _anim.dispose();
    _panelFocus.dispose();
    super.dispose();
  }

  void _measure(BuildContext context) {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final media = MediaQuery.of(context);
    _placement = OverlayPlacement.decide(
      triggerTop: box.localToGlobal(Offset.zero).dy,
      triggerHeight: box.size.height,
      availableHeight: media.size.height - media.viewInsets.bottom,
      gap: widget.style.overlayGap,
      margin: widget.style.overlayScreenMargin,
      maxHeight: widget.style.overlayMaxHeight,
      minHeight: widget.style.overlayMinHeight,
      contentHeight: _panelHeight,
    );
  }

  void _onPanelMeasured(Size size) {
    if (!mounted || _entry == null) return;
    final previous = _panelHeight;
    if (previous != null && (previous - size.height).abs() < 0.5) return;
    _panelHeight = size.height;
    _measure(context);
    _entry?.markNeedsBuild();
  }

  void _show() {
    if (_open) return;
    _restoreFocus = FocusManager.instance.primaryFocus;
    _measure(context);
    _panelHeight = null;
    _entry = OverlayEntry(builder: _buildPanel);
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    setState(() => _open = true);
    widget.onOpenChanged?.call(true);
    _anim.forward();
  }

  void _close() {
    if (_entry == null) return;
    _anim.reverse().then((_) {
      if (!mounted) {
        _entry?.remove();
        _entry = null;
        return;
      }
      _entry?.remove();
      _entry = null;
      setState(() => _open = false);
      widget.onOpenChanged?.call(false);
      _restoreFocus?.requestFocus();
      _restoreFocus = null;
    });
  }

  void _toggle() => _open ? _close() : _show();

  Widget _buildPanel(BuildContext overlayCtx) {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();
    _measure(context);

    final style = widget.style;
    final screenWidth = MediaQuery.sizeOf(overlayCtx).width;

    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            label: DatePickerStrings.close,
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: Offset(0, _placement.offsetY),
          // Escape closes it. A backdrop tap was the only way out, which
          // is no way out at all for a keyboard. The panel takes focus
          // so the key reaches it, and hands it back on the way out.
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _close,
            },
            child: FocusScope(
              node: _panelFocus,
              autofocus: true,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: FadeTransition(
                  opacity: _opacity,
                  child: ScaleTransition(
                    scale: _scale,
                    alignment: _placement.above
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    child: Material(
                      color: Colors.transparent,
                      elevation: style.overlayElevation,
                      shadowColor: style.overlayShadowColor,
                      borderRadius: BorderRadius.circular(style.overlayRadius),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        width: style.overlayMatchTriggerWidth
                            ? math.min(
                                math.max(
                                  box.size.width,
                                  DateTimePickerDefaults.overlayMinWidth,
                                ),
                                screenWidth - style.overlayScreenMargin * 2,
                              )
                            : null,
                        constraints: BoxConstraints(
                          maxHeight: _placement.height,
                          maxWidth: screenWidth - style.overlayScreenMargin * 2,
                        ),
                        decoration: BoxDecoration(
                          color: style.surfaceColor,
                          borderRadius: BorderRadius.circular(
                            style.overlayRadius,
                          ),
                          border: Border.all(
                            color: style.borderColor,
                            width: style.borderWidth,
                          ),
                        ),
                        // The ANCHOR owns the scrolling, not the panel.
                        // A `SingleChildScrollView` reports the height it
                        // was GIVEN, so a panel that scrolled itself
                        // measured as tall as whatever it was handed — and
                        // the placement then handed it that back. Inside
                        // one, the child is laid out unbounded, so what
                        // `_MeasureSize` sees is its natural height.
                        child: SingleChildScrollView(
                          child: _MeasureSize(
                            onChange: _onPanelMeasured,
                            child: widget.panel(overlayCtx, _close),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _anim.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : widget.style.overlayDuration;

    return CompositedTransformTarget(
      link: _link,
      // The key rides the TARGET, so a custom trigger is measured just
      // as the built-in one is.
      key: _triggerKey,
      child: widget.trigger(context, _open, _toggle),
    );
  }
}

// ---------------------------------------------------------------------------
// _MeasureSize — reports its child's laid-out size
// ---------------------------------------------------------------------------

/// Hands [onChange] the child's size after every layout that changes it.
///
/// The panel is sized by its CONTENT and the placement follows, which
/// needs a number no build pass has yet — so the first pass lays the
/// panel out against the whole screen, this reports what it came to, and
/// the second pass puts it where that height fits.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureSize renderObject,
  ) => renderObject.onChange = onChange;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final next = child?.size ?? Size.zero;
    if (_reported == next) return;
    _reported = next;
    // Marking anything dirty DURING layout throws, so the report lands
    // after the frame that produced it.
    SchedulerBinding.instance.addPostFrameCallback((_) => onChange(next));
  }
}
