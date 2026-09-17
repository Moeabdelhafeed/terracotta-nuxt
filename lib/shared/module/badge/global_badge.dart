import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';
import 'badge_models.dart';
import 'theme/badge_theme.dart';

export 'badge_models.dart';
export 'theme/badge_theme.dart';

// ---------------------------------------------------------------------------
// GlobalBadge
// ---------------------------------------------------------------------------

/// A wrapper that adds a badge overlay to any child widget.
class GlobalBadge extends StatelessWidget {
  const GlobalBadge({
    super.key,
    required this.child,
    this.count,
    this.label,
    this.icon,
    this.customBadge,
    this.position = BadgePosition.topEnd,
    this.style = const BadgeStyle(),
    this.show = true,
    this.standalone = false,
  });

  /// The widget to display the badge on.
  final Widget child;

  /// Count number. When set, uses [BadgeVariant.count].
  final int? count;

  /// Text label (e.g. "NEW"). When set, uses [BadgeVariant.label].
  final String? label;

  /// Icon. When set, uses [BadgeVariant.icon].
  final IconData? icon;

  /// Fully custom badge widget. Takes priority over count/label/icon.
  final Widget? customBadge;

  /// Position of the badge.
  final BadgePosition position;

  /// Styling configuration.
  final BadgeStyle style;

  /// Whether the badge is visible. Animate show/hide.
  final bool show;

  /// Renders the badge ON ITS OWN, with no child to attach to and no
  /// corner overhang. See [GlobalBadge.standalone].
  final bool standalone;

  BadgeVariant get _variant {
    if (customBadge != null) return BadgeVariant.custom;
    if (count != null) return BadgeVariant.count;
    if (label != null) return BadgeVariant.label;
    if (icon != null) return BadgeVariant.icon;
    return BadgeVariant.dot;
  }

  // ─── Convenience factories ─────────────────────────────────

  /// Dot-only badge.
  const GlobalBadge.dot({
    super.key,
    required this.child,
    this.position = BadgePosition.topEnd,
    this.style = const BadgeStyle(),
    this.show = true,
    this.standalone = false,
  }) : count = null,
       label = null,
       icon = null,
       customBadge = null;

  /// Count badge.
  factory GlobalBadge.count({
    Key? key,
    required Widget child,
    required int count,
    BadgePosition position = BadgePosition.topEnd,
    BadgeStyle style = const BadgeStyle(),
  }) {
    return GlobalBadge(
      key: key,
      count: count,
      position: position,
      style: style,
      // `hideWhenZero` is themeable now, so the factory cannot decide
      // here — it has no context. `build` applies it against the
      // RESOLVED value, which is where the theme can be seen.
      child: child,
    );
  }

  /// A badge with nothing to hang off — an inline pill or dot that
  /// sits in a row rather than in a corner.
  ///
  /// The wrapping form assumes a child to attach to, which is right for
  /// an icon in a navigation bar and wrong for a trailing count in a
  /// list row. Every module that needed the second shape hand-rolled its
  /// own rather than reach for this one, which is how four different
  /// badges ended up in the codebase.
  factory GlobalBadge.standalone({
    Key? key,
    int? count,
    String? label,
    IconData? icon,
    BadgeStyle style = const BadgeStyle(),
  }) {
    return GlobalBadge(
      key: key,
      count: count,
      label: label,
      icon: icon,
      style: style,
      // No corner to hang off, so no overhang either.
      standalone: true,
      child: const SizedBox.shrink(),
    );
  }

  /// Label badge (e.g. "NEW").
  const GlobalBadge.label({
    super.key,
    required this.child,
    required String this.label,
    this.position = BadgePosition.topEnd,
    this.style = const BadgeStyle(),
    this.show = true,
    this.standalone = false,
  }) : count = null,
       icon = null,
       customBadge = null;

  /// Icon badge.
  const GlobalBadge.icon({
    super.key,
    required this.child,
    required IconData this.icon,
    this.position = BadgePosition.topEnd,
    this.style = const BadgeStyle(),
    this.show = true,
    this.standalone = false,
  }) : count = null,
       label = null,
       customBadge = null;

  // ─── Semantic label ────────────────────────────────────────

  String? _semanticLabel(ResolvedBadgeStyle style) {
    final variant = _variant;
    switch (variant) {
      case BadgeVariant.count:
        final c = count ?? 0;
        if (c <= 0) return null;
        return c > style.maxCount
            ? BadgeStrings.countNotifications('${style.maxCount}+')
            : BadgeStrings.countNotifications('$c');
      case BadgeVariant.dot:
        return BadgeStrings.newNotification;
      case BadgeVariant.label:
        return label;
      case BadgeVariant.icon:
        return 'Badge';
      case BadgeVariant.custom:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = style.resolve(context);
    final variant = _variant;
    final isVisible =
        show &&
        !(variant == BadgeVariant.count &&
            rs.hideWhenZero &&
            (count ?? 0) <= 0);
    // A repeating scale is exactly what `disableAnimations` exists to
    // stop, and a badge pulses forever rather than settling.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final motion = reduceMotion ? Duration.zero : rs.animationDuration;

    final animatedBadge = AnimatedScale(
      scale: isVisible ? 1.0 : 0.0,
      duration: motion,
      curve: rs.animationCurve,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: motion,
        curve: rs.animationCurve,
        child: _buildBadge(context, variant, rs),
      ),
    );

    final badge = rs.pulsate && isVisible && !reduceMotion
        ? _PulsatingBadge(duration: kBadgePulseDuration, child: animatedBadge)
        : animatedBadge;

    final semanticBadge = _semanticLabel(rs) != null && isVisible
        ? Semantics(
            label: _semanticLabel(rs),
            excludeSemantics: true,
            child: badge,
          )
        : badge;

    // The corner it hangs off is DIRECTIONAL, so `end` is the right edge
    // in English and the left one in Arabic.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isTop =
        position == BadgePosition.topEnd || position == BadgePosition.topStart;
    final isEnd =
        position == BadgePosition.topEnd || position == BadgePosition.bottomEnd;
    final isRight = isEnd ^ isRtl;

    if (standalone) return semanticBadge;

    final baseOffset = -rs.extentFor(variant) / kBadgeOverhangFraction;
    final dx = rs.offset.dx + baseOffset;
    final dy = rs.offset.dy + baseOffset;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: isTop ? dy : null,
          bottom: !isTop ? dy : null,
          right: isRight ? dx : null,
          left: !isRight ? dx : null,
          child: semanticBadge,
        ),
      ],
    );
  }

  Widget _buildBadge(
    BuildContext context,
    BadgeVariant variant,
    ResolvedBadgeStyle style,
  ) {
    final bg = style.backgroundGradient == null ? style.backgroundColor : null;
    final fg = style.foregroundColor;
    final borderColor = style.borderColor;

    switch (variant) {
      case BadgeVariant.dot:
        return Container(
          width: style.dotSize,
          height: style.dotSize,
          decoration: BoxDecoration(
            color: bg,
            gradient: style.backgroundGradient,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: style.borderWidth),
            boxShadow: style.shadow,
          ),
        );

      case BadgeVariant.count:
        final text = style.countText(count);
        final minSize = style.size;
        return Container(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          padding:
              style.padding ??
              EdgeInsetsDirectional.symmetric(
                horizontal: text.length > 1 ? kBadgeCountHPad : 0,
              ),
          decoration: BoxDecoration(
            color: bg,
            gradient: style.backgroundGradient,
            borderRadius:
                style.borderRadius ?? BorderRadius.circular(minSize / 2),
            border: Border.all(color: borderColor, width: style.borderWidth),
            boxShadow: style.shadow,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: style.fontSize,
              fontWeight: style.fontWeight,
              height: 1,
            ),
          ),
        );

      case BadgeVariant.label:
        return Container(
          padding:
              style.padding ??
              const EdgeInsetsDirectional.symmetric(
                horizontal: kBadgeLabelHPad,
                vertical: kBadgeLabelVPad,
              ),
          decoration: BoxDecoration(
            color: bg,
            gradient: style.backgroundGradient,
            borderRadius:
                style.borderRadius ?? BorderRadius.circular(kBadgeLabelRadius),
            border: Border.all(color: borderColor, width: style.borderWidth),
            boxShadow: style.shadow,
          ),
          child: Text(
            label!,
            style: TextStyle(
              color: fg,
              fontSize: style.fontSize,
              fontWeight: style.fontWeight,
              height: 1,
            ),
          ),
        );

      case BadgeVariant.icon:
        final iconSize = style.size * kBadgeIconFraction;
        return Container(
          width: style.size,
          height: style.size,
          decoration: BoxDecoration(
            color: bg,
            gradient: style.backgroundGradient,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: style.borderWidth),
            boxShadow: style.shadow,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: iconSize, color: fg),
        );

      case BadgeVariant.custom:
        return customBadge!;
    }
  }
}

// ---------------------------------------------------------------------------
// Pulsating badge animation
// ---------------------------------------------------------------------------

class _PulsatingBadge extends StatefulWidget {
  const _PulsatingBadge({required this.duration, required this.child});
  final Duration duration;
  final Widget child;

  @override
  State<_PulsatingBadge> createState() => _PulsatingBadgeState();
}

class _PulsatingBadgeState extends State<_PulsatingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 1,
      end: kBadgePulseMinOpacity,
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(
        scale: 1.0 + _ctrl.value * (kBadgePulseScale - 1),
        child: FadeTransition(opacity: _opacity, child: child),
      ),
      child: widget.child,
    );
  }
}
