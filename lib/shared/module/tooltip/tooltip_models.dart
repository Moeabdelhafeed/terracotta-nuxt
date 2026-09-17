import 'package:flutter/material.dart';

import '../popup/models/popup_enums.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and timings that only change when this module changes.
/// Anything an app would rebrand lives on [TooltipStyle] instead.
abstract final class TooltipDefaults {
  static const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);

  /// Closest the tooltip comes to a screen edge. The popup engine
  /// slides it inward to keep this, and reports how far it slid so the
  /// arrow can walk back.
  static const screenMargin = 8.0;

  /// Distance from the child's EDGE to the tooltip's BODY. A bubble
  /// asks for more, because its arrow stands in the same gap — the
  /// tail's TIP ends up where a rectangle's edge would be.
  ///
  /// Material measured its own `verticalOffset` from the anchor's
  /// CENTRE, so its 24 was about 4 clear of a 40dp icon button. Carried
  /// over to an EDGE-measured gap unchanged, it read as a tooltip
  /// floating half a control away from the thing it points at.
  static const verticalOffset = 8.0;
  static const bubbleVerticalOffset = 16.0;

  /// Half the arrow's width, and its height.
  static const arrowSize = 8.0;

  /// How long it stays, and how long a hover has to rest before it
  /// appears. The wait is what stops a tooltip firing while a pointer
  /// crosses a toolbar on its way somewhere else.
  static const showDuration = Duration(milliseconds: 2500);
  static const waitDuration = Duration(milliseconds: 400);

  static const shadowBlur = 10.0;
  static const shadowOffset = Offset(0, 4);
  static const shadowOpacity = 0.15;

  /// Border a DARK tooltip draws so it separates from a dark page.
  static const darkBorderOpacity = 0.3;

  static const letterSpacing = 0.3;

  /// Widest a tooltip gets before its text wraps.
  ///
  /// It sizes to its CONTENT up to this — a tooltip that took its
  /// anchor's width instead wrapped one character per line on an icon
  /// button, which is what happens when a 40dp anchor decides the
  /// surface.
  static const maxWidth = 240.0;
}

// ---------------------------------------------------------------------------
// TooltipShape
// ---------------------------------------------------------------------------

/// Shape of the tooltip container.
enum TooltipShape {
  /// A plain rounded rectangle.
  rectangle,

  /// A rounded rectangle with an arrow pointing at the child.
  bubble;

  bool get isBubble => this == TooltipShape.bubble;
}

// ---------------------------------------------------------------------------
// TooltipTrigger
// ---------------------------------------------------------------------------

/// What opens the tooltip.
enum TooltipTrigger {
  /// Hover on a pointer device, long-press on a touch one. The default,
  /// and what Material's own tooltip does.
  hoverOrLongPress,

  /// Hover only — the long-press gesture stays free for the host.
  ///
  /// For an anchor that already long-presses to do something else: the
  /// media picker's tiles open a menu that way, and a tooltip stealing
  /// the gesture would take the menu with it.
  hoverOnly,

  /// TAP the anchor to toggle it.
  ///
  /// For an anchor whose label is the POINT of it rather than a hint
  /// about it — a colour swatch whose name exists nowhere else on the
  /// screen. Hover is not available on a phone and a long press is a
  /// gesture nobody guesses; a tap is the one that gets discovered.
  tap,

  /// Nothing opens it. The anchor keeps the tooltip's SEMANTICS, so a
  /// screen reader still reads the label — which is the whole value for
  /// an icon-only control.
  none;

  bool get opensOnHover =>
      this == TooltipTrigger.hoverOrLongPress ||
      this == TooltipTrigger.hoverOnly;
  bool get opensOnLongPress => this == TooltipTrigger.hoverOrLongPress;

  /// The popup trigger this maps to. Null when nothing opens it.
  GlobalPopupTrigger? get popupTrigger => switch (this) {
    TooltipTrigger.hoverOrLongPress => GlobalPopupTrigger.hoverOrLongPress,
    TooltipTrigger.hoverOnly => GlobalPopupTrigger.hover,
    TooltipTrigger.tap => GlobalPopupTrigger.tap,
    TooltipTrigger.none => null,
  };
}

// ---------------------------------------------------------------------------
// TooltipStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalTooltip` — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalTooltipTheme.style > TooltipStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedTooltipStyle] and `GlobalTooltipTheme.lerp`.
@immutable
class TooltipStyle {
  const TooltipStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.borderColor,
    this.borderRadius,
    this.decoration,
    this.textStyle,
    this.padding,
    this.screenMargin,
    this.verticalOffset,
    this.shadow,
    this.showDuration,
    this.waitDuration,
    this.arrowSize,
    this.maxWidth,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from `context.<group>Colors` at build time so a tooltip tracks
  /// role, brightness and saturation.
  ///
  /// `verticalOffset` is absent too — it depends on the SHAPE, which the
  /// bag does not know. `resolve` takes it.
  static const TooltipStyle defaults = TooltipStyle(
    padding: TooltipDefaults.padding,
    screenMargin: TooltipDefaults.screenMargin,
    showDuration: TooltipDefaults.showDuration,
    waitDuration: TooltipDefaults.waitDuration,
    arrowSize: TooltipDefaults.arrowSize,
    maxWidth: TooltipDefaults.maxWidth,
  );

  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Overrides [backgroundColor].
  final Gradient? gradient;

  /// Outline. Only a dark tooltip draws one by default — a light one on
  /// a light page already has its shadow.
  final Color? borderColor;

  final BorderRadius? borderRadius;

  /// Replaces the built decoration wholesale. The shape, gradient,
  /// border and shadow are all ignored when this is set.
  final Decoration? decoration;

  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  /// Inset from the screen edge, which Material clamps the bubble
  /// inside.
  /// Closest the tooltip comes to a screen edge.
  final double? screenMargin;

  /// Distance from the child. Null takes the shape's own.
  final double? verticalOffset;

  final BoxShadow? shadow;

  final Duration? showDuration;
  final Duration? waitDuration;

  /// Half the arrow's width, and its height.
  final double? arrowSize;

  /// Widest the surface gets before the text wraps.
  final double? maxWidth;

  /// Field-by-field override — anything set on [other] wins.
  TooltipStyle mergedWith(TooltipStyle? other) {
    if (other == null) return this;
    return TooltipStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      gradient: other.gradient ?? gradient,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      decoration: other.decoration ?? decoration,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      screenMargin: other.screenMargin ?? screenMargin,
      verticalOffset: other.verticalOffset ?? verticalOffset,
      shadow: other.shadow ?? shadow,
      showDuration: other.showDuration ?? showDuration,
      waitDuration: other.waitDuration ?? waitDuration,
      arrowSize: other.arrowSize ?? arrowSize,
      maxWidth: other.maxWidth ?? maxWidth,
    );
  }

  TooltipStyle copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    Gradient? gradient,
    Color? borderColor,
    BorderRadius? borderRadius,
    Decoration? decoration,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? screenMargin,
    double? verticalOffset,
    BoxShadow? shadow,
    Duration? showDuration,
    Duration? waitDuration,
    double? arrowSize,
    double? maxWidth,
  }) => TooltipStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    gradient: gradient ?? this.gradient,
    borderColor: borderColor ?? this.borderColor,
    borderRadius: borderRadius ?? this.borderRadius,
    decoration: decoration ?? this.decoration,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    screenMargin: screenMargin ?? this.screenMargin,
    verticalOffset: verticalOffset ?? this.verticalOffset,
    shadow: shadow ?? this.shadow,
    showDuration: showDuration ?? this.showDuration,
    waitDuration: waitDuration ?? this.waitDuration,
    arrowSize: arrowSize ?? this.arrowSize,
    maxWidth: maxWidth ?? this.maxWidth,
  );
}

// ---------------------------------------------------------------------------
// ResolvedTooltipStyle
// ---------------------------------------------------------------------------

/// [TooltipStyle] after `caller > theme > defaults > palette`, for ONE
/// shape. Every themed field is non-null, so build code reads
/// `rs.backgroundColor` with no `?? Colors.white` behind it.
@immutable
class ResolvedTooltipStyle {
  const ResolvedTooltipStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderRadius,
    required this.textStyle,
    required this.padding,
    required this.screenMargin,
    required this.verticalOffset,
    required this.shadow,
    required this.showDuration,
    required this.waitDuration,
    required this.arrowSize,
    required this.maxWidth,
    this.gradient,
    this.borderColor,
    this.decoration,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final BorderRadius borderRadius;

  /// Set only when the caller replaced the decoration wholesale.
  final Decoration? decoration;

  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final double screenMargin;
  final double verticalOffset;
  final BoxShadow shadow;
  final Duration showDuration;
  final Duration waitDuration;
  final double arrowSize;

  /// Widest the surface gets before the text wraps.
  final double maxWidth;

  /// Gap the popup leaves between the child and this tooltip, for
  /// [shape].
  ///
  /// [verticalOffset] is the distance to the BODY. A bubble's arrow
  /// stands in that gap — the popup reserves the tail's own height
  /// outside the surface — so the gap it asks for is that much smaller
  /// and the tip lands where a rectangle's edge would.
  double gapFor(TooltipShape shape) {
    if (!shape.isBubble) return verticalOffset;
    final gap = verticalOffset - arrowSize;
    return gap < 0 ? 0 : gap;
  }
}
