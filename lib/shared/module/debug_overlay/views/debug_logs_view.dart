import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/enums/app/log_level.dart';
import '../../../../core/utils/loggers/log_buffer.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_search_field.dart';
import '../widgets/log_entry_tile.dart';

/// Live-updating list of [LogEntry] rows with level chips, text search,
/// multi-select, per-row copy, and scroll-aware auto-follow: scrolling
/// up pauses following and unseen entries accumulate on a "↓ N new"
/// pill; returning to the bottom (or tapping the pill) resumes.
class DebugLogsView extends StatefulWidget {
  const DebugLogsView({super.key});

  @override
  State<DebugLogsView> createState() => _DebugLogsViewState();
}

class _DebugLogsViewState extends State<DebugLogsView> {
  LogLevel? _minLevel;
  String _search = '';
  bool _following = true;
  int _newCount = 0;
  StreamSubscription<LogEntry>? _sub;
  final _searchCtrl = TextEditingController();
  final _listCtrl = ScrollController();

  /// `seq`s of entries the user has manually expanded.
  final Set<int> _expanded = <int>{};

  /// `seq`s currently selected in multi-select mode.
  final Set<int> _selected = <int>{};
  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _listCtrl.addListener(_onScroll);
    _sub = LogBuffer.onAdd.listen((_) {
      if (!mounted) return;
      if (!_following) _newCount++;
      setState(() {});
      if (_following) _scrollToBottom();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  bool get _atBottom =>
      _listCtrl.hasClients &&
      _listCtrl.position.maxScrollExtent - _listCtrl.position.pixels < 40;

  /// Scrolling away from the bottom pauses following; scrolling back
  /// (or the jump pill) resumes it and clears the unseen counter.
  void _onScroll() {
    final atBottom = _atBottom;
    if (_following != atBottom) {
      setState(() {
        _following = atBottom;
        if (atBottom) _newCount = 0;
      });
    } else if (atBottom && _newCount != 0) {
      setState(() => _newCount = 0);
    }
  }

  void _scrollToBottom() {
    if (!_listCtrl.hasClients) return;
    _listCtrl.jumpTo(_listCtrl.position.maxScrollExtent);
  }

  List<LogEntry> _filtered() {
    final all = LogBuffer.all;
    if (_minLevel == null && _search.isEmpty) return all;
    final needle = _search.toLowerCase();
    return all.where((e) {
      if (_minLevel != null && e.level.index < _minLevel!.index) {
        return false;
      }
      if (needle.isNotEmpty &&
          !e.message.toLowerCase().contains(needle) &&
          !e.name.toLowerCase().contains(needle)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _toggleExpand(int seq) {
    if (_selectionMode) {
      _toggleSelect(seq);
      return;
    }
    setState(() {
      if (!_expanded.add(seq)) _expanded.remove(seq);
    });
  }

  void _toggleSelect(int seq) {
    setState(() {
      if (!_selected.add(seq)) _selected.remove(seq);
    });
  }

  void _enterSelectionWith(int seq) {
    setState(() => _selected.add(seq));
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  Future<void> _copySelected() async {
    final entries = LogBuffer.all
        .where((e) => _selected.contains(e.seq))
        .toList();
    final text = entries.map((e) => e.toPlain()).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final n = entries.length;
    GlobalToast.info('$n log${n == 1 ? '' : 's'} copied');
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    final total = LogBuffer.length;
    return Column(
      children: [
        _selectionMode
            ? _buildSelectionBar()
            : _buildFilterBar(filtered.length, total),
        Expanded(
          child: Stack(
            children: [
              filtered.isEmpty
                  ? Center(
                      child: Text(
                        total == 0 ? 'No logs yet' : 'No logs match',
                        style: DebugOverlayTheme.ui.copyWith(
                          color: DebugOverlayTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _listCtrl,
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final entry = filtered[i];
                        return LogEntryTile(
                          entry: entry,
                          expanded: _expanded.contains(entry.seq),
                          selectionMode: _selectionMode,
                          selected: _selected.contains(entry.seq),
                          onToggleExpand: () => _toggleExpand(entry.seq),
                          onLongPress: () => _enterSelectionWith(entry.seq),
                        );
                      },
                    ),
              if (!_following)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: DebugOverlayTheme.accent,
                      borderRadius: BorderRadius.circular(999),
                      elevation: 3,
                      child: InkWell(
                        onTap: _scrollToBottom,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_downward_rounded,
                                size: 13,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _newCount > 0 ? '$_newCount new' : 'Latest',
                                style: DebugOverlayTheme.ui.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(int filteredCount, int total) {
    final levelCounts = <LogLevel, int>{};
    for (final e in LogBuffer.all) {
      levelCounts[e.level] = (levelCounts[e.level] ?? 0) + 1;
    }
    final filtering = _minLevel != null || _search.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 8),
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
                  hintText: 'Filter by name or message',
                  onChanged: (v) => setState(() => _search = v),
                  resultCount: filtering ? filteredCount : null,
                ),
              ),
              const SizedBox(width: 2),
              _IconBtn(
                icon: Icons.copy_all_rounded,
                tooltip: 'Copy recent (filtered)',
                onTap: () async {
                  final n = await LogBuffer.copyRecentToClipboard(
                    count: 200,
                    minLevel: _minLevel,
                    nameContains: _search.isEmpty ? null : _search,
                  );
                  GlobalToast.info('$n log${n == 1 ? '' : 's'} copied');
                },
              ),
              _IconBtn(
                icon: Icons.delete_sweep_outlined,
                tooltip: 'Clear buffer',
                onTap: () {
                  LogBuffer.clear();
                  GlobalToast.info('Log buffer cleared');
                  setState(() => _newCount = 0);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _LevelChip(
                  label: 'all',
                  count: total,
                  color: DebugOverlayTheme.accent,
                  selected: _minLevel == null,
                  onTap: () => setState(() => _minLevel = null),
                ),
                for (final level in LogLevel.values) ...[
                  const SizedBox(width: 6),
                  _LevelChip(
                    // Chips act as a minimum: `≥warn` shows warn+error+fatal.
                    label: level == LogLevel.trace
                        ? 'trace'
                        : '≥${level.name == 'warning' ? 'warn' : level.name}',
                    count: levelCounts[level] ?? 0,
                    color: DebugOverlayTheme.levelColor(level),
                    selected: _minLevel == level,
                    onTap: () => setState(
                      () => _minLevel = _minLevel == level ? null : level,
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

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
      decoration: BoxDecoration(
        color: DebugOverlayTheme.accent.withValues(alpha: 0.12),
        border: const Border(
          bottom: BorderSide(color: DebugOverlayTheme.border),
        ),
      ),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.close_rounded,
            tooltip: 'Exit selection',
            onTap: _clearSelection,
          ),
          const SizedBox(width: 4),
          Text(
            '${_selected.length} selected',
            style: DebugOverlayTheme.ui.copyWith(
              color: DebugOverlayTheme.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _IconBtn(
            icon: Icons.done_all_rounded,
            tooltip: 'Select all visible',
            onTap: () {
              setState(() {
                for (final e in _filtered()) {
                  _selected.add(e.seq);
                }
              });
            },
          ),
          _IconBtn(
            icon: Icons.copy_rounded,
            tooltip: 'Copy selected',
            active: true,
            onTap: _copySelected,
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
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

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlobalIconButton(
        iconData: icon,
        onPressed: onTap,
        enforceMinTouchTarget: false,
        iconSize: 16,
        style: ButtonStateStyle(
          foregroundColor: active
              ? DebugOverlayTheme.accent
              : DebugOverlayTheme.textDim,
          width: 40,
          height: 40,
        ),
      ),
    );
  }
}
