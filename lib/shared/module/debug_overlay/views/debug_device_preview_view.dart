import 'package:flutter/material.dart';

import '../../../../core/flavor/flavor_config.dart';
import '../../../../core/responsive/extensions.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../debug_overlay_models.dart';

/// DevicePreview control + live viewport panel.
///
/// The toggle is tri-state — auto (follow the flavor's
/// `useDevicePreview`), force on, force off — live, no restart
/// (`MyApp` wraps unconditionally and re-reads `enabled` on change).
/// Below it, the viewport panel shows the metrics the responsive
/// system actually runs on (size, WindowSizeClass bucket, DPR,
/// orientation, text scale, safe areas) — simulated values included
/// while DevicePreview is active.
class DebugDevicePreviewView extends StatelessWidget {
  const DebugDevicePreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: DebugOverlayPrefs.devicePreviewOverride,
      builder: (context, override, _) {
        final flavor = FlavorConfig.maybeInstance?.flavor;
        final flavorWants = flavor?.useDevicePreview ?? false;
        final effective = override ?? flavorWants;
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            _FlatSection(
              title: 'Device preview',
              icon: Icons.smartphone_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _EffectivePill(on: effective),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'flavor default: ${flavorWants ? 'on' : 'off'}'
                          '${flavor == null ? '' : ' (${flavor.name})'}',
                          style: DebugOverlayTheme.mono.copyWith(
                            fontSize: 10,
                            color: DebugOverlayTheme.textDimmer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Segmented(
                    current: override,
                    onSelect: DebugOverlayPrefs.setDevicePreviewOverride,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DevicePreview renders the app inside simulated device '
                    'frames (sizes, DPRs, locales) for responsive testing — '
                    'a heavyweight wrap, so flavors gate it. Auto follows '
                    'the flavor; an override wins and persists across '
                    'launches.',
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 10,
                      color: DebugOverlayTheme.textDim,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const _FlatSection(
              title: 'Live viewport',
              icon: Icons.aspect_ratio_rounded,
              child: _ViewportPanel(),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _FlatSection extends StatelessWidget {
  const _FlatSection({
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

class _EffectivePill extends StatelessWidget {
  const _EffectivePill({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final color = on ? DebugOverlayTheme.accent : DebugOverlayTheme.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            on ? Icons.smartphone_rounded : Icons.fullscreen_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            on ? 'ON' : 'OFF',
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// auto / force on / force off — same segmented pattern as the theme
/// page + jump sheet.
class _Segmented extends StatelessWidget {
  const _Segmented({required this.current, required this.onSelect});

  final bool? current;
  final ValueChanged<bool?> onSelect;

  static const _options = <(bool?, String, IconData)>[
    (null, 'Auto', Icons.brightness_auto_rounded),
    (true, 'Force on', Icons.smartphone_rounded),
    (false, 'Force off', Icons.fullscreen_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Row(
        children: [
          for (final (value, label, icon) in _options)
            Expanded(
              child: Material(
                color: value == current
                    ? accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => onSelect(value),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 30,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 12,
                          color: value == current
                              ? accent
                              : DebugOverlayTheme.textDim,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: DebugOverlayTheme.ui.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: value == current
                                ? accent
                                : DebugOverlayTheme.textDim,
                          ),
                        ),
                      ],
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

// ─────────────────────────────────────────────────────────────

/// The metrics the responsive system runs on — live via MediaQuery
/// (which reflects DevicePreview's simulation when it's active).
class _ViewportPanel extends StatelessWidget {
  const _ViewportPanel();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final bucket = context.maybeBreakpoints?.windowSize.label ?? '—';
    final rows = <(String, String)>[
      (
        'logical size',
        '${size.width.toStringAsFixed(0)} × ${size.height.toStringAsFixed(0)} dp',
      ),
      ('window class', bucket),
      ('pixel ratio', '${mq.devicePixelRatio.toStringAsFixed(2)}×'),
      (
        'orientation',
        mq.orientation == Orientation.portrait ? 'portrait' : 'landscape',
      ),
      ('text scale', '${mq.textScaler.scale(1).toStringAsFixed(2)}×'),
      (
        'safe area',
        'top ${mq.padding.top.toStringAsFixed(0)} · bottom ${mq.padding.bottom.toStringAsFixed(0)}',
      ),
      ('reduce motion', mq.disableAnimations ? 'on' : 'off'),
      ('bold text', mq.boldText ? 'on' : 'off'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                color: DebugOverlayTheme.border.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 11,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    style: DebugOverlayTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
