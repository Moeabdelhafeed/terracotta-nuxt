import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/devtools/frame_timings.dart';
import '../../buttons/global_icon_button.dart';
import '../debug_overlay_models.dart';

/// Frame-timing lab: the last ~180 frames as stacked build+raster bars
/// with the display's real frame budget drawn in, jank frames flagged,
/// stat chips (fps / avg / p95 / worst / jank%), pause + clear.
class DebugFrameTimelineView extends StatefulWidget {
  const DebugFrameTimelineView({super.key});

  @override
  State<DebugFrameTimelineView> createState() => _DebugFrameTimelineViewState();
}

class _DebugFrameTimelineViewState extends State<DebugFrameTimelineView> {
  StreamSubscription<void>? _sub;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _sub = FrameTimings.changes.listen((_) {
      // Paused = stop repainting; the ring buffer keeps rolling so
      // resume shows current data, not a stale freeze-frame.
      if (mounted && !_paused) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Frame budget from the display's REAL refresh rate — 8.3ms on a
  /// 120Hz panel, not a hardcoded 16.7.
  double _budgetMs(BuildContext context) {
    final view = View.of(context);
    final rate = view.display.refreshRate;
    if (rate.isNaN || rate <= 0) return 1000 / 60;
    return 1000 / rate;
  }

  @override
  Widget build(BuildContext context) {
    final samples = FrameTimings.samples.toList().reversed.toList();
    final budget = _budgetMs(context);

    if (samples.isEmpty) {
      return Center(
        child: Text(
          'Warming up — interact with the app to record frames.',
          style: DebugOverlayTheme.ui.copyWith(
            color: DebugOverlayTheme.textDimmer,
          ),
        ),
      );
    }

    final totals = samples.map((s) => s.totalMs).toList();
    final avg = totals.reduce((a, b) => a + b) / totals.length;
    final sorted = [...totals]..sort();
    final p95 =
        sorted[(sorted.length * 0.95 - 1).clamp(0, sorted.length - 1).toInt()];
    final worst = sorted.last;
    final jankCount = totals.where((t) => t > budget).length;
    final jankPct = jankCount / totals.length * 100;
    final jankColor = jankPct > 10
        ? const Color(0xFFEF5350)
        : jankPct > 3
        ? const Color(0xFFFFA726)
        : const Color(0xFF66BB6A);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        // Stat chips row.
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _StatChip(label: 'fps', value: (1000 / avg).toStringAsFixed(0)),
            _StatChip(label: 'avg', value: '${avg.toStringAsFixed(1)}ms'),
            _StatChip(label: 'p95', value: '${p95.toStringAsFixed(1)}ms'),
            _StatChip(label: 'worst', value: '${worst.toStringAsFixed(1)}ms'),
            _StatChip(
              label: 'jank',
              value: '$jankCount (${jankPct.toStringAsFixed(0)}%)',
              color: jankColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _FlatSection(
          title:
              'Frames — newest right · budget ${budget.toStringAsFixed(1)}ms',
          icon: Icons.stacked_line_chart_rounded,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlobalIconButton(
                tooltip: _paused ? 'Resume' : 'Pause',
                enforceMinTouchTarget: false,
                iconData: _paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                onPressed: () => setState(() => _paused = !_paused),
                iconSize: 14,
                style: ButtonStateStyle(
                  width: 28,
                  height: 28,
                  foregroundColor: _paused
                      ? DebugOverlayTheme.accent
                      : DebugOverlayTheme.textDim,
                ),
              ),
              GlobalIconButton(
                tooltip: 'Clear buffer',
                enforceMinTouchTarget: false,
                iconData: Icons.delete_sweep_rounded,
                onPressed: () {
                  FrameTimings.clear();
                  setState(() {});
                },
                iconSize: 14,
                style: const ButtonStateStyle(
                  width: 28,
                  height: 28,
                  foregroundColor: DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: DebugOverlayTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DebugOverlayTheme.border),
                ),
                padding: const EdgeInsets.all(8),
                child: CustomPaint(
                  painter: _BarsPainter(samples: samples, budgetMs: budget),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  _LegendDot(color: Color(0xFF64B5F6), label: 'build'),
                  SizedBox(width: 12),
                  _LegendDot(color: Color(0xFFEF5350), label: 'raster'),
                  SizedBox(width: 12),
                  _LegendDot(color: Color(0xFFFFA726), label: 'over budget'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
    return Column(
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
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DebugOverlayTheme.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? DebugOverlayTheme.surface).withValues(
          alpha: color == null ? 1 : 0.12,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color?.withValues(alpha: 0.5) ?? DebugOverlayTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color ?? DebugOverlayTheme.text,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: DebugOverlayTheme.ui.copyWith(fontSize: 9.5, color: c),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: DebugOverlayTheme.ui.copyWith(
            fontSize: 10,
            color: DebugOverlayTheme.textDim,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Stacked per-frame bars: build (blue) below, raster (red) above, an
/// amber cap marks frames past the budget. Dashed budget guide across.
class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.samples, required this.budgetMs});

  final List<FrameSample> samples;
  final double budgetMs;

  static final _buildPaint = Paint()..color = const Color(0xFF64B5F6);
  static final _rasterPaint = Paint()..color = const Color(0xFFEF5350);
  static final _jankPaint = Paint()..color = const Color(0xFFFFA726);

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    // Scale to the worst frame, but never let the budget line ride the
    // top edge — keep at least 1.5x budget of headroom.
    final maxV = math.max(
      samples.map((s) => s.totalMs).fold<double>(0, math.max),
      budgetMs * 1.5,
    );
    double yOf(double ms) => size.height - (ms / maxV) * size.height;

    // Dashed budget guide.
    final guideY = yOf(budgetMs);
    final guide = Paint()
      ..color = DebugOverlayTheme.textDim.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const dash = 4.0;
    for (var x = 0.0; x < size.width; x += dash * 2) {
      canvas.drawLine(
        Offset(x, guideY),
        Offset(math.min(x + dash, size.width), guideY),
        guide,
      );
    }

    final slot = size.width / samples.length;
    final barW = math.max(1.0, slot * 0.7);
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final x = i * slot + (slot - barW) / 2;
      final buildTop = yOf(s.buildMs);
      final totalTop = yOf(s.buildMs + s.rasterMs);
      // Build segment (bottom).
      canvas.drawRect(
        Rect.fromLTRB(x, buildTop, x + barW, size.height),
        _buildPaint,
      );
      // Raster segment stacked above.
      canvas.drawRect(
        Rect.fromLTRB(x, totalTop, x + barW, buildTop),
        _rasterPaint,
      );
      // Over-budget cap marker.
      if (s.totalMs > budgetMs) {
        canvas.drawRect(
          Rect.fromLTRB(x, totalTop - 3, x + barW, totalTop),
          _jankPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      !identical(old.samples, samples) ||
      old.samples.length != samples.length ||
      old.budgetMs != budgetMs;
}
