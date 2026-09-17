import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/popup_theme.dart';
import 'popup_arrow_backdrop.dart';
import 'popup_enums.dart';
import 'popup_geometry.dart';
import 'popup_surface_style.dart';

/// Configuration bag for a [GlobalPopup] / [GlobalPopupController.show].
///
/// Every themeable field is **nullable**. Effective value resolution at
/// open time:
///
/// 1. Per-instance value (this object's field, if non-null)
/// 2. [GlobalPopupTheme] field of the same name (if registered + non-null)
/// 3. [GlobalPopupOptions.defaults] hard-coded fallback
///
/// Call [merged] to flatten everything into a fully-populated
/// `GlobalPopupOptions` whose fields are all non-null. The controller
/// materializes options that way before storing them, so internal
/// code can treat post-`merged` fields as guaranteed non-null.
@immutable
class GlobalPopupOptions extends DiagnosticableTree {
  const GlobalPopupOptions({
    this.animation,
    this.animationDuration,
    this.flipAnimationDuration,
    this.animationCurve,
    this.closeOnScroll,
    this.closeOnTapOutside,
    this.closeOnRouteChange,
    this.height,
    this.minHeight,
    this.maxHeight,
    this.preferAboveThreshold,
    this.dynamicResizeOnKeyboard,
    this.preserveStateOnFlip,
    this.gap,
    this.screenPadding,
    this.placement,
    this.width,
    this.arrow,
    this.backdrop,
    this.hooks,
    this.surfaceStyle,
    this.hoverOpenDelay,
    this.hoverCloseDelay,
    this.autoDismissAfter,
    this.respectReduceMotion,
    this.animateContentSize,
    this.contentSizeAnimationDuration,
    this.contentSizeAnimationCurve,
    this.openSemanticLabel,
    this.closeSemanticLabel,
    this.closeOthersOnOpen,
  });

  /// Entrance animation type. Themeable.
  final GlobalPopupAnimation? animation;

  /// Open / close duration. Themeable.
  final Duration? animationDuration;

  /// Faster duration used when the overlay flips to the other side after
  /// being clipped by the keyboard. Themeable.
  final Duration? flipAnimationDuration;

  /// Entrance animation curve. Themeable.
  final Curve? animationCurve;

  /// When `true`, scroll on the parent scrollable closes the overlay.
  /// When `false`, the overlay stays open and recomputes its position.
  /// Themeable.
  final bool? closeOnScroll;

  /// Tap anywhere outside the overlay closes it. Themeable.
  final bool? closeOnTapOutside;

  /// Push/pop a route closes the overlay. Themeable.
  final bool? closeOnRouteChange;

  /// Fixed overlay height. When non-null, the overlay is always exactly
  /// this tall on whichever side fits it. If neither side can fit
  /// [height] the overlay closes. Dynamic resize is disabled.
  /// **Not themeable** — opt-in per call site only.
  final double? height;

  /// Minimum height for the overlay to stay on its current side. Dynamic
  /// resize (e.g. keyboard rising) shrinks down to this floor; below it
  /// the overlay flips to the opposite side. Ignored when [height] is
  /// set. Themeable.
  final double? minHeight;

  /// Hard cap on overlay height. Themeable.
  final double? maxHeight;

  /// If space-below < this, the overlay prefers to render above the
  /// anchor. Themeable.
  final double? preferAboveThreshold;

  /// As the keyboard rises into the overlay, dynamically reduce
  /// maxHeight until it hits [minHeight], then flip. Ignored when
  /// [height] is set. Themeable.
  final bool? dynamicResizeOnKeyboard;

  /// Keep [GlobalPopupController.preservedState] populated across a
  /// reverse → swap → forward flip so builders can stash + restore
  /// scroll position, highlighted item, form value, etc. Cleared on
  /// `hide()` when `false`. Themeable.
  final bool? preserveStateOnFlip;

  /// Px between anchor and overlay. Themeable.
  final double? gap;

  /// Min distance from screen edges. Themeable.
  final double? screenPadding;

  /// Where the overlay anchors relative to its anchor. Themeable —
  /// useful for app-wide "always open below" style overrides.
  final GlobalPopupPlacement? placement;

  /// How wide the overlay surface is. Themeable.
  final GlobalPopupWidth? width;

  /// Optional arrow/tail pointing toward the anchor (tooltip-style).
  /// Themeable.
  final GlobalPopupArrow? arrow;

  /// Optional backdrop scrim (color, blur, modal flag). Themeable.
  final GlobalPopupBackdrop? backdrop;

  /// Lifecycle hooks — onOpen / onClose / onWillClose. **Not themeable**
  /// — hooks belong to the call site.
  final GlobalPopupHooks? hooks;

  /// Optional surface defaults — color, elevation, radius, padding.
  /// Themeable via [GlobalPopupTheme.surface].
  final GlobalPopupSurfaceStyle? surfaceStyle;

  /// Hover trigger close delay — overlay stays open this long after the
  /// pointer leaves the anchor (gives time to move into the overlay).
  /// Themeable.
  final Duration? hoverCloseDelay;

  /// How long a pointer must REST on the anchor before a hover trigger
  /// opens. Zero opens immediately.
  ///
  /// It is what stops a popup firing while a pointer crosses a toolbar
  /// on its way somewhere else — the single most useful thing about a
  /// tooltip's timing.
  final Duration? hoverOpenDelay;

  /// Closes itself this long after opening. Null stays until dismissed.
  ///
  /// For a tooltip: read it and it goes away. Not for a menu, where
  /// vanishing mid-decision is worse than staying.
  final Duration? autoDismissAfter;

  /// Honor `MediaQuery.disableAnimationsOf` — when reduce-motion is on,
  /// skip animations (treat as `GlobalPopupAnimation.none`). Themeable.
  final bool? respectReduceMotion;

  /// When `true`, the controller wraps the builder output in an
  /// `AnimatedSize` so the surface smoothly tweens its height (and
  /// width, for intrinsic-width strategies) whenever the rendered
  /// content's intrinsic size changes. Themeable.
  final bool? animateContentSize;

  /// Duration of the content-size tween when [animateContentSize] is
  /// on. Themeable.
  final Duration? contentSizeAnimationDuration;

  /// Curve of the content-size tween when [animateContentSize] is on.
  /// Themeable.
  final Curve? contentSizeAnimationCurve;

  /// String announced to screen-readers via `SemanticsService` when
  /// the popup opens. Localize at the call site using your app's
  /// translation pipeline (the module stays standalone — no ARB
  /// dependency). `null` → "Popup opened". Themeable.
  final String? openSemanticLabel;

  /// String announced to screen-readers when the popup closes.
  /// `null` → "Popup closed". Themeable.
  final String? closeSemanticLabel;

  /// When `true` (default), opening this popup closes any other
  /// open popups (other [GlobalPopupController]s currently in the
  /// internal LIFO stack). Set `false` for intentional stacking
  /// (e.g. confirm dialog popup over a parent menu popup).
  /// Themeable.
  final bool? closeOthersOnOpen;

  /// Hard-coded fallback values applied when neither the per-instance
  /// options nor the active [GlobalPopupTheme] supplied one. Used as
  /// the last layer in [merged]'s resolution stack.
  static const GlobalPopupOptions defaults = GlobalPopupOptions(
    animation: GlobalPopupAnimation.reveal,
    animationDuration: Duration(milliseconds: 200),
    flipAnimationDuration: Duration(milliseconds: 120),
    animationCurve: Curves.easeOutCubic,
    closeOnScroll: true,
    closeOnTapOutside: true,
    closeOnRouteChange: true,
    minHeight: 100,
    maxHeight: 300,
    preferAboveThreshold: 200,
    dynamicResizeOnKeyboard: true,
    preserveStateOnFlip: true,
    gap: 4,
    screenPadding: 8,
    placement: GlobalPopupPlacement.auto,
    width: GlobalPopupWidth.matchAnchor(),
    hoverCloseDelay: Duration(milliseconds: 100),
    hoverOpenDelay: Duration.zero,
    respectReduceMotion: true,
    animateContentSize: false,
    contentSizeAnimationDuration: Duration(milliseconds: 220),
    contentSizeAnimationCurve: Curves.easeOutCubic,
    // `openSemanticLabel` / `closeSemanticLabel` stay null here —
    // localized fallbacks resolve in `ResolvedPopupOptions`.
    closeOthersOnOpen: true,
  );

  /// Stack resolution: per-instance > [theme] > [defaults]. Returns a
  /// new `GlobalPopupOptions` where every themeable field is populated
  /// (non-null) so internal code can treat the result as fully
  /// materialized.
  GlobalPopupOptions merged(GlobalPopupTheme? theme) {
    final t = theme;
    const d = defaults;
    return GlobalPopupOptions(
      animation: animation ?? t?.animation ?? d.animation,
      animationDuration:
          animationDuration ?? t?.animationDuration ?? d.animationDuration,
      flipAnimationDuration:
          flipAnimationDuration ??
          t?.flipAnimationDuration ??
          d.flipAnimationDuration,
      animationCurve: animationCurve ?? t?.animationCurve ?? d.animationCurve,
      closeOnScroll: closeOnScroll ?? t?.closeOnScroll ?? d.closeOnScroll,
      closeOnTapOutside:
          closeOnTapOutside ?? t?.closeOnTapOutside ?? d.closeOnTapOutside,
      closeOnRouteChange:
          closeOnRouteChange ?? t?.closeOnRouteChange ?? d.closeOnRouteChange,
      // `height` is intentionally not themed — pass through as-is.
      height: height,
      minHeight: minHeight ?? t?.minHeight ?? d.minHeight,
      maxHeight: maxHeight ?? t?.maxHeight ?? d.maxHeight,
      preferAboveThreshold:
          preferAboveThreshold ??
          t?.preferAboveThreshold ??
          d.preferAboveThreshold,
      dynamicResizeOnKeyboard:
          dynamicResizeOnKeyboard ??
          t?.dynamicResizeOnKeyboard ??
          d.dynamicResizeOnKeyboard,
      preserveStateOnFlip:
          preserveStateOnFlip ??
          t?.preserveStateOnFlip ??
          d.preserveStateOnFlip,
      gap: gap ?? t?.gap ?? d.gap,
      screenPadding: screenPadding ?? t?.screenPadding ?? d.screenPadding,
      placement: placement ?? t?.placement ?? d.placement,
      width: width ?? t?.width ?? d.width,
      // Compound objects field-merge — theme provides base, caller
      // overlays. Caller's nullable fields stay null and inherit from
      // theme. Returns null when both sides are null (no arrow).
      arrow: t?.arrow == null
          ? arrow
          : (arrow == null ? t!.arrow : t!.arrow!.mergedWith(arrow)),
      backdrop: t?.backdrop == null
          ? backdrop
          : (backdrop == null
                ? t!.backdrop
                : t!.backdrop!.mergedWith(backdrop)),
      // `hooks` is intentionally not themed — pass through as-is.
      hooks: hooks,
      surfaceStyle: t?.surface == null
          ? surfaceStyle
          : (surfaceStyle == null
                ? t!.surface
                : t!.surface!.mergedWith(surfaceStyle)),
      hoverCloseDelay:
          hoverCloseDelay ?? t?.hoverCloseDelay ?? d.hoverCloseDelay,
      hoverOpenDelay: hoverOpenDelay ?? t?.hoverOpenDelay ?? d.hoverOpenDelay,
      autoDismissAfter:
          autoDismissAfter ?? t?.autoDismissAfter ?? d.autoDismissAfter,
      respectReduceMotion:
          respectReduceMotion ??
          t?.respectReduceMotion ??
          d.respectReduceMotion,
      animateContentSize:
          animateContentSize ?? t?.animateContentSize ?? d.animateContentSize,
      contentSizeAnimationDuration:
          contentSizeAnimationDuration ??
          t?.contentSizeAnimationDuration ??
          d.contentSizeAnimationDuration,
      contentSizeAnimationCurve:
          contentSizeAnimationCurve ??
          t?.contentSizeAnimationCurve ??
          d.contentSizeAnimationCurve,
      openSemanticLabel:
          openSemanticLabel ?? t?.openSemanticLabel ?? d.openSemanticLabel,
      closeSemanticLabel:
          closeSemanticLabel ?? t?.closeSemanticLabel ?? d.closeSemanticLabel,
      closeOthersOnOpen:
          closeOthersOnOpen ?? t?.closeOthersOnOpen ?? d.closeOthersOnOpen,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        EnumProperty<GlobalPopupAnimation>(
          'animation',
          animation,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'animationDuration',
          animationDuration,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'flipAnimationDuration',
          flipAnimationDuration,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Curve>(
          'animationCurve',
          animationCurve,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'closeOnScroll',
          value: closeOnScroll,
          ifTrue: 'closeOnScroll',
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'closeOnTapOutside',
          value: closeOnTapOutside,
          ifTrue: 'closeOnTapOutside',
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'closeOnRouteChange',
          value: closeOnRouteChange,
          ifTrue: 'closeOnRouteChange',
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('height', height, defaultValue: null))
      ..add(DoubleProperty('minHeight', minHeight, defaultValue: null))
      ..add(DoubleProperty('maxHeight', maxHeight, defaultValue: null))
      ..add(
        DoubleProperty(
          'preferAboveThreshold',
          preferAboveThreshold,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'dynamicResizeOnKeyboard',
          value: dynamicResizeOnKeyboard,
          ifTrue: 'dynamicResizeOnKeyboard',
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'preserveStateOnFlip',
          value: preserveStateOnFlip,
          ifTrue: 'preserveStateOnFlip',
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('gap', gap, defaultValue: null))
      ..add(DoubleProperty('screenPadding', screenPadding, defaultValue: null))
      ..add(
        EnumProperty<GlobalPopupPlacement>(
          'placement',
          placement,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<GlobalPopupWidth>(
          'width',
          width,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<GlobalPopupArrow>(
          'arrow',
          arrow,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<GlobalPopupBackdrop>(
          'backdrop',
          backdrop,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<GlobalPopupHooks>(
          'hooks',
          hooks,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<GlobalPopupSurfaceStyle>(
          'surfaceStyle',
          surfaceStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'hoverCloseDelay',
          hoverCloseDelay,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'respectReduceMotion',
          value: respectReduceMotion,
          ifTrue: 'respectReduceMotion',
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'animateContentSize',
          value: animateContentSize,
          ifTrue: 'animateContentSize',
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'contentSizeAnimationDuration',
          contentSizeAnimationDuration,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Curve>(
          'contentSizeAnimationCurve',
          contentSizeAnimationCurve,
          defaultValue: null,
        ),
      );
  }

  GlobalPopupOptions copyWith({
    GlobalPopupAnimation? animation,
    Duration? animationDuration,
    Duration? flipAnimationDuration,
    Curve? animationCurve,
    bool? closeOnScroll,
    bool? closeOnTapOutside,
    bool? closeOnRouteChange,
    double? height,
    double? minHeight,
    double? maxHeight,
    double? preferAboveThreshold,
    bool? dynamicResizeOnKeyboard,
    bool? preserveStateOnFlip,
    double? gap,
    double? screenPadding,
    GlobalPopupPlacement? placement,
    GlobalPopupWidth? width,
    GlobalPopupArrow? arrow,
    GlobalPopupBackdrop? backdrop,
    GlobalPopupHooks? hooks,
    GlobalPopupSurfaceStyle? surfaceStyle,
    Duration? hoverCloseDelay,
    bool? respectReduceMotion,
    bool? animateContentSize,
    Duration? contentSizeAnimationDuration,
    Curve? contentSizeAnimationCurve,
    String? openSemanticLabel,
    String? closeSemanticLabel,
    bool? closeOthersOnOpen,
  }) {
    return GlobalPopupOptions(
      animation: animation ?? this.animation,
      animationDuration: animationDuration ?? this.animationDuration,
      flipAnimationDuration:
          flipAnimationDuration ?? this.flipAnimationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      closeOnScroll: closeOnScroll ?? this.closeOnScroll,
      closeOnTapOutside: closeOnTapOutside ?? this.closeOnTapOutside,
      closeOnRouteChange: closeOnRouteChange ?? this.closeOnRouteChange,
      height: height ?? this.height,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      preferAboveThreshold: preferAboveThreshold ?? this.preferAboveThreshold,
      dynamicResizeOnKeyboard:
          dynamicResizeOnKeyboard ?? this.dynamicResizeOnKeyboard,
      preserveStateOnFlip: preserveStateOnFlip ?? this.preserveStateOnFlip,
      gap: gap ?? this.gap,
      screenPadding: screenPadding ?? this.screenPadding,
      placement: placement ?? this.placement,
      width: width ?? this.width,
      arrow: arrow ?? this.arrow,
      backdrop: backdrop ?? this.backdrop,
      hooks: hooks ?? this.hooks,
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      hoverCloseDelay: hoverCloseDelay ?? this.hoverCloseDelay,
      respectReduceMotion: respectReduceMotion ?? this.respectReduceMotion,
      animateContentSize: animateContentSize ?? this.animateContentSize,
      contentSizeAnimationDuration:
          contentSizeAnimationDuration ?? this.contentSizeAnimationDuration,
      contentSizeAnimationCurve:
          contentSizeAnimationCurve ?? this.contentSizeAnimationCurve,
      openSemanticLabel: openSemanticLabel ?? this.openSemanticLabel,
      closeSemanticLabel: closeSemanticLabel ?? this.closeSemanticLabel,
      closeOthersOnOpen: closeOthersOnOpen ?? this.closeOthersOnOpen,
    );
  }
}

/// Resolved overlay layout for the current frame. Passed by the
/// controller to the surface builder so surfaces can size + arrow
/// themselves correctly.
@immutable
class GlobalPopupLayout extends DiagnosticableTree {
  const GlobalPopupLayout({
    required this.isAbove,
    required this.maxHeight,
    required this.width,
    required this.anchorTopLeft,
    required this.anchorSize,
    required this.isFlipping,
    this.fixedHeight,
    this.minWidth,
    this.useIntrinsicWidth = false,
    this.effectivePlacement = GlobalPopupPlacement.auto,
    this.followerOffset = Offset.zero,
    this.liveClampShift,
  });

  /// `true` → overlay renders above the anchor.
  final bool isAbove;

  /// Maximum allowed overlay height for the current frame (may shrink
  /// as keyboard rises). Equals [fixedHeight] when set.
  final double maxHeight;

  /// When non-null, the overlay must render at exactly this height —
  /// caller should set both min and max constraints to this value.
  final double? fixedHeight;

  /// Resolved maximum width for the overlay. Derived from
  /// [GlobalPopupOptions.width] strategy + anchor + screen size.
  final double width;

  /// Resolved minimum width hint. Surfaces use this as a lower bound.
  /// `null` when the strategy has no minimum (e.g. content w/ no `min`).
  final double? minWidth;

  /// When true, surfaces should wrap content in `IntrinsicWidth` so the
  /// overlay sizes to its contents up to [width]. Used by `minAnchor` +
  /// `content` strategies.
  final bool useIntrinsicWidth;

  /// Anchor's top-left in global coords.
  final Offset anchorTopLeft;

  /// Anchor's measured size.
  final Size anchorSize;

  /// `true` for one frame after the overlay flipped sides — child can
  /// play a shorter "settling" animation if it wants.
  final bool isFlipping;

  /// Effective placement (after auto-resolve / flip). Surfaces / arrow
  /// renderers consume this to decide which edge to point at.
  final GlobalPopupPlacement effectivePlacement;

  /// Additional offset applied to the follower's position on top of
  /// the default placement geometry. Currently populated for centered
  /// placements (`top` / `bottom`) when the anchor sits close to a
  /// screen edge — the engine drifts the popup toward the larger
  /// available half so it doesn't bleed past `screenPadding`.
  final Offset followerOffset;

  /// Sideways correction the CURRENT layout pass is applying, published
  /// before the surface is laid out — see `ScreenClampX`.
  ///
  /// [followerOffset] carries the same correction, but only from the
  /// frame AFTER it was measured, because it travels back through the
  /// controller. An arrow reading only that visibly slides into place
  /// once the popup is already on screen. This is the same number, one
  /// frame earlier; add the two, since whatever has already been folded
  /// into `followerOffset` is zero here.
  ///
  /// Deliberately NOT listened to: it is written during layout, and the
  /// only writer publishes it immediately before laying out the subtree
  /// that reads it, so a reader in that subtree always sees the current
  /// value.
  final ValueListenable<double>? liveClampShift;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty(
          'isAbove',
          value: isAbove,
          ifTrue: 'isAbove',
          ifFalse: 'isBelow',
        ),
      )
      ..add(DoubleProperty('maxHeight', maxHeight))
      ..add(DoubleProperty('fixedHeight', fixedHeight, defaultValue: null))
      ..add(DoubleProperty('width', width))
      ..add(DoubleProperty('minWidth', minWidth, defaultValue: null))
      ..add(
        FlagProperty(
          'useIntrinsicWidth',
          value: useIntrinsicWidth,
          ifTrue: 'useIntrinsicWidth',
          defaultValue: false,
        ),
      )
      ..add(DiagnosticsProperty<Offset>('anchorTopLeft', anchorTopLeft))
      ..add(DiagnosticsProperty<Size>('anchorSize', anchorSize))
      ..add(
        FlagProperty(
          'isFlipping',
          value: isFlipping,
          ifTrue: 'isFlipping',
          defaultValue: false,
        ),
      )
      ..add(
        EnumProperty<GlobalPopupPlacement>(
          'effectivePlacement',
          effectivePlacement,
        ),
      );
  }
}
