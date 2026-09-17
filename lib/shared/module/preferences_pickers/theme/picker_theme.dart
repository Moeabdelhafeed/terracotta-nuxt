import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../picker_style.dart';

/// App-wide defaults for the preference pickers.
///
/// A thin hook on purpose: the controls a picker draws each carry
/// their own bag, so a house rebrands the chip, the radio, the tile
/// and the dropdown once and every picker follows. This one covers
/// what is left — the picker's own spacing and its header plate.
@immutable
class GlobalPickerTheme extends ThemeExtension<GlobalPickerTheme> {
  const GlobalPickerTheme({this.style});

  final PickerStyle? style;

  static GlobalPickerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalPickerTheme>();

  @override
  GlobalPickerTheme copyWith({PickerStyle? style}) =>
      GlobalPickerTheme(style: style ?? this.style);

  @override
  GlobalPickerTheme lerp(ThemeExtension<GlobalPickerTheme>? other, double t) {
    if (other is! GlobalPickerTheme) return this;
    return GlobalPickerTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Measurements interpolate; `showDividers` snaps, because half a
  /// rule is not a rule.
  static PickerStyle? _lerpStyle(PickerStyle? a, PickerStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return PickerStyle(
      summaryRadius: lerpDouble(a?.summaryRadius, b?.summaryRadius, t),
      pillSpacing: lerpDouble(a?.pillSpacing, b?.pillSpacing, t),
      rowSpacing: lerpDouble(a?.rowSpacing, b?.rowSpacing, t),
      headerIconSize: lerpDouble(a?.headerIconSize, b?.headerIconSize, t),
      headerIconContainerSize: lerpDouble(
        a?.headerIconContainerSize,
        b?.headerIconContainerSize,
        t,
      ),
      rowIconSize: lerpDouble(a?.rowIconSize, b?.rowIconSize, t),
      rowPadding: EdgeInsetsGeometry.lerp(a?.rowPadding, b?.rowPadding, t),
      densePadding: EdgeInsetsGeometry.lerp(
        a?.densePadding,
        b?.densePadding,
        t,
      ),
      showDividers: pick?.showDividers,
      respectReducedMotion: pick?.respectReducedMotion,
    );
  }
}

extension PickerStyleResolve on PickerStyle {
  /// Stacks `caller > GlobalPickerTheme.style > PickerStyle.defaults`.
  ResolvedPickerStyle resolve(BuildContext context) {
    final merged = PickerStyle.defaults
        .mergedWith(GlobalPickerTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = PickerStyle.defaults;

    final respect = merged.respectReducedMotion ?? floor.respectReducedMotion!;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedPickerStyle(
      summaryRadius: merged.summaryRadius ?? floor.summaryRadius!,
      pillSpacing: merged.pillSpacing ?? floor.pillSpacing!,
      rowSpacing: merged.rowSpacing ?? floor.rowSpacing!,
      headerIconSize: merged.headerIconSize ?? floor.headerIconSize!,
      headerIconContainerSize:
          merged.headerIconContainerSize ?? floor.headerIconContainerSize!,
      rowIconSize: merged.rowIconSize ?? floor.rowIconSize!,
      rowPadding: merged.rowPadding ?? floor.rowPadding!,
      densePadding: merged.densePadding ?? floor.densePadding!,
      showDividers: merged.showDividers ?? floor.showDividers!,
      still: still,
    );
  }
}
