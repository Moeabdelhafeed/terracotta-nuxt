import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/go_router_config.dart';
import '../../../../core/navigation/navigation_tracker.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';

/// Recent navigation events from [NavigationTracker] plus the live
/// route stack. Filter by kind; rows show the gap since the previous
/// event so slow flows stand out. Tap a row to re-navigate — push
/// events use the recorded route, pop events fall back to the
/// revealed route.
class DebugRouteHistoryView extends StatefulWidget {
  const DebugRouteHistoryView({super.key});

  @override
  State<DebugRouteHistoryView> createState() => _DebugRouteHistoryViewState();
}

class _DebugRouteHistoryViewState extends State<DebugRouteHistoryView> {
  StreamSubscription<void>? _sub;
  RouteHistoryKind? _kindFilter;

  @override
  void initState() {
    super.initState();
    _sub = NavigationTracker().historyChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  static const _kindMeta = <RouteHistoryKind, (String, Color)>{
    RouteHistoryKind.push: ('push', Color(0xFF66BB6A)),
    RouteHistoryKind.pop: ('pop', Color(0xFFFFA726)),
    RouteHistoryKind.replace: ('repl', Color(0xFF64B5F6)),
  };

  @override
  Widget build(BuildContext context) {
    final all = NavigationTracker().historySnapshot;
    final stack = NavigationTracker().stackSnapshot;
    final shown = [
      for (final e in all)
        if (_kindFilter == null || e.kind == _kindFilter) e,
    ];
    final counts = <RouteHistoryKind, int>{};
    for (final e in all) {
      counts[e.kind] = (counts[e.kind] ?? 0) + 1;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          decoration: const BoxDecoration(
            color: DebugOverlayTheme.surface,
            border: Border(bottom: BorderSide(color: DebugOverlayTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 26,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'all',
                        count: all.length,
                        color: DebugOverlayTheme.accent,
                        selected: _kindFilter == null,
                        onTap: () => setState(() => _kindFilter = null),
                      ),
                      for (final MapEntry(key: kind, value: (label, color))
                          in _kindMeta.entries) ...[
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: label,
                          count: counts[kind] ?? 0,
                          color: color,
                          selected: _kindFilter == kind,
                          onTap: () => setState(
                            () =>
                                _kindFilter = _kindFilter == kind ? null : kind,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              GlobalIconButton(
                tooltip: 'Clear history',
                enforceMinTouchTarget: false,
                iconData: Icons.delete_sweep_rounded,
                onPressed: () {
                  NavigationTracker().clearHistory();
                  GlobalToast.info('Navigation history cleared');
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
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (stack.isNotEmpty) _CurrentStack(stack: stack),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 13,
                      color: DebugOverlayTheme.textDim,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'EVENTS',
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DebugOverlayTheme.textDim,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${shown.length}',
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 10,
                        color: DebugOverlayTheme.textDimmer,
                      ),
                    ),
                  ],
                ),
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      all.isEmpty
                          ? 'No navigation events yet — move around the app'
                          : 'Nothing matches the filter',
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 11,
                        color: DebugOverlayTheme.textDimmer,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: DebugOverlayTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DebugOverlayTheme.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < shown.length; i++) ...[
                        if (i > 0)
                          Container(
                            height: 1,
                            color: DebugOverlayTheme.border.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        _Row(
                          entry: shown[i],
                          // Newest-first list: the chronologically
                          // previous event sits one index later.
                          gap: i + 1 < shown.length
                              ? shown[i].at.difference(shown[i + 1].at)
                              : null,
                          onGoTo: () => _goTo(context, shown[i]),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Re-navigate to a recorded entry. Push entries use the recorded
  /// route name (resolved against the registered GoRouter routes);
  /// pop entries jump to the previous route since "going to a popped
  /// route" rarely matches dev intent.
  void _goTo(BuildContext context, RouteHistoryEntry entry) {
    final target = switch (entry.kind) {
      RouteHistoryKind.pop => entry.previous ?? entry.route,
      _ => entry.route,
    };
    if (target.isEmpty) return;
    final router = GoRouterConfig.router;
    try {
      router.goNamed(target);
      GlobalToast.info('→ $target');
      return;
    } catch (_) {
      // Not a known name. Try as path.
    }
    if (target.startsWith('/')) {
      router.go(target);
    } else {
      router.go('/$target');
    }
    GlobalToast.info('→ $target');
  }
}

// ─────────────────────────────────────────────────────────────
// Live stack
// ─────────────────────────────────────────────────────────────

class _CurrentStack extends StatelessWidget {
  const _CurrentStack({required this.stack});

  /// Bottom-first as tracked; rendered top-of-stack first.
  final List<String> stack;

  @override
  Widget build(BuildContext context) {
    final topFirst = stack.reversed.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.layers_rounded,
                size: 13,
                color: DebugOverlayTheme.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                'CURRENT STACK',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: DebugOverlayTheme.textDim,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${stack.length} deep',
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10,
                  color: DebugOverlayTheme.textDimmer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: DebugOverlayTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DebugOverlayTheme.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < topFirst.length; i++) ...[
                  if (i > 0)
                    Container(
                      height: 1,
                      color: DebugOverlayTheme.border.withValues(alpha: 0.5),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                    child: Row(
                      children: [
                        Icon(
                          i == 0
                              ? Icons.my_location_rounded
                              : Icons.subdirectory_arrow_right_rounded,
                          size: 13,
                          color: i == 0
                              ? DebugOverlayTheme.accentDefault
                              : DebugOverlayTheme.textDimmer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            topFirst[i],
                            overflow: TextOverflow.ellipsis,
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 11,
                              fontWeight: i == 0
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: i == 0
                                  ? DebugOverlayTheme.text
                                  : DebugOverlayTheme.textDim,
                            ),
                          ),
                        ),
                        if (i == 0)
                          Text(
                            'top',
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: DebugOverlayTheme.accentDefault,
                              letterSpacing: 0.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter chip + row
// ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.18) : DebugOverlayTheme.bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.6)
                  : DebugOverlayTheme.border,
            ),
          ),
          child: Text(
            '$label $count',
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? color : DebugOverlayTheme.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.gap, required this.onGoTo});

  final RouteHistoryEntry entry;

  /// Time since the chronologically previous event; null for the
  /// oldest entry in view.
  final Duration? gap;

  final VoidCallback onGoTo;

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(entry.kind);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onGoTo,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KindChip(kind: entry.kind, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.route,
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          _hms(entry.at),
                          style: DebugOverlayTheme.mono.copyWith(
                            fontSize: 10,
                            color: DebugOverlayTheme.textDimmer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (entry.previous != null)
                          Flexible(
                            child: Text(
                              _previousLabel(entry.kind, entry.previous!),
                              style: DebugOverlayTheme.mono.copyWith(
                                fontSize: 10,
                                color: DebugOverlayTheme.textDim,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        if (gap != null) ...[
                          if (entry.previous != null) const SizedBox(width: 8),
                          Text(
                            '+${_fmtGap(gap!)}',
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 10,
                              color: gap!.inSeconds >= 10
                                  ? const Color(0xFFFFA726)
                                  : DebugOverlayTheme.textDimmer,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: DebugOverlayTheme.textDimmer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _previousLabel(RouteHistoryKind kind, String prev) =>
      switch (kind) {
        RouteHistoryKind.push => 'from $prev',
        RouteHistoryKind.pop => 'to $prev',
        RouteHistoryKind.replace => 'replaced $prev',
      };

  static Color _kindColor(RouteHistoryKind k) => switch (k) {
    RouteHistoryKind.push => const Color(0xFF66BB6A),
    RouteHistoryKind.pop => const Color(0xFFFFA726),
    RouteHistoryKind.replace => const Color(0xFF64B5F6),
  };

  static String _fmtGap(Duration d) {
    if (d.inMilliseconds < 1000) return '${d.inMilliseconds}ms';
    if (d.inSeconds < 60) {
      return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
    return '${d.inMinutes}m${d.inSeconds % 60}s';
  }

  static String _hms(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind, required this.color});

  final RouteHistoryKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      RouteHistoryKind.push => 'PUSH',
      RouteHistoryKind.pop => 'POP',
      RouteHistoryKind.replace => 'REPL',
    };
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: DebugOverlayTheme.mono.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
