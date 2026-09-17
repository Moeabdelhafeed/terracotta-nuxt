import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/strings/common_strings.dart';
import '../../../../data/services/remote_config_service.dart';
import '../../buttons/global_filled_button.dart';
import '../../buttons/global_icon_button.dart';
import '../../buttons/global_text_button.dart';
import '../../dialog/global_dialog.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_search_field.dart';
import '../widgets/debug_surfaces.dart';
import '../widgets/debug_switch.dart';
import '../widgets/debug_text_field.dart';

/// Runtime override panel for every [RemoteConfigService] key the app
/// reads. Setting an override wins ahead of RC / .env / hardcoded
/// resolution until cleared (in-memory; lost on restart).
///
/// The dev gets a pre-canned manifest so they don't have to remember
/// key names, types, or default values. Edit-on-tap opens a typed
/// dialog (text / bool / int) and writes through to
/// [RemoteConfigService.setOverride].
class DebugRcOverridesView extends StatefulWidget {
  const DebugRcOverridesView({super.key});

  @override
  State<DebugRcOverridesView> createState() => _DebugRcOverridesViewState();
}

class _DebugRcOverridesViewState extends State<DebugRcOverridesView> {
  StreamSubscription<void>? _sub;
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SourceFilter? _sourceFilter;
  final Set<String> _collapsed = {};

  // Manifest of every RC key the app currently reads, grouped by
  // domain for scanning. Adding a new key in [RemoteConfigService]
  // requires appending an entry here so the override panel can edit
  // it. Type drives the editor flavor (bool → inline switch).
  static const _groups = <_RcGroup>[
    _RcGroup('API', Icons.cloud_rounded, Color(0xFF64B5F6), [
      _RcKey('x_api_token', _RcType.string, 'Api token'),
      _RcKey('base_url', _RcType.string, 'API base URL'),
      _RcKey('maps_http_api_key', _RcType.string, 'Maps HTTP API key'),
    ]),
    _RcGroup('Feedback', Icons.feedback_rounded, Color(0xFF81C784), [
      _RcKey('feedback_enabled', _RcType.bool_, 'Feedback feature flag'),
      _RcKey('feedback_endpoint', _RcType.string, 'Feedback endpoint'),
      _RcKey(
        'feedback_support_email',
        _RcType.string,
        'Feedback support email',
      ),
      _RcKey(
        'feedback_attach_diagnostics_default',
        _RcType.bool_,
        'Attach diagnostics by default',
      ),
      _RcKey(
        'feedback_cooldown_seconds',
        _RcType.int_,
        'Feedback throttle window',
      ),
    ]),
    _RcGroup('Gates', Icons.door_front_door_rounded, Color(0xFFFFA726), [
      _RcKey('maintenance_mode', _RcType.bool_, 'Force maintenance gate'),
      _RcKey('onboarding_enabled', _RcType.bool_, 'Onboarding feature flag'),
    ]),
    _RcGroup('Connectivity', Icons.network_check_rounded, Color(0xFF4FC3F7), [
      _RcKey('connectivity_probe_url', _RcType.string, 'HEAD probe URL'),
      _RcKey(
        'connectivity_probe_interval_seconds',
        _RcType.int_,
        'Foreground probe interval',
      ),
      _RcKey(
        'connectivity_max_probe_failures',
        _RcType.int_,
        'Probe-untrusted threshold',
      ),
    ]),
    _RcGroup('Content', Icons.article_rounded, Color(0xFFBA68C8), [
      _RcKey('legal_source_mode', _RcType.string, 'Legal page source'),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _sub = RemoteConfigService.overrideChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overrides = RemoteConfigService.overrides;
    final sources = RemoteConfigService.lastSourceSnapshot;
    final q = _query.trim().toLowerCase();

    // Effective source per key: an active override wins; otherwise the
    // layer that last supplied it; null when nothing read it yet this
    // session.
    _SourceFilter sourceOf(_RcKey e) {
      if (overrides.containsKey(e.key)) return _SourceFilter.override_;
      return switch (sources[e.key]) {
        EnvSource.override => _SourceFilter.override_,
        EnvSource.remoteConfig => _SourceFilter.remoteConfig,
        EnvSource.flavorConfig => _SourceFilter.flavorConfig,
        EnvSource.dotenv => _SourceFilter.dotenv,
        EnvSource.hardcoded => _SourceFilter.hardcoded,
        null => _SourceFilter.unread,
      };
    }

    final sourceCounts = <_SourceFilter, int>{};
    for (final g in _groups) {
      for (final e in g.keys) {
        sourceCounts.update(sourceOf(e), (v) => v + 1, ifAbsent: () => 1);
      }
    }

    bool matches(_RcKey e) {
      if (_sourceFilter != null && sourceOf(e) != _sourceFilter) return false;
      return q.isEmpty ||
          e.key.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);
    }

    final shownGroups = [
      for (final g in _groups)
        if (g.keys.any(matches)) (g, g.keys.where(matches).toList()),
    ];
    final shownCount = shownGroups.fold<int>(0, (n, g) => n + g.$2.length);

    return Column(
      children: [
        if (overrides.isNotEmpty) _Banner(count: overrides.length),
        // Source filter chips — one scrollable row, assets-page style.
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            itemCount: _SourceFilter.values
                .where(sourceCounts.containsKey)
                .length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final f = _SourceFilter.values
                  .where(sourceCounts.containsKey)
                  .elementAt(i);
              return _FilterChip(
                filter: f,
                count: sourceCounts[f]!,
                selected: _sourceFilter == f,
                onTap: () => setState(
                  () => _sourceFilter = _sourceFilter == f ? null : f,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: DebugSearchField(
            controller: _searchCtrl,
            hintText: 'Filter keys',
            resultCount: (q.isEmpty && _sourceFilter == null)
                ? null
                : shownCount,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            itemCount: shownGroups.length,
            itemBuilder: (_, gi) {
              final (group, keys) = shownGroups[gi];
              final overriddenInGroup = keys
                  .where((e) => overrides.containsKey(e.key))
                  .length;
              // Any narrowing (search or chip) force-expands — a filtered
              // view with collapsed groups reads as "no results".
              final narrowing = q.isNotEmpty || _sourceFilter != null;
              final isCollapsed =
                  !narrowing && _collapsed.contains(group.label);
              return Padding(
                padding: EdgeInsets.only(top: gi == 0 ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: narrowing
                          ? null
                          : () => setState(() {
                              if (!_collapsed.remove(group.label)) {
                                _collapsed.add(group.label);
                              }
                            }),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                        child: Row(
                          children: [
                            Icon(group.icon, size: 13, color: group.color),
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
                              overriddenInGroup > 0
                                  ? '${keys.length} · $overriddenInGroup overridden'
                                  : '${keys.length}',
                              style: DebugOverlayTheme.mono.copyWith(
                                fontSize: 10,
                                color: overriddenInGroup > 0
                                    ? const Color(0xFFE57373)
                                    : DebugOverlayTheme.textDimmer,
                              ),
                            ),
                            const Spacer(),
                            if (!narrowing)
                              AnimatedRotation(
                                turns: isCollapsed ? -0.25 : 0,
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
                    if (!isCollapsed)
                      for (var i = 0; i < keys.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                          child: _Row(
                            entry: keys[i],
                            groupColor: group.color,
                            overrideValue: overrides[keys[i].key],
                            lastSource: sources[keys[i].key],
                            onEdit: () => _showEditor(context, keys[i]),
                            onClear: overrides.containsKey(keys[i].key)
                                ? () => RemoteConfigService.clearOverride(
                                    keys[i].key,
                                  )
                                : null,
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

  Future<void> _showEditor(BuildContext context, _RcKey entry) async {
    final current = RemoteConfigService.overrides[entry.key];
    switch (entry.type) {
      case _RcType.string:
        final result = await _editString(context, entry, current as String?);
        if (result != null) {
          RemoteConfigService.setOverride(entry.key, result);
        }
      case _RcType.bool_:
        final next = (current is bool) ? !current : true;
        RemoteConfigService.setOverride(entry.key, next);
      case _RcType.int_:
        final result = await _editInt(context, entry, current as int?);
        if (result != null) {
          RemoteConfigService.setOverride(entry.key, result);
        }
    }
  }

  Future<String?> _editString(
    BuildContext context,
    _RcKey entry,
    String? current,
  ) {
    return _showEditorDialog(
      context,
      entry: entry,
      initial: current ?? '',
      keyboardType: TextInputType.text,
    );
  }

  Future<int?> _editInt(
    BuildContext context,
    _RcKey entry,
    int? current,
  ) async {
    final result = await _showEditorDialog(
      context,
      entry: entry,
      initial: current?.toString() ?? '',
      keyboardType: const TextInputType.numberWithOptions(signed: true),
    );
    if (result == null) return null;
    return int.tryParse(result.trim());
  }

  /// Typed value editor — [GlobalDialog] chrome under the pinned
  /// console style, [DebugTextField] editor, Cancel/Save actions.
  Future<String?> _showEditorDialog(
    BuildContext context, {
    required _RcKey entry,
    required String initial,
    required TextInputType keyboardType,
  }) {
    final ctrl = TextEditingController(text: initial);
    return GlobalDialog.show<String>(
      context: context,
      title: entry.key,
      message: entry.description,
      showCloseButton: false,
      style: debugDialogStyle().copyWith(
        titleStyle: DebugOverlayTheme.mono.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: DebugOverlayTheme.text,
        ),
        messageStyle: DebugOverlayTheme.ui.copyWith(
          fontSize: 11,
          color: DebugOverlayTheme.textDim,
        ),
      ),
      content: _EditorContent(controller: ctrl, keyboardType: keyboardType),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Manifest types
// ─────────────────────────────────────────────────────────────

enum _RcType { string, bool_, int_ }

/// Effective-source buckets for the filter chips. `unread` = no code
/// path has read the key through [RemoteConfigService] this session,
/// so its winning layer is unknown until something reads it.
enum _SourceFilter {
  override_(
    label: 'overridden',
    icon: Icons.bolt_rounded,
    color: Color(0xFFE57373),
  ),
  remoteConfig(
    label: 'remote config',
    icon: Icons.cloud_rounded,
    color: Color(0xFF64B5F6),
  ),
  flavorConfig(
    label: 'flavor config',
    icon: Icons.tune_rounded,
    color: Color(0xFF9575CD),
  ),
  dotenv(
    label: '.env',
    icon: Icons.description_rounded,
    color: Color(0xFF81C784),
  ),
  hardcoded(
    label: 'hardcoded',
    icon: Icons.push_pin_rounded,
    color: Color(0xFFFFB74D),
  ),
  unread(
    label: 'not read yet',
    icon: Icons.visibility_off_rounded,
    color: Color(0xFF9E9E9E),
  );

  const _SourceFilter({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _RcKey {
  const _RcKey(this.key, this.type, this.description);

  final String key;
  final _RcType type;
  final String description;
}

/// Domain bucket — icon + hue carried into headers and row icon boxes.
class _RcGroup {
  const _RcGroup(this.label, this.icon, this.color, this.keys);

  final String label;
  final IconData icon;
  final Color color;
  final List<_RcKey> keys;
}

// ─────────────────────────────────────────────────────────────
// UI
// ─────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE57373);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count override${count == 1 ? '' : 's'} active — '
              'simulated values, lost on restart',
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          TextButton(
            onPressed: RemoteConfigService.clearAllOverrides,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: color,
            ),
            child: Text(
              'CLEAR ALL',
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.entry,
    required this.groupColor,
    required this.overrideValue,
    required this.lastSource,
    required this.onEdit,
    required this.onClear,
  });

  final _RcKey entry;
  final Color groupColor;
  // Named `overrideValue` (not `override`) so it doesn't shadow the
  // `@override` annotation in this class's scope.
  final Object? overrideValue;

  /// Which layer last supplied this key (RC / .env / hardcoded /
  /// override) — null when the app hasn't read it yet.
  final EnvSource? lastSource;

  final VoidCallback onEdit;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final isOverridden = overrideValue != null;
    final accent = isOverridden
        ? const Color(0xFFE57373)
        : DebugOverlayTheme.textDim;
    final isBool = entry.type == _RcType.bool_;

    return Material(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        splashColor: groupColor.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOverridden
                  ? accent.withValues(alpha: 0.5)
                  : DebugOverlayTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isOverridden ? accent : groupColor).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  _typeIcon(entry.type),
                  size: 14,
                  color: isOverridden ? accent : groupColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      entry.description,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 10,
                        color: DebugOverlayTheme.textDim,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (isOverridden && !isBool) ...[
                          Flexible(
                            child: Text(
                              '→ $overrideValue',
                              style: DebugOverlayTheme.mono.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else if (isOverridden && isBool) ...[
                          Text(
                            '→ $overrideValue',
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'from ',
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 10,
                              color: DebugOverlayTheme.textDimmer,
                            ),
                          ),
                          _SourceBadge(source: lastSource),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Bools flip inline; str/int open the typed editor.
              if (isBool)
                DebugSwitch(
                  value: (overrideValue as bool?) ?? false,
                  onChanged: (_) => onEdit(),
                  activeColor: accent,
                )
              else
                const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: DebugOverlayTheme.textDimmer,
                ),
              if (onClear != null)
                GlobalIconButton(
                  tooltip: 'Clear override',
                  enforceMinTouchTarget: false,
                  iconData: Icons.close_rounded,
                  onPressed: onClear,
                  iconSize: 14,
                  style: const ButtonStateStyle(
                    width: 28,
                    height: 28,
                    foregroundColor: DebugOverlayTheme.textDim,
                  ),
                ),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _typeIcon(_RcType t) => switch (t) {
    _RcType.string => Icons.notes_rounded,
    _RcType.bool_ => Icons.toggle_on_rounded,
    _RcType.int_ => Icons.numbers_rounded,
  };
}

/// Small badge naming the layer that last supplied a key's value.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final EnvSource? source;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      EnvSource.override => ('override', const Color(0xFFE57373)),
      EnvSource.remoteConfig => ('remote config', const Color(0xFF64B5F6)),
      EnvSource.flavorConfig => ('flavor config', const Color(0xFF9575CD)),
      EnvSource.dotenv => ('.env', const Color(0xFF81C784)),
      EnvSource.hardcoded => ('hardcoded', const Color(0xFFFFB74D)),
      // Nothing has read this key through RemoteConfigService yet this
      // session — the winning layer is unknown until a screen uses it.
      null => ('not read yet this session', DebugOverlayTheme.textDimmer),
    };
    return Text(
      label,
      style: DebugOverlayTheme.mono.copyWith(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

/// Assets-page-style source chip: icon + label + count, hue-tinted.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final _SourceFilter filter;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = filter.color;
    return Material(
      color: selected ? color.withValues(alpha: 0.15) : DebugOverlayTheme.bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: color.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.6)
                  : DebugOverlayTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filter.icon,
                size: 12,
                color: selected ? color : color.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 5),
              Text(
                filter.label,
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : DebugOverlayTheme.textDim,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10,
                  color: selected ? color : DebugOverlayTheme.textDimmer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Body of the value-editor dialog — [DebugTextField] + Cancel/Save.
/// Lives inside [GlobalDialog.show]'s route so its own context pops
/// with the result.
class _EditorContent extends StatelessWidget {
  const _EditorContent({
    required this.controller,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DebugTextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: true,
          fillColor: DebugOverlayTheme.surface,
          onSubmitted: (s) => Navigator.of(context).pop(s),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GlobalTextButton(
              text: CommonStrings.cancel,
              shrinkWidth: true,
              style: const ButtonStateStyle(
                foregroundColor: DebugOverlayTheme.textDim,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            GlobalFilledButton(
              text: CommonStrings.save,
              shrinkWidth: true,
              style: ButtonStateStyle(
                backgroundColor: DebugOverlayTheme.accent,
                foregroundColor: Colors.black87,
              ),
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
        ),
      ],
    );
  }
}
