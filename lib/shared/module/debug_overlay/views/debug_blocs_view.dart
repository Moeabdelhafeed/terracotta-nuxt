import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/devtools/debug_bloc_observer.dart';
import '../../buttons/global_icon_button.dart';
import '../../sheet/global_sheet.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_search_field.dart';
import '../widgets/debug_surfaces.dart';

/// Live transition log captured by [DebugBlocObserver]. Filter by bloc
/// name (search) or lifecycle kind (chips); pause to inspect without
/// the list jumping under new entries; tap a row for the full state /
/// event dump.
class DebugBlocsView extends StatefulWidget {
  const DebugBlocsView({super.key});

  @override
  State<DebugBlocsView> createState() => _DebugBlocsViewState();
}

class _DebugBlocsViewState extends State<DebugBlocsView> {
  StreamSubscription<void>? _sub;
  String _filter = '';
  BlocTransitionKind? _kindFilter;
  bool _paused = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sub = DebugBlocObserver.changes.listen((_) {
      // Buffer keeps recording while paused; the view just stops
      // repainting so rows hold still under the dev's finger.
      if (mounted && !_paused) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _kindMeta = <BlocTransitionKind, (String, Color)>{
    BlocTransitionKind.create: ('NEW', Color(0xFF66BB6A)),
    BlocTransitionKind.change: ('CHG', Color(0xFF64B5F6)),
    BlocTransitionKind.transition: ('TXN', Color(0xFF4FC3F7)),
    BlocTransitionKind.error: ('ERR', Color(0xFFEF5350)),
    BlocTransitionKind.close: ('END', Color(0xFFFFA726)),
  };

  @override
  Widget build(BuildContext context) {
    final all = DebugBlocObserver.snapshot;
    final q = _filter.trim().toLowerCase();
    final shown = [
      for (final e in all)
        if ((q.isEmpty || e.blocType.toLowerCase().contains(q)) &&
            (_kindFilter == null || e.kind == _kindFilter))
          e,
    ];
    final kindCounts = <BlocTransitionKind, int>{};
    for (final e in all) {
      kindCounts[e.kind] = (kindCounts[e.kind] ?? 0) + 1;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          decoration: const BoxDecoration(
            color: DebugOverlayTheme.surface,
            border: Border(bottom: BorderSide(color: DebugOverlayTheme.border)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DebugSearchField(
                      controller: _searchCtrl,
                      hintText: 'Filter by bloc',
                      onChanged: (v) => setState(() => _filter = v),
                      resultCount: q.isEmpty && _kindFilter == null
                          ? null
                          : shown.length,
                    ),
                  ),
                  const SizedBox(width: 4),
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
                          ? const Color(0xFFFFA726)
                          : DebugOverlayTheme.textDim,
                    ),
                  ),
                  GlobalIconButton(
                    tooltip: 'Clear',
                    enforceMinTouchTarget: false,
                    iconData: Icons.delete_sweep_rounded,
                    onPressed: () {
                      DebugBlocObserver.clear();
                      GlobalToast.info('Transition log cleared');
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
              const SizedBox(height: 8),
              SizedBox(
                height: 26,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _KindFilterChip(
                      label: 'all',
                      count: all.length,
                      color: DebugOverlayTheme.accent,
                      selected: _kindFilter == null,
                      onTap: () => setState(() => _kindFilter = null),
                    ),
                    for (final MapEntry(key: kind, value: (label, color))
                        in _kindMeta.entries) ...[
                      const SizedBox(width: 6),
                      _KindFilterChip(
                        label: label.toLowerCase(),
                        count: kindCounts[kind] ?? 0,
                        color: color,
                        selected: _kindFilter == kind,
                        onTap: () => setState(
                          () => _kindFilter = _kindFilter == kind ? null : kind,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_paused)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: const Color(0xFFFFA726).withValues(alpha: 0.12),
            child: Text(
              'PAUSED — buffer still recording, tap ▶ to catch up',
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFA726),
                letterSpacing: 0.4,
              ),
            ),
          ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(
                    all.isEmpty
                        ? 'No transitions yet — interact with the app'
                        : 'Nothing matches the filter',
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 11,
                      color: DebugOverlayTheme.textDimmer,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => Container(
                    height: 1,
                    color: DebugOverlayTheme.border.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (_, i) => _Row(
                    entry: shown[i],
                    onTap: () => _showDetail(context, shown[i]),
                  ),
                ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, BlocTransitionEntry entry) {
    final (label, color) = _kindMeta[entry.kind]!;
    GlobalBottomSheet.show<void>(
      context: context,
      showCloseButton: false,
      style: debugSheetStyle(),
      content: _DetailSheet(entry: entry, label: label, color: color),
    );
  }

  static String _hmsMs(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

// ─────────────────────────────────────────────────────────────

/// Full state/event dump for one transition — body of the detail
/// sheet. A widget class (not an inline builder) so its own context
/// sits inside the sheet route and `Navigator.pop` closes the sheet.
class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.entry,
    required this.label,
    required this.color,
  });

  final BlocTransitionEntry entry;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = entry.detail ?? entry.summary;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _KindChip(label: label, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.blocType,
                  overflow: TextOverflow.ellipsis,
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DebugOverlayTheme.text,
                  ),
                ),
              ),
              Text(
                _DebugBlocsViewState._hmsMs(entry.at),
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10.5,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // The sheet chrome scrolls the whole content, so the dump
          // container no longer needs its own Flexible + scroll view.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DebugOverlayTheme.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              text,
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 11,
                height: 1.45,
                color: DebugOverlayTheme.text,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: DebugOverlayTheme.accent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        '${entry.blocType} [$label] '
                        '${_DebugBlocsViewState._hmsMs(entry.at)}\n$text',
                  ),
                );
                GlobalToast.info('Transition copied');
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                child: Text(
                  'Copy',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindFilterChip extends StatelessWidget {
  const _KindFilterChip({
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
  const _Row({required this.entry, required this.onTap});

  final BlocTransitionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _DebugBlocsViewState._kindMeta[entry.kind]!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KindChip(label: label, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.blocType,
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                    Text(
                      entry.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 10.5,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
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

  static String _hms(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
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
