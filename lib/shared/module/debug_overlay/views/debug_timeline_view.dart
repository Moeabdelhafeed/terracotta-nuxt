import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/enums/app/log_level.dart';
import '../../../../core/devtools/debug_bloc_observer.dart';
import '../../../../core/devtools/network_capture.dart';
import '../../../../core/navigation/navigation_tracker.dart';
import '../../../../core/utils/loggers/log_buffer.dart';
import '../debug_overlay_models.dart';

/// One chronological stream of everything the overlay's ring buffers
/// know: navigation events, bloc transitions, network calls, and
/// warning+ logs. Answers "what happened in the last 30 seconds
/// before the bug" without hopping between four tools.
class DebugTimelineView extends StatefulWidget {
  const DebugTimelineView({super.key});

  @override
  State<DebugTimelineView> createState() => _DebugTimelineViewState();
}

enum _Source { nav, bloc, net, log }

class _Event {
  const _Event({
    required this.at,
    required this.source,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final DateTime at;
  final _Source source;
  final String title;
  final String subtitle;
  final Color color;
}

class _DebugTimelineViewState extends State<DebugTimelineView> {
  final _subs = <StreamSubscription<void>>[];
  _Source? _filter;

  @override
  void initState() {
    super.initState();
    void listen<T>(Stream<T> s) {
      _subs.add(
        s.listen((_) {
          if (mounted) setState(() {});
        }),
      );
    }

    listen(NavigationTracker().historyChanges);
    listen(DebugBlocObserver.changes);
    listen(NetworkCapture.changes);
    listen(LogBuffer.onAdd);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  static const _sourceMeta = <_Source, (String, IconData, Color)>{
    _Source.nav: ('NAV', Icons.route_rounded, Color(0xFF66BB6A)),
    _Source.bloc: ('BLOC', Icons.account_tree_rounded, Color(0xFF64B5F6)),
    _Source.net: ('NET', Icons.swap_vert_rounded, Color(0xFF4FC3F7)),
    _Source.log: ('LOG', Icons.warning_amber_rounded, Color(0xFFFFA726)),
  };

  List<_Event> _merged() {
    final events = <_Event>[
      for (final e in NavigationTracker().historySnapshot)
        _Event(
          at: e.at,
          source: _Source.nav,
          title: '${e.kind.name.toUpperCase()} ${e.route}',
          subtitle: e.previous == null ? '' : 'from ${e.previous}',
          color: _sourceMeta[_Source.nav]!.$3,
        ),
      for (final e in DebugBlocObserver.snapshot)
        _Event(
          at: e.at,
          source: _Source.bloc,
          title: e.blocType,
          subtitle: e.summary,
          color: _sourceMeta[_Source.bloc]!.$3,
        ),
      for (final e in NetworkCapture.entries)
        _Event(
          at: e.startedAt,
          source: _Source.net,
          title: '${e.method} ${_pathOnly(e.url)}',
          subtitle: [
            e.statusCode?.toString() ?? e.errorType ?? 'pending',
            if (e.duration != null) '${e.duration!.inMilliseconds}ms',
          ].join(' · '),
          color: _netColor(e),
        ),
      for (final e in LogBuffer.all)
        if (e.level.index >= LogLevel.warning.index)
          _Event(
            at: e.time,
            source: _Source.log,
            title: '${e.level.name.toUpperCase()} [${e.name}]',
            subtitle: e.message,
            color: DebugOverlayTheme.levelColor(e.level),
          ),
    ];
    events.sort((a, b) => b.at.compareTo(a.at));
    // Cap so four full ring buffers can't produce a 1000-row list.
    return events.length > 300 ? events.sublist(0, 300) : events;
  }

  static Color _netColor(NetworkCaptureEntry e) => switch (e.bucket) {
    StatusBucket.success => const Color(0xFF66BB6A),
    StatusBucket.redirect => const Color(0xFF4FC3F7),
    StatusBucket.clientError => const Color(0xFFFFA726),
    StatusBucket.error => const Color(0xFFEF5350),
    StatusBucket.pending => DebugOverlayTheme.textDim,
  };

  static String _pathOnly(String url) {
    final i = url.indexOf('://');
    if (i < 0) return url;
    final after = url.substring(i + 3);
    final slash = after.indexOf('/');
    return slash < 0 ? '/' : after.substring(slash);
  }

  @override
  Widget build(BuildContext context) {
    final all = _merged();
    final shown = [
      for (final e in all)
        if (_filter == null || e.source == _filter) e,
    ];
    final counts = <_Source, int>{};
    for (final e in all) {
      counts[e.source] = (counts[e.source] ?? 0) + 1;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: const BoxDecoration(
            color: DebugOverlayTheme.surface,
            border: Border(bottom: BorderSide(color: DebugOverlayTheme.border)),
          ),
          child: SizedBox(
            height: 26,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'all',
                  count: all.length,
                  color: DebugOverlayTheme.accent,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final MapEntry(key: source, value: (label, _, color))
                    in _sourceMeta.entries) ...[
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: label.toLowerCase(),
                    count: counts[source] ?? 0,
                    color: color,
                    selected: _filter == source,
                    onTap: () => setState(
                      () => _filter = _filter == source ? null : source,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(
                    'No events yet — interact with the app',
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 11,
                      color: DebugOverlayTheme.textDimmer,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => Container(
                    height: 1,
                    color: DebugOverlayTheme.border.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (_, i) => _Row(
                    event: shown[i],
                    // Newest-first — the chronologically previous event
                    // sits one index later.
                    gap: i + 1 < shown.length
                        ? shown[i].at.difference(shown[i + 1].at)
                        : null,
                  ),
                ),
        ),
      ],
    );
  }
}

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
  const _Row({required this.event, required this.gap});

  final _Event event;
  final Duration? gap;

  @override
  Widget build(BuildContext context) {
    final (label, icon, _) = _DebugTimelineViewState._sourceMeta[event.source]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: event.color.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 9, color: event.color),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: event.color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        overflow: TextOverflow.ellipsis,
                        style: DebugOverlayTheme.mono.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _hmsMs(event.at),
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 9.5,
                        color: DebugOverlayTheme.textDimmer,
                      ),
                    ),
                  ],
                ),
                if (event.subtitle.isNotEmpty || gap != null)
                  Row(
                    children: [
                      if (event.subtitle.isNotEmpty)
                        Flexible(
                          child: Text(
                            event.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 10,
                              color: DebugOverlayTheme.textDim,
                            ),
                          ),
                        ),
                      if (gap != null) ...[
                        if (event.subtitle.isNotEmpty) const SizedBox(width: 8),
                        Text(
                          '+${_fmtGap(gap!)}',
                          style: DebugOverlayTheme.mono.copyWith(
                            fontSize: 9.5,
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
        ],
      ),
    );
  }

  static String _fmtGap(Duration d) {
    if (d.inMilliseconds < 1000) return '${d.inMilliseconds}ms';
    if (d.inSeconds < 60) {
      return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
    return '${d.inMinutes}m${d.inSeconds % 60}s';
  }

  static String _hmsMs(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
