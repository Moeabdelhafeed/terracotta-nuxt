import 'package:flutter/material.dart';

import '../../../../core/animations/animation_presets.dart';
import '../../../../core/flavor/flavor_config.dart';
import '../../../../core/responsive/extensions.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../debug_overlay_models.dart';
import '../dev_tool_status.dart';
import 'debug_chrome.dart';

/// Single floating debug pill — replaces the bug FAB + flavor pill +
/// breakpoint pill.
///
/// Surfaces three signals at a glance:
/// - flavor (colored dot + 3-letter code)
/// - active window-size bucket (label)
/// - latest log alert (pulsing dot when warning+ fired since last open)
///
/// Tap → open overlay home (caller-supplied `onTap`).
/// Drag → reposition; snaps to the nearest vertical edge on release.
class DebugPill extends StatefulWidget {
  /// Bounds the pill last painted at — the window uses it as the origin
  /// of its open animation. Null before the first frame.
  static Rect? get lastRect => _DebugPillState.lastRect;

  const DebugPill({
    super.key,
    required this.onTap,
    this.badgeColor,
    this.opacity = 1,
  });

  final VoidCallback onTap;

  /// Latest log-level color (e.g. red on error). Renders as a small dot
  /// at the trailing edge of the pill. `null` → hidden.
  final Color? badgeColor;

  /// Fade applied INSIDE the pill's `Positioned`. Callers must not wrap
  /// this widget in an Opacity — a Positioned has to stay a direct child
  /// of its Stack, and doing so throws "Incorrect use of
  /// ParentDataWidget" every frame.
  final double opacity;

  @override
  State<DebugPill> createState() => _DebugPillState();
}

class _DebugPillState extends State<DebugPill> {
  /// Where the pill last painted, in global coordinates.
  ///
  /// Published so the debug WINDOW can grow out of the pill's actual
  /// bounds. Static because the window is built by a different widget
  /// and the pill is unmounted by the time it opens.
  static Rect? lastRect;

  Offset? _position;

  /// True between pan start and release — suspends the per-build edge
  /// re-snap so the pill tracks the finger freely.
  bool _dragging = false;

  /// Flung off the side: only [_EdgeTab] shows until it is tapped.
  bool _hidden = false;

  // Pill dimensions — used by the drag clamp + edge snap.
  static const _kHeight = DebugChrome.height;
  static const _kEdgeInset = 8.0;

  /// Visible width of the sliver left poking out once docked.
  static const _kTabWidth = 14.0;

  /// How far the docked tab hangs PAST the screen edge.
  ///
  /// The border has to stay uniform (a BoxDecoration cannot paint mixed
  /// sides with a radius), so the edge-facing stroke is hidden by moving
  /// it off-screen rather than by omitting it. One pixel was not enough:
  /// the rounded corners curve back into view and the alert glow spreads
  /// several pixels further still. Bleeding a full corner's worth puts
  /// the whole outer half — stroke, corners and most of the glow —
  /// beyond the edge, leaving only the inner face visible.
  static const _kEdgeBleed = 16.0;

  /// Gap kept from the safe-area edges.
  ///
  /// This used to ignore the insets on the theory that the status-bar
  /// and home-indicator strips were free real estate. They are not: the
  /// system swallows touches there, so a pill parked under the notch or
  /// the home indicator could no longer be tapped OR dragged — it was
  /// simply stuck, with no way back short of clearing prefs.
  static const _kSafeMargin = 4.0;

  /// Horizontal fling speed (px/s) past which the pill hides into the
  /// edge instead of snapping back onto it.
  static const _kFlingToHide = 900.0;

  // Measured pill width — content is driven by flavor + bucket labels
  // and length varies (DEV vs STAGING, Compact vs Extra Large), so we
  // can't hardcode. Filled in via post-frame measurement; right-edge
  // snapping uses this so the pill lands flush instead of overshooting.
  final GlobalKey _pillKey = GlobalKey();
  double _pillWidth = 200;

  @override
  void initState() {
    super.initState();
    // Disk-cached position (if any) — load once, then rebuild.
    if (DebugOverlayPrefs.loaded) {
      _position = DebugOverlayPrefs.pillPos;
      _hidden = DebugOverlayPrefs.pillHidden;
    } else {
      DebugOverlayPrefs.ensureLoaded().then((_) {
        if (!mounted) return;
        setState(() {
          _position = DebugOverlayPrefs.pillPos;
          _hidden = DebugOverlayPrefs.pillHidden;
        });
      });
    }
  }

  void _measurePill() {
    final box = _pillKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final w = box.size.width;
    if ((_pillWidth - w).abs() < 0.5) return;
    if (!mounted) return;
    // Rebuild so the default initial position (which uses [_pillWidth]
    // before measurement was available) snaps to the correct right
    // anchor. No-op when the user has already cached a position.
    setState(() => _pillWidth = w);
  }

  /// Vertical band the pill may occupy, honouring system insets.
  (double, double) _verticalBounds(EdgeInsets insets, Size screen) {
    final top = insets.top + _kSafeMargin;
    final bottom = screen.height - insets.bottom - _kHeight - _kSafeMargin;
    // Degenerate viewport (tiny window / huge insets): keep it valid.
    return bottom <= top ? (top, top) : (top, bottom);
  }

  void _setHidden({required bool hidden, required Offset at}) {
    setState(() {
      _hidden = hidden;
      _position = at;
      _dragging = false;
    });
    DebugOverlayPrefs.savePillPos(at);
    DebugOverlayPrefs.savePillHidden(hidden);
  }

  @override
  Widget build(BuildContext context) {
    final flavor = FlavorConfig.instance.flavor;
    final bp = context.maybeBreakpoints;
    final screen = MediaQuery.sizeOf(context);
    // The pill snaps to a screen EDGE, and in landscape that edge is
    // where the notch or the dynamic island lives — it only ever read
    // the top and bottom insets, so rotating the device parked it
    // underneath the island. Both axes now.
    final insets = MediaQuery.paddingOf(context);
    final (minY, maxY) = _verticalBounds(insets, screen);
    final leftRest = insets.left + _kEdgeInset;
    final rightRest = screen.width - insets.right - _pillWidth - _kEdgeInset;

    // Re-measure after every layout — bucket label changes width when
    // the window class flips (Compact → Medium → ...), and flavor
    // toggles change the prefix.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measurePill());

    final raw = _position ?? Offset(rightRest, minY);
    final onRight = raw.dx + _pillWidth / 2 > screen.width / 2;
    final top = raw.dy.clamp(minY, maxY);

    // The pill is ALWAYS edge-snapped at rest, so x is derived — never
    // trusted from disk. A cached absolute x goes stale the moment the
    // pill width changes (bucket label Compact → Extra Large, flavor
    // code) or the screen rotates/resizes; re-deriving from the nearest
    // edge with the CURRENT width keeps it flush. Mid-drag raw wins.
    final pos = _dragging ? raw : Offset(onRight ? rightRest : leftRest, top);

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final morph = reduceMotion ? Duration.zero : AppDurations.normal;
    // Docked, the tab hangs _kEdgeBleed past the screen edge so its
    // outer stroke falls off-screen — the border has to stay uniform
    // (see _PillSurface), so this is how that side is hidden.
    final left = _hidden
        ? (onRight
              ? screen.width - insets.right - _kTabWidth
              : insets.left - _kEdgeBleed)
        : pos.dx;

    lastRect = Rect.fromLTWH(
      left,
      _hidden ? top : pos.dy,
      _hidden ? _kTabWidth : _pillWidth,
      _kHeight,
    );

    return AnimatedPositioned(
      // Instant while a finger is on it; tweened when it settles or docks.
      duration: _dragging ? Duration.zero : morph,
      curve: Curves.easeOutCubic,
      left: left,
      top: _hidden ? top : pos.dy,
      child: Opacity(
        opacity: widget.opacity.clamp(0, 1),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hidden
              ? () => _setHidden(
                  hidden: false,
                  at: Offset(
                    onRight
                        ? screen.width - _pillWidth - _kEdgeInset
                        : _kEdgeInset,
                    top,
                  ),
                )
              : widget.onTap,
          onPanStart: _hidden
              ? null
              : (_) => setState(() {
                  _dragging = true;
                  _position = pos;
                }),
          onPanUpdate: (d) {
            setState(() {
              _position = _hidden
                  // Docked: it only slides along the edge.
                  ? Offset(raw.dx, (raw.dy + d.delta.dy).clamp(minY, maxY))
                  : Offset(
                      // Horizontally unclamped by design: a drag PAST the
                      // edge is what arms the fling-to-hide below.
                      pos.dx + d.delta.dx,
                      (pos.dy + d.delta.dy).clamp(minY, maxY),
                    );
            });
          },
          onPanEnd: (details) {
            if (_hidden) {
              DebugOverlayPrefs.savePillPos(Offset(raw.dx, top));
              return;
            }
            final vx = details.velocity.pixelsPerSecond.dx;
            final draggedOut =
                pos.dx < -_pillWidth / 3 ||
                pos.dx + _pillWidth > screen.width + _pillWidth / 3;
            // A hard flick at a side, or simply shoving it off — dock it.
            if (vx.abs() > _kFlingToHide || draggedOut) {
              final toRight = draggedOut ? onRight : vx > 0;
              _setHidden(
                hidden: true,
                at: Offset(
                  toRight
                      ? screen.width - _pillWidth - _kEdgeInset
                      : _kEdgeInset,
                  pos.dy.clamp(minY, maxY),
                ),
              );
              return;
            }
            // Otherwise snap to the nearest vertical edge using the
            // MEASURED width so the right edge lands flush instead of
            // guessing 200px and overshooting on short pills.
            final snapRight = pos.dx + _pillWidth / 2 > screen.width / 2;
            final snapped = Offset(
              snapRight ? screen.width - _pillWidth - _kEdgeInset : _kEdgeInset,
              pos.dy.clamp(minY, maxY),
            );
            setState(() {
              _dragging = false;
              _position = snapped;
            });
            DebugOverlayPrefs.savePillPos(snapped);
          },
          onPanCancel: () => setState(() => _dragging = false),
          child: _PillSurface(
            docked: _hidden,
            onRight: onRight,
            duration: morph,
            flavorColor: flavor.bannerColor,
            alertColor: widget.badgeColor,
            tabWidth: _kTabWidth + _kEdgeBleed,
            tabVisibleWidth: _kTabWidth,
            height: _kHeight,
            child: _buildPill(flavor.bannerColor, flavor.displayName, bp),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(Color flavorColor, String flavorLabel, dynamic bp) {
    final bucketLabel = bp?.windowSize.label as String?;
    // Content only — the painted surface is [_PillSurface], so it
    // survives the morph as ONE element instead of being swapped.
    return Padding(
      key: _pillKey,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flavor — dot + label
          _Dot(color: flavorColor, size: 8),

          const SizedBox(width: 6),
          _Label(flavorLabel),
          if (bucketLabel != null) ...[
            const SizedBox(width: 8),
            _Sep(),
            const SizedBox(width: 8),
            // Bucket — color-coded dot + label
            _Dot(color: _bucketColor(bucketLabel), size: 6),
            const SizedBox(width: 5),
            _Label(bucketLabel.toUpperCase()),
          ],

          // Forgotten-simulator indicator — amber wrench dot whenever
          // ANY override is live, visible without opening the panel.
          ListenableBuilder(
            listenable: DevToolStatus.listenable,
            builder: (_, _) {
              if (!DevToolStatus.anyActive) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  _Sep(),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.build_circle_rounded,
                    size: 11,
                    color: Color(0xFFFFA726),
                  ),
                ],
              );
            },
          ),

          if (widget.badgeColor != null) ...[
            const SizedBox(width: 8),
            _Sep(),
            const SizedBox(width: 8),
            // Log alert — pulsing dot. Reuses the level color from
            // DebugOverlayTheme so warning/error/fatal map consistently
            // here and inside the logs view.
            _PulseDot(color: widget.badgeColor!),
          ],

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  static Color _bucketColor(String label) => switch (label) {
    'Compact' => const Color(0xFF4CAF50),
    'Medium' => const Color(0xFF2196F3),
    'Expanded' => const Color(0xFFFF9800),
    'Large' => const Color(0xFFE91E63),
    'Extra Large' => const Color(0xFF9C27B0),
    _ => const Color(0xFF9E9E9E),
  };
}

// ─────────────────────────────────────────────────────────────

/// The painted pill — and, when docked, the sliver of it left poking
/// out of the screen edge.
///
/// ONE element across both states. The earlier version swapped two
/// separate widgets inside an AnimatedSwitcher, so "morphing" was really
/// a clip collapse — and `SizeTransition`'s internal `ClipRect` sheared
/// the drop shadow off while it ran. Here the surface itself animates
/// its width, radius and border, and only the CONTENT cross-fades, so
/// the shadow is painted by a box that is never clipped.
/// How far the docked chevron sits toward the wall.
const _kChevronNudge = 1.0;

class _PillSurface extends StatefulWidget {
  const _PillSurface({
    required this.child,
    required this.docked,
    required this.onRight,
    required this.duration,
    required this.flavorColor,
    required this.tabWidth,
    required this.tabVisibleWidth,
    required this.height,
    this.alertColor,
  });

  final Widget child;
  final bool docked;
  final bool onRight;
  final Duration duration;
  final Color flavorColor;

  /// Latest log-level colour. Docked, this drives a pulsing glow rather
  /// than a dot — at 14px wide there is no room for a legible dot, and a
  /// glow reads from the corner of the eye, which is the entire point of
  /// an alert you have deliberately tucked away.
  final Color? alertColor;

  /// Full docked width, INCLUDING the part hanging off-screen.
  final double tabWidth;

  /// The part actually on screen — the chevron centres in this, not in
  /// the full box, or it would sit past the edge.
  final double tabVisibleWidth;
  final double height;

  @override
  State<_PillSurface> createState() => _PillSurfaceState();
}

class _PillSurfaceState extends State<_PillSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _PillSurface old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  void _syncPulse() {
    final wanted = widget.docked && widget.alertColor != null;
    if (wanted && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!wanted && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(widget.height);
    // Docked, the edge-facing side is square and unstroked: there is no
    // edge there to describe, and a stroke against the bezel reads as a
    // glow smeared along the screen border.
    final outer = widget.docked ? Radius.zero : radius;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final alert = widget.alertColor;
        final glowing = widget.docked && alert != null;
        final t = _pulse.value;
        final edge = (glowing ? alert : widget.flavorColor).withValues(
          alpha: glowing ? 0.65 + 0.35 * t : DebugChrome.strokeOpacity,
        );

        return AnimatedContainer(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          height: widget.height,
          decoration: BoxDecoration(
            color: DebugChrome.surface,
            // MUST stay uniform: BoxDecoration cannot paint a border
            // with differing sides together with a borderRadius — it
            // asserts "is not uniform" during paint, on every frame,
            // which never reaches the engine and buries the app in
            // debugFrameWasSentToEngine noise. The edge-facing stroke is
            // hidden by bleeding the docked tab off-screen instead (see
            // kEdgeBleed), which also removes the glow-against-the-bezel
            // look.
            border: Border.all(color: edge),
            borderRadius: BorderRadius.only(
              topLeft: widget.onRight ? radius : outer,
              bottomLeft: widget.onRight ? radius : outer,
              topRight: widget.onRight ? outer : radius,
              bottomRight: widget.onRight ? outer : radius,
            ),
            boxShadow: [
              ...DebugChrome.shadow,
              // The alert glow itself — spreads with the pulse.
              if (glowing)
                BoxShadow(
                  color: alert.withValues(alpha: 0.30 + 0.35 * t),
                  blurRadius: 6 + 10 * t,
                  spreadRadius: 1 + 2 * t,
                ),
            ],
          ),
          // AnimatedSize tweens the box to whatever the current child
          // measures, so neither state needs a hard-coded width.
          //
          // The previous attempt animated an explicit `width` and put an
          // OverflowBox(maxWidth: infinity) inside: expanded, that box
          // sized itself to its parent while the parent sized itself to
          // the box, and the circular constraint threw during layout on
          // EVERY frame — which surfaces as a repeating
          // 'debugFrameWasSentToEngine' assertion, because a frame that
          // throws never reaches the engine.
          child: AnimatedSize(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            alignment: widget.onRight
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: widget.docked
                ? SizedBox(
                    width: widget.tabWidth,
                    // Reserve the off-screen half with padding rather than
                    // aligning a nested box: the glyph then centres in the
                    // strip that is actually VISIBLE. The extra pixel on
                    // the inner side balances the border stroke, which
                    // only exists on that side once docked.
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: widget.onRight
                            ? 0
                            : widget.tabWidth - widget.tabVisibleWidth - 2,
                        right: widget.onRight
                            ? widget.tabWidth - widget.tabVisibleWidth - 2
                            : 0,
                      ),
                      child: Center(
                        child: Padding(
                          // Nudge the glyph TOWARD the wall it is docked
                          // against: it points back at the screen, so
                          // sitting slightly outboard reads as tucked in
                          // rather than floating in the strip.
                          padding: EdgeInsets.only(
                            left: widget.onRight ? _kChevronNudge : 0,
                            right: widget.onRight ? 0 : _kChevronNudge,
                          ),
                          child: Icon(
                            widget.onRight
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  )
                : child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
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
      builder: (_, _) {
        final t = _ctrl.value;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.6 + 0.4 * t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4 * t),
                blurRadius: 4 + 4 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFamily: DebugOverlayTheme.kFont,
        fontFamilyFallback: DebugOverlayTheme.kFontFallback,
        letterSpacing: 0.4,
        decoration: TextDecoration.none,
      ),
    );
  }
}
