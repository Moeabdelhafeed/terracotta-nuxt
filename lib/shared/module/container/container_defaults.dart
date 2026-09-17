import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

/// Border line style for the container.
enum ContainerBorderLineStyle { solid, dashed, dotted, wave, zigzag }

/// Animated border effect type.
enum AnimatedBorderType {
  /// Border gradient rotates continuously.
  rotate,

  /// Border pulses between two colors.
  pulse,

  /// Shimmer effect moves along the border.
  shimmer,
}

/// Badge position on the container.
enum ContainerBadgePosition { topRight, topLeft, bottomRight, bottomLeft }

/// Ribbon position on the container.
enum ContainerRibbonPosition { topRight, topLeft }

/// How a [GlobalSelectableContainer] SHOWS that it is selected.
///
/// It could only do one thing before — a border, a five per cent wash
/// and a corner tick — which is quiet on a busy page and invisible on a
/// card that already has a border of its own.
enum ContainerSelectionEffect {
  /// The border and the wash, and nothing else. What it always did.
  outline,

  /// A stronger fill instead of a heavier line. Reads at a glance in a
  /// grid, where a two-point border does not.
  fill,

  /// The card LIFTS: a small scale and a shadow. The one effect that
  /// survives a card with its own border and its own background.
  lift,

  /// Outline plus lift, for a single choice out of a few.
  outlineLift,
}

/// Where a selectable container puts its tick.
enum ContainerSelectionMark {
  /// A disc in the top corner. What it always did.
  corner,

  /// No mark at all — for a grid where the fill or the lift says it.
  none,
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [ContainerStyle] instead.
///
/// These were thirty-six private `_k` consts at the top of the widget
/// file, which no caller and no test could name.
abstract final class ContainerDefaults {
  static const radius = 16.0;
  static const padding = 16.0;
  static const borderWidth = 2.0;

  /// The drop shadow, when the caller gave none. The colour comes from
  /// the palette's scrim at build time — it was `Colors.black`, which is
  /// not a colour this app owns.
  static const shadowOpacity = 0.08;
  static const shadowBlur = 10.0;
  static const shadowOffset = Offset(0, 4);

  /// How much of the surface shows through a glass container.
  static const blurBackgroundOpacity = 0.7;

  /// The scrim over a background IMAGE, so text on top of it stays
  /// readable. Only painted once the image is more than half opaque —
  /// below that the image is already a wash.
  static const imageScrimOpacity = 0.4;
  static const imageScrimThreshold = 0.5;

  // Dashes and waves.
  static const borderDashWidth = 6.0;
  static const borderDashGap = 4.0;

  /// How deep a scallop goes, and how long one is.
  ///
  /// A decorative wavy frame reads at about a quarter of its wavelength
  /// deep. At three points against a twenty-point wave it was an eighth
  /// — a fine ripple rather than a scallop, which is what made it look
  /// like a saw edge next to the reference art.
  static const borderWaveAmplitude = 5.0;
  static const borderWaveFrequency = 12.0;

  // Badge.
  static const badgeSize = 22.0;
  static const badgeFontSize = 11.0;
  static const badgeIconSize = 14.0;
  static const badgeOffset = -6.0;
  static const badgeTextHPad = 6.0;
  static const badgeTextVPad = 2.0;

  // Ribbon.
  static const ribbonWidth = 80.0;
  static const ribbonHeight = 20.0;
  static const ribbonOffset = 16.0;

  /// How far down each edge a corner ribbon's ends land, as a fraction
  /// of the box's SHORT side. The band's chord is that times root two.
  static const ribbonReachFactor = 0.55;
  static const ribbonMinReach = 34.0;
  static const ribbonMaxReach = 96.0;

  /// The band's thickness, as a fraction of its chord.
  static const ribbonHeightFactor = 0.28;
  static const ribbonMinHeight = 14.0;
  static const ribbonFontSize = 10.0;

  /// 45°, in radians. A corner ribbon crosses the corner.
  static const ribbonAngle = 0.7854;

  // Selection.
  static const checkmarkSize = 24.0;

  /// How far a selected card lifts, as a scale factor.
  static const selectedScale = 1.02;

  /// The fill behind a selected card, over its own surface.
  static const selectedWash = 0.05;
  static const selectedWashStrong = 0.12;

  /// The shadow a raised selection casts.
  static const selectedElevationBlur = 16.0;
  static const selectedElevationOpacity = 0.18;
  static const checkmarkIconSize = 16.0;
  static const checkmarkOffset = 8.0;
  static const selectedBorderWidth = 2.0;

  // Dismiss.
  static const dismissThreshold = 0.3;
  static const dismissVelocity = 800.0;
  static const actionPad = 24.0;

  // Tile.
  /// A row a finger can hit. A tile with a one-line title is otherwise
  /// as tall as its text, which is about twenty points.
  static const tileMinHeight = 48.0;
  static const tileDenseMinHeight = 40.0;

  /// What a leading or trailing slot is boxed to, so an oversized icon
  /// cannot set the row's height. `ListTile` does the same.
  static const tileSlotSize = 40.0;
  static const tileDenseSlotSize = 32.0;

  /// How far a container sinks under a finger.
  static const pressScale = 0.98;

  /// The ring a keyboard-focused container wears.
  static const focusRingWidth = 2.0;
  static const focusWashOpacity = 0.10;

  // Slots.
  static const headerGap = 12.0;
  static const footerGap = 12.0;
  static const dragHandleSize = 20.0;
  static const dragHandleOpacity = 0.3;
  static const expandChevronSize = 20.0;

  // Loading placeholder.
  static const shimmerTitleWidth = 140.0;
  static const shimmerTitleHeight = 16.0;
  static const shimmerBodyHeight = 60.0;
  static const shimmerGap = 12.0;

  /// What the full three-line placeholder comes to. Below this the
  /// loading state degrades to ONE bar filling the box — a caller that
  /// says `height: 120` gets a placeholder, not a striped overflow.
  static const shimmerFullHeight =
      shimmerTitleHeight +
      shimmerGap +
      shimmerBodyHeight +
      shimmerGap +
      shimmerTitleHeight * 0.8;

  // Motion.
  static const animatedBorderDuration = Duration(seconds: 3);
  static const pulseDuration = AppDurations.shimmer;
  static const selectionDuration = AppDurations.quick;
  static const dismissDuration = AppDurations.normal;
  static const expandDuration = AppDurations.normal;
}

// ---------------------------------------------------------------------------
// ContainerStyle
// ---------------------------------------------------------------------------
