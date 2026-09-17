import 'package:flutter/material.dart';

import '../../../../core/devtools/network_sim.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../debug_overlay_models.dart';

/// UI for [NetworkSim] — scenario presets + knobs mutating the
/// persisted values the Dio interceptor consults on every request.
class DebugNetworkSimView extends StatelessWidget {
  const DebugNetworkSimView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        DebugOverlayPrefs.netSimLatencyMs,
        DebugOverlayPrefs.netSimFailEveryN,
        DebugOverlayPrefs.netSimFailStatus,
      ]),
      builder: (_, _) {
        final latency = DebugOverlayPrefs.netSimLatencyMs.value;
        final failEvery = DebugOverlayPrefs.netSimFailEveryN.value;
        final failStatus = DebugOverlayPrefs.netSimFailStatus.value;
        final active = latency > 0 || failEvery > 0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            _SummaryHero(
              active: active,
              latency: latency,
              failEvery: failEvery,
              failStatus: failStatus,
              onDisable: active
                  ? () {
                      DebugOverlayPrefs.setNetSim(latencyMs: 0, failEveryN: 0);
                      NetworkSim.resetCounter();
                    }
                  : null,
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Scenario presets',
              icon: Icons.bolt_rounded,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _PresetChip(
                    label: 'Slow 3G',
                    icon: Icons.network_cell_rounded,
                    selected: active && latency == 800 && failEvery == 0,
                    onTap: () => _apply(latencyMs: 800, failEveryN: 0),
                  ),
                  _PresetChip(
                    label: 'Flaky',
                    icon: Icons
                        .signal_wifi_statusbar_connected_no_internet_4_rounded,
                    selected:
                        latency == 300 && failEvery == 5 && failStatus == 503,
                    onTap: () =>
                        _apply(latencyMs: 300, failEveryN: 5, failStatus: 503),
                  ),
                  _PresetChip(
                    label: 'Server down',
                    icon: Icons.cloud_off_rounded,
                    selected: failEvery == 1 && failStatus == 503,
                    onTap: () =>
                        _apply(latencyMs: 0, failEveryN: 1, failStatus: 503),
                  ),
                  _PresetChip(
                    label: 'Timeouts',
                    icon: Icons.hourglass_disabled_rounded,
                    selected: failEvery == 2 && failStatus == 0,
                    onTap: () =>
                        _apply(latencyMs: 1000, failEveryN: 2, failStatus: 0),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Latency',
              icon: Icons.timer_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: latency.toDouble().clamp(0, 3000),
                          min: 0,
                          max: 3000,
                          divisions: 30,
                          activeColor: DebugOverlayTheme.accent,
                          inactiveColor: DebugOverlayTheme.border,
                          onChanged: (v) =>
                              DebugOverlayPrefs.setNetSim(latencyMs: v.round()),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DebugOverlayTheme.accent.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: DebugOverlayTheme.accent.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Text(
                          '${latency}ms',
                          style: DebugOverlayTheme.mono.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: DebugOverlayTheme.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final t in const ['0', '1.5s', '3s'])
                          Text(
                            t,
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 9,
                              color: DebugOverlayTheme.textDimmer,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adds artificial delay before every request fires.',
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 10,
                      color: DebugOverlayTheme.textDim,
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Fail every Nth request',
              icon: Icons.error_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final n in const [0, 1, 2, 5, 10])
                        _Chip(
                          label: n == 0 ? 'off' : '1/$n',
                          selected: failEvery == n,
                          onTap: () {
                            DebugOverlayPrefs.setNetSim(failEveryN: n);
                            NetworkSim.resetCounter();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Counter resets when you change frequency.',
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 10,
                      color: DebugOverlayTheme.textDim,
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Failure kind',
              icon: Icons.pin_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in const [0, 408, 500, 502, 503, 504])
                    _Chip(
                      label: s == 0 ? 'timeout' : '$s',
                      selected: failStatus == s,
                      onTap: () => DebugOverlayPrefs.setNetSim(failStatus: s),
                    ),
                ],
              ),
            ),
            _Section(
              title: 'Counter',
              icon: Icons.restart_alt_rounded,
              child: Material(
                color: DebugOverlayTheme.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: NetworkSim.resetCounter,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DebugOverlayTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: DebugOverlayTheme.accent.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: DebugOverlayTheme.accentDefault,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reset request counter',
                                style: DebugOverlayTheme.ui.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Re-roll which request in the 1/N cycle fails next',
                                style: DebugOverlayTheme.ui.copyWith(
                                  fontSize: 10,
                                  color: DebugOverlayTheme.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 15,
                          color: DebugOverlayTheme.textDimmer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void _apply({
    required int latencyMs,
    required int failEveryN,
    int? failStatus,
  }) {
    DebugOverlayPrefs.setNetSim(
      latencyMs: latencyMs,
      failEveryN: failEveryN,
      failStatus: failStatus,
    );
    NetworkSim.resetCounter();
  }
}

// ─────────────────────────────────────────────────────────────

/// What the interceptor will DO right now, in one sentence.
class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.active,
    required this.latency,
    required this.failEvery,
    required this.failStatus,
    required this.onDisable,
  });

  final bool active;
  final int latency;
  final int failEvery;
  final int failStatus;
  final VoidCallback? onDisable;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFE57373) : const Color(0xFF66BB6A);
    final parts = <String>[
      if (latency > 0) 'every request +${latency}ms',
      if (failEvery > 0)
        '1 in $failEvery fails with ${failStatus == 0 ? 'a timeout' : 'HTTP $failStatus'}',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.bolt_rounded : Icons.check_circle_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'SIMULATING' : 'OFF',
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  active
                      ? parts.join(' · ')
                      : 'Requests pass through untouched.',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10.5,
                    color: DebugOverlayTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
          if (onDisable != null)
            TextButton(
              onPressed: onDisable,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: color,
              ),
              child: Text(
                'DISABLE',
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

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.18)
          : DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.6)
                  : DebugOverlayTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: selected ? accent : DebugOverlayTheme.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Material(
      color: selected ? accent.withValues(alpha: 0.18) : DebugOverlayTheme.bg,
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
                  ? accent.withValues(alpha: 0.6)
                  : DebugOverlayTheme.border,
            ),
          ),
          child: Text(
            label,
            style: DebugOverlayTheme.mono.copyWith(
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
