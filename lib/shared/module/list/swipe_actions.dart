import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';

/// One action behind a row.
///
/// [onInvoke] runs and the row closes. Nothing here removes the row —
/// a list does not own its items, so a delete action calls back and
/// the CALLER drops the item, which is also what makes undo possible.
@immutable
class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.onInvoke,
    this.label,
    this.background,
    this.foreground,
    this.isDestructive = false,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onInvoke;

  /// Shown under the icon when the pane is wide enough for it.
  final String? label;

  /// Defaults to the error colour when [isDestructive], the primary
  /// otherwise — resolved against the palette, not Material's scheme.
  final Color? background;
  final Color? foreground;

  /// Colours the pane as a warning AND makes this the action a full
  /// swipe commits to when it is first on its side.
  final bool isDestructive;

  /// What a screen reader calls this. Falls back to [label].
  final String? semanticLabel;

  /// What the a11y action and the tooltip say.
  String get accessibleLabel => semanticLabel ?? label ?? '';
}

/// The two panes behind one row.
///
/// [leading] and [trailing] are DIRECTIONAL — leading is the reading
/// start, so in Arabic it is revealed by dragging left. The physical
/// side is never named, because the gesture that reveals a pane is the
/// one that moves toward the reader's start, whichever way that is.
@immutable
class SwipeActions {
  const SwipeActions({
    this.leading = const <SwipeAction>[],
    this.trailing = const <SwipeAction>[],
    this.allowFullSwipe = true,
  });

  final List<SwipeAction> leading;
  final List<SwipeAction> trailing;

  /// Whether dragging most of the way across commits to the FIRST
  /// action on that side without waiting for a tap.
  ///
  /// Worth turning off when the first action is destructive and there
  /// is no undo: a full swipe is easy to do by accident on a list
  /// that is being scrolled quickly.
  final bool allowFullSwipe;

  bool get isEmpty => leading.isEmpty && trailing.isEmpty;
}

/// A row with a pane of actions behind each side.
///
/// The gesture is horizontal, which is why this is a LIST feature and
/// not a grid one: a vertical list has a spare horizontal axis, and a
/// grid does not — a horizontal drag over a grid is either a scroll or
/// a reorder.
class GlobalSwipeRow extends StatefulWidget {
  const GlobalSwipeRow({
    required this.actions,
    required this.child,
    required this.settleDuration,
    this.actionExtent = 72,
    this.fullSwipeThreshold = 0.55,
    this.enableHaptic = true,
    this.openRow,
    this.rowId,
    super.key,
  });

  final SwipeActions actions;
  final Widget child;

  /// Zero under reduced motion, in which case the row snaps between
  /// open and closed instead of gliding.
  final Duration settleDuration;

  /// How wide one action's pane is.
  final double actionExtent;

  /// The fraction of the row's width a drag has to cross before it
  /// commits to the first action on that side.
  final double fullSwipeThreshold;

  final bool enableHaptic;

  /// Shared across the rows of one list so only ONE is open at a time.
  /// A second open row is a row the reader has forgotten about, and it
  /// stays behind their finger while they scroll.
  final ValueNotifier<Object?>? openRow;

  /// This row's identity within [openRow]. Required to participate.
  final Object? rowId;

  @override
  State<GlobalSwipeRow> createState() => _GlobalSwipeRowState();
}

class _GlobalSwipeRowState extends State<GlobalSwipeRow>
    with SingleTickerProviderStateMixin {
  /// UNBOUNDED. An ordinary controller clamps its value to 0..1, and
  /// this one carries the row's offset in POINTS — a trailing pane at
  /// -144 was clamped to zero and the row never moved.
  late final AnimationController _ctrl = AnimationController.unbounded(
    vsync: this,
    duration: widget.settleDuration,
  );

  /// How far the row is dragged, measured from the reading START:
  /// positive reveals the leading pane, negative the trailing one.
  /// Physical direction is applied once, at the paint, so nothing else
  /// in here has to know which way the language runs.
  double _offset = 0;

  /// True while the drag is past the full-swipe threshold, so the
  /// haptic fires ONCE on the way in rather than every frame.
  bool _armed = false;

  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTick);
    widget.openRow?.addListener(_onOpenRowChanged);
  }

  @override
  void didUpdateWidget(GlobalSwipeRow old) {
    super.didUpdateWidget(old);
    if (old.settleDuration != widget.settleDuration) {
      _ctrl.duration = widget.settleDuration;
    }
    if (old.openRow != widget.openRow) {
      old.openRow?.removeListener(_onOpenRowChanged);
      widget.openRow?.addListener(_onOpenRowChanged);
    }
  }

  @override
  void dispose() {
    widget.openRow?.removeListener(_onOpenRowChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onTick() {
    setState(() => _offset = _ctrl.value);
  }

  void _onOpenRowChanged() {
    final open = widget.openRow?.value;
    if (open != widget.rowId && _offset != 0 && !_dragging) _close();
  }

  double get _leadingExtent =>
      widget.actions.leading.length * widget.actionExtent;
  double get _trailingExtent =>
      widget.actions.trailing.length * widget.actionExtent;

  /// Runs the settle from wherever the row is to [to].
  void _settleTo(double to) {
    if (widget.settleDuration == Duration.zero) {
      setState(() => _offset = to);
      return;
    }
    _ctrl
      ..stop()
      ..value = _offset
      ..animateTo(
        to,
        duration: widget.settleDuration,
        curve: Curves.easeOutCubic,
      );
  }

  void _close() => _settleTo(0);

  void _onDragStart(DragStartDetails _) {
    _dragging = true;
    _ctrl.stop();
    widget.openRow?.value = widget.rowId;
  }

  void _onDragUpdate(DragUpdateDetails d, double width) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // ONE conversion, here: everything below this line is measured
    // from the reading start.
    final delta = rtl ? -d.delta.dx : d.delta.dx;
    var next = _offset + delta;
    // Past the pane, resistance rather than a wall — a hard stop reads
    // as the gesture having been dropped.
    final maxLead = widget.actions.leading.isEmpty ? 0.0 : width;
    final maxTrail = widget.actions.trailing.isEmpty ? 0.0 : width;
    next = next.clamp(-maxTrail, maxLead);
    final full = widget.fullSwipeThreshold * width;
    final armed = widget.actions.allowFullSwipe && next.abs() >= full;
    if (armed && !_armed && widget.enableHaptic) HapticFeedback.mediumImpact();
    _armed = armed;
    setState(() => _offset = next);
  }

  void _onDragEnd(DragEndDetails d, double width) {
    _dragging = false;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final velocity = (rtl ? -1 : 1) * d.velocity.pixelsPerSecond.dx;
    final leading = _offset > 0;
    final pane = leading ? _leadingExtent : _trailingExtent;
    final actions = leading ? widget.actions.leading : widget.actions.trailing;
    if (actions.isEmpty) {
      _close();
      return;
    }
    if (_armed) {
      _armed = false;
      _invoke(actions.first);
      return;
    }
    // A FLICK opens or closes regardless of distance. Requiring half
    // the pane to be crossed made a quick flick feel like the row had
    // ignored it.
    const flick = 400.0;
    if (leading && velocity > flick) {
      _settleTo(pane);
      return;
    }
    if (!leading && velocity < -flick) {
      _settleTo(-pane);
      return;
    }
    if (velocity.abs() > flick) {
      _close();
      return;
    }
    _settleTo(_offset.abs() >= pane / 2 ? (leading ? pane : -pane) : 0);
  }

  void _invoke(SwipeAction action) {
    if (widget.enableHaptic && action.isDestructive) {
      HapticFeedback.heavyImpact();
    }
    _close();
    widget.openRow?.value = null;
    action.onInvoke();
  }

  Color _background(BuildContext context, SwipeAction a) =>
      a.background ??
      (a.isDestructive
          ? context.statusColors.error
          : context.primaryColors.primary);

  /// One colour for both panes: the palette names what goes ON a
  /// filled surface once, and an error pane is as filled as a primary
  /// one.
  Color _foreground(BuildContext context, SwipeAction a) =>
      a.foreground ?? context.textColors.onPrimary;

  /// The pane behind one side, laid out so the FIRST action sits
  /// nearest that edge — which is the one a full swipe commits to and
  /// the one the thumb reaches first.
  Widget _pane(BuildContext context, List<SwipeAction> actions, bool leading) {
    final revealed = _offset.abs();
    // Under a full swipe the first action takes the whole pane, which
    // is the standard way of saying "let go and this happens".
    final full = _armed;
    return Row(
      mainAxisAlignment: leading
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        for (var i = 0; i < actions.length; i++)
          if (!full || i == 0)
            SizedBox(
              width: full ? revealed : widget.actionExtent,
              child: _ActionButton(
                action: actions[i],
                background: _background(context, actions[i]),
                foreground: _foreground(context, actions[i]),
                onTap: () => _invoke(actions[i]),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return widget.child;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (ctx, c) {
        final width = c.maxWidth;
        final leading = _offset > 0;
        final actions = leading
            ? widget.actions.leading
            : widget.actions.trailing;
        return Semantics(
          // A swipe is INVISIBLE to a screen reader — the row would
          // simply have no archive and no delete. Every action is also
          // a custom action on the row itself.
          customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
            for (final a in [
              ...widget.actions.leading,
              ...widget.actions.trailing,
            ])
              if (a.accessibleLabel.isNotEmpty)
                CustomSemanticsAction(label: a.accessibleLabel): () =>
                    _invoke(a),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: (d) => _onDragUpdate(d, width),
            onHorizontalDragEnd: (d) => _onDragEnd(d, width),
            child: Stack(
              children: [
                if (_offset != 0)
                  Positioned.fill(
                    child: ClipRect(child: _pane(ctx, actions, leading)),
                  ),
                Transform.translate(
                  // The one place physical direction is applied.
                  offset: Offset(rtl ? -_offset : _offset, 0),
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One action's coloured pane. Its own button, so an action can be
/// TAPPED rather than committed to by dragging the whole way.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final SwipeAction action;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: foreground, size: context.iconSizes.md),
              if (action.label != null) ...[
                SizedBox(height: context.spacing.xs),
                // The label is the first thing to go when the pane is
                // narrow — an icon alone still reads, a clipped word
                // does not.
                Flexible(
                  child: Text(
                    action.label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
