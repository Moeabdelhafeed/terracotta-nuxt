import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/loggers/log_buffer.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import 'log_message_view.dart';

/// A single row in the debug-overlay log list.
///
/// - Tap toggles expand, or toggles selection in [selectionMode].
/// - Long-press enters selection mode (parent drives the transition).
/// - Dedicated copy icon sends only this entry to the clipboard.
/// - Expand icon only shown when the body actually has more content to reveal.
class LogEntryTile extends StatelessWidget {
  const LogEntryTile({
    super.key,
    required this.entry,
    required this.expanded,
    required this.onToggleExpand,
    required this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  final LogEntry entry;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onLongPress;
  final bool selectionMode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final render = LogRender.parse(entry);
    final lc = DebugOverlayTheme.levelColor(entry.level);
    final bgSelected = selected
        ? DebugOverlayTheme.accent.withValues(alpha: 0.08)
        : Colors.transparent;

    return ValueListenableBuilder<DebugDensity>(
      valueListenable: DebugOverlayPrefs.density,
      builder: (_, density, _) {
        // Compact mode shaves vertical padding + the meta-row gap so
        // ~40% more rows fit in the same screen real estate. Trade
        // visual breathing room for information density.
        final isCompact = density == DebugDensity.compact;
        final vPad = isCompact ? 4.0 : 8.0;
        final metaGap = isCompact ? 2.0 : 4.0;

        return Material(
          color: bgSelected,
          child: InkWell(
            onTap: onToggleExpand,
            onLongPress: onLongPress,
            splashColor: lc.withValues(alpha: 0.15),
            highlightColor: lc.withValues(alpha: 0.05),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: DebugOverlayTheme.border),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 3, color: lc),
                    if (selectionMode) _buildCheckbox(),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          selectionMode ? 4 : 10,
                          vPad,
                          6,
                          vPad,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMetaRow(lc, render),
                            SizedBox(height: metaGap),
                            LogMessageView(render: render, expanded: expanded),
                          ],
                        ),
                      ),
                    ),
                    _buildTrailing(context, render),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: selected ? DebugOverlayTheme.accent : Colors.transparent,
            border: Border.all(
              color: selected
                  ? DebugOverlayTheme.accent
                  : DebugOverlayTheme.textDim,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: selected
              ? const Icon(Icons.check, size: 13, color: DebugOverlayTheme.bg)
              : null,
        ),
      ),
    );
  }

  Widget _buildMetaRow(Color lc, LogRender render) {
    return Wrap(
      spacing: 6,
      runSpacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(text: entry.level.name.toUpperCase(), color: lc),
        if (render.method != null)
          _Pill(text: render.method!, color: const Color(0xFF4FC9FF)),
        if (render.status != null)
          _Pill(text: render.status!, color: _statusColor(render.status!)),
        Text(
          '#${entry.seq}',
          style: DebugOverlayTheme.mono.copyWith(
            color: DebugOverlayTheme.textDim,
            fontSize: 10,
          ),
        ),
        Text(
          _fmtTime(entry.time),
          style: DebugOverlayTheme.mono.copyWith(
            color: DebugOverlayTheme.textDim,
            fontSize: 10,
          ),
        ),
        Text(
          entry.name,
          style: DebugOverlayTheme.mono.copyWith(
            color: DebugOverlayTheme.accent.withValues(alpha: 0.75),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    final n = int.tryParse(status) ?? 0;
    if (n >= 500) return const Color(0xFFEF5350);
    if (n >= 400) return const Color(0xFFFFA726);
    if (n >= 300) return const Color(0xFFFFD54F);
    if (n >= 200) return const Color(0xFF66BB6A);
    return DebugOverlayTheme.textDim;
  }

  Widget _buildTrailing(BuildContext context, LogRender render) {
    if (selectionMode) return const SizedBox(width: 8);
    return Padding(
      padding: const EdgeInsets.only(right: 2, top: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _tinyBtn(
            icon: Icons.copy_rounded,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: entry.toPlain()));
              // The overlay standardizes on GlobalToast for copy
              // feedback (route jumper, assets, scenarios, ...).
              GlobalToast.info('Log copied');
            },
          ),
          if (render.isExpandable)
            _tinyBtn(
              icon: expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              onTap: onToggleExpand,
            ),
        ],
      ),
    );
  }

  Widget _tinyBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: DebugOverlayTheme.textDim),
      ),
    );
  }

  String _fmtTime(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}.${three(l.millisecond)}';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: DebugOverlayTheme.mono.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
