import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../image/global_image.dart';
import '../shimmer/global_shimmer.dart';
import '../tooltip/global_tooltip.dart';
import 'avatar_models.dart';
import 'theme/avatar_theme.dart';

export 'avatar_models.dart';
export 'theme/avatar_theme.dart';

/// Marks the ink layer of a tappable avatar.
const kAvatarInkKey = ValueKey<String>('avatar-ink');

/// Marks the ring drawn around member [index] of a group. `DecoratedBox`
/// alone is not a usable finder — every avatar paints its own.
ValueKey<String> avatarGroupRingKey(int index) =>
    ValueKey('avatar-group-ring-$index');

/// Marks the "+N" chip of a group.
const kAvatarGroupOverflowKey = ValueKey<String>('avatar-group-overflow');

/// Pre-compiled regex for splitting name into words (avoids per-call allocation).
final _whitespaceRegex = RegExp(r'\s+');

// ---------------------------------------------------------------------------
// GlobalAvatar
// ---------------------------------------------------------------------------

class GlobalAvatar extends StatelessWidget {
  const GlobalAvatar({
    super.key,
    this.imageUrl,
    this.imageProvider,
    this.name,
    this.child,
    this.size,
    this.sizePreset,
    this.style = const AvatarStyle(),
    this.status,
    this.enabled = true,
    this.loading = false,
    this.loadingWidget,
    this.onTap,
    this.onLongPress,
    this.tooltip,
    this.semanticLabel,
    this.errorWidget,
    this.placeholderIcon,
  });

  /// Network image URL.
  final String? imageUrl;

  /// Direct image provider (asset, file, memory). Takes priority over [imageUrl].
  final ImageProvider? imageProvider;

  /// Name used to generate initials fallback and background color.
  /// First letters of up to 2 words are used (e.g. "John Doe" → "JD").
  final String? name;

  /// Custom child widget. Takes priority over image and initials.
  final Widget? child;

  /// Explicit size in logical pixels. Overrides [sizePreset].
  final double? size;

  /// Predefined size preset. Overridden by [size].
  final AvatarSize? sizePreset;

  /// Styling configuration.
  final AvatarStyle style;

  /// Status indicator configuration. Null = no status dot.
  final AvatarStatus? status;

  /// Whether the avatar is interactive.
  final bool enabled;

  /// Shows shimmer loading state.
  final bool loading;

  /// Custom loading widget.
  final Widget? loadingWidget;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// Tooltip text.
  final String? tooltip;

  /// Accessibility label.
  final String? semanticLabel;

  /// Widget shown when image fails to load.
  final Widget? errorWidget;

  /// Icon shown when no image, name, or child is provided.
  final IconData? placeholderIcon;

  double get _effectiveSize => size ?? sizePreset?.value ?? kAvatarDefaultSize;

  /// Whether this avatar displays an image (vs initials/placeholder/child).
  bool get _isImageMode =>
      !loading && child == null && (imageProvider != null || imageUrl != null);

  @override
  Widget build(BuildContext context) {
    // Materialized ONCE: caller > theme > defaults, then colours from
    // the palette. Every helper below reads this rather than re-deriving
    // a `?? Colors.white` at each use.
    final rs = style.resolve(context);
    final avatarSize = _effectiveSize;
    final borderRadius = _resolveBorderRadius(avatarSize, rs);

    Widget avatar;

    if (loading) {
      avatar = _buildLoading(avatarSize, borderRadius, rs);
    } else if (child != null) {
      avatar = _buildCustomChild(context, avatarSize, borderRadius, rs);
    } else if (imageProvider != null || imageUrl != null) {
      avatar = _buildImage(context, avatarSize, borderRadius, rs);
    } else if (name != null && name!.isNotEmpty) {
      avatar = _buildInitials(context, avatarSize, borderRadius, rs);
    } else {
      avatar = _buildPlaceholder(context, avatarSize, borderRadius, rs);
    }

    // Gradient border — shadow moves to outer wrapper to avoid double shadow
    if (style.borderGradient != null) {
      avatar = _wrapGradientBorder(avatar, avatarSize, borderRadius, rs);
    }

    // Tap
    if (onTap != null || onLongPress != null) {
      avatar = _wrapTappable(avatar, borderRadius, rs);
    }

    // Status indicator
    if (status != null && !loading) {
      avatar = _wrapStatus(context, avatar, avatarSize, rs);
    }

    // Disabled
    if (!enabled) {
      avatar = AnimatedOpacity(
        opacity: kAvatarDisabledOpacity,
        duration: kAvatarAnimDuration,
        child: avatar,
      );
    }

    // Tooltip
    if (tooltip != null) {
      avatar = GlobalTooltip(message: tooltip!, child: avatar);
    }

    // Semantics
    final hasTap = onTap != null;
    return Semantics(
      label: semanticLabel ?? name ?? 'Avatar',
      image: _isImageMode,
      button: hasTap,
      onTap: hasTap && enabled ? onTap : null,
      excludeSemantics: true,
      child: avatar,
    );
  }

  // ─── Border radius resolution ──────────────────────────────

  BorderRadius _resolveBorderRadius(double avatarSize, ResolvedAvatarStyle rs) {
    if (rs.borderRadius != null) return rs.borderRadius!;
    return switch (rs.shape) {
      AvatarShape.circle => BorderRadius.circular(avatarSize / 2),
      AvatarShape.roundedSquare => BorderRadius.circular(avatarSize * 0.2),
      AvatarShape.squircle => BorderRadius.circular(avatarSize * 0.28),
    };
  }

  // ─── Background color from name ────────────────────────────

  static Color _colorFromName(String name) {
    const palette = [
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFFE53935),
      Color(0xFF8E24AA),
      Color(0xFFFB8C00),
      Color(0xFF00ACC1),
      Color(0xFF3949AB),
      Color(0xFF7CB342),
      Color(0xFFD81B60),
      Color(0xFF6D4C41),
      Color(0xFF546E7A),
      Color(0xFFFF6F00),
    ];
    var hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return palette[hash.abs() % palette.length];
  }

  static String _initialsFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(_whitespaceRegex);
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  // ─── Decoration helper ─────────────────────────────────────

  BoxDecoration _baseDecoration(
    BuildContext context,
    double avatarSize,
    BorderRadius borderRadius,
    ResolvedAvatarStyle rs, {
    Color? bgOverride,
    bool includeShadow = true,
  }) {
    final bg =
        bgOverride ??
        (rs.backgroundGradient == null
            ? (rs.backgroundColor ??
                  (name != null
                      ? _colorFromName(name!)
                      : context.primaryColors.primary))
            : null);

    return BoxDecoration(
      color: bg,
      gradient: rs.backgroundGradient,
      // Behind the content, not instead of it: initials, a placeholder
      // icon or a custom child still paint on top.
      image: rs.backgroundImage,
      borderRadius: borderRadius,
      border: rs.borderGradient == null ? rs.border : null,
      boxShadow: includeShadow ? rs.shadow : null,
    );
  }

  // ─── Builders ──────────────────────────────────────────────

  Widget _buildImage(
    BuildContext context,
    double avatarSize,
    BorderRadius borderRadius,
    ResolvedAvatarStyle rs,
  ) {
    final provider = imageProvider ?? NetworkImage(imageUrl!);

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: _baseDecoration(context, avatarSize, borderRadius, rs),
      clipBehavior: Clip.antiAlias,
      // Through `GlobalImage`, like every other picture in this app. An
      // avatar's `backgroundImage` is an `ImageProvider` handed in by
      // the caller, which the module had no entry point for until `.p`.
      //
      // The fallback stays an avatar's own business: a picture that
      // will not load falls back to the INITIALS, which no generic
      // error plate knows about.
      child: GlobalImage.p(
        provider,
        width: avatarSize,
        height: avatarSize,
        style: const ImageStyle(fit: BoxFit.cover),
        placeholder: GlobalShimmer.placeholder(
          width: avatarSize,
          height: avatarSize,
          borderRadius: borderRadius,
          shape: rs.shape == AvatarShape.circle
              ? ShimmerShape.circle
              : ShimmerShape.rounded,
        ),
        errorWidget: name != null && name!.isNotEmpty
            ? _buildInitialsContent(context, avatarSize, rs)
            : errorWidget ?? _buildPlaceholderContent(context, avatarSize, rs),
      ),
    );
  }

  Widget _buildInitials(
    BuildContext context,
    double avatarSize,
    BorderRadius borderRadius,
    ResolvedAvatarStyle rs,
  ) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: _baseDecoration(context, avatarSize, borderRadius, rs),
      clipBehavior: Clip.antiAlias,
      child: Center(child: _buildInitialsContent(context, avatarSize, rs)),
    );
  }

  Widget _buildInitialsContent(
    BuildContext context,
    double avatarSize,
    ResolvedAvatarStyle rs,
  ) {
    final initials = _initialsFromName(name!);
    final fg = rs.foregroundColor;
    final fontSize = avatarSize * rs.initialsFontRatio;

    return Text(
      initials,
      style:
          rs.initialsStyle ??
          TextStyle(
            color: fg,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    double avatarSize,
    BorderRadius borderRadius,
    ResolvedAvatarStyle rs,
  ) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: _baseDecoration(
        context,
        avatarSize,
        borderRadius,
        rs,
        bgOverride: rs.backgroundColor ?? rs.placeholderBackground,
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: _buildPlaceholderContent(context, avatarSize, rs)),
    );
  }

  Widget _buildPlaceholderContent(
    BuildContext context,
    double avatarSize,
    ResolvedAvatarStyle rs,
  ) {
    final fg = rs.placeholderForeground;
    return Icon(
      placeholderIcon ?? Icons.person_rounded,
      size: avatarSize * 0.55,
      color: fg,
    );
  }

  Widget _buildCustomChild(
    BuildContext context,
    double avatarSize,
    BorderRadius borderRadius,
    ResolvedAvatarStyle rs,
  ) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: _baseDecoration(context, avatarSize, borderRadius, rs),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
  }

  Widget _buildLoading(
    double avatarSize,
    BorderRadius borderRadius,
    ResolvedAvatarStyle rs,
  ) {
    if (loadingWidget != null) {
      return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: loadingWidget,
      );
    }
    return GlobalShimmer.placeholder(
      width: avatarSize,
      height: avatarSize,
      borderRadius: borderRadius,
      shape: rs.shape == AvatarShape.circle
          ? ShimmerShape.circle
          : ShimmerShape.rounded,
    );
  }

  // ─── Gradient border wrapper ───────────────────────────────

  Widget _wrapGradientBorder(
    Widget avatar,
    double avatarSize,
    BorderRadius borderRadius,
    ResolvedAvatarStyle rs,
  ) {
    final bw = rs.borderWidth;
    return Container(
      width: avatarSize + bw * 2,
      height: avatarSize + bw * 2,
      decoration: BoxDecoration(
        gradient: rs.borderGradient,
        borderRadius: _inflateRadius(borderRadius, bw),
        boxShadow: rs.shadow,
      ),
      child: Center(child: avatar),
    );
  }

  BorderRadius _inflateRadius(BorderRadius radius, double amount) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius.topLeft.x + amount),
      topRight: Radius.circular(radius.topRight.x + amount),
      bottomLeft: Radius.circular(radius.bottomLeft.x + amount),
      bottomRight: Radius.circular(radius.bottomRight.x + amount),
    );
  }

  // ─── Tap wrapper ───────────────────────────────────────────

  /// Puts the ink layer ON TOP of the avatar.
  ///
  /// A `Material` paints its ink BEHIND its child, and an avatar's whole
  /// job is to paint an opaque circle — so the old
  /// `Material(child: InkWell(child: avatar))` produced a ripple that
  /// was always hidden under the face. Taps worked; nothing was ever
  /// visible. The InkWell is stacked over the avatar instead, with a
  /// transparent Material of its own, so the splash lands above the
  /// paint it is meant to respond to.
  ///
  /// `customBorder`, not `borderRadius`: a circle clipped by a
  /// same-radius rectangle still leaks ink at the corners.
  Widget _wrapTappable(
    Widget avatar,
    BorderRadius borderRadius,
    ResolvedAvatarStyle rs,
  ) {
    final shape = rs.shape == AvatarShape.circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: borderRadius);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: kAvatarInkKey,
              onTap: enabled ? onTap : null,
              onLongPress: enabled ? onLongPress : null,
              customBorder: shape,
              splashColor: rs.splashColor,
              highlightColor: rs.highlightColor,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Status indicator ──────────────────────────────────────

  Widget _wrapStatus(
    BuildContext context,
    Widget avatar,
    double avatarSize,
    ResolvedAvatarStyle rs,
  ) {
    final st = status!;
    final dotSize = st.size ?? avatarSize * kAvatarStatusSizeRatio;
    // The ring lifts the dot off the avatar, so it matches the PAGE.
    final borderColor = st.borderColor ?? context.backgroundColors.background;
    final hasBorderGradient = rs.borderGradient != null;
    final totalSize = hasBorderGradient
        ? avatarSize + rs.borderWidth * 2
        : avatarSize;

    var dot =
        st.customWidget ??
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: st.resolveColor(),
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: st.borderWidth),
          ),
        );

    // A presence dot pulses FOREVER rather than settling, which is
    // exactly the motion `disableAnimations` exists to stop. The dot
    // still paints — it is the status, not the decoration; only the
    // pulse goes.
    if (st.pulsate && !MediaQuery.disableAnimationsOf(context)) {
      dot = _PulsatingDot(key: kAvatarPulseKey, child: dot);
    }

    // Adjust offset for gradient border so dot stays at the visual edge
    final baseOffset = dotSize * kAvatarStatusInsetRatio;
    final borderAdjust = hasBorderGradient ? rs.borderWidth : 0.0;
    final offset = baseOffset + borderAdjust;

    final positioned = switch (st.position) {
      AvatarStatusPosition.bottomRight => Positioned(
        bottom: offset,
        right: offset,
        child: dot,
      ),
      AvatarStatusPosition.bottomLeft => Positioned(
        bottom: offset,
        left: offset,
        child: dot,
      ),
      AvatarStatusPosition.topRight => Positioned(
        top: offset,
        right: offset,
        child: dot,
      ),
      AvatarStatusPosition.topLeft => Positioned(
        top: offset,
        left: offset,
        child: dot,
      ),
    };

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [avatar, positioned],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GlobalAvatarGroup
// ---------------------------------------------------------------------------

/// Displays a row of overlapping avatars with a "+N" overflow indicator.
class GlobalAvatarGroup extends StatelessWidget {
  const GlobalAvatarGroup({
    super.key,
    required this.avatars,
    this.maxVisible = kAvatarGroupMaxVisible,
    this.overlapFraction = kAvatarGroupOverlap,
    this.size,
    this.sizePreset,
    this.style = const AvatarStyle(),
    this.overflowStyle,
    this.overflowTextStyle,
    this.borderColor,
    this.borderWidth = kAvatarDefaultBorderWidth,
    this.onTap,
    this.onOverflowTap,
  });

  /// List of avatars to display.
  final List<GlobalAvatar> avatars;

  /// Max number of visible avatars. Additional ones show as "+N".
  final int maxVisible;

  /// Fraction of avatar diameter that overlaps (0.0–1.0).
  final double overlapFraction;

  /// Size override for all avatars.
  final double? size;

  /// Size preset for all avatars.
  final AvatarSize? sizePreset;

  /// Style applied to all avatars.
  final AvatarStyle style;

  /// Style for the overflow "+N" indicator.
  final AvatarStyle? overflowStyle;

  /// Text style for the overflow count.
  final TextStyle? overflowTextStyle;

  /// Border color between stacked avatars. Defaults to scaffold background.
  final Color? borderColor;

  /// Border width between stacked avatars.
  final double borderWidth;

  /// Called when any avatar is tapped (passes index).
  final ValueChanged<int>? onTap;

  /// Called when the overflow "+N" indicator is tapped.
  final VoidCallback? onOverflowTap;

  @override
  Widget build(BuildContext context) {
    // Resolved ONCE, exactly like a single avatar. Reading the RAW bag
    // here was the bug behind every square ring in the showcase: after
    // `AvatarStyle` went nullable, a caller's `const AvatarStyle()`
    // carries `shape: null`, so `style.shape == AvatarShape.circle` was
    // false and the group drew rectangles around circular faces.
    final rs = style.resolve(context);
    final avatarSize = size ?? sizePreset?.value ?? kAvatarDefaultSize;
    final isCircle = rs.shape == AvatarShape.circle;
    final radius = isCircle
        ? null
        : (rs.borderRadius ?? BorderRadius.circular(avatarSize * 0.2));

    // The ring matches the PAGE, same as the presence dot's — that is
    // what separates two overlapping faces instead of drawing a line
    // onto one of them. `scaffoldBackgroundColor` was close by accident
    // and wrong on any tinted surface.
    final ringColor = borderColor ?? context.backgroundColors.background;

    final visibleCount = avatars.length > maxVisible
        ? maxVisible
        : avatars.length;
    final overflowCount = avatars.length - visibleCount;
    final step = avatarSize * (1 - overlapFraction);
    final totalCount = visibleCount + (overflowCount > 0 ? 1 : 0);
    final totalWidth = totalCount == 0
        ? 0.0
        : avatarSize + (totalCount - 1) * step;

    Decoration ringFor(Color? fill, Gradient? gradient) => BoxDecoration(
      color: fill,
      gradient: gradient,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: radius,
      border: Border.all(color: ringColor, width: borderWidth),
    );

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Painted FIRST, so the last visible face overlaps it.
          // Everything else tucks under the face to its start side, and
          // the chip used to be the one element that broke that rule —
          // it sat on top and ate a third of the last avatar.
          if (overflowCount > 0)
            PositionedDirectional(
              start: visibleCount * step,
              child: Semantics(
                button: onOverflowTap != null,
                label: AvatarStrings.moreCount(overflowCount),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onOverflowTap,
                  child: Container(
                    key: kAvatarGroupOverflowKey,
                    width: avatarSize,
                    height: avatarSize,
                    alignment: Alignment.center,
                    decoration: ringFor(
                      overflowStyle?.backgroundColor ??
                          context.backgroundColors.outline.withValues(
                            alpha: kAvatarGroupOverflowOpacity,
                          ),
                      overflowStyle?.backgroundGradient,
                    ),
                    child: Text(
                      '+$overflowCount',
                      style:
                          overflowTextStyle ??
                          TextStyle(
                            fontSize:
                                avatarSize * kAvatarGroupOverflowFontRatio,
                            fontWeight: FontWeight.w700,
                            color:
                                overflowStyle?.foregroundColor ??
                                context.textColors.primary,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          // Reverse order, so avatar 0 paints LAST and sits on top: the
          // row reads front-to-back from its start edge.
          for (var i = visibleCount - 1; i >= 0; i--)
            PositionedDirectional(
              // Directional: `Positioned(left:)` stacked the row the
              // wrong way round in Arabic, against the overflow chip
              // that had been placed from the same edge.
              start: i * step,
              child: DecoratedBox(
                key: avatarGroupRingKey(i),
                decoration: ringFor(null, null),
                child: _memberOf(i, avatarSize),
              ),
            ),
        ],
      ),
    );
  }

  /// Rebuilds avatar [i] at the group's size.
  ///
  /// It carries the member's OWN properties across — status, tooltip,
  /// loading, semantics. The group used to copy four fields and drop
  /// the rest, so a presence dot handed to a group silently vanished.
  Widget _memberOf(int i, double avatarSize) {
    final member = avatars[i];
    return GlobalAvatar(
      imageUrl: member.imageUrl,
      imageProvider: member.imageProvider,
      name: member.name,
      // The ring is drawn OUTSIDE the face, so the face has to give up
      // room for it or the row grows by two pixels a head.
      size: avatarSize - borderWidth * 2,
      // The group's style is the base; a member's own bag overrides it
      // field by field, which is how one face in a row can differ.
      style: style.mergedWith(member.style),
      status: member.status,
      enabled: member.enabled,
      loading: member.loading,
      loadingWidget: member.loadingWidget,
      tooltip: member.tooltip,
      semanticLabel: member.semanticLabel,
      errorWidget: member.errorWidget,
      placeholderIcon: member.placeholderIcon,
      // A member's own tap wins; the group's index callback is the
      // fallback. Routed through GlobalAvatar rather than a bare
      // GestureDetector so a tap in a group ripples and announces
      // itself exactly like a tap on a lone avatar.
      onTap: member.onTap ?? (onTap != null ? () => onTap!(i) : null),
      onLongPress: member.onLongPress,
      child: member.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsating dot animation
// ---------------------------------------------------------------------------

class _PulsatingDot extends StatefulWidget {
  const _PulsatingDot({super.key, required this.child});
  final Widget child;

  @override
  State<_PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<_PulsatingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: kAvatarPulseDuration,
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 1,
      end: kAvatarPulseMinOpacity,
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
        scale: 1.0 + _ctrl.value * (kAvatarPulseScale - 1),
        child: FadeTransition(
          opacity: _opacity,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
