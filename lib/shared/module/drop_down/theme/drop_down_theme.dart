import 'package:flutter/material.dart';

import '../models/drop_down_style.dart';

/// App-wide [DropdownStyle] via `ThemeData.extensions` — the analogue of
/// `GlobalTextFieldTheme`. Per-instance `dropdownStyle:` always wins;
/// see `DropdownStyle.resolve` for the merge order.
///
/// ```dart
/// ThemeData(extensions: [
///   GlobalDropdownTheme(
///     style: DropdownStyle(accentBarWidth: 0),
///   ),
/// ]);
/// ```
class GlobalDropdownTheme extends ThemeExtension<GlobalDropdownTheme> {
  const GlobalDropdownTheme({this.style});

  final DropdownStyle? style;

  static GlobalDropdownTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalDropdownTheme>();

  @override
  GlobalDropdownTheme copyWith({DropdownStyle? style}) =>
      GlobalDropdownTheme(style: style ?? this.style);

  @override
  GlobalDropdownTheme lerp(
    ThemeExtension<GlobalDropdownTheme>? other,
    double t,
  ) {
    if (other is! GlobalDropdownTheme) return this;
    return GlobalDropdownTheme(style: _lerpStyle(style, other.style, t));
  }

  static DropdownStyle? _lerpStyle(
    DropdownStyle? a,
    DropdownStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return DropdownStyle(
      accentColor: Color.lerp(a.accentColor, b.accentColor, t),
      selectedTint: Color.lerp(a.selectedTint, b.selectedTint, t),
      flashTint: Color.lerp(a.flashTint, b.flashTint, t),
      accentBarWidth: _lerpDouble(a.accentBarWidth, b.accentBarWidth, t),
      itemPadding: EdgeInsetsGeometry.lerp(a.itemPadding, b.itemPadding, t),
      itemTextStyle: TextStyle.lerp(a.itemTextStyle, b.itemTextStyle, t),
      selectedItemTextStyle: TextStyle.lerp(
        a.selectedItemTextStyle,
        b.selectedItemTextStyle,
        t,
      ),
      groupHeaderTextStyle: TextStyle.lerp(
        a.groupHeaderTextStyle,
        b.groupHeaderTextStyle,
        t,
      ),
      checkboxSize: _lerpDouble(a.checkboxSize, b.checkboxSize, t),
      enableHaptic: t < 0.5 ? a.enableHaptic : b.enableHaptic,
      edgeFade: t < 0.5 ? a.edgeFade : b.edgeFade,
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
