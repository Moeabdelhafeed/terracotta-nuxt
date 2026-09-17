// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'animation_presets.dart';

/// Configuration for a single animation.
///
/// Supports multiple animation types that can be combined:
/// - Slide (offset-based movement)
/// - Fade (opacity change)
/// - Scale (size change)
/// - Rotation
///
/// Each animation defines begin/end values, duration, and curve.
///
/// Example usage:
/// ```dart
/// // Simple slide animation
/// AnimationConfig.slide(from: Offset(1, 0))
///
/// // Fade animation
/// AnimationConfig.fade(from: 0, to: 1)
///
/// // Combined animations
/// AnimationConfig.slide(from: Offset(1, 0))
///   .withFade(from: 0, to: 1)
///   .withScale(from: 0.8, to: 1)
/// ```
class AnimationConfig {
  /// Duration of the animation
  final Duration duration;

  /// Animation curve
  final Curve curve;

  // Slide animation properties
  final Offset? slideFrom;
  final Offset? slideTo;

  // Fade animation properties
  final double? fadeFrom;
  final double? fadeTo;

  // Scale animation properties
  final double? scaleFrom;
  final double? scaleTo;

  // Rotation animation properties (in turns, 1.0 = 360°)
  final double? rotateFrom;
  final double? rotateTo;

  // Whether each animation type is enabled
  final bool hasSlide;
  final bool hasFade;
  final bool hasScale;
  final bool hasRotate;

  const AnimationConfig({
    this.duration = AppDurations.normal,
    this.curve = Curves.easeInOut,
    this.slideFrom,
    this.slideTo,
    this.fadeFrom,
    this.fadeTo,
    this.scaleFrom,
    this.scaleTo,
    this.rotateFrom,
    this.rotateTo,
    this.hasSlide = false,
    this.hasFade = false,
    this.hasScale = false,
    this.hasRotate = false,
  });

  /// No animation - immediate transition
  const AnimationConfig.none()
    : duration = Duration.zero,
      curve = Curves.linear,
      slideFrom = null,
      slideTo = null,
      fadeFrom = null,
      fadeTo = null,
      scaleFrom = null,
      scaleTo = null,
      rotateFrom = null,
      rotateTo = null,
      hasSlide = false,
      hasFade = false,
      hasScale = false,
      hasRotate = false;

  /// Slide animation
  ///
  /// [from] - Starting offset (relative to widget size, e.g., Offset(1, 0) = start from right)
  /// [to] - Ending offset (default: Offset.zero = original position)
  factory AnimationConfig.slide({
    required Offset from,
    Offset to = Offset.zero,
    Duration duration = AppDurations.normal,
    Curve curve = Curves.easeOutCubic,
  }) {
    return AnimationConfig(
      duration: duration,
      curve: curve,
      slideFrom: from,
      slideTo: to,
      hasSlide: true,
    );
  }

  /// Fade animation
  ///
  /// [from] - Starting opacity (0.0 = invisible, 1.0 = fully visible)
  /// [to] - Ending opacity
  factory AnimationConfig.fade({
    required double from,
    double to = 1.0,
    Duration duration = AppDurations.normal,
    Curve curve = Curves.easeInOut,
  }) {
    return AnimationConfig(
      duration: duration,
      curve: curve,
      fadeFrom: from,
      fadeTo: to,
      hasFade: true,
    );
  }

  /// Scale animation
  ///
  /// [from] - Starting scale (1.0 = original size)
  /// [to] - Ending scale
  factory AnimationConfig.scale({
    required double from,
    double to = 1.0,
    Duration duration = AppDurations.normal,
    Curve curve = Curves.easeOutBack,
  }) {
    return AnimationConfig(
      duration: duration,
      curve: curve,
      scaleFrom: from,
      scaleTo: to,
      hasScale: true,
    );
  }

  /// Rotation animation
  ///
  /// [from] - Starting rotation in turns (1.0 = 360°)
  /// [to] - Ending rotation
  factory AnimationConfig.rotate({
    required double from,
    double to = 0.0,
    Duration duration = AppDurations.normal,
    Curve curve = Curves.easeInOut,
  }) {
    return AnimationConfig(
      duration: duration,
      curve: curve,
      rotateFrom: from,
      rotateTo: to,
      hasRotate: true,
    );
  }

  // ==================== Builder Methods ====================

  /// Add slide animation to the current config
  AnimationConfig withSlide({
    required Offset from,
    Offset to = Offset.zero,
  }) {
    return _copyWith(
      slideFrom: from,
      slideTo: to,
      hasSlide: true,
    );
  }

  /// Add fade animation to the current config
  AnimationConfig withFade({
    required double from,
    double to = 1.0,
  }) {
    return _copyWith(
      fadeFrom: from,
      fadeTo: to,
      hasFade: true,
    );
  }

  /// Add scale animation to the current config
  AnimationConfig withScale({
    required double from,
    double to = 1.0,
  }) {
    return _copyWith(
      scaleFrom: from,
      scaleTo: to,
      hasScale: true,
    );
  }

  /// Add rotation animation to the current config
  AnimationConfig withRotate({
    required double from,
    double to = 0.0,
  }) {
    return _copyWith(
      rotateFrom: from,
      rotateTo: to,
      hasRotate: true,
    );
  }

  /// Change the duration
  AnimationConfig withDuration(Duration duration) {
    return _copyWith(duration: duration);
  }

  /// Change the curve
  AnimationConfig withCurve(Curve curve) {
    return _copyWith(curve: curve);
  }

  /// Create a reversed version of this animation (swap from/to values)
  AnimationConfig reversed() {
    return AnimationConfig(
      duration: duration,
      curve: curve.flipped,
      slideFrom: slideTo,
      slideTo: slideFrom,
      fadeFrom: fadeTo,
      fadeTo: fadeFrom,
      scaleFrom: scaleTo,
      scaleTo: scaleFrom,
      rotateFrom: rotateTo,
      rotateTo: rotateFrom,
      hasSlide: hasSlide,
      hasFade: hasFade,
      hasScale: hasScale,
      hasRotate: hasRotate,
    );
  }

  AnimationConfig _copyWith({
    Duration? duration,
    Curve? curve,
    Offset? slideFrom,
    Offset? slideTo,
    double? fadeFrom,
    double? fadeTo,
    double? scaleFrom,
    double? scaleTo,
    double? rotateFrom,
    double? rotateTo,
    bool? hasSlide,
    bool? hasFade,
    bool? hasScale,
    bool? hasRotate,
  }) {
    return AnimationConfig(
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      slideFrom: slideFrom ?? this.slideFrom,
      slideTo: slideTo ?? this.slideTo,
      fadeFrom: fadeFrom ?? this.fadeFrom,
      fadeTo: fadeTo ?? this.fadeTo,
      scaleFrom: scaleFrom ?? this.scaleFrom,
      scaleTo: scaleTo ?? this.scaleTo,
      rotateFrom: rotateFrom ?? this.rotateFrom,
      rotateTo: rotateTo ?? this.rotateTo,
      hasSlide: hasSlide ?? this.hasSlide,
      hasFade: hasFade ?? this.hasFade,
      hasScale: hasScale ?? this.hasScale,
      hasRotate: hasRotate ?? this.hasRotate,
    );
  }

  /// Whether this config has any animations
  bool get hasAnimation => hasSlide || hasFade || hasScale || hasRotate;

  /// Build the animated widget using this configuration
  Widget buildAnimation({
    required Animation<double> animation,
    required Widget child,
  }) {
    if (!hasAnimation) return child;

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    var result = child;

    // Apply rotation first (closest to child)
    if (hasRotate) {
      result = RotationTransition(
        turns: Tween<double>(
          begin: rotateFrom ?? 0.0,
          end: rotateTo ?? 0.0,
        ).animate(curvedAnimation),
        child: result,
      );
    }

    // Apply scale
    if (hasScale) {
      result = ScaleTransition(
        scale: Tween<double>(
          begin: scaleFrom ?? 1.0,
          end: scaleTo ?? 1.0,
        ).animate(curvedAnimation),
        child: result,
      );
    }

    // Apply fade
    if (hasFade) {
      result = FadeTransition(
        opacity: Tween<double>(
          begin: fadeFrom ?? 1.0,
          end: fadeTo ?? 1.0,
        ).animate(curvedAnimation),
        child: result,
      );
    }

    // Apply slide (outermost transformation)
    if (hasSlide) {
      result = SlideTransition(
        position: Tween<Offset>(
          begin: slideFrom ?? Offset.zero,
          end: slideTo ?? Offset.zero,
        ).animate(curvedAnimation),
        child: result,
      );
    }

    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimationConfig &&
        other.duration == duration &&
        other.curve == curve &&
        other.slideFrom == slideFrom &&
        other.slideTo == slideTo &&
        other.fadeFrom == fadeFrom &&
        other.fadeTo == fadeTo &&
        other.scaleFrom == scaleFrom &&
        other.scaleTo == scaleTo &&
        other.rotateFrom == rotateFrom &&
        other.rotateTo == rotateTo;
  }

  @override
  int get hashCode {
    return Object.hash(
      duration,
      curve,
      slideFrom,
      slideTo,
      fadeFrom,
      fadeTo,
      scaleFrom,
      scaleTo,
      rotateFrom,
      rotateTo,
    );
  }

  @override
  String toString() {
    final parts = <String>[];
    if (hasSlide) parts.add('slide($slideFrom→$slideTo)');
    if (hasFade) parts.add('fade($fadeFrom→$fadeTo)');
    if (hasScale) parts.add('scale($scaleFrom→$scaleTo)');
    if (hasRotate) parts.add('rotate($rotateFrom→$rotateTo)');
    if (parts.isEmpty) parts.add('none');
    return 'AnimationConfig(${parts.join(', ')}, ${duration.inMilliseconds}ms, $curve)';
  }
}
