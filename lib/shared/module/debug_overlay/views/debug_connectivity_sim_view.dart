import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/connectivity/connectivity_config.dart';
import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/connectivity/connectivity_state.dart';
import '../../../../core/di/service_locator.dart';
import '../debug_overlay_models.dart';

/// Connectivity simulator — force any [ConnectivityVerdict] / VPN flag
/// at runtime so the dev can drive the offline banner, error pages, and
/// gate flows without yanking the cable.
///
/// Reads + mutates [ConnectivityCubit] via [getIt]. Override state lives
/// on the cubit itself; clearing it returns to real evaluation.
class DebugConnectivitySimView extends StatefulWidget {
  const DebugConnectivitySimView({super.key});

  @override
  State<DebugConnectivitySimView> createState() =>
      _DebugConnectivitySimViewState();
}

class _DebugConnectivitySimViewState extends State<DebugConnectivitySimView> {
  ConnectivityCubit? _cubit;
  ConnectivityState? _state;
  StreamSubscription<ConnectivityState>? _sub;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<ConnectivityCubit>()) {
      _cubit = getIt<ConnectivityCubit>();
      _state = _cubit!.state;
      _sub = _cubit!.stream.listen((s) {
        if (mounted) setState(() => _state = s);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Center(
        child: Text(
          'ConnectivityCubit not registered.',
          style: TextStyle(color: DebugOverlayTheme.textDim),
        ),
      );
    }

    final state = _state;
    final hasOverride = cubit.hasDebugOverride;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        if (hasOverride) _OverrideBanner(onClear: cubit.debugClearOverrides),
        _VerdictHero(state: state, simulated: hasOverride),
        const SizedBox(height: 14),
        _Section(
          title: 'Force verdict',
          icon: Icons.signal_cellular_alt_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ForceVerdictGrid(
                current: cubit.debugVerdictOverride,
                onSelect: cubit.debugForceVerdict,
              ),
              const SizedBox(height: 6),
              Text(
                'offline also covers captive portals; probe untrusted = '
                'probe endpoint failing while the link reports up.',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10,
                  color: DebugOverlayTheme.textDimmer,
                ),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Force VPN',
          icon: Icons.vpn_lock_rounded,
          child: _ForceVpnRow(
            current: cubit.debugVpnOverride,
            onSelect: cubit.debugForceVpn,
          ),
        ),
        _Section(
          title: 'VPN policy',
          icon: Icons.policy_rounded,
          child: _VpnPolicyRow(
            current: cubit.config.vpnPolicy,
            onSelect: (p) => cubit.updateConfig(
              cubit.config.copyWith(vpnPolicy: p),
            ),
          ),
        ),
        _Section(
          title: 'Details',
          icon: Icons.network_check_rounded,
          child: _CurrentState(state: state),
        ),
        _Section(
          title: 'Actions',
          icon: Icons.tune_rounded,
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.refresh_rounded,
                label: 'Re-probe now',
                description: 'Run a real evaluation cycle',
                onTap: cubit.reprobe,
              ),
              _ActionTile(
                icon: Icons.layers_clear_rounded,
                label: 'Clear all overrides',
                description: 'Return to real connectivity sources',
                onTap: hasOverride ? cubit.debugClearOverrides : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Verdict hero — the answer at a glance
// ─────────────────────────────────────────────────────────────

class _VerdictHero extends StatelessWidget {
  const _VerdictHero({required this.state, required this.simulated});

  final ConnectivityState? state;
  final bool simulated;

  @override
  Widget build(BuildContext context) {
    final verdict = state?.verdict;
    final (color, icon, label) = switch (verdict) {
      ConnectivityVerdict.online => (
        const Color(0xFF66BB6A),
        Icons.wifi_rounded,
        'ONLINE',
      ),
      ConnectivityVerdict.offline => (
        const Color(0xFFEF5350),
        Icons.wifi_off_rounded,
        'OFFLINE',
      ),
      ConnectivityVerdict.probeUntrusted => (
        const Color(0xFFFFA726),
        Icons.wifi_tethering_error_rounded,
        'PROBE UNTRUSTED',
      ),
      _ => (DebugOverlayTheme.textDim, Icons.help_outline_rounded, 'UNKNOWN'),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'source: ${state?.source.name ?? '—'}'
                  '${(state?.vpnDetected ?? false) ? ' · VPN' : ''}',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10.5,
                    color: DebugOverlayTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
          if (simulated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: DebugOverlayTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: DebugOverlayTheme.accent.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'SIMULATED',
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: DebugOverlayTheme.accent,
                  letterSpacing: 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Override banner
// ─────────────────────────────────────────────────────────────

class _OverrideBanner extends StatelessWidget {
  const _OverrideBanner({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final color = DebugOverlayTheme.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Override active — values are simulated, not measured',
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: color,
            ),
            child: Text(
              'CLEAR',
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

// ─────────────────────────────────────────────────────────────
// Current-state read-out
// ─────────────────────────────────────────────────────────────

class _CurrentState extends StatelessWidget {
  const _CurrentState({required this.state});
  final ConnectivityState? state;

  @override
  Widget build(BuildContext context) {
    if (state == null) {
      return const Text(
        '<no state>',
        style: TextStyle(color: DebugOverlayTheme.textDimmer),
      );
    }
    final s = state!;
    return Column(
      children: [
        _Row(label: 'verdict', value: s.verdict.name),
        _Row(label: 'source', value: s.source.name),
        _Row(label: 'vpnDetected', value: '${s.vpnDetected}'),
        _Row(label: 'probeFailures', value: '${s.probeFailures}'),
        _Row(label: 'queuedActions', value: '${s.queuedActions}'),
        _Row(
          label: 'lastChange',
          value: s.lastChange == null ? '<never>' : _hms(s.lastChange!),
        ),
      ],
    );
  }

  static String _hms(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 11,
                color: DebugOverlayTheme.textDim,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: DebugOverlayTheme.mono.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Force-verdict picker
// ─────────────────────────────────────────────────────────────

class _ForceVerdictGrid extends StatelessWidget {
  const _ForceVerdictGrid({required this.current, required this.onSelect});

  final ConnectivityVerdict? current;
  final ValueChanged<ConnectivityVerdict?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'auto',
          color: DebugOverlayTheme.textDim,
          selected: current == null,
          onTap: () => onSelect(null),
        ),
        _Chip(
          label: 'online',
          color: const Color(0xFF66BB6A),
          selected: current == ConnectivityVerdict.online,
          onTap: () => onSelect(ConnectivityVerdict.online),
        ),
        _Chip(
          label: 'offline',
          color: const Color(0xFFEF5350),
          selected: current == ConnectivityVerdict.offline,
          onTap: () => onSelect(ConnectivityVerdict.offline),
        ),
        _Chip(
          label: 'probe untrusted',
          color: const Color(0xFFFFA726),
          selected: current == ConnectivityVerdict.probeUntrusted,
          onTap: () => onSelect(ConnectivityVerdict.probeUntrusted),
        ),
      ],
    );
  }
}

class _VpnPolicyRow extends StatelessWidget {
  const _VpnPolicyRow({required this.current, required this.onSelect});

  final VpnPolicy current;
  final ValueChanged<VpnPolicy> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'allow',
          color: const Color(0xFF66BB6A),
          selected: current == VpnPolicy.allow,
          onTap: () => onSelect(VpnPolicy.allow),
        ),
        _Chip(
          label: 'warn',
          color: const Color(0xFFFFA726),
          selected: current == VpnPolicy.warn,
          onTap: () => onSelect(VpnPolicy.warn),
        ),
        _Chip(
          label: 'block',
          color: const Color(0xFFEF5350),
          selected: current == VpnPolicy.block,
          onTap: () => onSelect(VpnPolicy.block),
        ),
      ],
    );
  }
}

class _ForceVpnRow extends StatelessWidget {
  const _ForceVpnRow({required this.current, required this.onSelect});

  final bool? current;
  final ValueChanged<bool?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'auto',
          color: DebugOverlayTheme.textDim,
          selected: current == null,
          onTap: () => onSelect(null),
        ),
        _Chip(
          label: 'no VPN',
          color: const Color(0xFF4FC3F7),
          selected: current == false,
          onTap: () => onSelect(false),
        ),
        _Chip(
          label: 'VPN active',
          color: const Color(0xFFAB47BC),
          selected: current == true,
          onTap: () => onSelect(true),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.6)
                  : DebugOverlayTheme.border,
            ),
          ),
          child: Text(
            label,
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? color : DebugOverlayTheme.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Action tile
// ─────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: disabled
                    ? DebugOverlayTheme.textDimmer
                    : DebugOverlayTheme.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: disabled
                            ? DebugOverlayTheme.textDim
                            : DebugOverlayTheme.text,
                      ),
                    ),
                    Text(
                      description,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 10,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: disabled
                    ? DebugOverlayTheme.textDimmer
                    : DebugOverlayTheme.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section wrapper
// ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

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
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
