import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import '../models/popup_models.dart';
import 'global_popup_controller.dart' show GlobalPopupBuilder;
import 'popup_animations.dart';

/// Stateless builder for the overlay subtree. Pulled out of
/// `GlobalPopupController._buildInner` to keep the controller focused
/// on lifecycle + listeners.
///
/// Receives every piece of state via constructor params so the class
/// itself never holds a controller reference — making it
/// independently reviewable, future-testable, and trivially swappable.
class PopupOverlayBuilder {
  PopupOverlayBuilder({
    required this.options,
    required this.layoutGetter,
    required this.linkGetter,
    required this.animControllerGetter,
    required this.builderGetter,
    required this.anchorPointGetter,
    required this.overlayThemeGetter,
    required this.overlayDirectionGetter,
    required this.contentSizeKey,
    required this.measuredContentHeightGetter,
    required this.measuredContentHeightSetter,
    required this.liveClampShift,
    required this.clampShiftReporter,
    required this.lastObservedKeyboardGetter,
    required this.lastObservedKeyboardSetter,
    required this.recomputeScheduledGetter,
    required this.scheduleRecompute,
    required this.scheduleLayoutAfterFrame,
    required this.hide,
    required this.isTopMost,
  });

  final GlobalPopupOptions Function() options;
  final GlobalPopupLayout? Function() layoutGetter;
  final LayerLink? Function() linkGetter;
  final AnimationController? Function() animControllerGetter;
  final GlobalPopupBuilder? Function() builderGetter;
  final Offset? Function() anchorPointGetter;
  final ThemeData? Function() overlayThemeGetter;
  final TextDirection? Function() overlayDirectionGetter;

  final GlobalKey contentSizeKey;
  final double? Function() measuredContentHeightGetter;
  final void Function(double) measuredContentHeightSetter;

  /// Written during layout with the correction this pass is applying,
  /// so the arrow inside the surface can read it in the same pass.
  final ValueNotifier<double> liveClampShift;

  /// Called with the TOTAL sideways correction an intrinsic-width
  /// surface needs, once it has measured itself.
  final void Function(double) clampShiftReporter;

  final double Function() lastObservedKeyboardGetter;
  final void Function(double) lastObservedKeyboardSetter;
  final bool Function() recomputeScheduledGetter;

  final void Function() scheduleRecompute;
  final void Function() scheduleLayoutAfterFrame;
  final Future<void> Function({bool immediate}) hide;
  final bool Function() isTopMost;

  /// The `OverlayEntry.builder` entry point. Wraps actual build in a
  /// `Builder` so MediaQuery is a build-scope dependency.
  Widget build(BuildContext context) {
    return Builder(builder: _buildInner);
  }

  Widget _buildInner(BuildContext context) {
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardChanged = viewInsetsBottom != lastObservedKeyboardGetter();
    if (keyboardChanged) {
      lastObservedKeyboardSetter(viewInsetsBottom);
      scheduleLayoutAfterFrame();
    }

    final layout = layoutGetter();
    final link = linkGetter();
    final builder = builderGetter();
    final ctrl = animControllerGetter();
    if (layout == null || link == null || builder == null || ctrl == null) {
      return const SizedBox.shrink();
    }
    if (layout.width <= 0 || layout.maxHeight <= 0) {
      return const SizedBox.shrink();
    }

    final opts = options();
    final children = <Widget>[
      ..._buildBackdrop(opts, ctrl),
      ..._buildTapOutsideCatcher(opts),
      _buildAnchoredContent(context, opts, layout, link, ctrl, builder),
    ];

    Widget tree = Stack(children: children);
    if (opts.closeOnTapOutside!) {
      tree = _wrapEscapeTrap(tree);
    }
    final theme = overlayThemeGetter();
    if (theme != null) {
      tree = Theme(data: theme, child: tree);
    }
    final dir = overlayDirectionGetter();
    if (dir != null) {
      // Re-apply the anchor's ambient Directionality so RTL flips
      // (placement, arrow alignment, PositionedDirectional) work even
      // when the overlay paints at the Navigator root where the
      // ambient direction is LTR.
      tree = Directionality(textDirection: dir, child: tree);
    }
    return tree;
  }

  Iterable<Widget> _buildBackdrop(
    GlobalPopupOptions opts,
    AnimationController ctrl,
  ) sync* {
    final backdrop = opts.backdrop?.resolved();
    if (backdrop == null) return;
    final isModal = backdrop.modal ?? false;
    final hasFill =
        isModal || backdrop.color != null || backdrop.blurSigma! > 0;
    if (!hasFill) return;
    yield Positioned.fill(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, _) {
          final t = ctrl.value;
          Widget scrim = ColoredBox(
            color: (backdrop.color ?? Colors.transparent).withValues(
              alpha: (backdrop.color?.a ?? 0) * t,
            ),
            child: const SizedBox.expand(),
          );
          if (backdrop.blurSigma! > 0) {
            scrim = ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: backdrop.blurSigma! * t,
                  sigmaY: backdrop.blurSigma! * t,
                ),
                child: scrim,
              ),
            );
          }
          if (isModal) {
            scrim = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: opts.closeOnTapOutside!
                  ? () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      hide();
                    }
                  : null,
              child: scrim,
            );
          }
          return scrim;
        },
      ),
    );
  }

  Iterable<Widget> _buildTapOutsideCatcher(GlobalPopupOptions opts) sync* {
    final isModal = opts.backdrop?.modal ?? false;
    if (!opts.closeOnTapOutside! || isModal) return;
    yield Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Only the TOP-MOST popup dismisses on tap-outside.
          if (!isTopMost()) return;
          FocusManager.instance.primaryFocus?.unfocus();
          hide();
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildAnchoredContent(
    BuildContext context,
    GlobalPopupOptions opts,
    GlobalPopupLayout layout,
    LayerLink link,
    AnimationController ctrl,
    GlobalPopupBuilder builder,
  ) {
    final placement = layout.effectivePlacement;
    final geom = resolvePlacement(placement);
    final baseOverlayOffset = geom.isVertical
        ? Offset(0, geom.isAbove ? -opts.gap! : opts.gap!)
        : Offset(geom.isLeading ? -opts.gap! : opts.gap!, 0);
    final overlayOffset = baseOverlayOffset + layout.followerOffset;

    var rawChild = builder(context, layout);
    if (opts.animateContentSize!) {
      rawChild = NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          final box =
              contentSizeKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null || !box.hasSize) return false;
          final h = box.size.height;
          final measured = measuredContentHeightGetter();
          if (measured != null && (h - measured).abs() < 0.5) return false;
          measuredContentHeightSetter(h);
          if (!recomputeScheduledGetter()) scheduleRecompute();
          return false;
        },
        child: SizeChangedLayoutNotifier(
          key: contentSizeKey,
          child: rawChild,
        ),
      );
      final align = geom.isVertical
          ? (geom.isAbove ? Alignment.bottomCenter : Alignment.topCenter)
          : (geom.isLeading ? Alignment.centerRight : Alignment.centerLeft);
      rawChild = AnimatedSize(
        duration: opts.contentSizeAnimationDuration!,
        curve: opts.contentSizeAnimationCurve!,
        alignment: align,
        clipBehavior: Clip.none,
        child: rawChild,
      );
    }

    // Reactive reduce-motion check — materialize already applied
    // reduce-motion at show-time; toggling mid-popup respects too.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveAnimationType = (opts.respectReduceMotion! && reduceMotion)
        ? GlobalPopupAnimation.none
        : opts.animation!;

    final innerChild = effectiveAnimationType == GlobalPopupAnimation.none
        ? rawChild
        : GlobalPopupEntranceAnimation(
            animation: ctrl,
            isAbove: geom.isAbove,
            isVertical: geom.isVertical,
            isLeading: geom.isLeading,
            curve: opts.animationCurve!,
            type: effectiveAnimationType,
            child: rawChild,
          );

    final anchorPoint = anchorPointGetter();
    if (anchorPoint != null) {
      // atTap path — flow the popup from the tap point, but clamp to
      // the viewport so it doesn't bleed past the edges. Convert
      // global tap to overlay-local first; the Overlay may sit below
      // an AppBar / SafeArea so its origin isn't (0,0) global.
      final overlay = Overlay.of(context, rootOverlay: false);
      final overlayBox = overlay.context.findRenderObject() as RenderBox?;
      final local = overlayBox != null && overlayBox.attached
          ? overlayBox.globalToLocal(anchorPoint)
          : anchorPoint;
      return Positioned.fill(
        child: CustomSingleChildLayout(
          delegate: _AtTapLayoutDelegate(
            anchor: local,
            screenPadding: opts.screenPadding!,
          ),
          child: innerChild,
        ),
      );
    }
    // An intrinsic-width surface centred on its anchor is the one case
    // the engine cannot place on its own: it knows only the width CAP,
    // and drifting by what the cap would need slides a short popup off
    // the anchor. The clamp measures the real width and corrects only
    // if the surface would otherwise cross the screen padding.
    // EVERY vertical intrinsic-width surface, not only the centred
    // ones. A menu anchored near the right edge is aligned by its own
    // right edge to the anchor's — nothing about that keeps it inside
    // the screen, and one opened from a tile in the last column ran
    // off it. The clamp corrects only when the surface would otherwise
    // cross the padding, so it costs the fitting cases nothing.
    final needsMeasuredClamp = geom.isVertical && layout.useIntrinsicWidth;

    return CompositedTransformFollower(
      link: link,
      showWhenUnlinked: false,
      offset: overlayOffset,
      targetAnchor: geom.target,
      followerAnchor: geom.follower,
      child: UnconstrainedBox(
        alignment: geom.follower,
        constrainedAxis: geom.isVertical ? Axis.horizontal : Axis.vertical,
        child: needsMeasuredClamp
            ? ScreenClampX(
                // Where the follower attaches to the anchor, and which
                // point of ITSELF it attaches by. Centred is the case
                // this started as — `Alignment.x` of 0 — and a start
                // or end placement lands its own edge on the anchor's
                // instead.
                targetX:
                    layout.anchorTopLeft.dx +
                    layout.anchorSize.width * ((geom.target.x + 1) / 2),
                followerFactor: (geom.follower.x + 1) / 2,
                appliedDrift: layout.followerOffset.dx,
                screenWidth: MediaQuery.sizeOf(context).width,
                screenPadding: opts.screenPadding!,
                onTotalShift: clampShiftReporter,
                livePublisher: liveClampShift,
                child: innerChild,
              )
            : innerChild,
      ),
    );
  }

  Widget _wrapEscapeTrap(Widget tree) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              if (!isTopMost()) return null;
              hide();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: tree),
      ),
    );
  }
}

/// Positions a child near [anchor] but always within the viewport's
/// `screenPadding` insets. Default flow is down-right from the
/// anchor; flips to up / left when the child would overflow the
/// bottom / right edge.
class _AtTapLayoutDelegate extends SingleChildLayoutDelegate {
  _AtTapLayoutDelegate({
    required this.anchor,
    required this.screenPadding,
  });

  final Offset anchor;
  final double screenPadding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Cap the child at the padded viewport so it can't render larger
    // than the available space (forces the surface's intrinsic-size
    // path to shrink if needed).
    final maxW = (constraints.maxWidth - screenPadding * 2).clamp(
      0.0,
      constraints.maxWidth,
    );
    final maxH = (constraints.maxHeight - screenPadding * 2).clamp(
      0.0,
      constraints.maxHeight,
    );
    return BoxConstraints(maxWidth: maxW, maxHeight: maxH);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final padLeft = screenPadding;
    final padTop = screenPadding;
    final padRight = size.width - screenPadding;
    final padBottom = size.height - screenPadding;

    // Default — popup top-left at tap. Flip to bottom/right if the
    // child would overflow that side.
    var left = anchor.dx;
    if (left + childSize.width > padRight) {
      // Try anchoring popup's top-RIGHT at tap point.
      left = anchor.dx - childSize.width;
    }
    if (left < padLeft) left = padLeft;
    if (left + childSize.width > padRight) {
      left = padRight - childSize.width;
    }

    var top = anchor.dy;
    if (top + childSize.height > padBottom) {
      // Anchor popup's bottom-left at tap point.
      top = anchor.dy - childSize.height;
    }
    if (top < padTop) top = padTop;
    if (top + childSize.height > padBottom) {
      top = padBottom - childSize.height;
    }

    return Offset(left, top);
  }

  @override
  bool shouldRelayout(covariant _AtTapLayoutDelegate old) =>
      old.anchor != anchor || old.screenPadding != screenPadding;
}

// ─────────────────────────────────────────────────────────────────────
// ScreenClampX
// ─────────────────────────────────────────────────────────────────────

/// Keeps a centred, content-sized popup inside the screen padding.
///
/// The placement engine resolves a width BUDGET; a surface that sizes
/// itself to its content renders somewhere at or under it, and only
/// layout knows where. This measures the child, shifts it sideways by
/// the smallest amount that keeps both edges inside the padding, and
/// reports the total correction so the layout can absorb it — the
/// arrow reads `followerOffset`, so a correction the layout never hears
/// about is a tail pointing at nothing.
class ScreenClampX extends SingleChildRenderObjectWidget {
  const ScreenClampX({
    required this.targetX,
    required this.followerFactor,
    required this.appliedDrift,
    required this.screenWidth,
    required this.screenPadding,
    required this.onTotalShift,
    required this.livePublisher,
    required Widget super.child,
    super.key,
  });

  /// The point on the ANCHOR the surface is attached to.
  final double targetX;

  /// Which point of the SURFACE lands there, as a fraction of its own
  /// width: 0 its left edge, 0.5 its centre, 1 its right edge.
  ///
  /// Centred was once the only case this handled, and hard-coding it
  /// is why a start- or end-aligned menu was never clamped at all.
  final double followerFactor;

  /// Correction the layout ALREADY applied, which the follower has
  /// therefore already honoured.
  final double appliedDrift;

  final double screenWidth;
  final double screenPadding;
  final void Function(double) onTotalShift;

  /// Written with this pass's own shift, before the subtree that reads
  /// it is laid out.
  final ValueNotifier<double> livePublisher;

  @override
  RenderScreenClampX createRenderObject(BuildContext context) =>
      RenderScreenClampX(
        targetX: targetX,
        followerFactor: followerFactor,
        appliedDrift: appliedDrift,
        screenWidth: screenWidth,
        screenPadding: screenPadding,
        onTotalShift: onTotalShift,
        livePublisher: livePublisher,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderScreenClampX renderObject,
  ) {
    renderObject
      ..targetX = targetX
      ..followerFactor = followerFactor
      ..appliedDrift = appliedDrift
      ..screenWidth = screenWidth
      ..screenPadding = screenPadding
      ..onTotalShift = onTotalShift
      ..livePublisher = livePublisher;
  }
}

class RenderScreenClampX extends RenderShiftedBox {
  RenderScreenClampX({
    required double targetX,
    required double followerFactor,
    required double appliedDrift,
    required double screenWidth,
    required double screenPadding,
    required this.onTotalShift,
    required this.livePublisher,
  }) : _targetX = targetX,
       _followerFactor = followerFactor,
       _appliedDrift = appliedDrift,
       _screenWidth = screenWidth,
       _screenPadding = screenPadding,
       super(null);

  double _targetX;
  double get targetX => _targetX;
  set targetX(double v) {
    if (v == _targetX) return;
    _targetX = v;
    markNeedsLayout();
  }

  double _followerFactor;
  double get followerFactor => _followerFactor;
  set followerFactor(double v) {
    if (v == _followerFactor) return;
    _followerFactor = v;
    markNeedsLayout();
  }

  double _appliedDrift;
  double get appliedDrift => _appliedDrift;
  set appliedDrift(double v) {
    if (v == _appliedDrift) return;
    _appliedDrift = v;
    markNeedsLayout();
  }

  double _screenWidth;
  double get screenWidth => _screenWidth;
  set screenWidth(double v) {
    if (v == _screenWidth) return;
    _screenWidth = v;
    markNeedsLayout();
  }

  double _screenPadding;
  double get screenPadding => _screenPadding;
  set screenPadding(double v) {
    if (v == _screenPadding) return;
    _screenPadding = v;
    markNeedsLayout();
  }

  void Function(double) onTotalShift;
  ValueNotifier<double> livePublisher;

  double? _reported;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    // Measured DRY first, so the shift can be published before the
    // subtree that reads it is laid out — an arrow inside the surface
    // has to know in THIS pass, or it visibly slides across the bubble
    // one frame after the popup appears.
    final dry = child.getDryLayout(constraints);

    // Where the follower will put the child's left edge, corrections
    // the layout already knows about included.
    final left = _targetX + _appliedDrift - dry.width * _followerFactor;
    final minLeft = _screenPadding;
    final maxLeft = _screenWidth - _screenPadding - dry.width;

    var shift = 0.0;
    if (maxLeft < minLeft) {
      // Wider than the padded screen: nothing to choose between, so
      // pin the leading edge rather than centring the overflow.
      shift = minLeft - left;
    } else if (left < minLeft) {
      shift = minLeft - left;
    } else if (left > maxLeft) {
      shift = maxLeft - left;
    }

    // Publish, then lay out: readers below see this pass's value.
    livePublisher.value = shift;

    child.layout(constraints, parentUsesSize: true);
    size = child.size;
    (child.parentData! as BoxParentData).offset = Offset(shift, 0);

    // Reported as a TOTAL so folding it into the layout is a fixed
    // point: next pass the child is already where it belongs, the
    // shift computes to zero, and the total comes back unchanged.
    final total = _appliedDrift + shift;
    if (_reported != null && (_reported! - total).abs() < 0.5) return;
    _reported = total;
    final report = onTotalShift;
    SchedulerBinding.instance.addPostFrameCallback((_) => report(total));
  }
}
