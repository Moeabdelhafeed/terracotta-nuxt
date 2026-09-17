import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/connectivity/connectivity_state.dart';
import '../../../../core/di/service_locator.dart';
import '../debug_overlay_models.dart';

/// Slim status row pinned at the bottom of the developer overlay
/// window. Surfaces three live signals always-on regardless of which
/// tool is open:
///   • FPS — sampled from raster timings, EWMA smoothed
///   • Heap — process RSS on native, hidden on web (no API)
///   • Network — connectivity verdict + offline queue depth
///
/// Each segment is a tap target so the dev can dive into the relevant
/// tool. Hooks are wired by [onTapNetwork] etc — leave null to disable.
class StatusFooter extends StatefulWidget {
  const StatusFooter({
    super.key,
    this.onTapFps,
    this.onTapHeap,
    this.onTapNetwork,
  });

  final VoidCallback? onTapFps;
  final VoidCallback? onTapHeap;
  final VoidCallback? onTapNetwork;

  @override
  State<StatusFooter> createState() => _StatusFooterState();
}

class _StatusFooterState extends State<StatusFooter> {
  // FPS — running EWMA over the last few frames, computed from raster
  // timestamps. Skips frames where rasterDuration == 0 (no work) so
  // an idle UI doesn't pull the average to "infinity".
  double _fps = 60;
  Timer? _fpsTimer;

  // Heap — re-sampled every couple seconds. ProcessInfo.currentRss is
  // a syscall, no need to spam it.
  int? _heapBytes;
  Timer? _heapTimer;

  // Connectivity — pulled from the [ConnectivityCubit] via service
  // locator (this widget mounts inside the debug overlay which sits
  // above the BlocProvider tree, so InheritedWidget access doesn't
  // resolve here).
  ConnectivityState? _connectivityState;
  StreamSubscription<ConnectivityState>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    _fpsTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => mounted ? setState(() {}) : null,
    );

    if (!kIsWeb) {
      _heapTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted) return;
        setState(() => _heapBytes = io.ProcessInfo.currentRss);
      });
      _heapBytes = io.ProcessInfo.currentRss;
    }

    // Service locator may not be registered in tests / very early
    // bootstrap — guard so the footer degrades gracefully.
    final cubit = getIt.isRegistered<ConnectivityCubit>()
        ? getIt<ConnectivityCubit>()
        : null;
    if (cubit != null) {
      _connectivityState = cubit.state;
      _connectivitySub = cubit.stream.listen((s) {
        if (!mounted) return;
        setState(() => _connectivityState = s);
      });
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _fpsTimer?.cancel();
    _heapTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    for (final t in timings) {
      // Total frame time = build + raster (in microseconds). Convert
      // to FPS, clamp at 120 to swallow outliers.
      final us = t.totalSpan.inMicroseconds;
      if (us <= 0) continue;
      final instant = (1e6 / us).clamp(1.0, 120.0);
      // EWMA, alpha = 0.15 → smooth but reactive within a few frames.
      _fps = _fps * 0.85 + instant * 0.15;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: const BoxDecoration(
        color: DebugOverlayTheme.surface,
        border: Border(top: BorderSide(color: DebugOverlayTheme.border)),
      ),
      child: Row(
        children: [
          _Segment(
            icon: Icons.speed_rounded,
            label: '${_fps.round()} fps',
            color: _fpsColor(_fps),
            onTap: widget.onTapFps,
          ),
          const _SegmentDivider(),
          if (!kIsWeb && _heapBytes != null) ...[
            _Segment(
              icon: Icons.memory_rounded,
              label: _formatBytes(_heapBytes!),
              color: DebugOverlayTheme.textDim,
              onTap: widget.onTapHeap,
            ),
            const _SegmentDivider(),
          ],
          _Segment(
            icon: _netIcon(_connectivityState),
            label: _netLabel(_connectivityState),
            color: _netColor(_connectivityState),
            onTap: widget.onTapNetwork,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─── Network signal ─────────────────────────────────────────

  static IconData _netIcon(ConnectivityState? s) {
    if (s == null) return Icons.help_outline_rounded;
    return switch (s.verdict) {
      ConnectivityVerdict.online => Icons.cloud_done_rounded,
      ConnectivityVerdict.offline => Icons.cloud_off_rounded,
      ConnectivityVerdict.probeUntrusted => Icons.cloud_queue_rounded,
      ConnectivityVerdict.unknown => Icons.cloud_queue_rounded,
    };
  }

  static String _netLabel(ConnectivityState? s) {
    if (s == null) return 'net?';
    final verdict = switch (s.verdict) {
      ConnectivityVerdict.online => 'online',
      ConnectivityVerdict.offline => 'offline',
      ConnectivityVerdict.probeUntrusted => 'probe?',
      ConnectivityVerdict.unknown => 'unknown',
    };
    if (s.queuedActions > 0) return '$verdict · ${s.queuedActions} queued';
    return verdict;
  }

  static Color _netColor(ConnectivityState? s) {
    if (s == null) return DebugOverlayTheme.textDim;
    return switch (s.verdict) {
      ConnectivityVerdict.online => const Color(0xFF66BB6A),
      ConnectivityVerdict.offline => const Color(0xFFEF5350),
      ConnectivityVerdict.probeUntrusted => const Color(0xFFFFA726),
      ConnectivityVerdict.unknown => DebugOverlayTheme.textDim,
    };
  }

  // ─── FPS color thresholds ───────────────────────────────────

  static Color _fpsColor(double fps) {
    if (fps >= 55) return const Color(0xFF66BB6A);
    if (fps >= 40) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  // ─── Heap formatting ────────────────────────────────────────

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    final mb = bytes / (1024 * 1024);
    if (mb < 1024) return '${mb.toStringAsFixed(0)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 10.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      child: body,
    );
  }
}

class _SegmentDivider extends StatelessWidget {
  const _SegmentDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      color: DebugOverlayTheme.border,
    );
  }
}
