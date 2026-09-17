import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../data/services/navigation_service.dart';
import '../../sheet/global_sheet.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_search_field.dart';
import '../widgets/debug_surfaces.dart';
import '../widgets/debug_text_field.dart';

/// Dev panel: pick any defined route and navigate to it without
/// hand-typing a URL. Pulls every [GoRoute] in [AppRoutes.routes],
/// extracts `:param` placeholders, lets the developer fill them +
/// optional JSON `extra`, and dispatches with a chosen push mode.
///
/// Routes are grouped — App flow (real product screens), Dev bench,
/// Showcases — in collapsible sections; the route currently on screen
/// carries a live badge. Search filters by name + path and
/// force-expands.
class DebugRouteJumperView extends StatefulWidget {
  const DebugRouteJumperView({super.key});

  @override
  State<DebugRouteJumperView> createState() => _DebugRouteJumperViewState();
}

/// Coarse route buckets — heuristic on name/path, good enough for a
/// dev tool. Order here = section order in the list.
enum _RouteGroup {
  appFlow('App flow', Color(0xFF4FC3F7)),
  devBench('Dev bench', Color(0xFFFFA726)),
  showcases('Showcases', Color(0xFF66BB6A));

  const _RouteGroup(this.label, this.color);
  final String label;
  final Color color;
}

class _DebugRouteJumperViewState extends State<DebugRouteJumperView> {
  late final List<_RouteEntry> _all;
  final TextEditingController _filter = TextEditingController();
  String _query = '';
  final Set<_RouteGroup> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _all = _collect(AppRoutes.routes).toList(growable: false);
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Iterable<_RouteEntry> _collect(List<RouteBase> routes) sync* {
    for (final r in routes) {
      if (r is GoRoute) {
        yield _RouteEntry(name: r.name, path: r.path);
        if (r.routes.isNotEmpty) yield* _collect(r.routes);
      } else if (r is ShellRouteBase) {
        yield* _collect(r.routes);
      }
    }
  }

  /// Name of the route currently on top of the APP's router — badged in
  /// the list. Null when it can't be resolved (early boot, no service).
  String? _currentRouteName() {
    if (!getIt.isRegistered<NavigationService>()) return null;
    try {
      final config =
          getIt<NavigationService>().router.routerDelegate.currentConfiguration;
      return config.isEmpty ? null : config.last.route.name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // `_currentRouteName` reads the APP's router, which lives outside
    // this overlay's widget tree — navigating the app underneath never
    // rebuilds this view on its own. GoRouter's delegate is a
    // ChangeNotifier that fires on every navigation, so listen to it
    // directly to keep the CURRENT badge live while the window sits
    // open on top of the app.
    if (getIt.isRegistered<NavigationService>()) {
      return ListenableBuilder(
        listenable: getIt<NavigationService>().router.routerDelegate,
        builder: (context, _) => _buildList(context),
      );
    }
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;
    final filtered = !searching
        ? _all
        : _all
              .where(
                (e) =>
                    (e.name?.toLowerCase().contains(q) ?? false) ||
                    e.path.toLowerCase().contains(q),
              )
              .toList(growable: false);

    final grouped = <_RouteGroup, List<_RouteEntry>>{};
    for (final e in filtered) {
      grouped.putIfAbsent(e.group, () => []).add(e);
    }
    final groups = _RouteGroup.values.where(grouped.containsKey).toList();
    final current = _currentRouteName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: DebugSearchField(
            controller: _filter,
            hintText: 'Search by name or path',
            resultCount: searching ? filtered.length : null,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            itemCount: groups.length,
            itemBuilder: (_, gi) {
              final group = groups[gi];
              final entries = grouped[group]!;
              final isCollapsed = !searching && _collapsed.contains(group);
              return Padding(
                padding: EdgeInsets.only(top: gi == 0 ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GroupHeader(
                      group: group,
                      count: entries.length,
                      collapsed: isCollapsed,
                      collapsible: !searching,
                      onTap: () => setState(() {
                        if (!_collapsed.remove(group)) _collapsed.add(group);
                      }),
                    ),
                    if (!isCollapsed)
                      for (final e in entries)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _RouteTile(
                            entry: e,
                            isCurrent: e.name != null && e.name == current,
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RouteEntry {
  const _RouteEntry({required this.name, required this.path});

  final String? name;
  final String path;

  /// `:foo` placeholders in the path, in declaration order.
  List<String> get params {
    final re = RegExp(r':([a-zA-Z_][a-zA-Z0-9_]*)');
    return re.allMatches(path).map((m) => m.group(1)!).toList(growable: false);
  }

  _RouteGroup get group {
    final n = (name ?? '').toLowerCase();
    final p = path.toLowerCase();
    if (n.contains('showcase') || p.contains('showcase')) {
      return _RouteGroup.showcases;
    }
    if (n == 'playground' ||
        n == 'dev-hub' ||
        p.contains('playground') ||
        p.contains('dev-hub')) {
      return _RouteGroup.devBench;
    }
    return _RouteGroup.appFlow;
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.count,
    required this.collapsed,
    required this.collapsible,
    required this.onTap,
  });

  final _RouteGroup group;
  final int count;
  final bool collapsed;
  final bool collapsible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: collapsible ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: group.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              group.label.toUpperCase(),
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: DebugOverlayTheme.textDim,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
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
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({required this.entry, required this.isCurrent});

  final _RouteEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final groupColor = entry.group.color;
    return Material(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        splashColor: groupColor.withValues(alpha: 0.15),
        highlightColor: groupColor.withValues(alpha: 0.06),
        onTap: () => _showJumpSheet(context, entry),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isCurrent
                  ? groupColor.withValues(alpha: 0.6)
                  : DebugOverlayTheme.border,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.name ?? '(unnamed)',
                            overflow: TextOverflow.ellipsis,
                            style: DebugOverlayTheme.ui.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: entry.name == null
                                  ? DebugOverlayTheme.textDim
                                  : DebugOverlayTheme.text,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: groupColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CURRENT',
                              style: DebugOverlayTheme.mono.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: groupColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.path,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 11,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.params.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DebugOverlayTheme.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ':${entry.params.length}',
                    style: DebugOverlayTheme.mono.copyWith(
                      fontSize: 10,
                      color: DebugOverlayTheme.accent,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
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

  void _showJumpSheet(BuildContext context, _RouteEntry entry) {
    // GlobalBottomSheet owns the drag handle — no more double-handle
    // dance against the app theme's BottomSheetThemeData.
    GlobalBottomSheet.show<void>(
      context: context,
      showCloseButton: false,
      style: debugSheetStyle(),
      content: _JumpSheet(entry: entry),
    );
  }
}

/// Push-mode pickers for the jumper. Each maps to a `GoRouter` call
/// at dispatch time.
enum _JumpMode {
  push(label: 'push', description: 'Stack on top — pops back here'),
  pushReplace(
    label: 'pushReplacement',
    description: 'Replaces the current entry',
  ),
  go(
    label: 'go (clear stack)',
    description: 'Resets stack to this location',
  );

  const _JumpMode({required this.label, required this.description});
  final String label;
  final String description;
}

class _JumpSheet extends StatefulWidget {
  const _JumpSheet({required this.entry});

  final _RouteEntry entry;

  @override
  State<_JumpSheet> createState() => _JumpSheetState();
}

class _JumpSheetState extends State<_JumpSheet> {
  late final Map<String, TextEditingController> _paramCtrls;
  late final TextEditingController _extrasCtrl;
  _JumpMode _mode = _JumpMode.push;
  String? _extrasError;

  @override
  void initState() {
    super.initState();
    _paramCtrls = {
      for (final p in widget.entry.params) p: TextEditingController(),
    };
    _extrasCtrl = _JsonHighlightController();
  }

  @override
  void dispose() {
    for (final c in _paramCtrls.values) {
      c.dispose();
    }
    _extrasCtrl.dispose();
    super.dispose();
  }

  String _resolvedPath() {
    var path = widget.entry.path;
    for (final entry in _paramCtrls.entries) {
      final v = Uri.encodeComponent(entry.value.text);
      path = path.replaceAll(':${entry.key}', v.isEmpty ? ':${entry.key}' : v);
    }
    return path;
  }

  Object? _parseExtras() {
    setState(() => _extrasError = null);
    final raw = _extrasCtrl.text.trim();
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (e) {
      setState(() => _extrasError = e.toString());
      return null;
    }
  }

  bool _allParamsFilled() {
    return _paramCtrls.values.every((c) => c.text.trim().isNotEmpty);
  }

  void _jump() {
    if (!_allParamsFilled()) {
      GlobalToast.error(
        'Missing param',
        description: 'Fill all `:param` slots first',
      );
      return;
    }
    final extras = _parseExtras();
    if (_extrasError != null) return;

    final path = _resolvedPath();
    if (!getIt.isRegistered<NavigationService>()) {
      GlobalToast.error('NavigationService unregistered');
      return;
    }
    final nav = getIt<NavigationService>();
    switch (_mode) {
      case _JumpMode.push:
        nav.push(path, extra: extras);
      case _JumpMode.pushReplace:
        // NavigationService.pushReplacement doesn't carry extras; drop
        // straight to the router so JSON `extra` survives.
        nav.router.pushReplacement(path, extra: extras);
      case _JumpMode.go:
        nav.router.go(path, extra: extras);
    }
    Navigator.of(context).pop();
    GlobalToast.success('${_mode.label} → $path');
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final groupColor = entry.group.color;
    // Horizontal + top padding come from the sheet chrome's
    // contentPadding; the keyboard inset stays here so the fields lift
    // above the keyboard.
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.alt_route_rounded,
                  size: 16,
                  color: groupColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name ?? '(unnamed)',
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      entry.path,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 11,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _CloseButton(onTap: () => Navigator.of(context).pop()),
            ],
          ),
          if (entry.params.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionLabel(
              icon: Icons.link_rounded,
              text: 'Path parameters',
            ),
            const SizedBox(height: 6),
            for (final p in entry.params)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _LabeledField(
                  label: ':$p',
                  controller: _paramCtrls[p]!,
                  placeholder: 'value for :$p',
                ),
              ),
          ],
          const SizedBox(height: 16),
          const _SectionLabel(
            icon: Icons.data_object_rounded,
            text: 'Extras (JSON, optional)',
          ),
          const SizedBox(height: 6),
          DebugTextField(
            controller: _extrasCtrl,
            hint: '{"key": "value"}',
            minLines: 3,
            maxLines: 6,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            errorText: _extrasError == null
                ? null
                : 'Invalid JSON: $_extrasError',
          ),
          const SizedBox(height: 16),
          const _SectionLabel(icon: Icons.send_rounded, text: 'Push mode'),
          const SizedBox(height: 6),
          _ModeSegmented(
            mode: _mode,
            onSelect: (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: 6),
          Text(
            _mode.description,
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 10.5,
              color: DebugOverlayTheme.textDim,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy path',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _resolvedPath()));
                    GlobalToast.success('Path copied');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _SheetButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'Jump',
                  filled: true,
                  onTap: _jump,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugOverlayTheme.surfaceHigh,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: Icon(
            Icons.close_rounded,
            size: 14,
            color: DebugOverlayTheme.textDim,
          ),
        ),
      ),
    );
  }
}

/// Equal-width 3-way segmented control — replaces stacked description
/// cards so the sheet doesn't grow with every mode added; the selected
/// mode's description renders as one caption line below instead.
class _ModeSegmented extends StatelessWidget {
  const _ModeSegmented({required this.mode, required this.onSelect});

  final _JumpMode mode;
  final ValueChanged<_JumpMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Row(
        children: [
          for (final m in _JumpMode.values)
            Expanded(
              child: _ModeSegment(
                mode: m,
                selected: mode == m,
                onTap: () => onSelect(m),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final _JumpMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Material(
      color: selected ? accent.withValues(alpha: 0.18) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            mode.label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? accent : DebugOverlayTheme.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay-styled sheet action — the app-theme Material buttons clash
/// with the dark dev surface (and pick up the app's accent), so the
/// sheet draws its own: outline by default, accent-filled for the
/// primary action.
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    final fg = filled ? Colors.black : DebugOverlayTheme.text;
    return Material(
      color: filled ? accent : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: (filled ? Colors.black : accent).withValues(alpha: 0.15),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: filled ? null : Border.all(color: DebugOverlayTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 12, color: DebugOverlayTheme.textDimmer),
      const SizedBox(width: 5),
      Text(
        text,
        style: DebugOverlayTheme.ui.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: DebugOverlayTheme.textDim,
        ),
      ),
    ],
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.placeholder,
  });
  final String label;
  final TextEditingController controller;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 11,
              color: DebugOverlayTheme.textDim,
            ),
          ),
        ),
        Expanded(
          // Shared console field — the sheet's former hand-rolled
          // `_CompactField` variant (surfaceHigh fill, 6px radius).
          child: DebugTextField(
            controller: controller,
            hint: placeholder,
            fillColor: DebugOverlayTheme.surfaceHigh,
            radius: 6,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}

/// Live JSON syntax coloring for the "Extras" text area — no separate
/// preview pane; the input itself colorizes as you type. Regex-tokenized
/// (good enough for a single-object debug payload, not a full parser):
/// keys vs string values get different hues, numbers/booleans/null and
/// punctuation each get their own. Malformed JSON just falls back to
/// whatever partial tokens still match; the red border + error line
/// below (driven by the real `jsonDecode` attempt) is the correctness
/// signal, not the coloring.
class _JsonHighlightController extends TextEditingController {
  static final _token = RegExp(
    r'("(?:\\.|[^"\\])*")(\s*:)?'
    r'|(-?\d+\.?\d*(?:[eE][+-]?\d+)?)'
    r'|\b(true|false|null)\b'
    r'|([{}\[\],:])',
  );

  static const _keyColor = Color(0xFF4FC3F7);
  static const _stringColor = Color(0xFF9CCC65);
  static const _numberColor = Color(0xFFFFA726);
  static const _constColor = Color(0xFFBA68C8);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final source = text;
    if (source.isEmpty) return TextSpan(style: style);

    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _token.allMatches(source)) {
      if (m.start > last) {
        spans.add(
          TextSpan(text: source.substring(last, m.start), style: style),
        );
      }
      final color = switch (m) {
        _ when m.group(1) != null =>
          m.group(2) != null ? _keyColor : _stringColor,
        _ when m.group(3) != null => _numberColor,
        _ when m.group(4) != null => _constColor,
        _ => DebugOverlayTheme.textDim, // punctuation
      };
      spans.add(
        TextSpan(
          text: m.group(0),
          style: (style ?? const TextStyle()).copyWith(color: color),
        ),
      );
      last = m.end;
    }
    if (last < source.length) {
      spans.add(TextSpan(text: source.substring(last), style: style));
    }
    return TextSpan(style: style, children: spans);
  }
}
