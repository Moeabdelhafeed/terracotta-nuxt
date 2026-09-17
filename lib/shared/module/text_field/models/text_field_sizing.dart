import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// TextFieldSizing — box geometry
// ---------------------------------------------------------------------------

/// Controls the field's box geometry — height, width, and the Material
/// density flags that actually let those constraints take effect.
///
/// ## Why this exists
///
/// A bare `SizedBox` can NOT shrink (or reliably set) a Material text field:
/// `InputDecorator` enforces its own minimum height (~48–56 px) and ignores
/// the parent's tighter constraint. The lever is [isDense] / [isCollapsed],
/// which strip that baked-in minimum so the supplied height / padding govern.
///
/// This config therefore pairs the constraints (height / min / max / width)
/// with the density flags and an auto-default: any height constraint flips
/// [isDense] on unless you set it (or [isCollapsed]) explicitly.
///
/// ## Width-to-content
///
/// [fitWidthToContent] sizes the field to the text being typed (the hint
/// when empty), clamped to [minWidth] / [maxWidth], so a field can hug its
/// content instead of greedily filling its parent.
@immutable
class TextFieldSizing {
  const TextFieldSizing({
    this.height,
    this.minHeight,
    this.maxHeight,
    this.width,
    this.minWidth,
    this.maxWidth,
    this.isDense,
    this.isCollapsed,
    this.fitWidthToContent = false,
  });

  /// Exact box height. Wins over [minHeight] / [maxHeight].
  final double? height;
  final double? minHeight;
  final double? maxHeight;

  /// Exact box width. Wins over [minWidth] / [maxWidth] and
  /// [fitWidthToContent].
  final double? width;
  final double? minWidth;
  final double? maxWidth;

  /// `InputDecoration.isDense` — reduces the decorator's baked min height so
  /// smaller / exact heights take effect. Defaults to `true` whenever any
  /// height constraint is set (see [resolvedIsDense]); pass `false` to force
  /// the roomy default.
  final bool? isDense;

  /// `InputDecoration.isCollapsed` — removes the min height AND default
  /// padding entirely, for the tightest custom heights. Overrides [isDense]
  /// in Material when `true`.
  final bool? isCollapsed;

  /// Size the field to its text/hint instead of filling the parent, clamped
  /// to [minWidth] / [maxWidth]. Ignored when [width] is set.
  final bool fitWidthToContent;

  /// Any explicit vertical constraint present.
  bool get hasHeightConstraint =>
      height != null || minHeight != null || maxHeight != null;

  /// Any explicit horizontal constraint present.
  bool get hasWidthConstraint =>
      width != null ||
      minWidth != null ||
      maxWidth != null ||
      fitWidthToContent;

  /// Effective dense flag: explicit value, else auto-on when a height
  /// constraint exists (so it actually takes hold), else null (framework
  /// default). Forced off when [isCollapsed] is true (collapsed supersedes).
  ///
  /// The widget reads this directly (`sizing.resolvedIsDense`) and bridges
  /// only the legacy `style.height` — which this model can't see — with a
  /// trailing `?? (rs.height != null ? true : null)`.
  bool? get resolvedIsDense {
    if (isCollapsed ?? false) return null;
    if (isDense != null) return isDense;
    return hasHeightConstraint ? true : null;
  }

  TextFieldSizing copyWith({
    double? height,
    double? minHeight,
    double? maxHeight,
    double? width,
    double? minWidth,
    double? maxWidth,
    bool? isDense,
    bool? isCollapsed,
    bool? fitWidthToContent,
  }) {
    return TextFieldSizing(
      height: height ?? this.height,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      width: width ?? this.width,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      isDense: isDense ?? this.isDense,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      fitWidthToContent: fitWidthToContent ?? this.fitWidthToContent,
    );
  }
}
