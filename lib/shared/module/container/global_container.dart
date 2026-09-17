import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/responsive/responsive_value.dart';
import '../../../core/utils/device/info/screen_radius.dart';
import '../badge/global_badge.dart';
import '../image/global_image.dart';
import '../shimmer/global_shimmer.dart';
import '../text/global_text.dart';
import 'container_corner_scope.dart';
import 'container_models.dart';
import 'theme/container_theme.dart';

export 'container_corner_scope.dart';
export 'container_models.dart';
export 'theme/container_theme.dart';

part 'container_clamp.dart';
part 'container_content.dart';
part 'container_dismissible.dart';
part 'container_effects.dart';
part 'container_expandable.dart';
part 'container_painters.dart';
part 'container_variants.dart';

// ─── Bucket-aware width presets ─────────────────────────────────
// Used by GlobalContainer.shell / .prose / .form to clamp body
// width on tablet/desktop so reading + form lines don't stretch
// the full viewport. Compact buckets stay full-bleed.

/// App-shell preset — phones full-bleed, tablets up to 840,
/// laptops up to 1080, large up to 1200, ultrawide up to 1440.
const ResponsiveValue<double> _kShellWidths = ResponsiveValue<double>(
  compact: double.infinity,
  medium: 840,
  expanded: 1080,
  large: 1200,
  extraLarge: 1440,
);

/// Narrow reading column — comfortable line length (~70-80 ch).
const ResponsiveValue<double> _kProseWidths = ResponsiveValue<double>(
  compact: double.infinity,
  medium: 720,
  expanded: 720,
  large: 720,
  extraLarge: 720,
);

/// Form-friendly width — single column inputs.
const ResponsiveValue<double> _kFormWidths = ResponsiveValue<double>(
  compact: double.infinity,
  medium: 600,
  expanded: 600,
  large: 600,
  extraLarge: 600,
);

/// A universal styled container that replaces Card, Surface, Tile, and generic
/// styled containers. Supports gradient background, gradient border, blur/glass,
/// background image, device radius, tap/long press with ripple, header/footer
/// slots, collapsible/expandable, shimmer loading, and dark mode.
class GlobalContainer extends StatelessWidget {
  const GlobalContainer({
    super.key,
    this.child,
    this.style = const ContainerStyle(),
    this.onTap,
    this.onLongPress,
    this.header,
    this.footer,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.loading = false,
    this.enabled = true,
    this.badge,
    this.ribbon,
    this.showDragHandle = false,
    this.selected = false,
    this.onSecondaryTap,
    this.aspectRatio,
    this.isTile = false,
    this.semanticLabel,
    this.titleWidget,
    this.subtitleWidget,
  });

  // ─── Adaptive width-clamp factories ─────────────────────────
  //
  // Layout-only wrappers that center [child] under a bucket-aware
  // `maxWidth`. Compact buckets pass through full-bleed; tablets +
  // laptops clamp so reading / form lines don't stretch wide.
  // Compose **outside** the styled `GlobalContainer` body — these
  // are page-layout helpers, not styling.

  /// App-shell preset — phones full-bleed, tablets up to 840,
  /// laptops up to 1080, large up to 1200, ultrawide up to 1440.
  static Widget shell({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    Alignment alignment = Alignment.topCenter,
  }) => _BucketClamp(
    key: key,
    maxWidthByBucket: _kShellWidths,
    padding: padding,
    alignment: alignment,
    child: child,
  );

  /// Narrow reading column (~720 dp from medium upward).
  static Widget prose({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    Alignment alignment = Alignment.topCenter,
  }) => _BucketClamp(
    key: key,
    maxWidthByBucket: _kProseWidths,
    padding: padding,
    alignment: alignment,
    child: child,
  );

  /// Form-friendly column (~600 dp from medium upward).
  static Widget form({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    Alignment alignment = Alignment.topCenter,
  }) => _BucketClamp(
    key: key,
    maxWidthByBucket: _kFormWidths,
    padding: padding,
    alignment: alignment,
    child: child,
  );

  /// Custom width-clamp builder. Pick the `ResponsiveValue` yourself
  /// for non-standard layouts.
  static Widget clamped({
    Key? key,
    required Widget child,
    ResponsiveValue<double>? maxWidthByBucket,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
    Alignment alignment = Alignment.topCenter,
  }) => _BucketClamp(
    key: key,
    maxWidthByBucket: maxWidthByBucket,
    maxWidth: maxWidth,
    padding: padding,
    alignment: alignment,
    child: child,
  );

  /// Public bucket-aware widths — exposed for callers that want to
  /// echo the same clamp elsewhere (e.g. footer / header chrome).
  static const ResponsiveValue<double> shellWidths = _kShellWidths;
  static const ResponsiveValue<double> proseWidths = _kProseWidths;
  static const ResponsiveValue<double> formWidths = _kFormWidths;

  /// Content of the container.
  final Widget? child;

  /// Styling configuration.
  final ContainerStyle style;

  /// Tap callback. Adds InkWell ripple.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// Header widget above the child.
  final Widget? header;

  /// Footer widget below the child.
  final Widget? footer;

  /// Title text in header. Shorthand for a simple header.
  final String? title;

  /// Subtitle text in header.
  final String? subtitle;

  /// Leading widget in the title row (e.g. icon, avatar).
  final Widget? leading;

  /// Trailing widget in the title row (e.g. action button).
  final Widget? trailing;

  /// Shows shimmer loading placeholder instead of content.
  final bool loading;

  /// When false, dims the container and disables tap.
  final bool enabled;

  /// Badge overlay on a corner.
  final ContainerBadge? badge;

  /// Diagonal ribbon on a corner.
  final ContainerRibbon? ribbon;

  /// Shows a drag handle icon for reorderable lists.
  final bool showDragHandle;

  /// Whether this box is CHOSEN. Reported to a screen reader and, on a
  /// tile, washed with the selection tint.
  ///
  /// The base container carries it because a row that can be picked
  /// should not need a second widget wrapped round it —
  /// `GlobalSelectableContainer` is for the framed, checkmarked kind.
  final bool selected;

  /// Right-click on a desktop, or a two-finger tap. A context menu has
  /// nowhere else to hang off a card.
  final VoidCallback? onSecondaryTap;

  /// Locks the box's shape — for a media card, where the picture's
  /// proportions are the point.
  final double? aspectRatio;

  /// Lays the box out as a ROW with a minimum height a finger can hit,
  /// rather than a card that shrinks to its text.
  ///
  /// The anatomy was already here: with no `child`, the content builder
  /// makes `Row(leading, Column(title, subtitle), trailing)`, which IS
  /// a tile. It had no name, no floor and no slot sizing, so every
  /// caller reached for Material's `ListTile` instead.
  final bool isTile;

  /// A title that is not a plain string — a highlighted search match, a
  /// rich span. Wins over [title].
  ///
  /// `ListTile.title` is a Widget, so a tile factory that only takes a
  /// String is a wall: the FAQ list highlights the matched substring and
  /// had nowhere to put it.
  final Widget? titleWidget;

  /// As [titleWidget], for the second line.
  final Widget? subtitleWidget;

  /// What a screen reader calls the whole box. Null lets the content
  /// speak, which is right for a card and wrong for one whose meaning
  /// is a glyph.
  final String? semanticLabel;

  // ─── Factories ─────────────────────────────────────────────

  /// Simple card with title and content.
  factory GlobalContainer.card({
    Key? key,
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    Widget? child,
    ContainerStyle style = const ContainerStyle(),
    VoidCallback? onTap,
  }) => GlobalContainer(
    key: key,
    title: title,
    subtitle: subtitle,
    leading: leading,
    trailing: trailing,
    style: style,
    onTap: onTap,
    child: child,
  );

  /// Glass/frosted container.
  /// A ROW: leading, title over subtitle, trailing, and a floor a
  /// finger can hit.
  ///
  /// What `ListTile` is for, on this app's own surface — so a row takes
  /// the same corner, fill and press feedback as every card beside it,
  /// and a rebrand moves both.
  ///
  /// **A tile is FLAT by default**, where a card is not. A row is part
  /// of the surface it sits in; a shadow under every row of a list
  /// reads as a stack of floating cards and gives the list a texture
  /// nobody asked for. A caller who wants one says so in `style` —
  /// this is a default, not a rule.
  factory GlobalContainer.tile({
    Key? key,
    String? title,
    String? subtitle,
    Widget? titleWidget,
    Widget? subtitleWidget,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ContainerStyle style = const ContainerStyle(),
    bool selected = false,
    bool enabled = true,
    bool dense = false,
    String? semanticLabel,
  }) => GlobalContainer(
    key: key,
    title: title,
    subtitle: subtitle,
    titleWidget: titleWidget,
    subtitleWidget: subtitleWidget,
    leading: leading,
    trailing: trailing,
    onTap: onTap,
    onLongPress: onLongPress,
    selected: selected,
    enabled: enabled,
    isTile: true,
    semanticLabel: semanticLabel,
    // `const []` is a FLAT container and is not the same as null —
    // null asks for the house shadow. The caller's own `shadow` still
    // wins, because `mergedWith` lets the other side answer.
    style: const ContainerStyle(
      shadow: [],
    ).mergedWith(dense ? style.copyWith(dense: true) : style),
  );

  factory GlobalContainer.glass({
    Key? key,
    Widget? child,
    double blur = 15,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) => GlobalContainer(
    key: key,
    style: ContainerStyle(
      blur: blur,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
    ),
    child: child,
  );

  /// Container with gradient border.
  factory GlobalContainer.gradientBorder({
    Key? key,
    Widget? child,
    required Gradient gradient,
    double borderWidth = 2.0,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
  }) => GlobalContainer(
    key: key,
    style: ContainerStyle(
      borderGradient: gradient,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
    ),
    child: child,
  );

  /// Container with background image.
  factory GlobalContainer.image({
    Key? key,
    required ImageProvider image,
    Widget? child,
    BoxFit fit = BoxFit.cover,
    double imageOpacity = 1.0,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    List<BoxShadow>? shadow,
  }) => GlobalContainer(
    key: key,
    style: ContainerStyle(
      backgroundImage: image,
      backgroundImageFit: fit,
      backgroundImageOpacity: imageOpacity,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      shadow: shadow,
    ),
    child: child,
  );

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Materialized ONCE per build: every helper below reads `rs` rather
    // than re-deriving `style.x ?? cs.y` at each use, so there is one
    // place where a value can be wrong.
    final rs = style.resolve(context);
    // A SELECTED box is washed with the selection tint. It reads on a
    // row, where a border would fight the rows above and below it.
    final bg = selected
        ? Color.alphaBlend(
            context.primaryColors.primary.withValues(
              alpha: ContainerDefaults.selectedWash,
            ),
            rs.backgroundColor,
          )
        : rs.backgroundColor;
    final borderRadius = _resolveRadius(
      rs,
      scope: ContainerCornerScope.maybeOf(context),
      caller: style.borderRadius,
    );
    final hasBlur = rs.blur > 0;
    final hasBorderGradient = rs.borderGradient != null;
    final hasImage = rs.backgroundImage != null;
    final shadow = rs.shadow;
    final padding = rs.padding;

    // Build inner content
    Widget content;
    if (loading) {
      content = _buildShimmer();
    } else {
      content = _buildContent(rs);
    }

    // A TILE stands at a height a finger can hit. A card shrinks to its
    // content; a row in a list must not.
    if (isTile) {
      content = ConstrainedBox(
        constraints: BoxConstraints(minHeight: rs.tileMinHeight),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: content,
        ),
      );
    }

    // Padding
    content = Padding(padding: padding, child: content);

    // Tap / ripple
    // Two different questions. A DISABLED control is still a button to
    // a screen reader — it reports `enabled: false` rather than
    // vanishing from the tree — but it takes no ink and no press.
    final hasCallbacks =
        onTap != null || onLongPress != null || onSecondaryTap != null;
    final interactive = hasCallbacks && enabled;
    if (interactive) {
      // The RING is driven by the ink's own focus node.
      //
      // The ink owns the node, so it is the only thing that knows about
      // keyboard focus — a `Focus` of our own placed below it never
      // hears anything, because focus travels DOWN from the node that
      // has it. The same trap the bottom nav's icon reactions hit.
      //
      // There was no focus treatment here at all: a tile is the most
      // keyboard-navigable thing in the app and showed nothing but
      // `InkWell`'s default wash.
      // `inner` is NOT a tidiness thing. The builder closes over the
      // VARIABLE, and the result is assigned back to it — so a closure
      // that said `child: content` would read the `_FocusRing` it is
      // building, and build itself for ever. It does not throw: the
      // widget test HANGS.
      final inner = content;
      content = _FocusRing(
        color: rs.focusColor,
        width: rs.focusRingWidth,
        borderRadius: borderRadius,
        builder: (onFocusChange) => Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            focusColor: rs.focusColor.withValues(
              alpha: ContainerDefaults.focusWashOpacity,
            ),
            onFocusChange: onFocusChange,
            onTap: onTap == null
                ? null
                : () {
                    // Gated, and OFF by default: a list of fifty rows
                    // that all buzz is not feedback.
                    if (rs.enableHaptic) HapticFeedback.selectionClick();
                    onTap!();
                  },
            onLongPress: onLongPress,
            onSecondaryTap: onSecondaryTap,
            child: inner,
          ),
        ),
      );
    }

    // Background image overlay
    if (hasImage) {
      content = Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: hasBorderGradient
                  ? borderRadius.subtract(
                      BorderRadius.all(Radius.circular(rs.borderWidth)),
                    )
                  : borderRadius,
              child: Opacity(
                opacity: rs.backgroundImageOpacity,
                // Through `GlobalImage`, like every other picture in
                // this app. `ContainerStyle.backgroundImage` is an
                // `ImageProvider`, which the module had no entry point
                // for until `.p` — so this sat outside the adoption
                // guard for as long as it existed.
                child: GlobalImage.p(
                  rs.backgroundImage!,
                  width: double.infinity,
                  height: double.infinity,
                  style: ImageStyle(fit: rs.backgroundImageFit),
                ),
              ),
            ),
          ),
          // Dark overlay for readability
          if (rs.backgroundImageOpacity > ContainerDefaults.imageScrimThreshold)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: hasBorderGradient
                      ? borderRadius.subtract(
                          BorderRadius.all(Radius.circular(rs.borderWidth)),
                        )
                      : borderRadius,
                  color: rs.scrimColor.withValues(alpha: rs.imageScrimOpacity),
                ),
              ),
            ),
          content,
        ],
      );
    }

    final hasStyledBorder = rs.borderLineStyle != null;
    final hasInnerShadow = rs.innerShadow != null && rs.innerShadow!.isNotEmpty;
    final borderColor = rs.borderColor;

    // Inner shadow overlay (stays inside the clipped container)
    if (hasInnerShadow) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: CustomPaint(
              painter: _InnerShadowPainter(
                shadows: rs.innerShadow!,
                borderRadius: borderRadius,
              ),
            ),
          ),
        ],
      );
    }

    // Gradient border
    Widget result;
    if (hasBorderGradient) {
      result = Container(
        decoration: BoxDecoration(
          gradient: rs.borderGradient,
          borderRadius: borderRadius,
          boxShadow: shadow,
        ),
        child: Container(
          margin: EdgeInsets.all(rs.borderWidth),
          decoration: BoxDecoration(
            color: hasBlur
                ? bg.withValues(alpha: rs.blurBackgroundOpacity)
                : (hasImage
                      ? null
                      : (rs.backgroundGradient == null ? bg : null)),
            gradient: hasImage ? null : rs.backgroundGradient,
            borderRadius: borderRadius.subtract(
              BorderRadius.all(Radius.circular(rs.borderWidth)),
            ),
          ),
          clipBehavior: rs.clipBehavior,
          child: content,
        ),
      );
    } else {
      result = Container(
        decoration: BoxDecoration(
          color: hasBlur
              ? bg.withValues(alpha: rs.blurBackgroundOpacity)
              : (hasImage ? null : (rs.backgroundGradient == null ? bg : null)),
          gradient: hasImage ? null : rs.backgroundGradient,
          borderRadius: borderRadius,
          border: hasStyledBorder ? null : rs.border,
          boxShadow: shadow,
        ),
        clipBehavior: rs.clipBehavior,
        child: content,
      );
    }

    // Blur
    if (hasBlur) {
      result = ClipRRect(
        borderRadius: borderRadius,
        // WITH A SAVE LAYER. A plain antialiased clip does not contain
        // a `BackdropFilter` — the filter paints its own layer and the
        // rounded corners come back SQUARE. It only looked right while
        // an ancestor happened to be compositing already, which made
        // it a bug that appeared and disappeared with an animation.
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: rs.blur, sigmaY: rs.blur),
          child: result,
        ),
      );
    }

    // Styled border — painted OUTSIDE the clipped container so wave/zigzag aren't clipped
    if (hasStyledBorder) {
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(width: double.infinity, child: result),
          Positioned.fill(
            child: CustomPaint(
              painter: _StyledBorderPainter(
                borderRadius: borderRadius,
                color: borderColor,
                width: rs.borderWidth,
                lineStyle: rs.borderLineStyle!,
                dashWidth: rs.borderDashWidth,
                dashGap: rs.borderDashGap,
                waveAmplitude: rs.borderWaveAmplitude,
                waveFrequency: rs.borderWaveFrequency,
              ),
            ),
          ),
        ],
      );
    }

    // Size constraints
    if (rs.width != null ||
        rs.height != null ||
        rs.minHeight != null ||
        rs.maxHeight != null ||
        rs.minWidth != null ||
        rs.maxWidth != null) {
      result = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: rs.minWidth ?? 0,
          maxWidth: rs.maxWidth ?? double.infinity,
          minHeight: rs.minHeight ?? 0,
          maxHeight: rs.maxHeight ?? double.infinity,
        ),
        child: SizedBox(width: rs.width, height: rs.height, child: result),
      );
    }

    result = _applyOverlays(result, borderRadius, rs);

    // ONE node when the box is a CONTROL, and nothing when it is not.
    //
    // There was no `Semantics` in this module at all: a tappable
    // container announced whatever text happened to be inside it and
    // never that it could be pressed, or that it was disabled. A
    // DECORATIVE container gets no node of its own on purpose — a
    // styled rectangle is not something to announce, and wrapping every
    // one would put an empty container between a reader and its
    // content.
    if (aspectRatio != null) {
      result = AspectRatio(aspectRatio: aspectRatio!, child: result);
    }

    // The box SINKS under a finger. Off by default (`pressScale: 1`) —
    // a whole list of rows that all shrink is noise, but a single card
    // that is the page's one action wants it.
    if (interactive && rs.pressScale != 1) {
      result = _PressScale(
        scale: rs.pressScale,
        duration:
            rs.respectReducedMotion && MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : ContainerDefaults.selectionDuration,
        child: result,
      );
    }

    if (hasCallbacks || selected || semanticLabel != null) {
      // NO label of its own. `container: true` merges what is inside
      // into this node, so the title, the badge and the body are
      // already the label — spelling them out again gave a reader
      // "Plan, NEW" and then "Plan" and then "NEW", which is worse than
      // saying it once. That is the same rule the animation module's
      // read-out follows.
      //
      // And the content is NOT excluded, where a nav destination's is:
      // a destination's label is its whole meaning, while a card's
      // content is the point of the card.
      result = Semantics(
        container: true,
        button: hasCallbacks,
        enabled: hasCallbacks ? enabled : null,
        selected: selected ? true : null,
        label: semanticLabel,
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        child: result,
      );
    }

    return result;
  }

  // ─── Overlays ──────────────────────────────────────────────
}

// ═══════════════════════════════════════════════════════════════
// Expandable container
// ═══════════════════════════════════════════════════════════════
