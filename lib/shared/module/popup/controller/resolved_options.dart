import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../models/popup_models.dart';

/// Post-`_materialize` snapshot of [GlobalPopupOptions] where every
/// themable field is non-null. Constructed once at `show()` from a
/// merged options instance + asserted invariant; used internally by
/// the controller / flip animator / overlay builder so they can
/// reference fields without `!`.
///
/// This is a compile-time enforcement of the runtime invariant that
/// the materialize assert already enforces at debug-time: every
/// nullable field on [GlobalPopupOptions] is populated before the
/// controller starts reading it.
///
/// Genuinely-nullable fields (`height`, `arrow`, `backdrop`, `hooks`,
/// `surfaceStyle`) stay nullable — those are caller opt-ins, not
/// themable defaults.
@immutable
class ResolvedPopupOptions {
  /// Build from a fully-merged [GlobalPopupOptions]. Asserts that
  /// every themable field is populated. Producing a snapshot from
  /// non-materialized options is a programming error.
  ResolvedPopupOptions(GlobalPopupOptions merged)
    : animation = merged.animation!,
      animationDuration = merged.animationDuration!,
      flipAnimationDuration = merged.flipAnimationDuration!,
      animationCurve = merged.animationCurve!,
      closeOnScroll = merged.closeOnScroll!,
      closeOnTapOutside = merged.closeOnTapOutside!,
      closeOnRouteChange = merged.closeOnRouteChange!,
      height = merged.height,
      minHeight = merged.minHeight!,
      maxHeight = merged.maxHeight!,
      preferAboveThreshold = merged.preferAboveThreshold!,
      dynamicResizeOnKeyboard = merged.dynamicResizeOnKeyboard!,
      preserveStateOnFlip = merged.preserveStateOnFlip!,
      gap = merged.gap!,
      screenPadding = merged.screenPadding!,
      placement = merged.placement!,
      width = merged.width!,
      arrow = merged.arrow,
      backdrop = merged.backdrop,
      hooks = merged.hooks,
      surfaceStyle = merged.surfaceStyle,
      hoverCloseDelay = merged.hoverCloseDelay!,
      respectReduceMotion = merged.respectReduceMotion!,
      animateContentSize = merged.animateContentSize!,
      contentSizeAnimationDuration = merged.contentSizeAnimationDuration!,
      contentSizeAnimationCurve = merged.contentSizeAnimationCurve!,
      openSemanticLabel =
          merged.openSemanticLabel ?? PopupStrings.openedSemantic,
      closeSemanticLabel =
          merged.closeSemanticLabel ?? PopupStrings.closedSemantic,
      closeOthersOnOpen = merged.closeOthersOnOpen!,
      // Re-expose original `GlobalPopupOptions` so callers that need
      // to pass the merged input to engine / animator / surface (which
      // accept `GlobalPopupOptions`) can do so without copying back.
      raw = merged;

  final GlobalPopupAnimation animation;
  final Duration animationDuration;
  final Duration flipAnimationDuration;
  final Curve animationCurve;
  final bool closeOnScroll;
  final bool closeOnTapOutside;
  final bool closeOnRouteChange;

  /// Genuinely opt-in (no default). Stays nullable.
  final double? height;

  final double minHeight;
  final double maxHeight;
  final double preferAboveThreshold;
  final bool dynamicResizeOnKeyboard;
  final bool preserveStateOnFlip;
  final double gap;
  final double screenPadding;
  final GlobalPopupPlacement placement;
  final GlobalPopupWidth width;

  /// Compound objects stay nullable — surfaces handle `null`
  /// downstream by skipping that visual layer.
  final GlobalPopupArrow? arrow;
  final GlobalPopupBackdrop? backdrop;
  final GlobalPopupHooks? hooks;
  final GlobalPopupSurfaceStyle? surfaceStyle;

  final Duration hoverCloseDelay;
  final bool respectReduceMotion;
  final bool animateContentSize;
  final Duration contentSizeAnimationDuration;
  final Curve contentSizeAnimationCurve;
  final String openSemanticLabel;
  final String closeSemanticLabel;
  final bool closeOthersOnOpen;

  /// Original merged input. Used when handing options to APIs that
  /// take `GlobalPopupOptions` (placement engine, flip animator,
  /// overlay builder all currently accept the raw type so the
  /// migration is incremental).
  final GlobalPopupOptions raw;
}
