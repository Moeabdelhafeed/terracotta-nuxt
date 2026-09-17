import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_search_field.dart';

/// Live view of the `get_it` container. Walks [kRegisteredServices]
/// (the boot manifest) + [kLateRegisteredServices] (registered after
/// boot) and shows the real per-type state: LIVE (instance built),
/// LAZY (registered, not constructed yet) or MISSING (manifest drift —
/// the list and `initServiceLocator` disagree). Tap a lazy row to
/// resolve it on the spot.
class DebugServiceLocatorView extends StatefulWidget {
  const DebugServiceLocatorView({super.key});

  @override
  State<DebugServiceLocatorView> createState() =>
      _DebugServiceLocatorViewState();
}

enum _TypeState { live, lazy, missing }

class _DebugServiceLocatorViewState extends State<DebugServiceLocatorView> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  _TypeState _stateOf(Type type) {
    if (!getIt.isRegistered(type: type)) return _TypeState.missing;
    final probe = kServiceInstanceProbes[type];
    if (probe == null) return _TypeState.lazy;
    try {
      return probe() ? _TypeState.live : _TypeState.lazy;
    } on Object {
      // Registered but not as a lazy singleton — instance exists.
      return _TypeState.live;
    }
  }

  void _resolve(Type type) {
    try {
      getIt.get(type: type);
      GlobalToast.info('$type resolved');
      setState(() {});
    } on Object catch (e) {
      GlobalToast.error('$type failed to resolve', description: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    bool match(Type t) => q.isEmpty || '$t'.toLowerCase().contains(q);

    final boot = [
      for (final t in kRegisteredServices)
        if (match(t)) (t, _stateOf(t)),
    ];
    final late_ = [
      for (final t in kLateRegisteredServices)
        if (match(t)) (t, _stateOf(t)),
    ];

    final all = [...boot, ...late_];
    final liveCount = all.where((r) => r.$2 == _TypeState.live).length;
    final lazyCount = all.where((r) => r.$2 == _TypeState.lazy).length;
    final drift = boot.where((r) => r.$2 == _TypeState.missing).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: DebugSearchField(
            controller: _searchCtrl,
            hintText: 'Filter services',
            onChanged: (v) => setState(() => _query = v),
            resultCount: q.isEmpty ? null : all.length,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              Row(
                children: [
                  _StatChip(
                    label: 'live',
                    count: liveCount,
                    color: const Color(0xFF66BB6A),
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'lazy',
                    count: lazyCount,
                    color: const Color(0xFF64B5F6),
                  ),
                  if (drift.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _StatChip(
                      label: 'missing',
                      count: drift.length,
                      color: const Color(0xFFEF5350),
                    ),
                  ],
                ],
              ),
              if (drift.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    'Manifest drift: ${drift.length} type(s) in '
                    'kRegisteredServices are NOT registered in getIt. '
                    'Update initServiceLocator() or the manifest.',
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 10.5,
                      color: const Color(0xFFEF5350),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (boot.isNotEmpty)
                _Section(
                  title: 'Boot manifest',
                  icon: Icons.hub_rounded,
                  count: boot.length,
                  caption:
                      'initServiceLocator() — lazy singletons build on '
                      'first read. Tap a LAZY row to resolve it now.',
                  child: _Group(
                    children: [
                      for (final (t, s) in boot)
                        _Row(type: t, state: s, onResolve: _resolve),
                    ],
                  ),
                ),
              if (late_.isNotEmpty)
                _Section(
                  title: 'Registered after boot',
                  icon: Icons.schedule_rounded,
                  count: late_.length,
                  caption:
                      'NavigationService (needs GoRouter) + notification '
                      'services (skipped when notifications are off) — '
                      'unregistered here is legitimate.',
                  child: _Group(
                    children: [
                      for (final (t, s) in late_)
                        _Row(
                          type: t,
                          state: s,
                          onResolve: _resolve,
                          lateGroup: true,
                        ),
                    ],
                  ),
                ),
              if (all.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text(
                      'No services match "$_query"',
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 11,
                        color: DebugOverlayTheme.textDim,
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
}

// ─────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$count $label',
        style: DebugOverlayTheme.mono.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.count,
    required this.child,
    this.caption,
  });

  final String title;
  final IconData icon;
  final int count;
  final Widget child;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: DebugOverlayTheme.textDim),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
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
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 10,
                color: DebugOverlayTheme.textDimmer,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                color: DebugOverlayTheme.border.withValues(alpha: 0.5),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.type,
    required this.state,
    required this.onResolve,
    this.lateGroup = false,
  });

  final Type type;
  final _TypeState state;
  final void Function(Type) onResolve;
  final bool lateGroup;

  static IconData _kindIcon(String name) {
    if (name.endsWith('Cubit') || name.endsWith('Bloc')) {
      return Icons.account_tree_rounded;
    }
    if (name.endsWith('Service') || name.endsWith('Dispatcher')) {
      return Icons.miscellaneous_services_rounded;
    }
    if (name.endsWith('Store') ||
        name.endsWith('Cache') ||
        name.endsWith('Queue')) {
      return Icons.inventory_2_rounded;
    }
    return Icons.extension_rounded;
  }

  static Color _kindColor(String name) {
    if (name.endsWith('Cubit') || name.endsWith('Bloc')) {
      return const Color(0xFF64B5F6);
    }
    if (name.endsWith('Service') || name.endsWith('Dispatcher')) {
      return const Color(0xFF66BB6A);
    }
    if (name.endsWith('Store') ||
        name.endsWith('Cache') ||
        name.endsWith('Queue')) {
      return const Color(0xFFFFA726);
    }
    return const Color(0xFFBA68C8);
  }

  @override
  Widget build(BuildContext context) {
    final name = '$type';
    final kindColor = _kindColor(name);
    final (pillLabel, pillColor) = switch (state) {
      _TypeState.live => ('LIVE', const Color(0xFF66BB6A)),
      _TypeState.lazy => ('LAZY', const Color(0xFF64B5F6)),
      _TypeState.missing =>
        lateGroup
            ? ('NOT YET', DebugOverlayTheme.textDimmer)
            : ('MISSING', const Color(0xFFEF5350)),
    };
    final canResolve = state == _TypeState.lazy;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canResolve ? () => onResolve(type) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kindColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(_kindIcon(name), size: 14, color: kindColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: pillColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: pillColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  pillLabel,
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: pillColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (canResolve) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 14,
                  color: DebugOverlayTheme.textDimmer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
