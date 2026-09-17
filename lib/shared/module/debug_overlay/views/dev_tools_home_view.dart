import 'package:flutter/material.dart';

import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../dev_tool_reset.dart';
import '../dev_tool_status.dart';
import '../widgets/debug_search_field.dart';

/// Landing page of the developer overlay — search + recents + tools in
/// a compact two-column grid, grouped by [DevToolCategory] with
/// collapsible, color-coded sections.
///
/// - Tap a tile → open the tool. Long-press → pin to the title strip.
/// - ⓘ on a tile → description panel (tiles stay compact).
/// - Active simulators get a live dot + the amber strip up top, so a
///   forgotten mock/network sim can't silently haunt the session.
class DevToolsHomeView extends StatefulWidget {
  const DevToolsHomeView({super.key, required this.onOpenTool});

  final ValueChanged<DevTool> onOpenTool;

  @override
  State<DevToolsHomeView> createState() => _DevToolsHomeViewState();
}

class _DevToolsHomeViewState extends State<DevToolsHomeView> {
  String _query = '';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  /// Tool whose description panel is open (ⓘ), null = closed.
  DevTool? _infoTool;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;
    final filtered = !searching
        ? DevTool.values
        : DevTool.values.where((t) {
            return t.label.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q);
          }).toList();

    final byCategory = <DevToolCategory, List<DevTool>>{};
    for (final tool in filtered) {
      byCategory.putIfAbsent(tool.category, () => []).add(tool);
    }
    final categories = DevToolCategory.values
        .where((c) => byCategory.containsKey(c))
        .toList();

    return ListenableBuilder(
      listenable: DevToolStatus.listenable,
      builder: (context, _) {
        final active = DevToolStatus.active();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: DebugSearchField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                autofocus: true,
                hintText: 'Search tools',
                resultCount: searching ? filtered.length : null,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (active.isNotEmpty && !searching)
              _ActiveStrip(tools: active, onOpenTool: widget.onOpenTool),
            if (!searching) _RecentsRow(onOpenTool: widget.onOpenTool),
            if (filtered.isEmpty)
              const Expanded(child: _NoMatch())
            else
              Expanded(
                child: Stack(
                  children: [
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: DebugOverlayPrefs.collapsedCategories,
                      builder: (_, collapsed, _) => ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: categories.length,
                        itemBuilder: (_, i) {
                          final cat = categories[i];
                          // Searching force-expands every section.
                          final isCollapsed =
                              !searching && collapsed.contains(cat.label);
                          return Padding(
                            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                            child: _Section(
                              category: cat,
                              tools: byCategory[cat]!,
                              collapsed: isCollapsed,
                              collapsible: !searching,
                              query: q,
                              onOpenTool: widget.onOpenTool,
                              onInfo: (t) => setState(() => _infoTool = t),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_infoTool != null)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: _InfoPanel(
                          tool: _infoTool!,
                          onOpen: () {
                            final t = _infoTool!;
                            setState(() => _infoTool = null);
                            widget.onOpenTool(t);
                          },
                          onClose: () => setState(() => _infoTool = null),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────

Color _categoryColor(DevToolCategory c) => DebugOverlayTheme.categoryColor(c);

const _kActiveColor = Color(0xFFFFA726);

// ─────────────────────────────────────────────────────────────

/// "You left simulators on" strip — amber, one chip per active tool.
class _ActiveStrip extends StatelessWidget {
  const _ActiveStrip({required this.tools, required this.onOpenTool});

  final List<DevTool> tools;
  final ValueChanged<DevTool> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: _kActiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kActiveColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(Icons.bolt_rounded, size: 14, color: _kActiveColor),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    tools.length == 1
                        ? '1 override active'
                        : '${tools.length} overrides active',
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kActiveColor,
                    ),
                  ),
                  for (final t in tools)
                    _MiniChip(
                      label: t.label,
                      icon: t.icon,
                      color: _kActiveColor,
                      onTap: () => onOpenTool(t),
                    ),
                  _MiniChip(
                    label: 'Reset all',
                    icon: Icons.restart_alt_rounded,
                    color: const Color(0xFFEF5350),
                    onTap: () async {
                      final n = await DevToolReset.resetAll();
                      GlobalToast.info(
                        'All overrides cleared',
                        description: '$n simulator${n == 1 ? '' : 's'} reset',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recently-opened tools as one-tap chips.
class _RecentsRow extends StatelessWidget {
  const _RecentsRow({required this.onOpenTool});

  final ValueChanged<DevTool> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: DebugOverlayPrefs.recentTools,
      builder: (_, names, _) {
        final tools = [
          for (final n in names)
            for (final t in DevTool.values)
              if (t.name == n) t,
        ];
        if (tools.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Text(
                'RECENT',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: DebugOverlayTheme.textDimmer,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final t in tools) ...[
                        _MiniChip(
                          label: t.label,
                          icon: t.icon,
                          color: _categoryColor(t.category),
                          onTap: () => onOpenTool(t),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _NoMatch extends StatelessWidget {
  const _NoMatch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 32,
            color: DebugOverlayTheme.textDimmer,
          ),
          const SizedBox(height: 8),
          Text(
            'No tools match',
            style: DebugOverlayTheme.ui.copyWith(
              color: DebugOverlayTheme.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.category,
    required this.tools,
    required this.collapsed,
    required this.collapsible,
    required this.query,
    required this.onOpenTool,
    required this.onInfo,
  });

  final DevToolCategory category;
  final List<DevTool> tools;
  final bool collapsed;
  final bool collapsible;
  final String query;
  final ValueChanged<DevTool> onOpenTool;
  final ValueChanged<DevTool> onInfo;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: collapsible
              ? () => DebugOverlayPrefs.toggleCategoryCollapsed(category.label)
              : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  category.label.toUpperCase(),
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DebugOverlayTheme.textDim,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${tools.length}',
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 10,
                    color: DebugOverlayTheme.textDimmer,
                  ),
                ),
                const Spacer(),
                if (collapsible)
                  AnimatedRotation(
                    turns: collapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: DebugOverlayTheme.textDimmer,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Collapsed sections keep the header (with count) only.
        if (!collapsed)
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final twoCol = constraints.maxWidth >= 340;
              final tileWidth = twoCol
                  ? (constraints.maxWidth - gap) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final tool in tools)
                    SizedBox(
                      width: tileWidth,
                      child: _ToolTile(
                        tool: tool,
                        color: _categoryColor(tool.category),
                        query: query,
                        onTap: () => onOpenTool(tool),
                        onInfo: () => onInfo(tool),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.tool,
    required this.color,
    required this.query,
    required this.onTap,
    required this.onInfo,
  });

  final DevTool tool;
  final Color color;
  final String query;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final isActive = DevToolStatus.isActive(tool);
    return ValueListenableBuilder<List<String>>(
      valueListenable: DebugOverlayPrefs.pinnedTools,
      builder: (_, pinned, _) {
        final isPinned = pinned.contains(tool.name);
        return Material(
          color: DebugOverlayTheme.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            onLongPress: () => DebugOverlayPrefs.togglePin(tool.name),
            borderRadius: BorderRadius.circular(10),
            splashColor: color.withValues(alpha: 0.18),
            highlightColor: color.withValues(alpha: 0.08),
            child: Container(
              // Fixed height: a label wrapping to its second line must
              // not make this tile taller than its row neighbors.
              height: 48,
              padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 6, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? _kActiveColor.withValues(alpha: 0.55)
                      : DebugOverlayTheme.border,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                // Center the content row in the fixed-height tile — the
                // default topStart leaves dead space under the row.
                alignment: AlignmentDirectional.centerStart,
                children: [
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(tool.icon, color: color, size: 16),
                          ),
                          if (isPinned)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: const BoxDecoration(
                                  color: DebugOverlayTheme.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  size: 9,
                                  color: DebugOverlayTheme.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HighlightText(
                          tool.label,
                          query: query,
                          highlightColor: color,
                        ),
                      ),
                      if (isActive)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsetsDirectional.only(start: 2),
                          decoration: const BoxDecoration(
                            color: _kActiveColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  // ⓘ hugs the top-end corner — zero layout footprint,
                  // the label keeps the full row width.
                  PositionedDirectional(
                    top: -3,
                    end: -5,
                    child: InkWell(
                      onTap: onInfo,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 12,
                          color: DebugOverlayTheme.textDimmer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Label with the query substring tinted — cheap match highlighting.
class _HighlightText extends StatelessWidget {
  const _HighlightText(
    this.text, {
    required this.query,
    required this.highlightColor,
  });

  final String text;
  final String query;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    // Two lines max, tight leading — fits inside the fixed 48px tile
    // without growing it.
    final base = DebugOverlayTheme.ui.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    final q = query.trim();
    final idx = q.isEmpty ? -1 : text.toLowerCase().indexOf(q.toLowerCase());
    if (idx < 0) {
      return Text(
        text,
        style: base,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + q.length),
            style: TextStyle(color: highlightColor),
          ),
          TextSpan(text: text.substring(idx + q.length)),
        ],
      ),
      style: base,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Bottom description card — opened from a tile's ⓘ so the grid tiles
/// themselves stay one-line compact.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.tool,
    required this.onOpen,
    required this.onClose,
  });

  final DevTool tool;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(tool.category);
    return TweenAnimationBuilder<double>(
      key: ValueKey('info-${tool.name}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: Material(
        color: DebugOverlayTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(tool.icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tool.label,
                            style: DebugOverlayTheme.ui.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tool.category.label,
                          style: DebugOverlayTheme.ui.copyWith(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool.description,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 11.5,
                        height: 1.35,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _PanelAction(
                          label: 'Open',
                          color: color,
                          onTap: onOpen,
                        ),
                        const SizedBox(width: 6),
                        ValueListenableBuilder<List<String>>(
                          valueListenable: DebugOverlayPrefs.pinnedTools,
                          builder: (_, pinned, _) => _PanelAction(
                            label: pinned.contains(tool.name) ? 'Unpin' : 'Pin',
                            color: DebugOverlayTheme.textDim,
                            onTap: () => DebugOverlayPrefs.togglePin(tool.name),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GlobalIconButton(
                enforceMinTouchTarget: false,
                iconData: Icons.close_rounded,
                onPressed: onClose,
                iconSize: 16,
                style: const ButtonStateStyle(
                  width: 28,
                  height: 28,
                  foregroundColor: DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  const _PanelAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
