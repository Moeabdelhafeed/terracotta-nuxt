import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/popup_models.dart';

/// Inputs to [computePopupPlacement] — everything the engine needs
/// to decide layout for the current frame. Bundled into a value
/// object so the engine entry point stays a pure function.
@immutable
class PlacementInputs {
  const PlacementInputs({
    required this.anchorTopLeft,
    required this.anchorSize,
    required this.screenSize,
    required this.safeTop,
    required this.safeBottom,
    required this.keyboardHeight,
    required this.textDirection,
    required this.options,
    required this.currentLayout,
    required this.measuredContentHeight,
    required this.measuredClampShiftX,
    required this.liveClampShift,
    required this.isFlipRecompute,
    required this.flipInProgress,
    required this.anchorVisible,
    required this.clippedByScrollable,
  });

  final Offset anchorTopLeft;
  final Size anchorSize;
  final Size screenSize;
  final double safeTop;
  final double safeBottom;
  final double keyboardHeight;
  final TextDirection textDirection;
  final GlobalPopupOptions options;
  final GlobalPopupLayout? currentLayout;
  final double? measuredContentHeight;

  /// Sideways correction an intrinsic-width surface reported after it
  /// measured itself — see `_ScreenClampX`. Null until it has.
  final double? measuredClampShiftX;

  /// Channel the clamp publishes into during layout, handed to the
  /// layout it produces.
  final ValueListenable<double>? liveClampShift;

  final bool isFlipRecompute;
  final bool flipInProgress;
  final bool anchorVisible;
  final bool clippedByScrollable;
}

/// Discriminated outcome returned by [computePopupPlacement].
/// Controller dispatches on the sealed subtype.
sealed class PlacementOutcome {
  const PlacementOutcome();
}

class PlacementOk extends PlacementOutcome {
  const PlacementOk(this.layout);
  final GlobalPopupLayout layout;
}

class PlacementRequestFlip extends PlacementOutcome {
  const PlacementRequestFlip({required this.toAbove});
  final bool toAbove;
}

class PlacementAutoClose extends PlacementOutcome {
  const PlacementAutoClose();
}

class PlacementHardClose extends PlacementOutcome {
  const PlacementHardClose();
}

/// Pure layout computation — no side effects, no controller access.
///
/// Returns one of:
/// - [PlacementOk] — layout for this frame
/// - [PlacementRequestFlip] — caller should trigger a side-flip animation
/// - [PlacementAutoClose] — anchor no longer visible / scrollable-clipped
/// - [PlacementHardClose] — fixed-height popup with no space on either side
PlacementOutcome computePopupPlacement(PlacementInputs i) {
  final opts = i.options;
  final availableBottom = i.screenSize.height - i.keyboardHeight - i.safeBottom;
  final keyboardActive = i.keyboardHeight > 0;
  final suppressAutoClose = opts.dynamicResizeOnKeyboard! && keyboardActive;
  if ((!i.anchorVisible || i.clippedByScrollable) && !suppressAutoClose) {
    return const PlacementAutoClose();
  }

  final spaceAbove = i.anchorTopLeft.dy - i.safeTop - opts.screenPadding!;
  final spaceBelow =
      availableBottom -
      i.anchorTopLeft.dy -
      i.anchorSize.height -
      opts.screenPadding!;

  final fixedHeight = opts.height;
  final currentIsAbove = i.currentLayout?.isAbove;

  bool isAbove;
  double maxHeight;

  if (fixedHeight != null) {
    final fitsBelow = spaceBelow >= fixedHeight;
    final fitsAbove = spaceAbove >= fixedHeight;
    if (fitsBelow) {
      isAbove = false;
    } else if (fitsAbove) {
      isAbove = true;
    } else {
      return const PlacementHardClose();
    }
    maxHeight = fixedHeight;
  } else {
    // Dynamic side selection — `physicalPlacement` flips semantic
    // start/end for RTL so the engine reasons in physical terms.
    final requestedPhysical = physicalPlacement(
      opts.placement!,
      i.textDirection,
    );
    final isExplicit =
        requestedPhysical != GlobalPopupPlacement.auto &&
        requestedPhysical != GlobalPopupPlacement.atTap;
    final explicitGeom = isExplicit
        ? resolvePlacement(requestedPhysical)
        : null;

    if (isExplicit && explicitGeom!.isVertical) {
      final wantsAbove = explicitGeom.isAbove;
      final wantedSpace = wantsAbove ? spaceAbove : spaceBelow;
      final oppositeSpace = wantsAbove ? spaceBelow : spaceAbove;
      if (wantedSpace >= opts.minHeight!) {
        isAbove = wantsAbove;
        maxHeight = wantedSpace.clamp(opts.minHeight!, opts.maxHeight!);
      } else if (oppositeSpace >= opts.minHeight!) {
        isAbove = !wantsAbove;
        maxHeight = oppositeSpace.clamp(opts.minHeight!, opts.maxHeight!);
      } else {
        isAbove = spaceAbove > spaceBelow;
        maxHeight = (isAbove ? spaceAbove : spaceBelow).clamp(
          opts.minHeight!,
          opts.maxHeight!,
        );
      }
    } else if (isExplicit) {
      // Horizontal placement.
      isAbove = false;
      maxHeight = (availableBottom - i.safeTop - opts.screenPadding! * 2).clamp(
        opts.minHeight!,
        opts.maxHeight!,
      );
    } else {
      // `auto`.
      final preferAbove = spaceBelow < opts.preferAboveThreshold!;
      if (preferAbove && spaceAbove >= opts.minHeight!) {
        isAbove = true;
        maxHeight = spaceAbove.clamp(opts.minHeight!, opts.maxHeight!);
      } else if (spaceBelow >= opts.minHeight!) {
        isAbove = false;
        maxHeight = spaceBelow.clamp(opts.minHeight!, opts.maxHeight!);
      } else if (spaceAbove >= opts.minHeight!) {
        isAbove = true;
        maxHeight = spaceAbove.clamp(opts.minHeight!, opts.maxHeight!);
      } else {
        isAbove = spaceAbove > spaceBelow;
        maxHeight = (isAbove ? spaceAbove : spaceBelow).clamp(
          opts.minHeight!,
          opts.maxHeight!,
        );
      }
    }

    // Dynamic content-size resize — request flip when growing content
    // outpaces current side's space and the opposite has more.
    if (opts.animateContentSize! &&
        i.measuredContentHeight != null &&
        currentIsAbove != null &&
        !i.flipInProgress) {
      final desired = i.measuredContentHeight!;
      final currentSpace = isAbove ? spaceAbove : spaceBelow;
      final oppositeSpace = isAbove ? spaceBelow : spaceAbove;
      if (currentSpace < desired && oppositeSpace > currentSpace + 32) {
        return PlacementRequestFlip(toAbove: !isAbove);
      }
    }

    // Keyboard-driven shrink + flip.
    if (opts.dynamicResizeOnKeyboard! && !isAbove && i.keyboardHeight > 0) {
      final dynamicBelow = spaceBelow.clamp(0.0, opts.maxHeight!);
      if (dynamicBelow < opts.minHeight! &&
          spaceAbove >= opts.minHeight! &&
          currentIsAbove == false &&
          !i.flipInProgress) {
        return const PlacementRequestFlip(toAbove: true);
      }
      maxHeight = dynamicBelow > maxHeight ? maxHeight : dynamicBelow;
      if (maxHeight < opts.minHeight!) maxHeight = opts.minHeight!;
    }
  }

  // Bidirectional side-change → request flip (skip when this run IS
  // the flip's internal recompute).
  if (currentIsAbove != null &&
      currentIsAbove != isAbove &&
      !i.isFlipRecompute &&
      !i.flipInProgress) {
    return PlacementRequestFlip(toAbove: isAbove);
  }

  final effective = resolveEffectivePlacement(
    requested: physicalPlacement(opts.placement!, i.textDirection),
    isAbove: isAbove,
  );

  final widthResult = _resolveWidthStrategy(
    opts: opts,
    measuredClampShiftX: i.measuredClampShiftX,
    effective: effective,
    anchorTopLeft: i.anchorTopLeft,
    anchorSize: i.anchorSize,
    screenSize: i.screenSize,
  );

  return PlacementOk(
    GlobalPopupLayout(
      isAbove: isAbove,
      maxHeight: maxHeight,
      fixedHeight: fixedHeight,
      width: widthResult.maxWidth,
      minWidth: widthResult.minWidth,
      useIntrinsicWidth: widthResult.useIntrinsic,
      anchorTopLeft: i.anchorTopLeft,
      anchorSize: i.anchorSize,
      isFlipping: i.isFlipRecompute,
      effectivePlacement: effective,
      followerOffset: Offset(widthResult.followerDriftX, 0),
      liveClampShift: i.liveClampShift,
    ),
  );
}

/// Maps a requested placement + the engine-chosen `isAbove` side to
/// the placement actually used. For `auto` the placement tracks
/// `isAbove`; for explicit vertical placements it flips to the
/// opposite when the engine fell back. Horizontal placements pass
/// through unchanged. Public so the flip animator can call it too.
GlobalPopupPlacement resolveEffectivePlacement({
  required GlobalPopupPlacement requested,
  required bool isAbove,
}) {
  if (requested == GlobalPopupPlacement.auto ||
      requested == GlobalPopupPlacement.atTap) {
    return isAbove
        ? GlobalPopupPlacement.topStart
        : GlobalPopupPlacement.bottomStart;
  }
  final geom = resolvePlacement(requested);
  if (!geom.isVertical) return requested;
  if (geom.isAbove == isAbove) return requested;
  switch (requested) {
    case GlobalPopupPlacement.bottomStart:
      return GlobalPopupPlacement.topStart;
    case GlobalPopupPlacement.bottom:
      return GlobalPopupPlacement.top;
    case GlobalPopupPlacement.bottomEnd:
      return GlobalPopupPlacement.topEnd;
    case GlobalPopupPlacement.topStart:
      return GlobalPopupPlacement.bottomStart;
    case GlobalPopupPlacement.top:
      return GlobalPopupPlacement.bottom;
    case GlobalPopupPlacement.topEnd:
      return GlobalPopupPlacement.bottomEnd;
    default:
      return requested;
  }
}

class _WidthResult {
  const _WidthResult(
    this.maxWidth,
    this.minWidth,
    this.useIntrinsic,
    this.followerDriftX,
  );
  final double maxWidth;
  final double? minWidth;
  final bool useIntrinsic;

  /// How far to shift the popup horizontally past its default
  /// anchored center so it stays within `screenPadding` of the
  /// viewport edges. Only non-zero for centered vertical placements
  /// (`top` / `bottom`).
  final double followerDriftX;
}

_WidthResult _resolveWidthStrategy({
  required GlobalPopupOptions opts,
  required double? measuredClampShiftX,
  required GlobalPopupPlacement effective,
  required Offset anchorTopLeft,
  required Size anchorSize,
  required Size screenSize,
}) {
  final screenPadding = opts.screenPadding!;
  final screenMax = screenSize.width - screenPadding * 2;
  final geomForBudget = resolvePlacement(effective);
  final double availableHoriz;
  // `isCenteredVertical` lets the centered placements claim the full
  // padded screen width and drift toward the larger half via the
  // returned `followerDriftX` — see post-resolution drift calc below.
  var isCenteredVertical = false;
  if (geomForBudget.isVertical) {
    final anchorLeft = anchorTopLeft.dx;
    final anchorRight = anchorLeft + anchorSize.width;
    final spaceFromAnchorLeft = screenSize.width - anchorLeft - screenPadding;
    final spaceFromAnchorRight = anchorRight - screenPadding;
    switch (effective) {
      case GlobalPopupPlacement.bottomEnd:
      case GlobalPopupPlacement.topEnd:
        availableHoriz = spaceFromAnchorRight.clamp(0.0, screenMax);
      case GlobalPopupPlacement.bottom:
      case GlobalPopupPlacement.top:
        // Full padded width is fair game; popup will drift sideways
        // toward whichever half has more room so the edges land
        // within `screenPadding` of the viewport.
        isCenteredVertical = true;
        availableHoriz = screenMax;
      default:
        availableHoriz = spaceFromAnchorLeft.clamp(0.0, screenMax);
    }
  } else {
    final anchorLeft = anchorTopLeft.dx;
    final anchorRight = anchorLeft + anchorSize.width;
    final spaceRightOfAnchor =
        screenSize.width - anchorRight - screenPadding - opts.gap!;
    final spaceLeftOfAnchor = anchorLeft - screenPadding - opts.gap!;
    availableHoriz = geomForBudget.isLeading
        ? spaceLeftOfAnchor.clamp(0.0, screenMax)
        : spaceRightOfAnchor.clamp(0.0, screenMax);
  }
  final budget = availableHoriz <= 0 ? screenMax : availableHoriz;

  final widthStrategy = opts.width!;
  double resolvedMaxWidth;
  double? resolvedMinWidth;
  var useIntrinsic = false;
  // Screen-aligned strategies position by SCREEN edges, not the anchor —
  // resolved after the switch via followerDriftX.
  double? screenAlignInset;
  switch (widthStrategy) {
    case WidthMatchAnchor():
      final w = anchorSize.width.clamp(0.0, budget);
      resolvedMaxWidth = w;
      resolvedMinWidth = w;
    case WidthMinAnchor(:final max):
      // Capped by the SCREEN, not by the space beside the anchor.
      //
      // The anchor-side budget is a placement concern: a menu opened
      // from a tile at the right edge had thirty points to its right,
      // so it resolved thirty points wide and every row overflowed by
      // exactly the width of its icon. These two strategies size to
      // their CONTENT and are clamped into the viewport by layout
      // afterwards, so the padded screen width is the honest cap.
      final minW = anchorSize.width.clamp(0.0, screenMax);
      resolvedMinWidth = minW;
      resolvedMaxWidth = (max ?? screenMax).clamp(minW, screenMax);
      useIntrinsic = true;
    case WidthFixed(:final width):
      final w = width.clamp(0.0, budget).toDouble();
      resolvedMaxWidth = w;
      resolvedMinWidth = w;
    case WidthFraction(:final fraction):
      final w = (screenSize.width * fraction).clamp(0.0, budget);
      resolvedMaxWidth = w;
      resolvedMinWidth = w;
    case WidthContent(:final min, :final max):
      // See `WidthMinAnchor` above — the cap is the padded SCREEN.
      resolvedMinWidth = (min ?? 0).clamp(0.0, screenMax).toDouble();
      resolvedMaxWidth = (max ?? screenMax).clamp(resolvedMinWidth, screenMax);
      useIntrinsic = true;
    case WidthScreenInset(:final inset):
      // Deliberately ignores the anchor-based budget: the drift below
      // shifts the surface so it spans the screen minus the inset on each
      // edge, regardless of where the (possibly narrow) anchor sits.
      final w = (screenSize.width - 2 * inset).clamp(0.0, screenSize.width);
      resolvedMaxWidth = w;
      resolvedMinWidth = w;
      screenAlignInset = inset;
  }

  // Compute follower drift for centered vertical placements so the
  // resolved popup width doesn't bleed past the screen padding even
  // when the anchor sits far from viewport center.
  var followerDriftX = 0.0;
  if (screenAlignInset != null) {
    // Screen-inset width: shift the surface so its left edge lands at
    // x = inset, whatever the anchor position/alignment. Left edge under
    // the current geometry first:
    final anchorLeft = anchorTopLeft.dx;
    final double leftEdge;
    switch (effective) {
      case GlobalPopupPlacement.bottomEnd:
      case GlobalPopupPlacement.topEnd:
        leftEdge = anchorLeft + anchorSize.width - resolvedMaxWidth;
      case GlobalPopupPlacement.bottom:
      case GlobalPopupPlacement.top:
        leftEdge = anchorLeft + anchorSize.width / 2 - resolvedMaxWidth / 2;
      default:
        leftEdge = anchorLeft;
    }
    followerDriftX = screenAlignInset - leftEdge;
  } else if (isCenteredVertical && useIntrinsic) {
    // An intrinsic-width surface is at MOST `resolvedMaxWidth` and
    // usually far narrower, so drifting by what the maximum would need
    // slides a short tooltip sideways off the anchor it points at —
    // by a constant amount, whatever it actually renders.
    //
    // The follower centres the surface on the anchor using its REAL
    // size, so the only correction needed is the one that keeps it
    // inside the screen padding, and only the layout knows the width
    // that takes. `_ScreenClampX` measures it, applies the shift, and
    // reports it back here so `followerOffset` — which is what the
    // arrow walks back along — still tells the whole story.
    followerDriftX = measuredClampShiftX ?? 0;
  } else if (isCenteredVertical) {
    final anchorCenterX = anchorTopLeft.dx + anchorSize.width / 2;
    final halfW = resolvedMaxWidth / 2;
    final leftEdge = anchorCenterX - halfW;
    final rightEdge = anchorCenterX + halfW;
    final padLeft = screenPadding;
    final padRight = screenSize.width - screenPadding;
    if (leftEdge < padLeft) {
      followerDriftX = padLeft - leftEdge;
    } else if (rightEdge > padRight) {
      followerDriftX = padRight - rightEdge;
    }
  }

  return _WidthResult(
    resolvedMaxWidth,
    resolvedMinWidth,
    useIntrinsic,
    followerDriftX,
  );
}
