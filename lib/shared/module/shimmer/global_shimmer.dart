// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:
import 'package:shimmer/shimmer.dart' as pkg;

// Project imports:
import '../../../core/extensions/theme_colors_extension.dart';

/// A comprehensive shimmer widget that supports theming, various shapes,
/// and convenient helper methods for common use cases.
class GlobalShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Color? containerColor;
  final Duration period;

  /// Which way the highlight sweeps. NULL follows the reading
  /// direction, which is what a shimmer should do: it stands in for
  /// text that is not there yet, and in Arabic that text is read from
  /// the right. It used to default to `ltr` outright, so every
  /// placeholder in the app swept against the reader.
  final GlobalShimmerDirection? direction;
  final bool enabled;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxDecoration? decoration;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final ShimmerShape shape;

  const GlobalShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.containerColor,
    this.period = const Duration(milliseconds: 1500),
    this.direction,
    this.enabled = true,
    this.width,
    this.height,
    this.borderRadius,
    this.decoration,
    this.margin,
    this.padding,
    this.shape = ShimmerShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBaseColor = baseColor ?? context.shimmerColors.baseColor;
    final effectiveHighlightColor =
        highlightColor ?? context.shimmerColors.highlight;
    final effectiveContainerColor =
        containerColor ?? context.backgroundColors.surface;
    // A shimmer sweeps FOREVER — it never settles the way a transition
    // does, which is exactly the motion `disableAnimations` exists to
    // stop. Switched off it still paints the placeholder block, so the
    // "something is loading here" shape survives; only the sweep goes.
    final animate = enabled && !MediaQuery.disableAnimationsOf(context);

    // ONE copy of the child, inside the shimmer.
    //
    // This used to be a `Stack` with the child painted twice: once
    // inside the shimmer and once, unshimmered and fully opaque, on top
    // of it. Every placeholder factory passes `SizedBox.shrink()`, so
    // two of nothing looked fine and hid the bug — but `GlobalShimmer`
    // and `.wrap` take a REAL child, and there the opaque copy covered
    // the effect completely. Guard: "a real child shimmers".
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: pkg.Shimmer.fromColors(
        baseColor: effectiveBaseColor,
        highlightColor: effectiveHighlightColor,
        period: period,
        direction:
            (direction ??
                    (Directionality.of(context) == TextDirection.rtl
                        ? GlobalShimmerDirection.rtl
                        : GlobalShimmerDirection.ltr))
                .toPackage(),
        enabled: animate,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration:
              decoration ?? _getShapeDecoration(effectiveContainerColor),
          child: ClipRRect(
            borderRadius: _getClipBorderRadius(),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Get decoration based on shape
  BoxDecoration _getShapeDecoration(Color containerColor) {
    switch (shape) {
      case ShimmerShape.circle:
        return BoxDecoration(
          color: containerColor,
          shape: BoxShape.circle,
        );
      case ShimmerShape.rectangle:
        return BoxDecoration(
          color: containerColor,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        );
      case ShimmerShape.rounded:
        return BoxDecoration(
          color: containerColor,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        );
    }
  }

  /// Get border radius for clipping
  BorderRadiusGeometry _getClipBorderRadius() {
    switch (shape) {
      case ShimmerShape.circle:
        return BorderRadius.circular(1000); // Large radius for circle
      case ShimmerShape.rectangle:
        return borderRadius ?? BorderRadius.circular(8);
      case ShimmerShape.rounded:
        return borderRadius ?? BorderRadius.circular(12);
    }
  }

  // ==================== HELPER METHODS ====================

  /// Creates a simple placeholder shimmer
  static Widget placeholder({
    double? width,
    double? height,
    BorderRadiusGeometry? borderRadius,
    Color? baseColor,
    Color? highlightColor,
    Color? containerColor,
    Duration period = const Duration(milliseconds: 1500),
    GlobalShimmerDirection? direction,
    bool enabled = true,
    EdgeInsets? margin,
    EdgeInsets? padding,
    ShimmerShape shape = ShimmerShape.rectangle,
  }) {
    return GlobalShimmer(
      width: width,
      height: height,
      borderRadius: borderRadius,
      baseColor: baseColor,
      highlightColor: highlightColor,
      containerColor: containerColor,
      period: period,
      direction: direction,
      enabled: enabled,
      margin: margin,
      padding: padding,
      shape: shape,
      child: const SizedBox.shrink(),
    );
  }

  /// Wraps an existing widget with shimmer
  static Widget wrap({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Color? containerColor,
    Duration period = const Duration(milliseconds: 1500),
    GlobalShimmerDirection? direction,
    bool enabled = true,
    BorderRadiusGeometry? borderRadius,
    EdgeInsets? margin,
    EdgeInsets? padding,
    ShimmerShape shape = ShimmerShape.rectangle,
  }) {
    return GlobalShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      containerColor: containerColor,
      period: period,
      direction: direction,
      enabled: enabled,
      borderRadius: borderRadius,
      margin: margin,
      padding: padding,
      shape: shape,
      child: child,
    );
  }

  /// Creates a circular shimmer placeholder (perfect for avatars)
  static Widget circle({
    required double size,
    Color? baseColor,
    Color? highlightColor,
    Color? containerColor,
    Duration period = const Duration(milliseconds: 1500),
    bool enabled = true,
    EdgeInsets? margin,
  }) {
    return GlobalShimmer(
      width: size,
      height: size,
      baseColor: baseColor,
      highlightColor: highlightColor,
      containerColor: containerColor,
      period: period,
      enabled: enabled,
      margin: margin,
      shape: ShimmerShape.circle,
      child: const SizedBox.shrink(),
    );
  }

  /// Creates a shimmer for text-like content
  static Widget text({
    double? width,
    double height = 16,
    Color? baseColor,
    Color? highlightColor,
    Color? containerColor,
    Duration period = const Duration(milliseconds: 1500),
    bool enabled = true,
    EdgeInsets? margin,
    BorderRadiusGeometry? borderRadius,
  }) {
    return GlobalShimmer(
      width: width,
      height: height,
      baseColor: baseColor,
      highlightColor: highlightColor,
      containerColor: containerColor,
      period: period,
      enabled: enabled,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
      child: const SizedBox.shrink(),
    );
  }

  /// Creates a shimmer for card-like content
  static Widget card({
    double? width,
    double? height,
    Color? baseColor,
    Color? highlightColor,
    Color? containerColor,
    Duration period = const Duration(milliseconds: 1500),
    bool enabled = true,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BorderRadiusGeometry? borderRadius,
  }) {
    return GlobalShimmer(
      width: width,
      height: height,
      baseColor: baseColor,
      highlightColor: highlightColor,
      containerColor: containerColor,
      period: period,
      enabled: enabled,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      shape: ShimmerShape.rounded,
      child: const SizedBox.shrink(),
    );
  }

  /// Creates a list of shimmer items
  static Widget list({
    required int itemCount,
    required Widget Function(int index) itemBuilder,
    Axis scrollDirection = Axis.vertical,
    EdgeInsets? padding,
    double? spacing,
    bool shrinkWrap = true,
    ScrollPhysics? physics,
  }) {
    return ListView.separated(
      scrollDirection: scrollDirection,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(
        width: scrollDirection == Axis.horizontal ? (spacing ?? 8) : 0,
        height: scrollDirection == Axis.vertical ? (spacing ?? 8) : 0,
      ),
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }

  /// Creates a grid of shimmer items
  static Widget grid({
    required int itemCount,
    required Widget Function(int index) itemBuilder,
    required int crossAxisCount,
    double mainAxisSpacing = 8,
    double crossAxisSpacing = 8,
    double childAspectRatio = 1.0,
    EdgeInsets? padding,
    bool shrinkWrap = true,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }
}

/// Enum for different shimmer shapes
/// Direction the highlight sweeps.
///
/// The module's own enum, not the package's. `ShimmerDirection` used to
/// appear in `GlobalShimmer`'s signature, so every caller — and the
/// showcase — had to import `package:shimmer` to name a direction. Same
/// leak the toast had before it grew its own types.
enum GlobalShimmerDirection {
  ltr,
  rtl,
  ttb,
  btt;

  pkg.ShimmerDirection toPackage() => switch (this) {
    GlobalShimmerDirection.ltr => pkg.ShimmerDirection.ltr,
    GlobalShimmerDirection.rtl => pkg.ShimmerDirection.rtl,
    GlobalShimmerDirection.ttb => pkg.ShimmerDirection.ttb,
    GlobalShimmerDirection.btt => pkg.ShimmerDirection.btt,
  };
}

enum ShimmerShape {
  rectangle,
  rounded,
  circle,
}

/// Extension for common shimmer patterns
extension ShimmerExtensions on Widget {
  /// Wraps the widget with shimmer effect
  Widget shimmer({
    Color? baseColor,
    Color? highlightColor,
    Color? containerColor,
    Duration period = const Duration(milliseconds: 1500),
    GlobalShimmerDirection? direction,
    bool enabled = true,
    BorderRadiusGeometry? borderRadius,
    EdgeInsets? margin,
    EdgeInsets? padding,
    ShimmerShape shape = ShimmerShape.rectangle,
  }) {
    return GlobalShimmer.wrap(
      child: this,
      baseColor: baseColor,
      highlightColor: highlightColor,
      containerColor: containerColor,
      period: period,
      direction: direction,
      enabled: enabled,
      borderRadius: borderRadius,
      margin: margin,
      padding: padding,
      shape: shape,
    );
  }
}

/// Predefined shimmer configurations for common use cases
class ShimmerPresets {
  static const Duration fastAnimation = Duration(milliseconds: 1000);
  static const Duration normalAnimation = Duration(milliseconds: 1500);
  static const Duration slowAnimation = Duration(milliseconds: 2000);

  /// Common shimmer for list items
  static Widget listItem({
    double? width,
    double height = 60,
    bool enabled = true,
    EdgeInsets? margin,
  }) {
    return GlobalShimmer.card(
      width: width,
      height: height,
      enabled: enabled,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
    );
  }

  /// Common shimmer for profile avatars
  static Widget avatar({
    double size = 40,
    bool enabled = true,
    EdgeInsets? margin,
  }) {
    return GlobalShimmer.circle(
      size: size,
      enabled: enabled,
      margin: margin,
    );
  }

  /// Common shimmer for text lines
  static Widget textLine({
    double? width,
    double height = 12,
    bool enabled = true,
    EdgeInsets? margin,
  }) {
    return GlobalShimmer.text(
      width: width,
      height: height,
      enabled: enabled,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 2),
    );
  }

  /// Common shimmer for buttons
  static Widget button({
    double? width,
    double height = 44,
    bool enabled = true,
    EdgeInsets? margin,
  }) {
    return GlobalShimmer.placeholder(
      width: width,
      height: height,
      enabled: enabled,
      margin: margin,
      borderRadius: BorderRadius.circular(22),
    );
  }
}
