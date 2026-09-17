import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/devtools/perf_flags.dart';
import '../../../../core/devtools/persistent_widget_inspector.dart';
import '../../toast/global_toast.dart';
import '../global_debug_overlay.dart';

/// Performance debugging aids + image cache inspector.
///
/// Framework overlays flip [PerfFlags] notifiers (`MyApp` rebuilds the
/// [MaterialApp] on change); the rendering-global aids (slow
/// animations, repaint rainbow, layout bounds) apply through the
/// PerfFlags setters — rainbow/bounds reassemble after the flip since
/// the framework only re-reads them on paint rebuilds.
class DebugPerfView extends StatefulWidget {
  const DebugPerfView({super.key});

  @override
  State<DebugPerfView> createState() => _DebugPerfViewState();
}

class _DebugPerfViewState extends State<DebugPerfView> {
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    // Image cache stats are sampled — no stream available, just poll
    // every second so the dev sees live values without a refresh tap.
    _statsTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  void _reassembleNextFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.reassembleApplication();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cache = PaintingBinding.instance.imageCache;
    return ListenableBuilder(
      // The inspector notifiers are in here too: its two switches can be
      // flipped from the IDE, from the keyboard shortcut, or by the
      // framework's own reset on exit, and a stale switch in this panel
      // reads as "the toggle is broken".
      listenable: Listenable.merge([
        PerfFlags.listenable,
        PersistentWidgetInspector.selectModeNotifier,
        PersistentWidgetInspector.selectOnTapNotifier,
      ]),
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        children: [
          _FlatSection(
            title: 'Visual debugging',
            icon: Icons.layers_rounded,
            child: _TileGroup(
              children: [
                _ToggleTile(
                  icon: Icons.speed_rounded,
                  label: 'Performance overlay',
                  description:
                      'GPU + UI thread frame-time graphs over every frame',
                  value: PerfFlags.showPerformanceOverlay.value,
                  onChanged: (v) => PerfFlags.showPerformanceOverlay.value = v,
                ),
                _ToggleTile(
                  icon: Icons.grid_on_rounded,
                  label: 'Raster cache checker',
                  description:
                      'Tints cached pictures so re-raster regressions stand out',
                  value: PerfFlags.checkerboardRasterCacheImages.value,
                  onChanged: (v) =>
                      PerfFlags.checkerboardRasterCacheImages.value = v,
                ),
                _ToggleTile(
                  icon: Icons.filter_none_rounded,
                  label: 'Offscreen layers checker',
                  description:
                      'Marks layers composited offscreen — flag fillrate hogs',
                  value: PerfFlags.checkerboardOffscreenLayers.value,
                  onChanged: (v) =>
                      PerfFlags.checkerboardOffscreenLayers.value = v,
                ),
                _ToggleTile(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Semantics debugger',
                  description:
                      'Visualises the semantics tree without a screen reader',
                  value: PerfFlags.showSemanticsDebugger.value,
                  onChanged: (v) => PerfFlags.showSemanticsDebugger.value = v,
                ),
                _ToggleTile(
                  icon: Icons.palette_rounded,
                  label: 'Repaint rainbow',
                  description:
                      'Repaint regions cycle colors — over-repainting jumps out',
                  value: PerfFlags.repaintRainbow.value,
                  onChanged: (v) {
                    PerfFlags.setRepaintRainbow(v);
                    _reassembleNextFrame();
                  },
                ),
                _ToggleTile(
                  icon: Icons.crop_square_rounded,
                  label: 'Layout bounds',
                  description:
                      'Paints boxes, padding and baselines over everything',
                  value: PerfFlags.layoutBounds.value,
                  onChanged: (v) {
                    PerfFlags.setLayoutBounds(v);
                    _reassembleNextFrame();
                  },
                ),
              ],
            ),
          ),
          _FlatSection(
            title: 'Widget inspector',
            icon: Icons.my_location_rounded,
            child: _TileGroup(
              children: [
                _ToggleTile(
                  icon: Icons.my_location_rounded,
                  label: 'Select mode  ·  ⌘/Ctrl + ⇧ + I',
                  description:
                      'Same switch the IDE flips. The shortcut works even '
                      'while select mode blocks every tap',
                  value: PersistentWidgetInspector.selectMode,
                  onChanged: (v) => PersistentWidgetInspector.selectMode = v,
                ),
                _ToggleTile(
                  icon: Icons.touch_app_rounded,
                  label: 'Select on tap  ·  ⌘/Ctrl + ⇧ + T',
                  description:
                      'Off lets taps reach the app while the inspector '
                      'stays open. Persisted — the framework resets it on '
                      'every launch, this puts it back',
                  value: PersistentWidgetInspector.selectOnTap,
                  onChanged: (v) => PersistentWidgetInspector.selectOnTap = v,
                ),
                _ToggleTile(
                  icon: Icons.keyboard_rounded,
                  label: 'Trace key events',
                  description:
                      'Logs every key the shortcut handler is offered. A '
                      'dead shortcut prints nothing here when the platform '
                      'is not delivering keys at all',
                  value: PersistentWidgetInspector.debugTraceKeys,
                  onChanged: (v) => setState(
                    () => PersistentWidgetInspector.debugTraceKeys = v,
                  ),
                ),
              ],
            ),
          ),
          _FlatSection(
            title: 'Animation',
            icon: Icons.slow_motion_video_rounded,
            child: _TileGroup(
              children: [
                _ToggleTile(
                  icon: Icons.slow_motion_video_rounded,
                  label: 'Slow animations (×5)',
                  description:
                      'timeDilation 5 — inspect janky transitions frame by frame',
                  value: PerfFlags.slowAnimations.value,
                  onChanged: PerfFlags.setSlowAnimations,
                ),
              ],
            ),
          ),
          _FlatSection(
            title: 'Image cache',
            icon: Icons.image_rounded,
            trailing: _EvictButton(
              onTap: () {
                cache.clear();
                cache.clearLiveImages();
                GlobalToast.success('Image cache evicted');
                if (mounted) setState(() {});
              },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UsageBar(
                  label: 'images',
                  current: cache.currentSize,
                  max: cache.maximumSize,
                  currentLabel: '${cache.currentSize}',
                  maxLabel: '${cache.maximumSize}',
                ),
                const SizedBox(height: 8),
                _UsageBar(
                  label: 'memory',
                  current: cache.currentSizeBytes,
                  max: cache.maximumSizeBytes,
                  currentLabel: _formatBytes(cache.currentSizeBytes),
                  maxLabel: _formatBytes(cache.maximumSizeBytes),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                      label: 'live (in use)',
                      value: '${cache.liveImageCount}',
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      label: 'pending decode',
                      value: '${cache.pendingImageCount}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Frame timing has its own dedicated tool — point, don't clone.
          _FlatSection(
            title: 'Frame timing',
            icon: Icons.stacked_line_chart_rounded,
            child: _LinkTile(
              label: 'Open Frame timeline',
              description:
                  'Per-frame build/raster chart with jank highlighting',
              onTap: () =>
                  DebugOverlayController.openTool(DevTool.frameTimeline),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    final mb = bytes / (1024 * 1024);
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }
}

// ─────────────────────────────────────────────────────────────

class _FlatSection extends StatelessWidget {
  const _FlatSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: DebugOverlayTheme.textDim),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DebugOverlayTheme.textDim,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// One bordered surface hosting rows separated by hairlines.
class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                color: DebugOverlayTheme.border.withValues(alpha: 0.5),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (value ? accent : DebugOverlayTheme.textDimmer)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                icon,
                size: 14,
                color: value ? accent : DebugOverlayTheme.textDim,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 10,
                      color: DebugOverlayTheme.textDim,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: accent,
              activeTrackColor: accent.withValues(alpha: 0.4),
              inactiveThumbColor: DebugOverlayTheme.textDim,
              inactiveTrackColor: DebugOverlayTheme.surfaceHigh,
              trackOutlineColor: const WidgetStatePropertyAll(
                DebugOverlayTheme.border,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.label,
    required this.description,
    required this.onTap,
  });

  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DebugOverlayTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 10,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: DebugOverlayTheme.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvictButton extends StatelessWidget {
  const _EvictButton({required this.onTap});
  final VoidCallback onTap;

  static const _red = Color(0xFFEF5350);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _red.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_sweep_rounded, size: 12, color: _red),
              const SizedBox(width: 4),
              Text(
                'Evict',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label + thin usage bar + `current / max` — fill color shifts amber
/// past 80%.
class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.label,
    required this.current,
    required this.max,
    required this.currentLabel,
    required this.maxLabel,
  });

  final String label;
  final int current;
  final int max;
  final String currentLabel;
  final String maxLabel;

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    final color = fraction > 0.8
        ? const Color(0xFFFFA726)
        : DebugOverlayTheme.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10.5,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ),
            Text(
              '$currentLabel / $maxLabel',
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 5,
            child: Stack(
              children: [
                Container(color: DebugOverlayTheme.surfaceHigh),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: DebugOverlayTheme.mono.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: DebugOverlayTheme.ui.copyWith(
            fontSize: 10,
            color: DebugOverlayTheme.textDimmer,
          ),
        ),
      ],
    );
  }
}
