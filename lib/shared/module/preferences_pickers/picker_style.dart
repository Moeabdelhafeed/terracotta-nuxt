import 'package:flutter/material.dart';

/// The floor for the preference pickers.
abstract final class PickerDefaults {
  /// Corner of the collapsed summary tile the `sheet` and `dialog`
  /// variants show.
  static const summaryRadius = 12.0;

  /// Gap between the pills of a `pillRow`.
  static const pillSpacing = 8.0;

  /// Gap between the rows of a `list`.
  static const rowSpacing = 0.0;

  /// The header's glyph, and the plate behind it.
  static const headerIconSize = 16.0;
  static const headerIconContainerSize = 28.0;

  /// The leading glyph on a list row.
  static const rowIconSize = 18.0;

  /// A row's inner padding, and the tighter one `dense` asks for.
  static const rowPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );
  static const densePadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 8,
  );

  /// Whether a list row is separated from the next by a rule.
  ///
  /// OFF. A radio row already ends where the next one begins — the
  /// mark, the indent and the pressed tint all say so — and a rule
  /// between every pair of a three-option list is more furniture than
  /// content. `showDividers: true` is there for a long list where the
  /// eye needs the help.
  static const showDividers = false;

  static const respectReducedMotion = true;
}

/// How the preference pickers LOOK.
///
/// Deliberately thin, and it will stay thin. Every option a picker
/// draws is now one of the app's own controls — a `GlobalChip`, a
/// `GlobalRadio`, a `GlobalContainer.tile`, a `GlobalDropdown` — and
/// each of those already carries its own themeable bag. What is left
/// here is only what belongs to the picker itself: the spacing
/// between options, the header's glyph plate, the summary tile's
/// corner.
///
/// The alternative was a bag that re-stated a chip's fill, a radio's
/// dot colour and a tile's corner, which is a second place for all
/// three to be wrong. A picker should not own a look.
@immutable
class PickerStyle {
  const PickerStyle({
    this.summaryRadius,
    this.pillSpacing,
    this.rowSpacing,
    this.headerIconSize,
    this.headerIconContainerSize,
    this.rowIconSize,
    this.rowPadding,
    this.densePadding,
    this.showDividers,
    this.respectReducedMotion,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = PickerStyle(
    summaryRadius: PickerDefaults.summaryRadius,
    pillSpacing: PickerDefaults.pillSpacing,
    rowSpacing: PickerDefaults.rowSpacing,
    headerIconSize: PickerDefaults.headerIconSize,
    headerIconContainerSize: PickerDefaults.headerIconContainerSize,
    rowIconSize: PickerDefaults.rowIconSize,
    rowPadding: PickerDefaults.rowPadding,
    densePadding: PickerDefaults.densePadding,
    showDividers: PickerDefaults.showDividers,
    respectReducedMotion: PickerDefaults.respectReducedMotion,
  );

  /// Rows that breathe. Nothing between them but space.
  static const airy = PickerStyle(
    rowSpacing: 8,
    rowPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
  );

  /// Ruled rows, for a long list where the eye needs the help.
  static const ruled = PickerStyle(showDividers: true);

  final double? summaryRadius;
  final double? pillSpacing;
  final double? rowSpacing;
  final double? headerIconSize;
  final double? headerIconContainerSize;
  final double? rowIconSize;
  final EdgeInsetsGeometry? rowPadding;
  final EdgeInsetsGeometry? densePadding;
  final bool? showDividers;

  /// Whether `MediaQuery.disableAnimationsOf` flattens the pickers'
  /// own motion.
  ///
  /// There is very little of it left — the controls each honour the
  /// setting themselves — so this covers the picker's own
  /// transitions, not theirs.
  final bool? respectReducedMotion;

  /// Field-by-field: whatever `other` answers wins, and what it
  /// leaves null keeps this bag's answer.
  PickerStyle mergedWith(PickerStyle? other) {
    if (other == null) return this;
    return PickerStyle(
      summaryRadius: other.summaryRadius ?? summaryRadius,
      pillSpacing: other.pillSpacing ?? pillSpacing,
      rowSpacing: other.rowSpacing ?? rowSpacing,
      headerIconSize: other.headerIconSize ?? headerIconSize,
      headerIconContainerSize:
          other.headerIconContainerSize ?? headerIconContainerSize,
      rowIconSize: other.rowIconSize ?? rowIconSize,
      rowPadding: other.rowPadding ?? rowPadding,
      densePadding: other.densePadding ?? densePadding,
      showDividers: other.showDividers ?? showDividers,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  PickerStyle copyWith({
    double? summaryRadius,
    double? pillSpacing,
    double? rowSpacing,
    double? headerIconSize,
    double? headerIconContainerSize,
    double? rowIconSize,
    EdgeInsetsGeometry? rowPadding,
    EdgeInsetsGeometry? densePadding,
    bool? showDividers,
    bool? respectReducedMotion,
  }) => PickerStyle(
    summaryRadius: summaryRadius ?? this.summaryRadius,
    pillSpacing: pillSpacing ?? this.pillSpacing,
    rowSpacing: rowSpacing ?? this.rowSpacing,
    headerIconSize: headerIconSize ?? this.headerIconSize,
    headerIconContainerSize:
        headerIconContainerSize ?? this.headerIconContainerSize,
    rowIconSize: rowIconSize ?? this.rowIconSize,
    rowPadding: rowPadding ?? this.rowPadding,
    densePadding: densePadding ?? this.densePadding,
    showDividers: showDividers ?? this.showDividers,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is PickerStyle &&
      other.summaryRadius == summaryRadius &&
      other.pillSpacing == pillSpacing &&
      other.rowSpacing == rowSpacing &&
      other.headerIconSize == headerIconSize &&
      other.headerIconContainerSize == headerIconContainerSize &&
      other.rowIconSize == rowIconSize &&
      other.rowPadding == rowPadding &&
      other.densePadding == densePadding &&
      other.showDividers == showDividers &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hash(
    summaryRadius,
    pillSpacing,
    rowSpacing,
    headerIconSize,
    headerIconContainerSize,
    rowIconSize,
    rowPadding,
    densePadding,
    showDividers,
    respectReducedMotion,
  );
}

/// A [PickerStyle] with every question answered.
@immutable
class ResolvedPickerStyle {
  const ResolvedPickerStyle({
    required this.summaryRadius,
    required this.pillSpacing,
    required this.rowSpacing,
    required this.headerIconSize,
    required this.headerIconContainerSize,
    required this.rowIconSize,
    required this.rowPadding,
    required this.densePadding,
    required this.showDividers,
    required this.still,
  });

  final double summaryRadius;
  final double pillSpacing;
  final double rowSpacing;
  final double headerIconSize;
  final double headerIconContainerSize;
  final double rowIconSize;
  final EdgeInsetsGeometry rowPadding;
  final EdgeInsetsGeometry densePadding;
  final bool showDividers;

  /// Whether the reader has asked for motion to stop.
  final bool still;

  EdgeInsetsGeometry paddingFor({required bool dense}) =>
      dense ? densePadding : rowPadding;
}
