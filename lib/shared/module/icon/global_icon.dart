import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../badge/global_badge.dart';
import '../tooltip/global_tooltip.dart';
import 'icon_models.dart';
import 'theme/icon_theme.dart';

export 'icon_models.dart';
export 'theme/icon_theme.dart';

/// A highly customizable icon widget with support for gradients, backgrounds,
/// container shapes, opacity, RTL mirroring, and transparency-aware ripple effects.
///
/// Use convenience factories for common patterns:
/// - [GlobalIcon.basic] — minimal icon
/// - [GlobalIcon.circle] — icon in a circular container
/// - [GlobalIcon.badge] — icon with colored badge-style background
/// - [GlobalIcon.gradient] — icon with gradient fill
/// - [GlobalIcon.outlined] — icon with border outline
class GlobalIcon extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// Styling configuration.
  final IconStyle style;

  /// Callback when tapped. When null, no tap handling is added.
  final VoidCallback? onTap;

  /// Long-press callback.
  final VoidCallback? onLongPress;

  /// Tooltip text shown on long-press (accessibility).
  final String? tooltip;

  /// Whether the glyph mirrors horizontally in RTL.
  ///
  /// OFF by default, and that is not a style choice: this used to be on
  /// for every icon, so an Arabic build rendered a house, a person and
  /// a magnifier back to front. Only DIRECTIONAL glyphs — arrows, a
  /// back chevron, send — mean the opposite thing mirrored, and only
  /// those should ask.
  final bool mirrorInRtl;

  /// When true, the ripple effect is masked to the icon shape (non-transparent pixels only).
  final bool shapedRipple;

  /// Badge widget over the icon's corner. For the common cases use
  /// [badgeCount] / [badgeLabel] / [badgeDot] instead.
  final Widget? badge;

  /// Shorthands that build a `GlobalBadge` for you. Passing more than
  /// one, or one of these AND [badge], asserts.
  final int? badgeCount;
  final String? badgeLabel;
  final bool badgeDot;

  /// Whether the icon responds to input.
  ///
  /// A disabled icon drops to [IconDefaults.disabledOpacity], refuses
  /// its callbacks and says so to a screen reader. Dimming it with
  /// `opacity` instead leaves the semantics announcing a button that
  /// does nothing.
  final bool enabled;

  /// What a screen reader calls this icon.
  ///
  /// [tooltip] is used when this is null — but a tooltip also makes the
  /// icon hover- and long-press-interactive, which is not what a name
  /// alone should cost.
  final String? semanticLabel;

  /// Which corner to place the badge.
  final BadgePosition badgePosition;

  /// Fine-tune badge position. Applied after the corner placement.
  final Offset badgeOffset;

  const GlobalIcon({
    super.key,
    required this.icon,
    this.style = const IconStyle(),
    this.onTap,
    this.onLongPress,
    this.tooltip,
    this.mirrorInRtl = false,
    this.shapedRipple = false,
    this.badge,
    this.badgeCount,
    this.badgeLabel,
    this.badgeDot = false,
    this.badgePosition = BadgePosition.topEnd,
    this.badgeOffset = Offset.zero,
    this.enabled = true,
    this.semanticLabel,
  }) : assert(
         (badge == null ? 0 : 1) +
                 (badgeCount == null ? 0 : 1) +
                 (badgeLabel == null ? 0 : 1) +
                 (badgeDot ? 1 : 0) <=
             1,
         'Pass at most one of badge / badgeCount / badgeLabel / badgeDot',
       );

  // ─── Convenience factories ─────────────────────────────────

  /// Simple icon with color and size.
  factory GlobalIcon.basic(
    IconData icon, {
    Key? key,
    double? size,
    Color? color,
    VoidCallback? onTap,
    String? tooltip,
    Widget? badge,
    int? badgeCount,
    String? badgeLabel,
    bool badgeDot = false,
    BadgePosition badgePosition = BadgePosition.topEnd,
    Offset badgeOffset = Offset.zero,
    bool enabled = true,
    String? semanticLabel,
    IconStyle? style,
  }) => GlobalIcon(
    key: key,
    icon: icon,
    onTap: onTap,
    tooltip: tooltip,
    badge: badge,
    badgeCount: badgeCount,
    badgeLabel: badgeLabel,
    badgeDot: badgeDot,
    badgePosition: badgePosition,
    badgeOffset: badgeOffset,
    enabled: enabled,
    semanticLabel: semanticLabel,
    // The factory's own bag is the FLOOR; anything the caller sets on
    // `style` wins. Without this a factory was all-or-nothing: reaching
    // `enableHaptic` or `padding` meant abandoning it and writing the
    // whole bag by hand.
    style: IconStyle(size: size, color: color).mergedWith(style),
  );

  /// Icon inside a circular container with background.
  factory GlobalIcon.circle(
    IconData icon, {
    Key? key,
    double size = IconDefaults.containedSize,
    double containerSize = IconDefaults.containerSize,
    Color? color,
    Color? backgroundColor,
    double backgroundOpacity = IconDefaults.backgroundOpacity,
    VoidCallback? onTap,
    String? tooltip,
    Widget? badge,
    int? badgeCount,
    String? badgeLabel,
    bool badgeDot = false,
    BadgePosition badgePosition = BadgePosition.topEnd,
    Offset badgeOffset = Offset.zero,
    bool enabled = true,
    String? semanticLabel,
    IconStyle? style,
  }) => GlobalIcon(
    key: key,
    icon: icon,
    onTap: onTap,
    tooltip: tooltip,
    badge: badge,
    badgeCount: badgeCount,
    badgeLabel: badgeLabel,
    badgeDot: badgeDot,
    badgePosition: badgePosition,
    badgeOffset: badgeOffset,
    enabled: enabled,
    semanticLabel: semanticLabel,
    // The factory's own bag is the FLOOR; anything the caller sets on
    // `style` wins. Without this a factory was all-or-nothing: reaching
    // `enableHaptic` or `padding` meant abandoning it and writing the
    // whole bag by hand.
    style: IconStyle(
      size: size,
      color: color,
      containerSize: containerSize,
      containerShape: IconContainerShape.circle,
      backgroundColor: backgroundColor,
      backgroundOpacity: backgroundOpacity,
    ).mergedWith(style),
  );

  /// Icon with a soft colored badge-style background (rounded rect).
  factory GlobalIcon.badge(
    IconData icon, {
    Key? key,
    double size = IconDefaults.containedSize,
    double containerSize = IconDefaults.containerSize,
    Color? color,
    Color? backgroundColor,
    double backgroundOpacity = IconDefaults.softBackgroundOpacity,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    String? tooltip,
    Widget? badge,
    int? badgeCount,
    String? badgeLabel,
    bool badgeDot = false,
    BadgePosition badgePosition = BadgePosition.topEnd,
    Offset badgeOffset = Offset.zero,
    bool enabled = true,
    String? semanticLabel,
    IconStyle? style,
  }) => GlobalIcon(
    key: key,
    icon: icon,
    onTap: onTap,
    tooltip: tooltip,
    badge: badge,
    badgeCount: badgeCount,
    badgeLabel: badgeLabel,
    badgeDot: badgeDot,
    badgePosition: badgePosition,
    badgeOffset: badgeOffset,
    enabled: enabled,
    semanticLabel: semanticLabel,
    // The factory's own bag is the FLOOR; anything the caller sets on
    // `style` wins. Without this a factory was all-or-nothing: reaching
    // `enableHaptic` or `padding` meant abandoning it and writing the
    // whole bag by hand.
    style: IconStyle(
      size: size,
      color: color,
      containerSize: containerSize,
      containerShape: IconContainerShape.rounded,
      backgroundColor: backgroundColor,
      backgroundOpacity: backgroundOpacity,
      borderRadius: borderRadius,
    ).mergedWith(style),
  );

  /// Icon with a gradient fill.
  factory GlobalIcon.gradient(
    IconData icon, {
    Key? key,
    double size = IconDefaults.size,
    required Gradient gradient,
    BlendMode blendMode = IconDefaults.gradientBlendMode,
    VoidCallback? onTap,
    String? tooltip,
    Widget? badge,
    int? badgeCount,
    String? badgeLabel,
    bool badgeDot = false,
    BadgePosition badgePosition = BadgePosition.topEnd,
    Offset badgeOffset = Offset.zero,
    bool enabled = true,
    String? semanticLabel,
    IconStyle? style,
  }) => GlobalIcon(
    key: key,
    icon: icon,
    onTap: onTap,
    tooltip: tooltip,
    badge: badge,
    badgeCount: badgeCount,
    badgeLabel: badgeLabel,
    badgeDot: badgeDot,
    badgePosition: badgePosition,
    badgeOffset: badgeOffset,
    enabled: enabled,
    semanticLabel: semanticLabel,
    // The factory's own bag is the FLOOR; anything the caller sets on
    // `style` wins. Without this a factory was all-or-nothing: reaching
    // `enableHaptic` or `padding` meant abandoning it and writing the
    // whole bag by hand.
    style: IconStyle(
      size: size,
      gradient: gradient,
      gradientBlendMode: blendMode,
    ).mergedWith(style),
  );

  /// Icon with an outlined border.
  factory GlobalIcon.outlined(
    IconData icon, {
    Key? key,
    double size = IconDefaults.containedSize,
    double containerSize = IconDefaults.containerSize,
    Color? color,
    // Null takes the palette's outline — `Colors.grey` before, which
    // is the same grey on a white page and a black one.
    Color? borderColor,
    double borderWidth = IconDefaults.borderWidth,
    IconContainerShape shape = IconContainerShape.rounded,
    VoidCallback? onTap,
    String? tooltip,
    Widget? badge,
    int? badgeCount,
    String? badgeLabel,
    bool badgeDot = false,
    BadgePosition badgePosition = BadgePosition.topEnd,
    Offset badgeOffset = Offset.zero,
    bool enabled = true,
    String? semanticLabel,
    IconStyle? style,
  }) => GlobalIcon(
    key: key,
    icon: icon,
    onTap: onTap,
    tooltip: tooltip,
    badge: badge,
    badgeCount: badgeCount,
    badgeLabel: badgeLabel,
    badgeDot: badgeDot,
    badgePosition: badgePosition,
    badgeOffset: badgeOffset,
    enabled: enabled,
    semanticLabel: semanticLabel,
    // The factory's own bag is the FLOOR; anything the caller sets on
    // `style` wins. Without this a factory was all-or-nothing: reaching
    // `enableHaptic` or `padding` meant abandoning it and writing the
    // whole bag by hand.
    style: IconStyle(
      size: size,
      color: color,
      containerSize: containerSize,
      containerShape: shape,
      borderColor: borderColor,
      borderWidth: borderWidth,
    ).mergedWith(style),
  );

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rs = style.resolve(context, enabled: enabled);

    // 1. The glyph, with its colour / gradient / outline.
    var content = rs.strokeWidth != null && rs.strokeWidth! > 0
        ? _buildStrokedIcon(context, rs)
        : _applyColorAndGradient(
            Icon(icon, size: rs.size, color: Colors.white),
            rs,
          );

    // 2. RTL mirroring — opt-in, see [mirrorInRtl].
    if (mirrorInRtl) {
      content = _applyRtlMirror(context, content);
    }

    // 3. A glyph swap crossfades, when asked and when motion is allowed.
    if (rs.animateIconChange && !MediaQuery.disableAnimationsOf(context)) {
      content = AnimatedSwitcher(
        duration: rs.animationDuration,
        switchInCurve: rs.animationCurve,
        switchOutCurve: rs.animationCurve,
        // Keyed on the GLYPH, not on the widget: a rebuild with the same
        // icon must not re-run the fade.
        child: KeyedSubtree(
          key: ValueKey<int>(icon.codePoint),
          child: content,
        ),
      );
    }

    // 4. Opacity. Folded into the colours when it can be — an `Opacity`
    // widget costs a `saveLayer` on what is usually a leaf in a list.
    if (rs.opacity < 1.0 && !rs.foldsOpacity) {
      content = Opacity(opacity: rs.opacity, child: content);
    }

    // 5. Container, border, tap handling.
    final hasTap = enabled && (onTap != null || onLongPress != null);
    final radius = rs.effectiveBorderRadius;
    final fill = rs.fillColor == null ? null : rs.faded(rs.fillColor!);

    if (rs.hasContainer) {
      if (rs.borderGradient != null) {
        content = _buildGradientBorderContainer(content, rs);
        // The ring is painted, so the ripple wraps outside it.
        if (hasTap) {
          content = shapedRipple
              ? _buildShapedRipple(content, rs)
              : _buildStandardTap(content, rs);
        }
      } else if (hasTap && !shapedRipple) {
        // `Ink` outside, `InkWell` inside: the ripple is clipped to the
        // container's shape instead of splashing past its corners.
        content = Material(
          type: MaterialType.transparency,
          child: Ink(
            width: rs.containerSize,
            height: rs.containerSize,
            padding: rs.padding,
            decoration: BoxDecoration(
              color: fill,
              border: rs.border,
              borderRadius: radius,
              boxShadow: rs.shadow,
            ),
            child: InkWell(
              onTap: _tapHandler(rs),
              onLongPress: _longPressHandler(rs),
              borderRadius: _insetRadius(radius, rs.border),
              child: Center(child: content),
            ),
          ),
        );
      } else {
        content = Container(
          width: rs.containerSize,
          height: rs.containerSize,
          padding: rs.padding,
          decoration: BoxDecoration(
            color: fill,
            border: rs.border,
            borderRadius: radius,
            boxShadow: rs.shadow,
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: content,
        );
        if (hasTap && shapedRipple) {
          content = _buildShapedRipple(content, rs);
        }
      }
    } else {
      if (rs.padding != null) {
        content = Padding(padding: rs.padding!, child: content);
      }
      if (hasTap) {
        content = shapedRipple
            ? _buildShapedRipple(content, rs)
            : _buildStandardTap(content, rs);
      }
    }

    // 6. Badge.
    final badgeWidget = _badgeWidget();
    if (badgeWidget != null) {
      content = _withBadge(badgeWidget, content);
    }

    // 7. Tooltip. It publishes the label on the ANCHOR too, so an
    // icon-only control is readable without opening anything.
    final named = semanticLabel ?? tooltip;
    if (tooltip != null) {
      content = GlobalTooltip(
        message: tooltip!,
        announceOnAnchor: named == null,
        child: content,
      );
    }

    // 8. Semantics. A tappable glyph is a button and needs a name — an
    // icon-only control has no other text.
    final wantsTap = onTap != null || onLongPress != null;
    if (wantsTap || named != null) {
      content = Semantics(
        button: wantsTap,
        enabled: wantsTap ? enabled : null,
        label: named,
        excludeSemantics: named != null,
        child: content,
      );
    }

    return content;
  }

  /// The badge to hang off the corner, from whichever slot was used.
  Widget? _badgeWidget() {
    if (badge != null) return badge;
    if (badgeCount != null) return GlobalBadge.standalone(count: badgeCount);
    if (badgeLabel != null) return GlobalBadge.standalone(label: badgeLabel);
    if (badgeDot) return GlobalBadge.standalone();
    return null;
  }

  /// Wraps [onTap] with the haptic the style asked for.
  VoidCallback? _tapHandler(ResolvedIconStyle rs) {
    final cb = onTap;
    if (cb == null || !enabled) return null;
    if (!rs.enableHaptic) return cb;
    return () {
      unawaited(HapticFeedback.selectionClick());
      cb();
    };
  }

  VoidCallback? _longPressHandler(ResolvedIconStyle rs) {
    final cb = onLongPress;
    if (cb == null || !enabled) return null;
    if (!rs.enableHaptic) return cb;
    return () {
      unawaited(HapticFeedback.mediumImpact());
      cb();
    };
  }

  /// Hands the badge to `GlobalBadge`.
  ///
  /// This module used to position it itself — a `Stack` with a hard
  /// -4dp overhang on every corner — and ship its own `IconBadge` dot /
  /// count / label / icon constructors, each with `Colors.red` and a
  /// white ring baked in. That was a second badge implementation
  /// standing beside a themed one.
  Widget _withBadge(Widget badgeWidget, Widget content) => GlobalBadge(
    customBadge: badgeWidget,
    position: badgePosition,
    style: BadgeStyle(offset: badgeOffset),
    child: content,
  );

  Widget _applyColorAndGradient(Widget child, ResolvedIconStyle rs) {
    if (rs.gradient == null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(rs.faded(rs.color), BlendMode.srcATop),
        child: child,
      );
    }
    // Gradient over the colour: the colour still shows wherever the
    // blend leaves it.
    return ShaderMask(
      shaderCallback: (bounds) => rs.gradient!.createShader(bounds),
      blendMode: rs.gradientBlendMode,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(rs.color, rs.gradientBlendMode),
        child: child,
      ),
    );
  }

  Widget _applyRtlMirror(BuildContext context, Widget child) {
    if (Directionality.of(context) != TextDirection.rtl) return child;
    // Some glyphs mirror THEMSELVES: `IconData.matchTextDirection` is
    // set on the directional ones in Material's set (arrows, send,
    // chevrons), and Flutter's own `Icon` flips those in RTL before we
    // see them. Flipping again turns them back round — an arrow that
    // pointed the right way in Arabic only because it had been mirrored
    // twice.
    if (icon.matchTextDirection) return child;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: child,
    );
  }

  /// The glyph, stroked.
  ///
  /// An icon is TEXT — a glyph in a font — so an outline is what a
  /// stroking `Paint` on that text does, in one rasterization. It used
  /// to be eight copies of the glyph stamped around the fill at 45°
  /// steps: nine rasterizations for a ring that showed facets at any
  /// real width, and a box padded by four times the stroke to hold
  /// stamps that only ever travelled one.
  ///
  /// `Icon` cannot do this — it has no `foreground` — so the glyph is
  /// built as `Text` here, which also means the RTL flip `Icon` does
  /// for `matchTextDirection` glyphs has to be done by hand.
  Widget _buildStrokedIcon(BuildContext context, ResolvedIconStyle rs) {
    Widget glyph(TextStyle style) => Text(
      String.fromCharCode(icon.codePoint),
      style: TextStyle(
        inherit: false,
        fontSize: rs.size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontFamilyFallback: icon.fontFamilyFallback,
        height: 1,
      ).merge(style),
      textAlign: TextAlign.center,
    );

    var stroke = glyph(
      TextStyle(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rs.strokeWidth!
          ..strokeJoin = StrokeJoin.round
          ..color = rs.faded(rs.strokeColor),
      ),
    );
    if (rs.strokeGradient != null) {
      stroke = ShaderMask(
        shaderCallback: (bounds) => rs.strokeGradient!.createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: stroke,
      );
    }

    final fill = _applyColorAndGradient(
      glyph(const TextStyle(color: Colors.white)),
      rs,
    );

    Widget stacked = Stack(
      alignment: Alignment.center,
      children: <Widget>[stroke, fill],
    );
    // `Icon` mirrors these itself; `Text` does not.
    if (icon.matchTextDirection &&
        Directionality.of(context) == TextDirection.rtl) {
      stacked = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: stacked,
      );
    }

    return SizedBox(
      width: rs.strokedSize,
      height: rs.strokedSize,
      child: Center(child: stacked),
    );
  }

  Widget _buildGradientBorderContainer(Widget child, ResolvedIconStyle rs) {
    final radius = rs.effectiveBorderRadius;
    final bw = rs.gradientBorderWidth;
    final size = rs.containerSize;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: rs.borderGradient,
        borderRadius: radius,
        boxShadow: rs.shadow,
      ),
      child: Container(
        margin: EdgeInsets.all(bw),
        padding: rs.padding,
        decoration: BoxDecoration(
          color: rs.fillColor ?? rs.gradientBorderFill,
          borderRadius: radius.subtract(BorderRadius.all(Radius.circular(bw))),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  /// Shrinks border radius by the border width so the ripple sits inside the border.
  BorderRadius _insetRadius(BorderRadius radius, BoxBorder? border) {
    if (border == null || border is! Border) return radius;
    final inset = border.top.width;
    if (inset <= 0) return radius;
    return BorderRadius.only(
      topLeft: Radius.circular(
        (radius.topLeft.x - inset).clamp(0, double.infinity),
      ),
      topRight: Radius.circular(
        (radius.topRight.x - inset).clamp(0, double.infinity),
      ),
      bottomLeft: Radius.circular(
        (radius.bottomLeft.x - inset).clamp(0, double.infinity),
      ),
      bottomRight: Radius.circular(
        (radius.bottomRight.x - inset).clamp(0, double.infinity),
      ),
    );
  }

  Widget _buildStandardTap(Widget child, ResolvedIconStyle rs) {
    final radius = rs.effectiveBorderRadius;
    return Material(
      type: MaterialType.transparency,
      borderRadius: radius,
      clipBehavior: radius != BorderRadius.zero ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: _tapHandler(rs),
        onLongPress: _longPressHandler(rs),
        borderRadius: radius,
        child: child,
      ),
    );
  }

  Widget _buildShapedRipple(Widget child, ResolvedIconStyle rs) {
    final mask = Icon(icon, size: rs.size, color: Colors.white);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: _AlphaMaskedInkWell(
            onTap: _tapHandler(rs) ?? () {},
            onLongPress: _longPressHandler(rs),
            borderRadius: rs.effectiveBorderRadius,
            maskIcon: mask,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Alpha-masked InkWell — ripple only shows on non-transparent icon pixels
// ---------------------------------------------------------------------------

class _AlphaMaskedInkWell extends StatelessWidget {
  const _AlphaMaskedInkWell({
    required this.onTap,
    this.onLongPress,
    required this.borderRadius,
    required this.maskIcon,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final Widget maskIcon;

  @override
  Widget build(BuildContext context) {
    return _MaskedRippleCompositor(
      mask: IgnorePointer(child: maskIcon),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: borderRadius,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _MaskedRippleCompositor extends MultiChildRenderObjectWidget {
  _MaskedRippleCompositor({
    required Widget mask,
    required Widget child,
  }) : super(children: [mask, child]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMaskedRipple();
}

class _MaskedRippleParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderMaskedRipple extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MaskedRippleParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MaskedRippleParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MaskedRippleParentData) {
      child.parentData = _MaskedRippleParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    var child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints.tight(size));
      final pd = child.parentData as _MaskedRippleParentData;
      pd.offset = Offset.zero;
      child = pd.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final ripple = lastChild;
    if (ripple == null) return false;
    final pd = ripple.parentData as _MaskedRippleParentData;
    return result.addWithPaintOffset(
      offset: pd.offset,
      position: position,
      hitTest: (result, transformed) =>
          ripple.hitTest(result, position: transformed),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final maskChild = firstChild;
    final rippleChild = lastChild;
    if (maskChild == null || rippleChild == null) return;

    final rect = offset & size;
    context.canvas.saveLayer(rect, Paint());
    context.paintChild(rippleChild, offset);
    context.canvas.saveLayer(rect, Paint()..blendMode = BlendMode.dstIn);
    context.paintChild(maskChild, offset);
    context.canvas.restore();
    context.canvas.restore();
  }
}
