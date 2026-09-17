import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../models/popup_models.dart';
import 'placement_engine.dart';

/// Owns the reverse → swap → forward animation sequence triggered when
/// the popup needs to flip to the opposite side mid-life (e.g.
/// keyboard rising into the bottom region, content growing past the
/// current side's space).
///
/// Lives outside [GlobalPopupController] so the controller stays
/// focused on lifecycle + listeners. All cross-cutting state is
/// passed in via callbacks so the animator does not hold a reference
/// to the controller.
///
/// **Anti-flicker invariants** (don't break these — they're load-bearing):
///
/// - `inProgress` guards re-entry so continuous scroll-driven recomputes
///   don't cancel an in-flight reverse mid-stride.
/// - The layout swap that drops the popup on the new side happens
///   AFTER reverse completes and BEFORE forward starts.
/// - `await WidgetsBinding.instance.endOfFrame` between layout swap and
///   forward() ensures the rebuild paints the new side before the
///   first tick of forward(), else forward()'s opening frame renders
///   against the OLD layout → visible double-animation.
class FlipAnimator {
  FlipAnimator({
    required this.options,
    required this.controller,
    required this.anchorContext,
    required this.isEntryAttached,
    required this.markNeedsBuild,
    required this.getLayout,
    required this.setLayout,
    required this.recomputeLayout,
  });

  /// Resolved popup options (post-`_materialize`).
  final GlobalPopupOptions Function() options;

  /// `AnimationController` driving the entrance animation. The flip
  /// animator borrows it: mutates `duration` to `flipAnimationDuration`
  /// then restores `animationDuration` on the way out.
  final AnimationController? Function() controller;

  /// Anchor's BuildContext — read once per flip to resolve
  /// `Directionality` for the new effective placement.
  final BuildContext? Function() anchorContext;

  /// True when the OverlayEntry is still inserted. Used as a "did the
  /// popup get closed mid-animation" early-out.
  final bool Function() isEntryAttached;

  /// Triggers an overlay rebuild after the layout swap so the new
  /// side renders before forward() begins ticking.
  final void Function() markNeedsBuild;

  /// Current layout snapshot. Animator clones it with the flipped
  /// `isAbove` + `effectivePlacement` for the brief mid-flip frame
  /// before [recomputeLayout] runs against fresh space measurements.
  final GlobalPopupLayout? Function() getLayout;
  final void Function(GlobalPopupLayout?) setLayout;

  /// Controller's `_recomputeLayout(isFlipping: true)` — re-runs the
  /// engine right after the side swap to refresh maxHeight / width
  /// against the new side's space.
  final void Function({bool isFlipping}) recomputeLayout;

  bool _inProgress = false;
  bool get inProgress => _inProgress;

  /// Run a flip to [toAbove]. Idempotent while already running.
  Future<void> run({required bool toAbove}) async {
    if (_inProgress) return;
    final anim = controller();
    if (anim == null) return;
    _inProgress = true;
    try {
      final opts = options();
      anim.duration = opts.flipAnimationDuration!;
      try {
        await anim.reverse();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[GlobalPopup] flip reverse swallowed: $e\n$st');
        }
        return;
      }
      if (!isEntryAttached()) return;

      // Resolve the flipped placement against the USER'S requested one
      // (e.g. `bottomEnd` flips to `topEnd`, not `topStart`). Reads
      // ambient Directionality so RTL apps swap start/end first.
      final ctx = anchorContext();
      final dir = ctx == null
          ? TextDirection.ltr
          : (Directionality.maybeOf(ctx) ?? TextDirection.ltr);
      final flipped = resolveEffectivePlacement(
        requested: physicalPlacement(opts.placement!, dir),
        isAbove: toAbove,
      );

      // Force the new side immediately so subsequent recomputes don't
      // re-trigger another flip.
      final prev = getLayout();
      if (prev != null) {
        setLayout(
          GlobalPopupLayout(
            isAbove: toAbove,
            maxHeight: prev.maxHeight,
            fixedHeight: prev.fixedHeight,
            width: prev.width,
            minWidth: prev.minWidth,
            useIntrinsicWidth: prev.useIntrinsicWidth,
            anchorTopLeft: prev.anchorTopLeft,
            anchorSize: prev.anchorSize,
            isFlipping: true,
            effectivePlacement: flipped,
            followerOffset: prev.followerOffset,
          ),
        );
      }
      recomputeLayout(isFlipping: true);
      markNeedsBuild();
      // Wait one frame so the new layout paints before forward() runs.
      await WidgetsBinding.instance.endOfFrame;
      if (!isEntryAttached()) return;
      try {
        await anim.forward();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[GlobalPopup] flip forward swallowed: $e\n$st');
        }
        return;
      }
      anim.duration = opts.animationDuration!;
    } finally {
      _inProgress = false;
    }
  }
}
