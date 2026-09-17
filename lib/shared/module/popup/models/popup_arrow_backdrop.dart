import 'dart:async';

import 'package:flutter/foundation.dart'; // ignore: unnecessary_import
import 'package:flutter/material.dart';

/// Where the arrow sits along the popup's edge (perpendicular to the
/// anchor side). `start` / `center` / `end` map to the leading edge,
/// center, and trailing edge respectively.
enum GlobalPopupArrowAlignment { start, center, end }

/// Optional arrow / tail pointing toward the anchor (tooltip-style).
@immutable
class GlobalPopupArrow extends DiagnosticableTree {
  /// All fields are nullable so theme + per-call instances can be
  /// merged field-by-field via [mergedWith]. Resolved against
  /// [defaults] at paint time.
  const GlobalPopupArrow({
    this.size,
    this.color,
    this.offset,
    this.alignment,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.elevation,
    this.shadowColor,
    this.castShadow,
    this.shadowSpread,
    this.bow,
    this.baseFillet,
  });

  /// Triangle leg length (height for vertical placements, width for
  /// horizontal). Width of the base is `size * 1.6`.
  final double? size;

  /// Fill color. `null` → matches the surface.
  final Color? color;

  /// Distance from the placement edge corner to the arrow centerline.
  /// Larger value → arrow further from the corner. Only consulted when
  /// [alignment] is `start` or `end`.
  final double? offset;

  /// Position along the surface edge: `start`, `center`, or `end`. For
  /// vertical placements (above/below the anchor) this is the
  /// horizontal alignment; for horizontal placements (start/end of
  /// anchor) it is the vertical alignment.
  final GlobalPopupArrowAlignment? alignment;

  /// Radius applied to the tip + base corners of the triangle. `0` =
  /// sharp triangle (default). Useful values: `1`–`3` for a slightly
  /// rounded look that matches material surfaces.
  final double? borderRadius;

  /// Optional stroke color along the two slanted edges of the arrow.
  final Color? borderColor;

  /// Stroke width when [borderColor] is set.
  final double? borderWidth;

  /// Drop-shadow elevation matching the surface's elevation. When
  /// `null`, the surface's elevation is used (so the arrow visually
  /// continues the surface's shadow). Set to `0` to disable.
  final double? elevation;

  /// Shadow color. `null` → black @ default Material opacity (matches
  /// the surface's shadow).
  final Color? shadowColor;

  /// Whether the arrow should cast its own drop-shadow. Default `true`
  /// — the arrow takes the surface's elevation (unless [elevation] is
  /// overridden) and renders the same shadow against the anchor so the
  /// tail looks continuous with the body. The painter clips the shadow
  /// to the half-plane facing away from the surface body so it can't
  /// bleed back into the popup's interior. Set `false` when you want
  /// a flat, shadowless tail (e.g. low-elevation tooltips).
  final bool? castShadow;

  /// Multiplier applied to the effective elevation before the shadow is
  /// rasterized. The arrow's elevation comes from [elevation] (or the
  /// surface's elevation when null), but Flutter's `Canvas.drawShadow`
  /// produces a fairly subtle halo on the small triangle compared to
  /// the much larger surface body — boost above 1.0 to make the tail's
  /// drop-shadow read as continuous with the popup body's. Default
  /// `1.6` gives a stronger but still natural halo; set to `1.0` to
  /// match the surface elevation exactly.
  final double? shadowSpread;

  /// How far the two slanted edges bow OUTWARD from the straight
  /// triangle baseline, in logical pixels. `0` (default) → flat,
  /// straight edges. Positive values bend each edge into a convex
  /// quadratic curve so the tail looks like a soft tongue bulging out
  /// of the popup body. Reasonable values: `2`–`5` for size `8`–`12`
  /// arrows; scale up with [size].
  final double? bow;

  /// Radius of the convex fillet drawn at each base corner — where the
  /// arrow's slanted edge meets the popup's surface edge. `0` (default)
  /// → sharp meeting, the arrow ends with a hard corner against the
  /// body. Positive values draw a circular arc that is tangent to
  /// BOTH the slanted edge and the surface edge, so the tail visually
  /// merges into the popup body with a smooth blend instead of an
  /// acute corner. The arrow's canvas is expanded outward by the
  /// fillet's inset distance so the extended geometry is not clipped.
  /// Reasonable values: `2`–`6`. Pair with [borderRadius] to also
  /// round the tip.
  final double? baseFillet;

  /// Hard-coded fallback values applied when neither the per-instance
  /// arrow nor the active [GlobalPopupTheme.arrow] supplied a value
  /// for a given field. Used as the last layer in [mergedWith]'s
  /// resolution stack + read by surfaces / painter when consuming a
  /// merged instance.
  static const GlobalPopupArrow defaults = GlobalPopupArrow(
    size: 8,
    offset: 16,
    alignment: GlobalPopupArrowAlignment.center,
    borderRadius: 0,
    borderWidth: 0,
    castShadow: true,
    shadowSpread: 1.6,
    bow: 0,
    baseFillet: 0,
  );

  /// Stack resolution: this > [other] > [defaults] for every field.
  /// Use when you want to overlay caller's nullable fields on top of a
  /// theme arrow without losing the theme's other choices. Callers
  /// generally want `themeArrow.mergedWith(callerArrow)` so caller
  /// wins where set.
  GlobalPopupArrow mergedWith(GlobalPopupArrow? other) {
    if (other == null) return this;
    return GlobalPopupArrow(
      size: other.size ?? size,
      color: other.color ?? color,
      offset: other.offset ?? offset,
      alignment: other.alignment ?? alignment,
      borderRadius: other.borderRadius ?? borderRadius,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      elevation: other.elevation ?? elevation,
      shadowColor: other.shadowColor ?? shadowColor,
      castShadow: other.castShadow ?? castShadow,
      shadowSpread: other.shadowSpread ?? shadowSpread,
      bow: other.bow ?? bow,
      baseFillet: other.baseFillet ?? baseFillet,
    );
  }

  /// Materialize against [defaults] so every field is non-null. Use
  /// at paint time after merging with theme.
  GlobalPopupArrow resolved() => defaults.mergedWith(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('size', size))
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(DoubleProperty('offset', offset))
      ..add(EnumProperty<GlobalPopupArrowAlignment>('alignment', alignment))
      ..add(DoubleProperty('borderRadius', borderRadius))
      ..add(ColorProperty('borderColor', borderColor, defaultValue: null))
      ..add(DoubleProperty('borderWidth', borderWidth))
      ..add(DoubleProperty('elevation', elevation, defaultValue: null))
      ..add(ColorProperty('shadowColor', shadowColor, defaultValue: null))
      ..add(
        FlagProperty(
          'castShadow',
          value: castShadow,
          ifTrue: 'castShadow',
          ifFalse: 'flat',
        ),
      )
      ..add(DoubleProperty('shadowSpread', shadowSpread))
      ..add(DoubleProperty('bow', bow))
      ..add(DoubleProperty('baseFillet', baseFillet));
  }
}

/// Optional backdrop scrim behind the overlay.
///
/// All fields nullable so theme + per-call instances merge field-by-
/// field via [mergedWith]. Resolved against [defaults] at the build
/// site.
@immutable
class GlobalPopupBackdrop extends DiagnosticableTree {
  const GlobalPopupBackdrop({
    this.color,
    this.blurSigma,
    this.modal,
  });

  /// Backdrop fill behind the overlay. Null = transparent.
  final Color? color;

  /// Optional BackdropFilter blur (modal-style).
  final double? blurSigma;

  /// Modal: scrim consumes all pointer events (no pass-through).
  /// Non-modal (default): scrim only catches taps for dismiss; drags +
  /// other events still reach descendants (so scrolling parent works).
  final bool? modal;

  /// Hard-coded fallback values applied when neither the per-instance
  /// backdrop nor the active [GlobalPopupTheme.backdrop] supplied a
  /// value for a given field.
  static const GlobalPopupBackdrop defaults = GlobalPopupBackdrop(
    blurSigma: 0,
    modal: false,
  );

  /// Stack resolution: [other] > this. Pass per-call backdrop as
  /// `other` and theme/defaults as `this`.
  GlobalPopupBackdrop mergedWith(GlobalPopupBackdrop? other) {
    if (other == null) return this;
    return GlobalPopupBackdrop(
      color: other.color ?? color,
      blurSigma: other.blurSigma ?? blurSigma,
      modal: other.modal ?? modal,
    );
  }

  /// Materialize against [defaults] so non-null-themed fields
  /// (`blurSigma`, `modal`) are guaranteed non-null.
  GlobalPopupBackdrop resolved() => defaults.mergedWith(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(DoubleProperty('blurSigma', blurSigma, defaultValue: null))
      ..add(
        FlagProperty(
          'modal',
          value: modal,
          ifTrue: 'modal',
          ifFalse: 'pass-through',
        ),
      );
  }
}

/// Lifecycle hooks for a [GlobalPopup].
@immutable
class GlobalPopupHooks {
  const GlobalPopupHooks({
    this.onOpen,
    this.onClose,
    this.onWillClose,
  });

  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// Return `false` to cancel a close (e.g. unsaved changes). Returns a
  /// `FutureOr<bool>` so callers can await a confirm dialog.
  final FutureOr<bool> Function()? onWillClose;
}
