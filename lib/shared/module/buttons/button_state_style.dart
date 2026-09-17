// Flutter imports:
import 'package:flutter/material.dart';

/// Size preset ladder shared by the button family.
///
/// Sets the box height + horizontal padding on the text-labelled
/// buttons and the square side on [GlobalIconButton]. Explicit
/// `style.height` / `style.padding` / `style.width` always win.
enum ButtonSize {
  small,
  medium,
  large;

  /// Box height for text-labelled buttons.
  double get height => switch (this) {
    ButtonSize.small => 36,
    ButtonSize.medium => 44,
    ButtonSize.large => 52,
  };

  /// Horizontal content padding for text-labelled buttons.
  double get horizontalPadding => switch (this) {
    ButtonSize.small => 12,
    ButtonSize.medium => 16,
    ButtonSize.large => 24,
  };

  /// Square side for icon buttons.
  double get iconSide => switch (this) {
    ButtonSize.small => 40,
    ButtonSize.medium => 48,
    ButtonSize.large => 56,
  };
}

/// Immutable style configuration for a button state.
///
/// Groups the visual properties that vary per button state. The states
/// the widgets actually accept are **normal / disabled / loading /
/// success / error** — hover is handled internally (scale + elevation
/// via `HoverableMixin`) and focus via the InkWell overlay, so there is
/// deliberately no `hoveredStyle`/`focusedStyle` bag to pass.
///
/// Use [copyWith] for variations and [merge] to cascade
/// (base → state-specific); [merge] always lets `other` win.
///
/// Example:
/// ```dart
/// const baseStyle = ButtonStateStyle(
///   backgroundColor: Colors.blue,
///   foregroundColor: Colors.white,
/// );
///
/// // With gradient:
/// final gradientStyle = ButtonStateStyle(
///   backgroundGradient: LinearGradient(
///     colors: [Colors.blue, Colors.purple],
///   ),
///   foregroundColor: Colors.white,
/// );
///
/// final disabledStyle = baseStyle.copyWith(
///   backgroundColor: Colors.grey,
/// );
/// ```
@immutable
class ButtonStateStyle {
  const ButtonStateStyle({
    this.text,
    this.backgroundColor,
    this.backgroundGradient,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.elevation,
    this.shadowColor,
    this.border,
    this.borderGradient,
    this.leading,
    this.trailing,
    this.textStyle,
    this.width,
    this.height,
    this.slotsAtEdges,
    this.slotEdgeInset,
  });

  /// Pin `leading` / `trailing` to the button's edges and centre the
  /// label in the FULL width, rather than laying the three out as one
  /// centred row.
  ///
  /// For a wide bar with an affordance in the corner: in a centred row
  /// the label sits off-centre by half the icon, and shifts again
  /// whenever the label's length changes. Null → false.
  final bool? slotsAtEdges;

  /// Distance from the edge to a pinned slot. Only read when
  /// [slotsAtEdges]. Null → the standard slot spacing.
  final double? slotEdgeInset;

  /// Text to display on the button. Overrides the base text when in this state.
  final String? text;

  /// Background color of the button.
  ///
  /// If [backgroundGradient] is also specified, the gradient takes precedence.
  final Color? backgroundColor;

  /// Background gradient of the button.
  ///
  /// When specified, this takes precedence over [backgroundColor].
  final Gradient? backgroundGradient;

  /// Foreground (text/icon) color of the button.
  final Color? foregroundColor;

  /// Border radius of the button.
  final BorderRadiusGeometry? borderRadius;

  /// Internal padding of the button.
  final EdgeInsetsGeometry? padding;

  /// Elevation (shadow) of the button.
  final double? elevation;

  /// Shadow color for the button's elevation.
  ///
  /// When null, defaults to black. Useful for colored shadows that match
  /// gradient backgrounds.
  final Color? shadowColor;

  /// Decorative border around the button.
  ///
  /// Can be combined with any background (solid, gradient, or transparent).
  /// Example: `BorderSide(color: Colors.blue, width: 2)`
  final BorderSide? border;

  /// Gradient border around the button.
  ///
  /// When specified, takes precedence over [border] color. Uses [border.width]
  /// for stroke width (defaults to 1.5 if [border] is null).
  /// Example: `LinearGradient(colors: [Colors.blue, Colors.purple])`
  final Gradient? borderGradient;

  /// Widget displayed before the text (start of reading direction).
  final Widget? leading;

  /// Widget displayed after the text (end of reading direction).
  final Widget? trailing;

  /// Text style for the button label.
  final TextStyle? textStyle;

  /// Fixed width of the button. If null, uses default sizing.
  final double? width;

  /// Fixed height of the button. If null, uses default sizing.
  final double? height;

  /// Creates a copy with the given fields replaced.
  ///
  /// Use this to create variations of a style:
  /// ```dart
  /// final hoveredStyle = baseStyle.copyWith(elevation: 4);
  /// ```
  ButtonStateStyle copyWith({
    String? text,
    Color? backgroundColor,
    Gradient? backgroundGradient,
    Color? foregroundColor,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry? padding,
    double? elevation,
    Color? shadowColor,
    BorderSide? border,
    Gradient? borderGradient,
    Widget? leading,
    Widget? trailing,
    TextStyle? textStyle,
    bool? slotsAtEdges,
    double? slotEdgeInset,
    double? width,
    double? height,
  }) {
    return ButtonStateStyle(
      text: text ?? this.text,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      border: border ?? this.border,
      borderGradient: borderGradient ?? this.borderGradient,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      textStyle: textStyle ?? this.textStyle,
      slotsAtEdges: slotsAtEdges ?? this.slotsAtEdges,
      slotEdgeInset: slotEdgeInset ?? this.slotEdgeInset,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// Merges this style with another, with [other] taking precedence.
  ///
  /// This is used to apply state-specific overrides on top of a base style:
  /// ```dart
  /// final effectiveStyle = baseStyle.merge(disabledStyle);
  /// ```
  ///
  /// Only non-null values from [other] will override values in this style.
  ButtonStateStyle merge(ButtonStateStyle? other) {
    if (other == null) return this;

    return ButtonStateStyle(
      text: other.text ?? text,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      elevation: other.elevation ?? elevation,
      shadowColor: other.shadowColor ?? shadowColor,
      border: other.border ?? border,
      borderGradient: other.borderGradient ?? borderGradient,
      leading: other.leading ?? leading,
      trailing: other.trailing ?? trailing,
      textStyle: other.textStyle ?? textStyle,
      slotsAtEdges: other.slotsAtEdges ?? slotsAtEdges,
      slotEdgeInset: other.slotEdgeInset ?? slotEdgeInset,
      width: other.width ?? width,
      height: other.height ?? height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ButtonStateStyle &&
        other.text == text &&
        other.backgroundColor == backgroundColor &&
        other.backgroundGradient == backgroundGradient &&
        other.foregroundColor == foregroundColor &&
        other.borderRadius == borderRadius &&
        other.padding == padding &&
        other.elevation == elevation &&
        other.shadowColor == shadowColor &&
        other.border == border &&
        other.borderGradient == borderGradient &&
        other.leading == leading &&
        other.trailing == trailing &&
        other.textStyle == textStyle &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(
    text,
    backgroundColor,
    backgroundGradient,
    foregroundColor,
    borderRadius,
    padding,
    elevation,
    shadowColor,
    border,
    borderGradient,
    leading,
    trailing,
    textStyle,
    width,
    height,
  );
}
