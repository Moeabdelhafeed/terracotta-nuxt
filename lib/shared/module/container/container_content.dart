part of 'global_container.dart';

// What a `GlobalContainer` puts INSIDE its box: the title row, the
// badge, the ribbon, the loading placeholder, the corner and the
// overlays. An extension rather than a second class, so it still reads
// `_buildContent(rs)` at the call site and still sees every field.
//
// Split out because the widget file had grown to 2122 lines against
// this repo's own "prefer splitting over 400" rule.
extension _ContainerContent on GlobalContainer {
  Widget _applyOverlays(
    Widget result,
    BorderRadius borderRadius,
    ResolvedContainerStyle rs,
  ) {
    if (showDragHandle) {
      result = Stack(
        children: [
          SizedBox(width: double.infinity, child: result),
          Positioned(
            top: 0,
            bottom: 0,
            right: ContainerDefaults.checkmarkOffset,
            child: Center(
              child: Icon(
                Icons.drag_handle_rounded,
                size: ContainerDefaults.dragHandleSize,
                color: rs.onSurfaceColor.withValues(
                  alpha: ContainerDefaults.dragHandleOpacity,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (rs.innerShadowGradient != null) {
      result = Stack(
        children: [
          SizedBox(width: double.infinity, child: result),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: CustomPaint(
                painter: _GradientInnerShadowPainter(
                  gradient: rs.innerShadowGradient!,
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (ribbon != null) {
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(width: double.infinity, child: result),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(children: [_buildRibbon(ribbon!, rs)]),
            ),
          ),
        ],
      );
    }

    if (rs.margin != null) {
      result = Padding(padding: rs.margin!, child: result);
    }

    if (badge != null) {
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(width: double.infinity, child: result),
          _buildBadge(badge!, rs),
        ],
      );
    }

    if (!enabled) {
      result = Opacity(opacity: 0.5, child: result);
    }

    return result;
  }

  // ─── Radius ───────────────────────────────────────────────

  BorderRadius _resolveRadius(
    ResolvedContainerStyle rs, {
    BorderRadius? scope,
    BorderRadius? caller,
  }) {
    // The CALLER'S OWN bag first: being explicit outranks the run a
    // container happens to sit in.
    if (caller != null) return caller;
    // Then a `ContainerCornerScope` — a list rounding its rows as one
    // card. It cannot be done by clipping, because a square clip does
    // not reach the rounded background the tile paints inside it.
    //
    // It has to beat the RESOLVED value, not just a null one: the app
    // theme answers `borderRadius` for every container, so a scope
    // that only applied when nothing else had was a scope that never
    // applied at all.
    if (scope != null) return scope;
    if (rs.borderRadius != null) return rs.borderRadius!;
    if (rs.useDeviceRadius && DeviceRadius.hasRoundedCorners) {
      return DeviceRadius.borderRadiusPadded;
    }
    return BorderRadius.circular(ContainerDefaults.radius);
  }

  // ─── Content builder ──────────────────────────────────────

  Widget _buildContent(ResolvedContainerStyle rs) {
    final hasTitle =
        title != null ||
        subtitle != null ||
        titleWidget != null ||
        subtitleWidget != null ||
        leading != null ||
        trailing != null;
    final hasHeader = header != null;
    final hasFooter = footer != null;

    if (!hasTitle && !hasHeader && !hasFooter) {
      return child ?? const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Custom header
        if (hasHeader) ...[
          header!,
          const SizedBox(height: ContainerDefaults.headerGap),
        ],

        // Title row
        if (hasTitle) ...[
          Row(
            children: [
              if (leading != null) ...[
                // BOXED, so an oversized glyph cannot set the row's
                // height — the same thing `ListTile` does to its own
                // slots. Only on a tile: a card's header can be
                // whatever the caller put there.
                if (isTile) _slot(rs, leading!) else leading!,
                const SizedBox(width: ContainerDefaults.headerGap),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (titleWidget != null)
                      titleWidget!
                    else if (title != null)
                      GlobalText(
                        title!,
                        // Preset instead of a literal size: GlobalText
                        // resolves it from the type scale, so the card
                        // header follows the font-size preference.
                        preset: TextPreset.bodyLarge,
                        textStyle: GlobalTextStyle(
                          fontWeight: FontWeight.w600,
                          color: rs.onSurfaceColor,
                        ),
                      ),
                    if (subtitleWidget != null)
                      subtitleWidget!
                    else if (subtitle != null)
                      GlobalText(
                        subtitle!,
                        preset: TextPreset.bodySmall,
                        textStyle: GlobalTextStyle(
                          color: rs.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                if (isTile) _slot(rs, trailing!) else trailing!,
            ],
          ),
          if (child != null)
            const SizedBox(height: ContainerDefaults.headerGap),
        ],

        // Child content
        ?child,

        // Footer
        if (hasFooter) ...[
          const SizedBox(height: ContainerDefaults.footerGap),
          footer!,
        ],
      ],
    );
  }

  // ─── Badge builder ────────────────────────────────────────

  /// The corner badge, through `GlobalBadge`.
  ///
  /// It was hand-rolled: a `Container` with a circle or a pill
  /// decoration and a `Text` inside, so a count on a card did not match
  /// a count on a tab, a destination or a drawer row — the four
  /// surfaces `test/badge/badge_adoption_test.dart` already holds
  /// together. Only the two shapes `GlobalBadge` does not offer stay
  /// local: an arbitrary widget, which is the caller's own, and an ICON
  /// badge sized by `ContainerBadge.size`.
  Widget _buildBadge(ContainerBadge b, ResolvedContainerStyle rs) {
    final color = b.color ?? rs.badgeColor;
    final foreground = b.textColor ?? rs.onBadgeColor;
    final size = b.size ?? ContainerDefaults.badgeSize;
    final badgeStyle = BadgeStyle(
      backgroundColor: color,
      foregroundColor: foreground,
      size: b.size,
      dotSize: b.size == null ? null : b.size! / 2,
    );

    final Widget badgeWidget;
    if (b.widget != null) {
      badgeWidget = b.widget!;
    } else if (b.icon != null) {
      // `GlobalBadge` has no icon-in-a-disc form; this one keeps its own.
      badgeWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Icon(
            b.icon,
            size: ContainerDefaults.badgeIconSize,
            color: foreground,
          ),
        ),
      );
    } else if (b.text != null) {
      badgeWidget = GlobalBadge.standalone(label: b.text, style: badgeStyle);
    } else {
      badgeWidget = GlobalBadge.standalone(style: badgeStyle);
    }

    final dx = b.offset.dx + ContainerDefaults.badgeOffset;
    final dy = b.offset.dy + ContainerDefaults.badgeOffset;

    switch (b.position) {
      case ContainerBadgePosition.topRight:
        return Positioned(top: dy, right: dx, child: badgeWidget);
      case ContainerBadgePosition.topLeft:
        return Positioned(top: dy, left: dx, child: badgeWidget);
      case ContainerBadgePosition.bottomRight:
        return Positioned(bottom: dy, right: dx, child: badgeWidget);
      case ContainerBadgePosition.bottomLeft:
        return Positioned(bottom: dy, left: dx, child: badgeWidget);
    }
  }

  /// The corner ribbon, SIZED FROM THE CORNER.
  ///
  /// It used to be a fixed 80x20 band rotated about its own centre and
  /// offset sixteen points in — geometry that has no idea how big the
  /// box is. On a card a line or two tall the band is most of the card,
  /// so it crossed the text instead of the corner, and its ends stopped
  /// short of the edges rather than running into them.
  ///
  /// A corner band at forty-five degrees whose ends land on the two
  /// edges at distance `d` from the corner has a chord of `d * sqrt(2)`.
  /// Taking `d` from the box's own SHORT side is what makes it scale: a
  /// tall card gets a generous banner, a one-line card gets a small one,
  /// and both cross the corner rather than the content.
  Widget _buildRibbon(ContainerRibbon r, ResolvedContainerStyle rs) {
    final color = r.color ?? rs.badgeColor;
    final foreground = r.textColor ?? rs.onBadgeColor;
    final isRight = r.position == ContainerRibbonPosition.topRight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final short = math.min(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : ContainerDefaults.ribbonWidth,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : ContainerDefaults.ribbonWidth,
        );

        // How far down each edge the band's ends land. Clamped so a
        // huge card does not grow a banner across half of it, and a
        // tiny one still gets something legible.
        final reach = (short * ContainerDefaults.ribbonReachFactor).clamp(
          ContainerDefaults.ribbonMinReach,
          ContainerDefaults.ribbonMaxReach,
        );
        final band = reach * math.sqrt2;
        final height = (band * ContainerDefaults.ribbonHeightFactor).clamp(
          ContainerDefaults.ribbonMinHeight,
          ContainerDefaults.ribbonHeight,
        );

        // The band's CENTRE sits on the corner's diagonal, `reach / 2`
        // in along each edge — which is what puts its two ends ON the
        // edges rather than past them.
        //
        // The two offsets are NOT the same number. The box is long and
        // thin, so centring it horizontally means backing off half its
        // CHORD and centring it vertically half its THICKNESS. Using one
        // inset for both — which the first version did — pushes the band
        // out along the top edge by the difference, and it reads as a
        // tag hanging off the corner instead of crossing it.
        final acrossInset = reach / 2 - band / 2;
        final downInset = reach / 2 - height / 2;

        // The `Positioned` needs a `Stack` of its OWN: this builder is
        // the outer stack's child, so a `Positioned` returned straight
        // from here is not a direct child of it and Flutter throws
        // "Incorrect use of ParentDataWidget" on every frame.
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: downInset,
              right: isRight ? acrossInset : null,
              left: isRight ? null : acrossInset,
              width: band,
              height: height,
              child: Transform.rotate(
                angle: isRight
                    ? ContainerDefaults.ribbonAngle
                    : -ContainerDefaults.ribbonAngle,
                child: Container(
                  alignment: Alignment.center,
                  color: color,
                  child: Text(
                    r.text,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: r.fontSize,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// A leading or trailing slot: a MINIMUM box, not a clamp.
  ///
  /// A hard `SizedBox(40)` gives the row an even rhythm and also
  /// squeezes anything legitimately wider than a glyph — a
  /// `GlobalSwitch` is about sixty points across, so every setting row
  /// overflowed by exactly twenty. `ListTile` constrains its slots the
  /// same way: a floor so a small icon still reserves a target, and no
  /// ceiling, because a control knows its own size.
  Widget _slot(ResolvedContainerStyle rs, Widget child) => ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: rs.slotSize,
      minHeight: rs.slotSize,
    ),
    child: Center(widthFactor: 1, heightFactor: 1, child: child),
  );

  /// The loading placeholder, which FITS.
  ///
  /// It was a fixed three-line `Column` of about 145 points, so a
  /// caller who said `height: 120` — which the showcase does — got a
  /// yellow-and-black stripe instead of a placeholder. Below what the
  /// three lines need it degrades to ONE bar filling the box, which
  /// still says "this is loading" and cannot overflow. Same rule the
  /// animation module's error plate follows.
  Widget _buildShimmer() => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.hasBoundedHeight &&
          constraints.maxHeight < ContainerDefaults.shimmerFullHeight) {
        return GlobalShimmer.placeholder(
          width: double.infinity,
          height: constraints.maxHeight,
          borderRadius: BorderRadius.circular(8),
        );
      }
      return _buildShimmerColumn();
    },
  );

  Widget _buildShimmerColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GlobalShimmer.text(
          width: ContainerDefaults.shimmerTitleWidth,
          height: ContainerDefaults.shimmerTitleHeight,
        ),
        const SizedBox(height: ContainerDefaults.shimmerGap),
        GlobalShimmer.placeholder(
          width: double.infinity,
          height: ContainerDefaults.shimmerBodyHeight,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: ContainerDefaults.shimmerGap),
        GlobalShimmer.text(
          width: ContainerDefaults.shimmerTitleWidth * 0.7,
          height: ContainerDefaults.shimmerTitleHeight * 0.8,
        ),
      ],
    );
  }
}
