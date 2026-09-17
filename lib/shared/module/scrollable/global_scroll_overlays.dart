import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/scroll_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../tooltip/global_tooltip.dart';
import 'scrollable_models.dart';
import 'scrollable_style.dart';
import 'theme/scrollable_theme.dart';

/// The chrome that floats over a scrollable: a way back to the top, a
/// progress strip, and a "there is new content up there" pill.
///
/// Wrap any scrollable with it. `GlobalScrollable` does this for you;
/// `GlobalList` and `GlobalGrid` use it directly.
///
/// **It does NOT rebuild the child.** The scroll position lives in a
/// `ValueNotifier` that only the overlays listen to — this used to
/// `setState` on every pixel of every scroll, which rebuilt the entire
/// list underneath it once a frame for the sake of a 3-pixel strip.
class GlobalScrollOverlays extends StatefulWidget {
  const GlobalScrollOverlays({
    super.key,
    required this.child,
    required this.controller,
    this.axis = Axis.vertical,
    this.style,
    this.scrollToTopBuilder,
    this.newItemPendingCount = 0,
    this.newItemFabBuilder,
    this.onNewItemTap,
    this.onReachedEnd,
  });

  final Widget child;
  final ScrollController controller;
  final Axis axis;

  /// Merged over `GlobalScrollableTheme` and then the floor. Which
  /// overlays are shown is part of it (`showScrollToTop`,
  /// `showScrollProgress`) — that is an app-wide decision, not a
  /// per-call one.
  final ScrollableStyle? style;

  /// Replaces the default round button. Handed the callback that
  /// scrolls; a builder that ignores it is a button that does nothing.
  final Widget Function(BuildContext, VoidCallback)? scrollToTopBuilder;

  /// Above zero, the "jump to new" pill appears with this count.
  final int newItemPendingCount;
  final Widget Function(BuildContext, int pendingCount, VoidCallback onTap)?
  newItemFabBuilder;
  final VoidCallback? onNewItemTap;

  /// Fires when the reader reaches the end on their own — the owner
  /// uses it to clear [newItemPendingCount].
  final VoidCallback? onReachedEnd;

  @override
  State<GlobalScrollOverlays> createState() => _GlobalScrollOverlaysState();
}

/// What the overlays need from the scroll position, as one value so a
/// single notifier drives both of them.
@immutable
class _ScrollSnapshot {
  const _ScrollSnapshot({required this.progress, required this.pastThreshold});

  final double progress;
  final bool pastThreshold;

  static const zero = _ScrollSnapshot(progress: 0, pastThreshold: false);

  @override
  bool operator ==(Object other) =>
      other is _ScrollSnapshot &&
      other.progress == progress &&
      other.pastThreshold == pastThreshold;

  @override
  int get hashCode => Object.hash(progress, pastThreshold);
}

class _GlobalScrollOverlaysState extends State<GlobalScrollOverlays> {
  final _snapshot = ValueNotifier<_ScrollSnapshot>(_ScrollSnapshot.zero);

  /// Distance from the end that counts as "reached it".
  static const _endSlack = 24.0;

  late ResolvedScrollableStyle _style;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The palette and reduce-motion are INHERITED reads, so this
    // cannot happen in `initState`.
    _style = widget.style.resolve(context);
  }

  @override
  void didUpdateWidget(GlobalScrollOverlays old) {
    super.didUpdateWidget(old);
    if (widget.style != old.style) _style = widget.style.resolve(context);
    if (widget.controller != old.controller) {
      old.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _snapshot.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !widget.controller.hasClients) return;
    final pos = widget.controller.position;
    if (!pos.hasContentDimensions) return;
    final pixels = pos.pixels;
    final max = pos.maxScrollExtent;
    _snapshot.value = _ScrollSnapshot(
      progress: max > 0 ? (pixels / max).clamp(0.0, 1.0) : 0.0,
      pastThreshold: pixels > _style.scrollToTopThreshold,
    );
    if (widget.onReachedEnd != null && max - pixels < _endSlack) {
      widget.onReachedEnd!();
    }
  }

  void _scrollToTop() {
    if (!widget.controller.hasClients) return;
    if (_style.enableHaptic) HapticFeedback.selectionClick();
    final duration = _style.scrollToTopDuration;
    if (duration == Duration.zero) {
      widget.controller.jumpTo(0);
      return;
    }
    widget.controller.animateTo(
      0,
      duration: duration,
      curve: ScrollableDefaults.scrollToTopCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final hasNewItem = widget.onNewItemTap != null;
    if (!style.showScrollToTop && !style.showScrollProgress && !hasNewItem) {
      return widget.child;
    }

    // The two builder slots hand a CALLER's widget to a `Positioned`
    // with only an edge, which leaves it unbounded on both axes. Our
    // own FABs are fixed-size and never noticed; the first
    // full-width button anyone passed asserted with
    // `BoxConstraints forces an infinite width` and took the whole
    // page's layout down with it. The Stack knows how much room it
    // has, so the slot passes it on rather than leaving a caller to
    // discover this.
    return LayoutBuilder(
      builder: (ctx, c) => _buildStack(ctx, style, hasNewItem, c.biggest),
    );
  }

  Widget _buildStack(
    BuildContext context,
    ResolvedScrollableStyle style,
    bool hasNewItem,
    Size room,
  ) {
    /// Caps a caller's chrome at the room the Stack actually has,
    /// minus the margin it is inset by on each side.
    Widget bounded(Widget child) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: (room.width - style.fabMargin * 2).clamp(0.0, room.width),
        maxHeight: (room.height - style.fabMargin * 2).clamp(0.0, room.height),
      ),
      child: child,
    );

    return Stack(
      children: [
        Positioned.fill(
          // The chrome repaints on every frame of every scroll — the
          // strip is a new width sixty times a second. Without a
          // boundary it shares a layer with the CONTENT, so the whole
          // list is re-rasterised each time for the sake of three
          // pixels. (The rebuild was fixed by the notifier; this is the
          // paint.)
          child: RepaintBoundary(child: widget.child),
        ),
        if (style.showScrollProgress)
          _ProgressBand(
            axis: widget.axis,
            style: style,
            snapshot: _snapshot,
          ),
        if (style.showScrollToTop)
          PositionedDirectional(
            // DIRECTIONAL: in Arabic the way back to the top belongs
            // on the left, where the reader's thumb is.
            end: style.fabMargin,
            bottom: style.fabMargin,
            child: _Reveal(
              listenable: _snapshot,
              visible: (s) => s.pastThreshold,
              duration: style.overlayDuration,
              child: widget.scrollToTopBuilder != null
                  ? bounded(widget.scrollToTopBuilder!(context, _scrollToTop))
                  : _ScrollToTopFab(style: style, onPressed: _scrollToTop),
            ),
          ),
        if (hasNewItem)
          PositionedDirectional(
            end: style.fabMargin,
            bottom: style.showScrollToTop
                ? style.fabMargin + style.fabSize + ScrollableDefaults.fabGap
                : style.fabMargin,
            child: _Reveal(
              listenable: _snapshot,
              // Not driven by the scroll — the count is. The reveal
              // still rides the same notifier so both pieces of
              // chrome animate on one clock.
              visible: (_) => widget.newItemPendingCount > 0,
              duration: style.overlayDuration,
              child: widget.newItemFabBuilder != null
                  ? bounded(
                      widget.newItemFabBuilder!(
                        context,
                        widget.newItemPendingCount,
                        widget.onNewItemTap!,
                      ),
                    )
                  : _NewItemFab(
                      count: widget.newItemPendingCount,
                      style: style,
                      onPressed: widget.onNewItemTap!,
                    ),
            ),
          ),
      ],
    );
  }
}

/// Slides and fades one piece of chrome in and out, without touching
/// anything else in the Stack.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.listenable,
    required this.visible,
    required this.duration,
    required this.child,
  });

  final ValueListenable<_ScrollSnapshot> listenable;
  final bool Function(_ScrollSnapshot) visible;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_ScrollSnapshot>(
      valueListenable: listenable,
      // The chrome itself is built ONCE and passed through — only the
      // two animated wrappers rebuild.
      child: child,
      builder: (ctx, snapshot, inner) {
        final show = visible(snapshot);
        return IgnorePointer(
          // A button at zero opacity is still a target, and a screen
          // reader still finds it. Off-screen chrome is neither.
          ignoring: !show,
          child: ExcludeSemantics(
            excluding: !show,
            child: AnimatedSlide(
              duration: duration,
              curve: ScrollableDefaults.scrollToTopCurve,
              offset: show ? Offset.zero : const Offset(0, 1.4),
              child: AnimatedOpacity(
                duration: duration,
                opacity: show ? 1 : 0,
                child: inner,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The reading-progress strip.
///
/// Always a horizontal band across the box, because that is what a
/// progress bar reads as in every language and on every axis. It used
/// to turn into a 3-pixel VERTICAL sliver down the left edge for a
/// horizontal scrollable, which nothing else in the app does.
class _ProgressBand extends StatelessWidget {
  const _ProgressBand({
    required this.axis,
    required this.style,
    required this.snapshot,
  });

  final Axis axis;
  final ResolvedScrollableStyle style;
  final ValueListenable<_ScrollSnapshot> snapshot;

  @override
  Widget build(BuildContext context) {
    final atTop = style.progressPlacement == ScrollProgressPlacement.top;
    return Positioned(
      top: atTop ? 0 : null,
      bottom: atTop ? null : 0,
      left: 0,
      right: 0,
      height: style.progressThickness,
      child: IgnorePointer(
        child: Semantics(
          label: ScrollStrings.progress,
          child: ValueListenableBuilder<_ScrollSnapshot>(
            valueListenable: snapshot,
            builder: (ctx, s, _) => _ProgressStrip(
              progress: s.progress,
              color: style.progressColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: ScrollableDefaults.progressTrackOpacity),
      ),
      child: Align(
        // DIRECTIONAL: progress runs the way the reader does.
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          // FULL height, explicitly — a `DecoratedBox` with no child
          // of its own measures ZERO against a loose constraint, and
          // the fill paints nothing at all.
          heightFactor: 1,
          child: ColoredBox(color: color),
        ),
      ),
    );
  }
}

/// The way back to the top.
///
/// It was a bare `InkWell` in a `Material` with no name — the one
/// control that floats over every long page said nothing to a screen
/// reader and had no tooltip for a pointer either.
class _ScrollToTopFab extends StatelessWidget {
  const _ScrollToTopFab({required this.style, required this.onPressed});
  final ResolvedScrollableStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = ScrollStrings.toTop;
    return Semantics(
      button: true,
      label: label,
      // GlobalTooltip, not Material's — `test/tooltip/global_tooltip_test.dart`
      // fails on a raw one, and a bubble near the screen corner is
      // exactly the case Material clamps without saying by how much.
      child: GlobalTooltip(
        message: label,
        child: Material(
          color: context.primaryColors.primary,
          shape: const CircleBorder(),
          elevation: context.elevation.medium,
          shadowColor: context.overlayColors.scrim,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: style.fabSize,
              height: style.fabSize,
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: context.iconColors.onPrimary,
                size: ScrollableDefaults.fabIconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "N new" — the pill that says content arrived above where you are.
class _NewItemFab extends StatelessWidget {
  const _NewItemFab({
    required this.count,
    required this.style,
    required this.onPressed,
  });
  final int count;
  final ResolvedScrollableStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = ScrollStrings.newItems(count);
    final onPrimary = context.iconColors.onPrimary;
    final spacing = context.spacing;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: context.primaryColors.primary,
        shape: const StadiumBorder(),
        elevation: context.elevation.medium,
        shadowColor: context.overlayColors.scrim,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: context.iconSizes.sm,
                  color: onPrimary,
                ),
                SizedBox(width: spacing.xs),
                // The Semantics above already says it — saying it
                // twice is how a reader hears "3 new, 3 new".
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
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
