import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/strings/module_strings.dart';
import 'indicator_math.dart';
import 'indicator_models.dart';
import 'indicator_style.dart';
import 'theme/indicator_theme.dart';

export 'indicator_math.dart';
export 'indicator_models.dart';
export 'indicator_style.dart';
export 'theme/indicator_theme.dart';

/// Animated page-indicator dot row. Pick a [DotIndicatorEffect] for
/// how the active state moves between positions:
///   * `scale` — active dot grows + tints (classic)
///   * `worm` — active dot stretches into a pill toward the next
///   * `expanding` — active pill shrinks back, next pill expands
///   * `slide` — marker pill slides across static dots
///   * `jumping` — dot bounces in an arc between cells
///   * `color` — color-only swap, no size change
///   * `scrollingDots` — strip scrolls so active sits centered
///   * `swap` — old + new dot trade colors mid-flight
///
/// Drives off [count] + [activeIndex]. Each effect interpolates over
/// [DotIndicatorStyle.duration] using [DotIndicatorStyle.curve].
/// An arrow on a dot row: move by [delta] pages.
class _MoveIntent extends Intent {
  const _MoveIntent(this.delta);
  final int delta;
}

/// Home / End.
class _EdgeIntent extends Intent {
  const _EdgeIntent({required this.last});
  final bool last;
}

class GlobalDotIndicator extends StatefulWidget {
  const GlobalDotIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
    this.continuousIndex,
    this.effect = DotIndicatorEffect.scale,
    this.style,
    this.onTap,
    this.onHover,
    this.itemBuilder,
    this.axis = Axis.horizontal,
  }) : assert(count > 0, 'count must be > 0');

  /// Number of dots in the row.
  final int count;

  /// 0-based active dot. Out-of-range values are clamped at render
  /// time. Used for snap-style transitions — the indicator runs its
  /// internal AnimationController from the previous index to this
  /// one over `style.duration`.
  final int activeIndex;

  /// When non-null, the indicator skips its internal animation and
  /// reads this fractional position each frame. Pass
  /// `pageController.page` (wrapped in an [AnimatedBuilder] /
  /// `ListenableBuilder`) to sync the indicator perfectly with a
  /// swipe in progress.
  final double? continuousIndex;

  final DotIndicatorEffect effect;

  /// The caller's half of `caller > GlobalIndicatorTheme.dotStyle >
  /// DotIndicatorStyle.defaults`.
  final DotIndicatorStyle? style;

  /// Tap handler. Null = non-interactive.
  final ValueChanged<int>? onTap;

  /// Pointer hover handler — fires with the hovered dot index when
  /// the cursor enters one, and `null` when it leaves the indicator
  /// region. Pointer-driven only (touch has no hover). Used by
  /// `GlobalPageView`'s hover-peek mode.
  final ValueChanged<int?>? onHover;

  /// Custom per-dot widget builder. When set, replaces the default
  /// dot shape entirely — caller can render any widget (icon, emoji,
  /// image, label) per position. Receives the index, the boolean
  /// "is currently active" flag, and a 0..1 `activeness` value for
  /// smooth in-flight rendering (lets you e.g. lerp icon colors
  /// during a transition).
  ///
  /// Active state still drives motion via [effect] — the builder
  /// only swaps the rendered widget at each position. Most effects
  /// (worm / slide / jumping / scrollingDots) ignore `itemBuilder`
  /// because their motion overlays bear no relation to per-dot
  /// content. Scale / color / swap / morph / rotate / flash / drop
  /// / bounce / splash / chain use it.
  final Widget Function(
    BuildContext context,
    int index,
    bool isActive,
    double activeness,
  )?
  itemBuilder;

  /// Lay the dots horizontally (left → right) or vertically
  /// (top → bottom). Vertical mode wraps the horizontal layout in
  /// `RotatedBox(quarterTurns: 1)`, so every effect — including the
  /// directional ones (slide / drop / worm) — runs along the
  /// resulting axis without bespoke per-effect plumbing.
  final Axis axis;

  @override
  State<GlobalDotIndicator> createState() => _GlobalDotIndicatorState();
}

class _GlobalDotIndicatorState extends State<GlobalDotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late int _from;
  late int _to;

  /// Resolved in `didChangeDependencies`, never in `initState`: the
  /// palette and the reader's reduce-motion setting are inherited
  /// reads, and the controller's duration comes from them.
  late ResolvedDotIndicatorStyle style;

  @override
  void initState() {
    super.initState();
    _from = widget.activeIndex.clamp(0, widget.count - 1);
    _to = _from;
    _ctrl = AnimationController(vsync: this, value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    style = (widget.style ?? const DotIndicatorStyle()).resolve(context);
    _ctrl.duration = style.duration;
  }

  @override
  void didUpdateWidget(covariant GlobalDotIndicator old) {
    super.didUpdateWidget(old);
    if (widget.style != old.style) {
      style = (widget.style ?? const DotIndicatorStyle()).resolve(context);
    }
    _ctrl.duration = style.duration;

    final clamped = widget.activeIndex.clamp(0, widget.count - 1);
    if (clamped != _to) {
      _from = _to;
      _to = clamped;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (style.enableHaptic) HapticFeedback.selectionClick();
    widget.onTap?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final active = style.activeColor;
    final inactive = style.inactiveColor;

    // One height for EVERY effect, so swapping one for another — or
    // running the jumping arc — does not push what is above and below
    // it up and down.
    final reservedHeight = style.reservedHeight;

    Widget body;
    // Continuous mode: caller drives position with a fractional value
    // (typically pageController.page). Skip the internal controller
    // and derive from/to/t from the fractional index directly so the
    // indicator stays perfectly in sync with the swipe.
    if (widget.continuousIndex != null) {
      final raw = widget.continuousIndex!.clamp(0.0, widget.count - 1.0);
      _from = raw.floor();
      _to = raw.ceil().clamp(0, widget.count - 1);
      final t = _from == _to ? 1.0 : (raw - _from);
      body = _buildForEffect(active: active, inactive: inactive, t: t);
    } else {
      body = AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = style.curve.transform(_ctrl.value);
          return _buildForEffect(active: active, inactive: inactive, t: t);
        },
      );
    }

    Widget laid = SizedBox(
      height: reservedHeight,
      child: Center(child: body),
    );
    // Pointer-driven hover dispatch — divides the indicator's
    // horizontal extent into `count` equal zones (we don't try to
    // hit-test individual dots because effects like slide / worm /
    // scrollingDots make per-dot bounds unstable).
    if (widget.onHover != null) {
      // Held BEFORE the reassignment.
      //
      // A closure captures the variable, not its value — so a builder
      // that read `laid` read whatever `laid` had become by the time
      // it ran, which is this very `LayoutBuilder`. It nested itself
      // forever: `MouseRegion > LayoutBuilder > MouseRegion > …` until
      // layout threw. Hover has been dead since it was written, and
      // nothing exercised it.
      final hovered = laid;
      laid = LayoutBuilder(
        builder: (ctx, c) {
          return MouseRegion(
            onExit: (_) => widget.onHover!.call(null),
            onHover: (event) {
              final extent = c.maxWidth;
              if (extent <= 0) return;
              final idx = ((event.localPosition.dx / extent) * widget.count)
                  .floor()
                  .clamp(0, widget.count - 1);
              widget.onHover!.call(idx);
            },
            child: hovered,
          );
        },
      );
    }
    // Vertical mode: rotate 90° CW so the row reads top → bottom.
    // Tap hit-testing rotates with the visual, so dot indices map
    // correctly. Every effect — including overlay motion (worm,
    // slide, drop, jumping) — runs along the new axis for free.
    if (widget.axis == Axis.vertical) {
      laid = RotatedBox(quarterTurns: 1, child: laid);
    }

    return _wrapForReaders(laid);
  }

  /// One node for the whole row, and a keyboard that can move it.
  ///
  /// The module had NO `Semantics` in twelve hundred lines: a page
  /// indicator is the one thing on a carousel that says where the
  /// reader is, and it said nothing — while its dots, when tappable,
  /// announced as nothing at all.
  Widget _wrapForReaders(Widget child) {
    final position = _to.clamp(0, widget.count - 1);
    final interactive = widget.onTap != null;

    // The DOTS are decoration; the row is the node. Fifteen effects
    // draw a different number of boxes for the same five pages —
    // announcing each of them would read the page count wrong in
    // eleven of them.
    Widget node = ExcludeSemantics(child: child);

    if (interactive) {
      node = FocusableActionDetector(
        focusNode: _focus,
        shortcuts: _shortcuts(),
        actions: {
          _MoveIntent: CallbackAction<_MoveIntent>(
            onInvoke: (intent) {
              final next = (position + intent.delta).clamp(
                0,
                widget.count - 1,
              );
              if (next != position) _tap(next);
              return null;
            },
          ),
          _EdgeIntent: CallbackAction<_EdgeIntent>(
            onInvoke: (intent) {
              _tap(intent.last ? widget.count - 1 : 0);
              return null;
            },
          ),
        },
        child: node,
      );
    }

    final here = IndicatorStrings.pageOf(position + 1, widget.count);

    // A page indicator REPORTS. Only a tappable one is a control — and
    // then it is ONE control, not `count` of them.
    if (!interactive) {
      return Semantics(
        container: true,
        readOnly: true,
        label: here,
        child: node,
      );
    }

    // An ADJUSTABLE, which is what a row of pages is to a reader: a
    // value with a next and a previous. The three have to be given
    // together — a node carrying `onIncrease` and no `increasedValue`
    // asserts.
    return Semantics(
      container: true,
      slider: true,
      label: IndicatorStrings.goToPage(position + 1),
      value: here,
      increasedValue: position < widget.count - 1
          ? IndicatorStrings.pageOf(position + 2, widget.count)
          : here,
      decreasedValue: position > 0
          ? IndicatorStrings.pageOf(position, widget.count)
          : here,
      onIncrease: position < widget.count - 1 ? () => _tap(position + 1) : null,
      onDecrease: position > 0 ? () => _tap(position - 1) : null,
      child: node,
    );
  }

  /// Arrows move a page; Home and End go to the ends.
  ///
  /// The horizontal row MIRRORS, so the key that moves forward is the
  /// one pointing at the next dot rather than the one named "next".
  Map<ShortcutActivator, Intent> _shortcuts() {
    final forward = _MoveIntent(_rtl ? -1 : 1);
    final backward = _MoveIntent(_rtl ? 1 : -1);

    return {
      const SingleActivator(LogicalKeyboardKey.home): const _EdgeIntent(
        last: false,
      ),
      const SingleActivator(LogicalKeyboardKey.end): const _EdgeIntent(
        last: true,
      ),
      if (widget.axis == Axis.horizontal) ...{
        const SingleActivator(LogicalKeyboardKey.arrowRight): forward,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): backward,
      } else ...{
        const SingleActivator(LogicalKeyboardKey.arrowDown): const _MoveIntent(
          1,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowUp): const _MoveIntent(
          -1,
        ),
      },
    };
  }

  Widget _buildForEffect({
    required Color active,
    required Color inactive,
    required double t,
  }) {
    switch (widget.effect) {
      case DotIndicatorEffect.scale:
        return _buildScale(active, inactive, t);
      case DotIndicatorEffect.color:
        return _buildColor(active, inactive, t);
      case DotIndicatorEffect.swap:
        return _buildSwap(active, inactive, t);
      case DotIndicatorEffect.worm:
        return _buildWorm(active, inactive, t);
      case DotIndicatorEffect.expanding:
        return _buildExpanding(active, inactive, t);
      case DotIndicatorEffect.slide:
        return _buildSlide(active, inactive, t);
      case DotIndicatorEffect.jumping:
        return _buildJumping(active, inactive, t);
      case DotIndicatorEffect.scrollingDots:
        return _buildScrollingDots(active, inactive, t);
      case DotIndicatorEffect.flash:
        return _buildFlash(active, inactive, t);
      case DotIndicatorEffect.rotate:
        return _buildRotate(active, inactive, t);
      case DotIndicatorEffect.morph:
        return _buildMorph(active, inactive, t);
      case DotIndicatorEffect.drop:
        return _buildDrop(active, inactive, t);
      case DotIndicatorEffect.bounce:
        return _buildBounce(active, inactive, t);
      case DotIndicatorEffect.splash:
        return _buildSplash(active, inactive, t);
      case DotIndicatorEffect.chain:
        return _buildChain(active, inactive, t);
    }
  }

  // ─── Effects ─────────────────────────────────────────────────

  // --- scale --------------------------------------------------------
  Widget _buildScale(Color active, Color inactive, double t) {
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        final activeness = _activenessForIndex(i, t);
        final size =
            lerpDouble(
              style.dotSize,
              style.activeDotSize,
              activeness,
            ) ??
            style.dotSize;
        final color = Color.lerp(inactive, active, activeness)!;
        return _renderDot(
          index: i,
          isActive: activeness > 0.5,
          activeness: activeness,
          color: color,
          size: size,
          shape: style.shape,
          gradientWhenActive: activeness > 0.5,
        );
      },
    );
  }

  // --- color (size-fixed) -------------------------------------------
  Widget _buildColor(Color active, Color inactive, double t) {
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        final activeness = _activenessForIndex(i, t);
        final color = Color.lerp(inactive, active, activeness)!;
        return _renderDot(
          index: i,
          isActive: activeness > 0.99,
          activeness: activeness,
          color: color,
          size: style.dotSize,
          shape: style.shape,
          gradientWhenActive: activeness > 0.99,
        );
      },
    );
  }

  // --- swap ---------------------------------------------------------
  Widget _buildSwap(Color active, Color inactive, double t) {
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        double a;
        if (i == _to && _from == _to) {
          a = 1;
        } else if (i == _to) {
          a = t;
        } else if (i == _from && _from != _to) {
          a = 1 - t;
        } else {
          a = 0;
        }
        return _renderDot(
          index: i,
          isActive: a > 0.99,
          activeness: a,
          color: Color.lerp(inactive, active, a)!,
          size: style.dotSize,
          shape: style.shape,
          gradientWhenActive: a > 0.99,
        );
      },
    );
  }

  // --- worm ---------------------------------------------------------
  Widget _buildWorm(Color active, Color inactive, double t) {
    return _OverlayRow(
      count: widget.count,
      style: style,
      rtl: _rtl,
      onTap: widget.onTap == null ? null : _tap,
      inactive: inactive,
      overlay: (cellWidth, dotRowTop) {
        // The worm stretches between the *from* and *to* cell
        // centers. Length expands then contracts.
        final fromCenter = _cellCenterX(_from, cellWidth);
        final toCenter = _cellCenterX(_to, cellWidth);
        // Worm "head" follows the to-cell; tail trails the from-cell.
        final headT = math.min(1.0, t * 2);
        final tailT = math.max(0.0, (t - 0.5) * 2);
        final headX = fromCenter + (toCenter - fromCenter) * headT;
        final tailX = fromCenter + (toCenter - fromCenter) * tailT;
        final left = math.min(headX, tailX) - style.dotSize / 2;
        final right = math.max(headX, tailX) + style.dotSize / 2;
        final width = right - left;
        return Positioned(
          left: left,
          top: dotRowTop,
          width: width,
          height: style.dotSize,
          child: _Dot(
            width: width,
            height: style.dotSize,
            color: active,
            gradient: style.gradient,
            radius: style.dotSize / 2,
            shadow: style.shadow,
          ),
        );
      },
    );
  }

  // --- expanding ----------------------------------------------------
  Widget _buildExpanding(Color active, Color inactive, double t) {
    final pillLen = style.dotSize * style.expansionFactor;
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        double activeness = 0;
        if (i == _to) {
          activeness = t;
        } else if (i == _from && _from != _to) {
          activeness = 1 - t;
        } else if (i == _to && _from == _to) {
          activeness = 1;
        }
        final width =
            lerpDouble(
              style.dotSize,
              pillLen,
              activeness,
            ) ??
            style.dotSize;
        final color = Color.lerp(inactive, active, activeness)!;
        return _Dot(
          width: width,
          height: style.dotSize,
          color: color,
          gradient: activeness > 0.5 ? style.gradient : null,
          radius: style.dotSize / 2,
          shadow: activeness > 0.5 ? style.shadow : null,
        );
      },
    );
  }

  // --- slide --------------------------------------------------------
  Widget _buildSlide(Color active, Color inactive, double t) {
    return _OverlayRow(
      count: widget.count,
      style: style,
      rtl: _rtl,
      onTap: widget.onTap == null ? null : _tap,
      inactive: inactive,
      overlay: (cellWidth, dotRowTop) {
        final fromCenter = _cellCenterX(_from, cellWidth);
        final toCenter = _cellCenterX(_to, cellWidth);
        final x = fromCenter + (toCenter - fromCenter) * t;
        final pillLen = style.dotSize * style.slideMarkerFactor;
        return Positioned(
          left: x - pillLen / 2,
          top: dotRowTop,
          width: pillLen,
          height: style.dotSize,
          child: _Dot(
            width: pillLen,
            height: style.dotSize,
            color: active,
            gradient: style.gradient,
            radius: style.dotSize / 2,
            shadow: style.shadow,
          ),
        );
      },
    );
  }

  // --- jumping ------------------------------------------------------
  Widget _buildJumping(Color active, Color inactive, double t) {
    return _OverlayRow(
      count: widget.count,
      style: style,
      rtl: _rtl,
      onTap: widget.onTap == null ? null : _tap,
      inactive: inactive,
      overlay: (cellWidth, dotRowTop) {
        final fromCenter = _cellCenterX(_from, cellWidth);
        final toCenter = _cellCenterX(_to, cellWidth);
        final x = fromCenter + (toCenter - fromCenter) * t;
        // Parabolic arc — peak at t = 0.5.
        final arc = 4 * t * (1 - t); // 0..1..0
        final jumpHeight = style.dotSize * 1.4;
        // Anchor on dot rail; subtract arc so the peak is *above*
        // the rail. Also recenter for the bigger active dot.
        final baseTop = dotRowTop + (style.dotSize - style.activeDotSize) / 2;
        final y = baseTop - arc * jumpHeight;
        return Positioned(
          left: x - style.activeDotSize / 2,
          top: y,
          width: style.activeDotSize,
          height: style.activeDotSize,
          child: _Dot(
            width: style.activeDotSize,
            height: style.activeDotSize,
            color: active,
            gradient: style.gradient,
            radius: style.activeDotSize / 2,
            shadow: style.shadow,
          ),
        );
      },
    );
  }

  // --- scrolling dots ----------------------------------------------
  Widget _buildScrollingDots(Color active, Color inactive, double t) {
    final s = style;
    final visible = math.min(s.scrollingDotsVisibleCount, widget.count);
    final cell = s.dotSize + s.dotSpacing;
    final rowWidth = cell * visible;
    final centerOffset = rowWidth / 2 - s.dotSize / 2;
    final rowHeight = s.dotSize * s.scrollingDotsCenterScale + 4;
    final hitZone = math.max(s.scrollingDotsHitZone, s.dotSize);

    // Fractional active index — continuous-index mode wins when set;
    // otherwise we lerp from _from to _to over t.
    final activeFrac = widget.continuousIndex != null
        ? widget.continuousIndex!.clamp(0.0, widget.count - 1.0)
        : _from + (_to - _from) * t;

    // Boundary clamp — strip can't slide past either edge. Without
    // this, near-edge selections leave half the row blank.
    final maxActiveBeforeClamp = (widget.count - 1) - (visible - 1) / 2;
    final clampedActive = activeFrac.clamp(
      (visible - 1) / 2,
      maxActiveBeforeClamp,
    );
    final stripOffset = centerOffset - clampedActive * cell;

    Widget strip = SizedBox(
      width: rowWidth,
      height: rowHeight,
      child: Stack(
        // Clip dots outside the visible window. ShaderMask fades the
        // edges but content still renders past the SizedBox without
        // a clip — they show through.
        clipBehavior: Clip.hardEdge,
        children: [
          for (var i = 0; i < widget.count; i++)
            Builder(
              builder: (context) {
                final left = stripOffset + i * cell;
                final dotCenter = left + s.dotSize / 2;
                final distFromCenter = (dotCenter - rowWidth / 2).abs();
                final maxDist = rowWidth / 2;
                final closeness = (1 - distFromCenter / maxDist).clamp(
                  0.0,
                  1.0,
                );

                // Active-ness for color crossfade. Smooth across the
                // animation — no hard if/else swap.
                double activeness;
                if (i == _to && _from == _to) {
                  activeness = 1;
                } else if (i == _to) {
                  activeness = t;
                } else if (i == _from && _from != _to) {
                  activeness = 1 - t;
                } else {
                  activeness = 0;
                }

                // Active dot always at full center-scale, never shrinks
                // even when off-center near boundaries.
                final scale = activeness > 0.01
                    ? s.scrollingDotsCenterScale
                    : 1 + (s.scrollingDotsCenterScale - 1) * closeness;
                final size = s.dotSize * scale;

                final dotColor = Color.lerp(
                  inactive.withValues(
                    alpha: math.max(closeness, s.scrollingDotsMinAlpha),
                  ),
                  active,
                  activeness,
                )!;

                return Positioned(
                  // Position by dot center to keep alignment stable
                  // across size changes.
                  left: dotCenter - hitZone / 2,
                  top: (rowHeight - hitZone) / 2,
                  width: hitZone,
                  height: hitZone,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onTap == null ? null : () => _tap(i),
                    child: Center(
                      child: _Dot(
                        width: size,
                        height: size,
                        color: dotColor,
                        gradient: activeness > 0.5 ? s.gradient : null,
                        radius: size / 2,
                        shadow: activeness > 0.5 ? s.shadow : null,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );

    // The strip positions every dot absolutely, so it mirrors by being
    // FLIPPED rather than by re-deriving the arithmetic. Safe here and
    // nowhere else: this is the one effect that ignores `itemBuilder`,
    // so what is being flipped is always a plain shape.
    if (_rtl) {
      strip = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: strip,
      );
    }

    if (!s.scrollingDotsFadeEdges) return strip;

    // A fade says "there is more this way". At the FIRST dot there is
    // nothing before it and at the LAST nothing after, so fading those
    // ends dimmed a dot the reader can see all of and promised a strip
    // that is not there.
    //
    // The strip stops scrolling once the active dot reaches either
    // clamp, which is exactly when each end runs out.
    const edge = 0.12;
    final fades = IndicatorMath.edgeFades(
      clampedActive: clampedActive,
      visible: visible,
      count: widget.count,
    );
    final fadeStart = fades.start;
    final fadeEnd = fades.end;
    if (!fadeStart && !fadeEnd) return strip;

    const clear = Color(0x00000000);
    const solid = Color(0xFF000000);

    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          fadeStart ? clear : solid,
          solid,
          solid,
          fadeEnd ? clear : solid,
        ],
        stops: const [0, edge, 1 - edge, 1],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: strip,
    );
  }

  // --- flash --------------------------------------------------------
  Widget _buildFlash(Color active, Color inactive, double t) {
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        final activeness = _activenessForIndex(i, t);
        final color = Color.lerp(inactive, active, activeness)!;
        // Pulse opacity — dim in the middle of the transition, full
        // at the start/end. Only applies to the to-cell.
        final pulse = i == _to && _from != _to
            ? style.flashMinOpacity +
                  (1 - style.flashMinOpacity) * (1 - 4 * t * (1 - t).abs())
            : 1.0;
        return _renderDot(
          index: i,
          isActive: activeness > 0.5,
          activeness: activeness,
          color: color,
          size: style.dotSize,
          shape: style.shape,
          opacity: pulse.clamp(0.0, 1.0),
          gradientWhenActive: activeness > 0.5,
        );
      },
    );
  }

  // --- rotate -------------------------------------------------------
  Widget _buildRotate(Color active, Color inactive, double t) {
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        final activeness = _activenessForIndex(i, t);
        final color = Color.lerp(inactive, active, activeness)!;
        final size =
            lerpDouble(
              style.dotSize,
              style.activeDotSize,
              activeness,
            ) ??
            style.dotSize;
        // Spin the to-cell during transition. Inactive dots don't
        // rotate.
        final rotation = i == _to && _from != _to ? t * math.pi * 2 : 0.0;
        return _renderDot(
          index: i,
          isActive: activeness > 0.5,
          activeness: activeness,
          color: color,
          size: size,
          shape: style.shape,
          rotation: rotation,
          gradientWhenActive: activeness > 0.5,
        );
      },
    );
  }

  // --- morph --------------------------------------------------------
  Widget _buildMorph(Color active, Color inactive, double t) {
    // Active dot morphs through shape sequence: circle → square →
    // circle. We do this by sweeping the border radius from full
    // (circle) to a small value (square) and back over t.
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        final activeness = _activenessForIndex(i, t);
        final color = Color.lerp(inactive, active, activeness)!;
        if (i != _to || _from == _to) {
          return _renderDot(
            index: i,
            isActive: activeness > 0.99,
            activeness: activeness,
            color: color,
            size: style.dotSize,
            shape: style.shape,
          );
        }
        // To-cell during animation: morph radius circle → 2 → circle.
        final morphT = math.sin(t * math.pi); // 0 → 1 → 0
        final radius =
            lerpDouble(
              style.dotSize / 2,
              2,
              morphT,
            ) ??
            style.dotSize / 2;
        return _Dot(
          width: style.dotSize,
          height: style.dotSize,
          color: color,
          radius: radius,
          shape: DotShape.circle, // morph overrides
          gradient: activeness > 0.5 ? style.gradient : null,
          shadow: activeness > 0.5 ? style.shadow : null,
        );
      },
    );
  }

  // --- drop ---------------------------------------------------------
  Widget _buildDrop(Color active, Color inactive, double t) {
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        final activeness = _activenessForIndex(i, t);
        final color = Color.lerp(inactive, active, activeness)!;
        final drop = style.dotSize * style.dropDistanceFactor;
        final moving = _from != _to && (i == _from || i == _to);

        // A cell the marker LEAVES keeps its own inactive dot the whole
        // time, and the departing active one falls away over it.
        //
        // The active dot used to be the cell's only dot: it fell out,
        // the cell stayed empty, and the inactive dot underneath
        // snapped back into existence on the next transition — a dot
        // that reappeared from nowhere, one tap late. It is also what
        // made a flight BACK to that cell look wrong.
        if (!moving) {
          return _renderDot(
            index: i,
            isActive: activeness > 0.5,
            activeness: activeness,
            color: color,
            size: style.dotSize,
            shape: style.shape,
            gradientWhenActive: activeness > 0.5,
          );
        }

        final leaving = i == _from;
        return Stack(
          alignment: Alignment.center,
          children: [
            // The cell's resting dot, always there.
            _renderDot(
              index: i,
              isActive: false,
              activeness: 0,
              color: inactive,
              size: style.dotSize,
              shape: style.shape,
            ),
            // And the active one, falling out or falling in.
            Transform.translate(
              offset: Offset(0, leaving ? drop * t : -drop * (1 - t)),
              child: _renderDot(
                index: i,
                isActive: !leaving,
                activeness: leaving ? 1 - t : t,
                color: active,
                size: style.dotSize,
                shape: style.shape,
                opacity: (leaving ? 1 - t : t).clamp(0.0, 1.0),
                gradientWhenActive: !leaving,
              ),
            ),
          ],
        );
      },
    );
  }

  // --- bounce -------------------------------------------------------
  Widget _buildBounce(Color active, Color inactive, double t) {
    // Same as scale but with elastic overshoot — apply elasticOut on
    // top of the user's curve.
    final bouncyT = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        final base = _activenessForIndex(i, t);
        // Use bouncy curve for the to-cell only; outgoing cell
        // shrinks linearly so it doesn't overshoot weirdly.
        final activeness = i == _to ? base * bouncyT / (t == 0 ? 1 : t) : base;
        final clamped = activeness.clamp(0.0, 1.4);
        final size =
            lerpDouble(
              style.dotSize,
              style.activeDotSize,
              clamped,
            ) ??
            style.dotSize;
        final color = Color.lerp(inactive, active, base.clamp(0.0, 1.0))!;
        return _renderDot(
          index: i,
          isActive: base > 0.5,
          activeness: base,
          color: color,
          size: size,
          shape: style.shape,
          gradientWhenActive: base > 0.5,
        );
      },
    );
  }

  // --- splash -------------------------------------------------------
  Widget _buildSplash(Color active, Color inactive, double t) {
    // Scale base + an expanding ring around the to-cell. Ring's
    // radius grows + opacity fades on settle.
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        final activeness = _activenessForIndex(i, t);
        final size =
            lerpDouble(
              style.dotSize,
              style.activeDotSize,
              activeness,
            ) ??
            style.dotSize;
        final color = Color.lerp(inactive, active, activeness)!;
        final dot = _renderDot(
          index: i,
          isActive: activeness > 0.5,
          activeness: activeness,
          color: color,
          size: size,
          shape: style.shape,
          gradientWhenActive: activeness > 0.5,
        );
        if (i != _to || _from == _to) return dot;
        // Ring overlay — grow + fade as t advances.
        final ringRadius =
            style.dotSize *
            (0.5 +
                (style.splashMaxRadiusFactor - 0.5) *
                    Curves.easeOut.transform(t));
        final ringOpacity = (1 - t).clamp(0.0, 1.0);
        final ringColor = style.splashRingColor.withValues(
          alpha: ringOpacity,
        );
        // The cell stays the DOT's size and the ring paints outside it.
        //
        // The ring used to size the cell, so the row spread apart while
        // it expanded and snapped shut the moment the next transition
        // moved the ring elsewhere — the dots either side visibly
        // jumped back into place.
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              dot,
              IgnorePointer(
                child: OverflowBox(
                  maxWidth: ringRadius * 2,
                  maxHeight: ringRadius * 2,
                  child: CustomPaint(
                    painter: _RingPainter(
                      color: ringColor,
                      strokeWidth: style.splashRingWidth,
                      radius: ringRadius,
                    ),
                    size: Size(ringRadius * 2, ringRadius * 2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- chain --------------------------------------------------------
  Widget _buildChain(Color active, Color inactive, double t) {
    // Inactive dots between _from and _to tint sequentially as the
    // active state cascades. Each intermediate dot pulses for a
    // fraction of the total t window.
    final dir = _to - _from;
    final span = dir.abs();
    return _DotRow(
      count: widget.count,
      spacing: style.dotSpacing,
      onTap: widget.onTap == null ? null : _tap,
      itemBuilder: (i) {
        var activeness = _activenessForIndex(i, t);
        // Intermediate cells: stagger their tint based on position
        // in the chain.
        if (_from != _to && span > 1) {
          final between = (i - _from) * (dir > 0 ? 1 : -1);
          if (between > 0 && between < span) {
            final stagger = between / span;
            // Pulse window — peaks at stagger, dies off ±0.15.
            final dist = (t - stagger).abs();
            const pulseWidth = 0.25;
            final pulse = math.max(0.0, 1 - dist / pulseWidth).clamp(0.0, 1.0);
            activeness = math.max(activeness, pulse);
          }
        }
        final color = Color.lerp(inactive, active, activeness)!;
        final size =
            lerpDouble(
              style.dotSize,
              style.activeDotSize,
              activeness,
            ) ??
            style.dotSize;
        return _renderDot(
          index: i,
          isActive: activeness > 0.5,
          activeness: activeness,
          color: color,
          size: size,
          shape: style.shape,
          gradientWhenActive: activeness > 0.5,
        );
      },
    );
  }

  /// Dispatches to [itemBuilder] when set, else renders a default
  /// [_Dot]. Centralized so every effect honors `itemBuilder`
  /// without duplicating the conditional.
  Widget _renderDot({
    required int index,
    required bool isActive,
    required double activeness,
    required Color color,
    required double size,
    required DotShape shape,
    double rotation = 0,
    double opacity = 1,
    bool gradientWhenActive = false,
  }) {
    if (widget.itemBuilder != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: opacity,
            child: Builder(
              builder: (context) =>
                  widget.itemBuilder!(context, index, isActive, activeness),
            ),
          ),
        ),
      );
    }
    return _Dot(
      width: size,
      height: size,
      color: color,
      radius: style.radius,
      shape: shape,
      gradient: gradientWhenActive ? style.gradient : null,
      shadow: gradientWhenActive ? style.shadow : null,
      borderColor: style.borderColor,
      borderWidth: style.borderWidth,
      paintStyle: style.paintStyle,
      rotation: rotation,
      opacity: opacity,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  /// Smoothed activeness for dot `i` given the transition `t`. Used
  /// by scale + color effects — combines _from / _to weights so the
  /// outgoing dot fades out while incoming fades in.
  double _activenessForIndex(int i, double t) {
    if (_from == _to) return i == _to ? 1 : 0;
    if (i == _to) return t;
    if (i == _from) return 1 - t;
    return 0;
  }

  /// Returns the *dot* center along the rail, not the cell center.
  /// Inactive dots are rendered at `left: i*cellWidth, width: dotSize`
  /// — so their visual center sits at `i*cellWidth + dotSize/2`, NOT
  /// at `i*cellWidth + cellWidth/2`. Aligning markers to the latter
  /// shifts every active position by `dotSpacing/2`, producing the
  /// "active dot off to the right" misalignment seen in worm/slide/
  /// jumping effects.
  double _cellCenterX(int index, double cellWidth) =>
      cellWidth * _physicalIndex(index) + style.dotSize / 2;

  /// The row's own focus node — one for the whole indicator, not one
  /// per dot: it is a single control that moves through pages.
  final FocusNode _focus = FocusNode(debugLabel: 'GlobalDotIndicator');

  /// Whether the row runs right-to-left.
  ///
  /// Only meaningful on the horizontal axis: a vertical row is turned
  /// by a `RotatedBox` and runs top-to-bottom in every language.
  bool get _rtl =>
      widget.axis == Axis.horizontal &&
      Directionality.of(context) == TextDirection.rtl;

  /// Where a logical index SITS.
  ///
  /// The overlay effects position everything absolutely, so they used
  /// to draw dot 0 on the left in every language — while the pages
  /// they indicate mirror, because a `PageView` is a scrollable and
  /// scrollables reverse. In Arabic the marker therefore ran opposite
  /// to the content, and the `Row`-based effects (scale, colour, swap)
  /// mirrored while the overlay ones (worm, slide, jumping) did not:
  /// the same widget, two different answers, depending on the effect.
  double _physicalIndex(num index) =>
      IndicatorMath.physicalIndex(index, widget.count, rtl: _rtl);
}

// ─── Row helpers ─────────────────────────────────────────────────

class _DotRow extends StatelessWidget {
  const _DotRow({
    required this.count,
    required this.spacing,
    required this.itemBuilder,
    this.onTap,
  });

  final int count;
  final double spacing;
  final Widget Function(int index) itemBuilder;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < count; i++) {
      if (i > 0) children.add(SizedBox(width: spacing));
      final dot = itemBuilder(i);
      children.add(
        onTap == null
            ? dot
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap!(i),
                child: dot,
              ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

/// Row of inactive dots with a single overlay marker positioned
/// absolutely (worm / slide / jumping effects). Single Stack —
/// every child positions itself relative to the same coordinate
/// space so centering math stays trivial.
///
/// The overlay builder receives `cellWidth` and `dotRowTop` — the
/// y-coordinate of the dot rail's top edge. Position the marker at
/// `dotRowTop` (or with a vertical offset for arcs) and it lines up
/// pixel-perfect with the inactive rail.
class _OverlayRow extends StatelessWidget {
  const _OverlayRow({
    required this.count,
    required this.style,
    required this.inactive,
    required this.overlay,
    required this.rtl,
    this.onTap,
  });

  /// Mirrors the rail, so it lines up with the marker over it.
  final bool rtl;

  final int count;
  final ResolvedDotIndicatorStyle style;
  final Color inactive;
  final Positioned Function(double cellWidth, double dotRowTop) overlay;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final cellWidth = style.dotSize + style.dotSpacing;
    final rowWidth = cellWidth * count - style.dotSpacing;
    // Total height: dot height + headroom for the jumping arc above.
    final headroom = style.dotSize * 1.5;
    final totalHeight = style.dotSize + headroom;
    // The dot rail sits at the bottom of the box so jumping arcs
    // have room to peak above without clipping.
    final dotRowTop = headroom;
    return SizedBox(
      width: rowWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Inactive dot rail.
          for (var i = 0; i < count; i++)
            Positioned(
              left: (rtl ? (count - 1 - i) : i) * cellWidth,
              top: dotRowTop,
              width: style.dotSize,
              height: style.dotSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap == null ? null : () => onTap!(i),
                child: _Dot(
                  width: style.dotSize,
                  height: style.dotSize,
                  color: inactive,
                  radius: style.radius,
                  borderColor: style.borderColor,
                  borderWidth: style.borderWidth,
                  paintStyle: style.paintStyle,
                ),
              ),
            ),
          // Overlay marker — same coordinate space, lines up cleanly.
          overlay(cellWidth, dotRowTop),
        ],
      ),
    );
  }
}

// ─── Single dot widget ────────────────────────────────────────────

class _Dot extends StatelessWidget {
  const _Dot({
    required this.width,
    required this.height,
    required this.color,
    required this.radius,
    this.shape = DotShape.circle,
    this.gradient,
    this.shadow,
    this.borderColor,
    this.borderWidth = 0,
    this.paintStyle = PaintingStyle.fill,
    this.rotation = 0,
    this.opacity = 1,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;
  final DotShape shape;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;
  final Color? borderColor;
  final double borderWidth;
  final PaintingStyle paintStyle;
  final double rotation;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isStroke = paintStyle == PaintingStyle.stroke;
    final fillColor = isStroke || gradient != null ? null : color;
    final border = borderColor != null && borderWidth > 0
        ? Border.all(color: borderColor!, width: borderWidth)
        : (isStroke ? Border.all(color: color, width: 1.5) : null);

    Widget dot;
    switch (shape) {
      case DotShape.circle:
        dot = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fillColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: shadow,
            border: border,
          ),
        );
      case DotShape.square:
        dot = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fillColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius.clamp(0, 4)),
            boxShadow: shadow,
            border: border,
          ),
        );
      case DotShape.pill:
        dot = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fillColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: shadow,
            border: border,
          ),
        );
      case DotShape.diamond:
        // 45° rotated square. Visual size shrinks ~71% — bump up so
        // diamonds read at the same scale as circles.
        dot = Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: width * 0.78,
            height: height * 0.78,
            decoration: BoxDecoration(
              color: fillColor,
              gradient: gradient,
              borderRadius: BorderRadius.circular(2),
              boxShadow: shadow,
              border: border,
            ),
          ),
        );
      case DotShape.star:
        dot = CustomPaint(
          size: Size(width, height),
          painter: _StarPainter(
            color: gradient == null ? color : null,
            gradient: gradient,
            stroke: isStroke ? color : null,
            strokeWidth: 1.5,
          ),
        );
    }

    if (rotation != 0) dot = Transform.rotate(angle: rotation, child: dot);
    if (opacity != 1) dot = Opacity(opacity: opacity, child: dot);
    return dot;
  }
}

/// Ring stroke for [DotIndicatorEffect.splash].
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius;
}

/// 5-point star painter for [DotShape.star].
class _StarPainter extends CustomPainter {
  _StarPainter({
    this.color,
    this.gradient,
    this.stroke,
    this.strokeWidth = 1,
  });

  final Color? color;
  final Gradient? gradient;
  final Color? stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rOuter = math.min(cx, cy);
    final rInner = rOuter * 0.45;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? rOuter : rInner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    final paint = Paint();
    if (stroke != null) {
      paint
        ..style = PaintingStyle.stroke
        ..color = stroke!
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round;
    } else if (gradient != null) {
      paint.shader = gradient!.createShader(Offset.zero & size);
    } else {
      paint.color = color ?? Colors.transparent;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color ||
      old.gradient != gradient ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth;
}
