import 'package:flutter/material.dart';

import '../models/popup_models.dart';

/// Entrance animation switchboard — wraps `child` with the
/// transformation appropriate for the requested
/// [GlobalPopupAnimation] type.
///
/// Driven by [animation] (the controller's `AnimationController`),
/// honors [isAbove] / [isVertical] / [isLeading] so each variant
/// originates from the anchor-facing edge.
class GlobalPopupEntranceAnimation extends StatelessWidget {
  const GlobalPopupEntranceAnimation({
    super.key,
    required this.animation,
    required this.isAbove,
    required this.isVertical,
    required this.isLeading,
    required this.curve,
    required this.type,
    required this.child,
  });

  final Animation<double> animation;
  final bool isAbove;
  final bool isVertical;
  final bool isLeading;
  final Curve curve;
  final GlobalPopupAnimation type;
  final Widget child;

  Alignment get _origin {
    if (isVertical) {
      return isAbove ? Alignment.bottomCenter : Alignment.topCenter;
    }
    return isLeading ? Alignment.centerRight : Alignment.centerLeft;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curved = curve.transform(animation.value);
        // Overshoot curves (elasticOut, easeOutBack) can produce values
        // outside [0, 1]. Reveal/Scale/Fade use `curved` as Opacity which
        // asserts the range — clamp before passing in.
        final opacity = curved.clamp(0.0, 1.0);
        final clipFraction = curved.clamp(0.0, 1.0);
        switch (type) {
          case GlobalPopupAnimation.reveal:
            final revealOpacity = (curved / 0.4).clamp(0.0, 1.0);
            return Opacity(
              opacity: revealOpacity,
              child: _PopupClipReveal(
                fraction: clipFraction,
                isVertical: isVertical,
                fromTop: isVertical ? !isAbove : true,
                fromStart: !isVertical && !isLeading,
                child: child!,
              ),
            );
          case GlobalPopupAnimation.expand:
            // True scale-from-anchor — `Transform.scale` scales along
            // the axis facing the anchor without touching layout, so
            // the follower keeps its position exact and there is no
            // horizontal drift.
            final expandOpacity = (curved * 1.4).clamp(0.0, 1.0);
            final scaleAlign = isVertical
                ? (isAbove ? Alignment.bottomCenter : Alignment.topCenter)
                : (isLeading ? Alignment.centerRight : Alignment.centerLeft);
            final axisFactor = clipFraction.clamp(0.001, 1.0);
            return Opacity(
              opacity: expandOpacity,
              child: Transform.scale(
                scaleX: isVertical ? 1.0 : axisFactor,
                scaleY: isVertical ? axisFactor : 1.0,
                alignment: scaleAlign,
                child: child,
              ),
            );
          case GlobalPopupAnimation.scale:
            // Scale itself accepts overshoot — keeps bouncy character.
            final scaleValue = 0.7 + curved * 0.3;
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scaleValue,
                alignment: _origin,
                child: child,
              ),
            );
          case GlobalPopupAnimation.fade:
            return Opacity(opacity: opacity, child: child);
          case GlobalPopupAnimation.none:
            return child!;
        }
      },
      child: child,
    );
  }
}

class _PopupClipReveal extends StatelessWidget {
  const _PopupClipReveal({
    required this.fraction,
    required this.isVertical,
    required this.fromTop,
    required this.fromStart,
    required this.child,
  });

  final double fraction;
  final bool isVertical;
  final bool fromTop;
  final bool fromStart;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipper: _PopupRevealClipper(
        fraction: fraction,
        isVertical: isVertical,
        fromTop: fromTop,
        fromStart: fromStart,
      ),
      child: child,
    );
  }
}

class _PopupRevealClipper extends CustomClipper<Rect> {
  _PopupRevealClipper({
    required this.fraction,
    required this.isVertical,
    required this.fromTop,
    required this.fromStart,
  });
  final double fraction;
  final bool isVertical;
  final bool fromTop;
  final bool fromStart;

  // Pad the clip outward by this amount so the surface's drop shadow
  // isn't cut at the reveal edges (the shadow blurs outside the body).
  static const _shadowPad = 24.0;

  @override
  Rect getClip(Size size) {
    if (isVertical) {
      final visibleHeight = size.height * fraction;
      if (fromTop) {
        return Rect.fromLTWH(
          -_shadowPad,
          -_shadowPad,
          size.width + _shadowPad * 2,
          visibleHeight + _shadowPad * 2,
        );
      }
      return Rect.fromLTWH(
        -_shadowPad,
        size.height - visibleHeight - _shadowPad,
        size.width + _shadowPad * 2,
        visibleHeight + _shadowPad * 2,
      );
    }
    final visibleWidth = size.width * fraction;
    if (fromStart) {
      return Rect.fromLTWH(
        -_shadowPad,
        -_shadowPad,
        visibleWidth + _shadowPad * 2,
        size.height + _shadowPad * 2,
      );
    }
    return Rect.fromLTWH(
      size.width - visibleWidth - _shadowPad,
      -_shadowPad,
      visibleWidth + _shadowPad * 2,
      size.height + _shadowPad * 2,
    );
  }

  @override
  bool shouldReclip(covariant _PopupRevealClipper old) =>
      old.fraction != fraction ||
      old.fromTop != fromTop ||
      old.fromStart != fromStart ||
      old.isVertical != isVertical;
}
