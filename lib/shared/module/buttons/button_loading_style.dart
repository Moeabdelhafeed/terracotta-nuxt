// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'button_state_style.dart';

/// Types of loading indicators available for buttons.
enum LoadingType {
  /// Shimmer effect across the entire button.
  shimmer,

  /// Linear progress indicator in the trailing position.
  linear,

  /// Circular progress indicator in the trailing position.
  circular,

  /// Animated border trace around the button.
  border,

  /// Bouncing dots indicator in the trailing position.
  dots,

  /// No loading indicator, just disables interaction.
  none,
}

/// Extended style specifically for loading state with loading-specific properties.
///
/// Inherits all properties from [ButtonStateStyle] and adds loading-specific
/// configuration like [loadingType], shimmer colors, and animation duration.
///
/// Example:
/// ```dart
/// const loadingStyle = ButtonLoadingStyle(
///   text: 'Submitting...',
///   loadingType: LoadingType.circular,
///   backgroundColor: Colors.blue.shade300,
/// );
/// ```
@immutable
class ButtonLoadingStyle extends ButtonStateStyle {
  const ButtonLoadingStyle({
    // Inherited from ButtonStateStyle
    super.text,
    super.backgroundColor,
    super.backgroundGradient,
    super.foregroundColor,
    super.borderRadius,
    super.padding,
    super.elevation,
    super.shadowColor,
    super.border,
    super.borderGradient,
    super.leading,
    super.trailing,
    super.textStyle,
    super.slotsAtEdges,
    super.slotEdgeInset,
    super.width,
    super.height,
    // Loading-specific properties
    this.loadingType = LoadingType.shimmer,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.shimmerPeriod,
  });

  /// The type of loading indicator to display.
  ///
  /// Defaults to [LoadingType.shimmer].
  final LoadingType loadingType;

  /// Base color for shimmer effect. Only used when [loadingType] is [LoadingType.shimmer].
  ///
  /// If null, derives from [backgroundColor] with reduced opacity.
  final Color? shimmerBaseColor;

  /// Highlight color for shimmer effect. Only used when [loadingType] is [LoadingType.shimmer].
  ///
  /// If null, derives from [backgroundColor] with increased opacity.
  final Color? shimmerHighlightColor;

  /// Duration of one shimmer animation cycle.
  ///
  /// Defaults to 1500ms if null.
  final Duration? shimmerPeriod;

  @override
  ButtonLoadingStyle copyWith({
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
    LoadingType? loadingType,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Duration? shimmerPeriod,
  }) {
    return ButtonLoadingStyle(
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
      loadingType: loadingType ?? this.loadingType,
      shimmerBaseColor: shimmerBaseColor ?? this.shimmerBaseColor,
      shimmerHighlightColor:
          shimmerHighlightColor ?? this.shimmerHighlightColor,
      shimmerPeriod: shimmerPeriod ?? this.shimmerPeriod,
    );
  }

  /// Merges with [other], **[other] winning** — the same direction as
  /// [ButtonStateStyle.merge].
  ///
  /// This override used to invert the contract (`this` won, [other]
  /// only filled nulls). Same method name, opposite precedence,
  /// dispatched by runtime type: any code holding a [ButtonStateStyle]
  /// that happened to be a [ButtonLoadingStyle] silently flipped which
  /// side won. Loading-specific fields are taken from [other] only when
  /// it is itself a [ButtonLoadingStyle].
  @override
  ButtonLoadingStyle merge(ButtonStateStyle? other) {
    if (other == null) return this;
    final otherLoading = other is ButtonLoadingStyle ? other : null;

    return ButtonLoadingStyle(
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
      width: other.width ?? width,
      height: other.height ?? height,
      loadingType: otherLoading?.loadingType ?? loadingType,
      shimmerBaseColor: otherLoading?.shimmerBaseColor ?? shimmerBaseColor,
      shimmerHighlightColor:
          otherLoading?.shimmerHighlightColor ?? shimmerHighlightColor,
      shimmerPeriod: otherLoading?.shimmerPeriod ?? shimmerPeriod,
    );
  }

  /// Creates a [ButtonLoadingStyle] from a base [ButtonStateStyle] with loading properties.
  ///
  /// Useful for converting an existing style to a loading style:
  /// ```dart
  /// final loadingStyle = ButtonLoadingStyle.fromStyle(
  ///   baseStyle,
  ///   loadingType: LoadingType.dots,
  /// );
  /// ```
  factory ButtonLoadingStyle.fromStyle(
    ButtonStateStyle style, {
    LoadingType loadingType = LoadingType.shimmer,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Duration? shimmerPeriod,
  }) {
    return ButtonLoadingStyle(
      text: style.text,
      backgroundColor: style.backgroundColor,
      backgroundGradient: style.backgroundGradient,
      foregroundColor: style.foregroundColor,
      borderRadius: style.borderRadius,
      padding: style.padding,
      elevation: style.elevation,
      shadowColor: style.shadowColor,
      border: style.border,
      borderGradient: style.borderGradient,
      leading: style.leading,
      trailing: style.trailing,
      textStyle: style.textStyle,
      width: style.width,
      height: style.height,
      loadingType: loadingType,
      shimmerBaseColor: shimmerBaseColor,
      shimmerHighlightColor: shimmerHighlightColor,
      shimmerPeriod: shimmerPeriod,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ButtonLoadingStyle &&
        super == other &&
        other.loadingType == loadingType &&
        other.shimmerBaseColor == shimmerBaseColor &&
        other.shimmerHighlightColor == shimmerHighlightColor &&
        other.shimmerPeriod == shimmerPeriod;
  }

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    loadingType,
    shimmerBaseColor,
    shimmerHighlightColor,
    shimmerPeriod,
  );
}
