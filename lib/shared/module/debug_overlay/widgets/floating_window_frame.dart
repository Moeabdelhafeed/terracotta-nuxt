import 'package:flutter/material.dart';

import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../buttons/global_icon_button.dart';
import '../dev_tool_status.dart';
import '../global_debug_overlay.dart';
import 'status_footer.dart';

/// Draggable + resizable floating window frame for the debug overlay.
///
/// Position and size persist across open/close via static fields so the
/// window returns where the user left it. Drag the title bar to move,
/// drag the bottom-right corner to resize.
class FloatingWindowFrame extends StatefulWidget {
  const FloatingWindowFrame({
    super.key,
    required this.breadcrumb,
    required this.onClose,
    required this.canGoBack,
    required this.onBack,
    required this.child,
    this.entrance = 1,
    this.entranceFrom,
  });

  /// Stack of title segments — first is home, last is the current
  /// page. Rendered as `Home › Logs` chips in the title bar.
  final List<String> breadcrumb;
  final VoidCallback onClose;
  final bool canGoBack;
  final VoidCallback? onBack;
  final Widget child;

  /// Open progress, 0 → 1. Applied INSIDE the frame's `Positioned`: the
  /// caller cannot wrap this widget in an Opacity/Transform, because a
  /// Positioned must stay a direct child of its Stack.
  final double entrance;

  /// Rect the frame grows OUT of — the pill's bounds. The frame lerps
  /// its own rect from this to its resting one, so the window physically
  /// expands from the pill instead of merely scaling in place.
  final Rect? entranceFrom;

  @override
  State<FloatingWindowFrame> createState() => _FloatingWindowFrameState();
}

class _FloatingWindowFrameState extends State<FloatingWindowFrame> {
  // Defaults — used until [DebugOverlayPrefs] hydrates the cached
  // values. Static so subsequent same-session opens skip the empty
  // initial state if prefs already loaded.
  static Offset _position = const Offset(20, 80);
  static Size _size = const Size(380, 560);

  static const _minSize = Size(280, 320);
  static const _edgeInset = 4.0;

  @override
  void initState() {
    super.initState();
    if (DebugOverlayPrefs.loaded) {
      _hydrateFromPrefs();
    } else {
      DebugOverlayPrefs.ensureLoaded().then((_) {
        if (!mounted) return;
        setState(_hydrateFromPrefs);
      });
    }
  }

  void _hydrateFromPrefs() {
    final p = DebugOverlayPrefs.windowPos;
    final s = DebugOverlayPrefs.windowSize;
    if (p != null) _position = p;
    if (s != null) _size = s;
  }

  /// Scale + fade applied INSIDE the Positioned, so the frame stays a
  /// direct Stack child. Wrapping a Positioned from the outside throws
  /// "Incorrect use of ParentDataWidget" on every frame.
  Widget _withEntrance({required Widget child, required Size fullSize}) {
    if (widget.entrance >= 1) return child;
    // The CONTENT keeps its final size and is clipped to the growing
    // rect. Re-laying the whole panel out at every intermediate size
    // would thrash (and squeeze text past its minimums); a fixed-size
    // OverflowBox inside a bounded parent is safe — the earlier crash
    // came from an UNBOUNDED one, which sized itself to a parent that
    // was sizing itself to the box.
    return Opacity(
      opacity: Curves.easeIn.transform(widget.entrance.clamp(0, 1)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: fullSize.width,
          maxWidth: fullSize.width,
          minHeight: fullSize.height,
          maxHeight: fullSize.height,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;

    // Clamp stored rect to the current screen on every build. Unlike
    // the pill, the WINDOW stays out of the safe areas — the title bar
    // is the only drag handle, and parked under a notch / status bar
    // it becomes unreachable.
    final minY = pad.top + _edgeInset;
    final maxBottom = screen.height - pad.bottom - _edgeInset;
    final maxW = (screen.width - _edgeInset * 2).clamp(
      _minSize.width,
      double.infinity,
    );
    final maxH = (maxBottom - minY).clamp(_minSize.height, double.infinity);
    final w = _size.width.clamp(_minSize.width, maxW);
    final h = _size.height.clamp(_minSize.height, maxH);
    final x = _position.dx.clamp(_edgeInset, screen.width - w - _edgeInset);
    final maxY = (maxBottom - h).clamp(minY, double.infinity);
    final y = _position.dy.clamp(minY, maxY);

    // Resting rect, and the one actually painted this frame: while the
    // window is opening it is lerped from the pill's bounds, so the box
    // genuinely GROWS rather than scaling in place.
    final resting = Rect.fromLTWH(x, y, w, h);
    final from = widget.entranceFrom;
    final rect = (from == null || widget.entrance >= 1)
        ? resting
        : Rect.lerp(from, resting, widget.entrance)!;

    return Positioned.fromRect(
      rect: rect,
      child: _withEntrance(
        fullSize: Size(w, h),
        child: Material(
          color: Colors.transparent,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: DebugOverlayTheme.bg.withValues(alpha: 0.93),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DebugOverlayTheme.accent.withValues(alpha: 0.25),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTitleBar(screen, w, h),
                    const _PinnedStrip(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, constraints) {
                          // Two-pane layout when window is wide enough —
                          // dev's tools stay visible while content fills
                          // the right side. Below the threshold the
                          // sidebar would steal too much horizontal space
                          // so we fall back to the stacked Navigator.
                          if (constraints.maxWidth >= 640) {
                            return Row(
                              children: [
                                const _Sidebar(),
                                Container(
                                  width: 1,
                                  color: DebugOverlayTheme.border,
                                ),
                                Expanded(child: widget.child),
                              ],
                            );
                          }
                          return widget.child;
                        },
                      ),
                    ),
                    StatusFooter(
                      onTapNetwork: () =>
                          DebugOverlayController.openTool(DevTool.network),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) {
                      setState(() {
                        _size = Size(
                          (w + d.delta.dx).clamp(
                            _minSize.width,
                            screen.width - x - _edgeInset,
                          ),
                          (h + d.delta.dy).clamp(
                            _minSize.height,
                            maxBottom - y,
                          ),
                        );
                      });
                    },
                    onPanEnd: (_) => DebugOverlayPrefs.saveWindowSize(_size),
                    child: _buildResizeHandle(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(Size screen, double w, double h) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (d) {
        final pad = MediaQuery.of(context).padding;
        final minY = pad.top + _edgeInset;
        final maxY = (screen.height - pad.bottom - _edgeInset - h).clamp(
          minY,
          double.infinity,
        );
        setState(() {
          _position = Offset(
            (_position.dx + d.delta.dx).clamp(
              _edgeInset,
              screen.width - w - _edgeInset,
            ),
            (_position.dy + d.delta.dy).clamp(minY, maxY),
          );
        });
      },
      onPanEnd: (_) => DebugOverlayPrefs.saveWindowPos(_position),
      child: Container(
        height: 40,
        decoration: const BoxDecoration(
          color: DebugOverlayTheme.surface,
          border: Border(bottom: BorderSide(color: DebugOverlayTheme.border)),
        ),
        child: Row(
          children: [
            if (widget.canGoBack)
              GlobalIconButton(
                iconData: Icons.arrow_back_rounded,
                onPressed: widget.onBack,
                enforceMinTouchTarget: false,
                iconSize: 18,
                style: const ButtonStateStyle(
                  foregroundColor: DebugOverlayTheme.text,
                  width: 40,
                  height: 40,
                ),
              )
            else
              const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  if (!widget.canGoBack) const _DragGrip(),
                  if (!widget.canGoBack) const SizedBox(width: 8),
                  Expanded(child: _Breadcrumb(segments: widget.breadcrumb)),
                ],
              ),
            ),
            // Density only reshapes row-heavy TOOL views (logs, network,
            // kv tables) — on home it does nothing, so hide it there.
            ValueListenableBuilder<String?>(
              valueListenable: DebugOverlayController.currentToolName,
              builder: (_, current, child) =>
                  current == null ? const SizedBox.shrink() : child!,
              child: const _DensityToggle(),
            ),
            GlobalIconButton(
              iconData: Icons.close_rounded,
              onPressed: widget.onClose,
              enforceMinTouchTarget: false,
              iconSize: 18,
              style: const ButtonStateStyle(
                foregroundColor: DebugOverlayTheme.textDim,
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle() {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _ResizeHandlePainter()),
    );
  }
}

class _DragGrip extends StatelessWidget {
  const _DragGrip();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          width: 14,
          height: 2,
          color: DebugOverlayTheme.textDimmer,
        ),
      ),
    );
  }
}

/// Persistent left rail rendered when the window is wide enough
/// (≥640dp). Lists every [DevTool] grouped by category so the dev can
/// jump between them without first popping back to the home page.
///
/// Tap a tool → routes via [DebugOverlayController] which pops the
/// existing Navigator stack to home first, then pushes — so depth
/// stays bounded at 1. The current tool is highlighted.
class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final byCategory = <DevToolCategory, List<DevTool>>{};
    for (final tool in DevTool.values) {
      byCategory.putIfAbsent(tool.category, () => []).add(tool);
    }
    return Container(
      width: 180,
      color: DebugOverlayTheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        children: [
          for (final cat in DevToolCategory.values)
            if (byCategory[cat] != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                child: Text(
                  cat.label.toUpperCase(),
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: DebugOverlayTheme.textDimmer,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              for (final tool in byCategory[cat]!) _SidebarItem(tool: tool),
            ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.tool});
  final DevTool tool;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => DebugOverlayController.openTool(tool),
          onLongPress: () => DebugOverlayPrefs.togglePin(tool.name),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(tool.icon, size: 14, color: DebugOverlayTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tool.label,
                    style: DebugOverlayTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinned-tools strip — slim row of icon buttons rendered between the
/// title bar and the body. Visible from every page so devs can jump
/// between favourite tools without first popping back to home.
///
/// Long-press any tool card on the home view to add/remove a pin.
/// State lives in [DebugOverlayPrefs.pinnedTools]; this widget is a
/// pure listener.
class _PinnedStrip extends StatelessWidget {
  const _PinnedStrip();

  @override
  Widget build(BuildContext context) {
    // pinned list + current route + live sim toggles all reshape the
    // strip — merge them into one rebuild trigger.
    final listenable = Listenable.merge([
      DebugOverlayPrefs.pinnedTools,
      DebugOverlayController.currentToolName,
      DevToolStatus.listenable,
    ]);
    return ListenableBuilder(
      listenable: listenable,
      builder: (_, _) {
        final names = DebugOverlayPrefs.pinnedTools.value;
        if (names.isEmpty) return const SizedBox.shrink();
        final current = DebugOverlayController.currentToolName.value;
        // The tool you're already looking at earns no jump chip.
        final tools = <DevTool>[
          for (final n in names)
            if (n != current)
              for (final t in DevTool.values)
                if (t.name == n) t,
        ];
        if (tools.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            color: DebugOverlayTheme.bg,
            border: Border(
              bottom: BorderSide(color: DebugOverlayTheme.border),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.push_pin_rounded,
                size: 11,
                color: DebugOverlayTheme.textDimmer,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tools.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 4),
                  itemBuilder: (_, i) => _PinnedChip(tool: tools[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PinnedChip extends StatelessWidget {
  const _PinnedChip({required this.tool});
  final DevTool tool;

  @override
  Widget build(BuildContext context) {
    final color = DebugOverlayTheme.categoryColor(tool.category);
    final isActive = DevToolStatus.isActive(tool);
    return Material(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => DebugOverlayController.openTool(tool),
        onLongPress: () => DebugOverlayPrefs.togglePin(tool.name),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tool.icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                tool.label,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA726),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Density toggle — flips [DebugOverlayPrefs.density] between
/// [DebugDensity.comfy] and [DebugDensity.compact]. Row-heavy views
/// (logs, kv tables, network) read the notifier and shrink padding +
/// font size when compact.
class _DensityToggle extends StatelessWidget {
  const _DensityToggle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DebugDensity>(
      valueListenable: DebugOverlayPrefs.density,
      builder: (_, value, _) {
        final isCompact = value == DebugDensity.compact;
        // No `tooltip:` — title bar sits above the inner Navigator
        // (which provides the Overlay tooltips need). Adding one here
        // throws "No Overlay widget found" on first build.
        return GlobalIconButton(
          enforceMinTouchTarget: false,
          iconData: isCompact
              ? Icons.density_small_rounded
              : Icons.density_medium_rounded,
          onPressed: () => DebugOverlayPrefs.setDensity(
            isCompact ? DebugDensity.comfy : DebugDensity.compact,
          ),
          iconSize: 16,
          style: const ButtonStateStyle(
            width: 32,
            height: 40,
            foregroundColor: DebugOverlayTheme.textDim,
          ),
        );
      },
    );
  }
}

/// Breadcrumb header — `Home › Logs` chips. Last segment renders bold
/// (current page); earlier ones dimmed. Single segment falls back to a
/// plain title style so the home page doesn't show a lonely chevron.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.segments});

  final List<String> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    if (segments.length == 1) {
      return Text(
        segments.first,
        style: DebugOverlayTheme.ui.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }
    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      final isLast = i == segments.length - 1;
      children.add(
        Flexible(
          child: Text(
            segments[i],
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 13,
              fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
              color: isLast
                  ? DebugOverlayTheme.text
                  : DebugOverlayTheme.textDim,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      if (!isLast) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: DebugOverlayTheme.textDimmer,
            ),
          ),
        );
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _ResizeHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DebugOverlayTheme.textDim
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 3; i++) {
      final gap = i * 4.0;
      canvas.drawLine(
        Offset(size.width - gap, size.height - 1),
        Offset(size.width - 1, size.height - gap),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
