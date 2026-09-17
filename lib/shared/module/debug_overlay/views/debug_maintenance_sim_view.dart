import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bootstrap/bootstrap_maintenance.dart';
import '../../../../core/maintenance/maintenance_cubit.dart';
import '../../../../core/maintenance/maintenance_state.dart';
import '../../../../data/services/remote_config_service.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_text_field.dart';

/// Drives `MaintenanceCubit` by setting RC overrides for the
/// `maintenance_*` keys, then reseeding the cubit immediately (the
/// bootstrap subscription only reseeds on real RC activates).
///
/// The gate replaces the WHOLE subtree — including this overlay — so
/// every trigger arms an auto-revert timer by default. The timer is
/// static: it keeps ticking after the gate unmounts this view.
class DebugMaintenanceSimView extends StatefulWidget {
  const DebugMaintenanceSimView({super.key});

  @override
  State<DebugMaintenanceSimView> createState() =>
      _DebugMaintenanceSimViewState();
}

/// Auto-revert that outlives the widget tree. The maintenance gate
/// swallows the app (and this overlay) while active, so a plain State
/// timer would be disposed the moment the sim works.
abstract final class _AutoRevert {
  static Timer? _timer;

  /// Selected duration in seconds; 0 = manual (no auto-revert).
  static int seconds = 60;

  static void arm() {
    _timer?.cancel();
    if (seconds == 0) return;
    _timer = Timer(Duration(seconds: seconds), () {
      clearSim();
      GlobalToast.info('Maintenance sim auto-cleared');
    });
  }

  static void disarm() {
    _timer?.cancel();
    _timer = null;
  }

  /// Remove every maintenance_* override and push the change into the
  /// cubit so the gate drops instantly.
  static void clearSim() {
    disarm();
    for (final key in const [
      'maintenance_mode',
      'maintenance_title',
      'maintenance_message',
      'maintenance_eta',
      'maintenance_support_url',
      'maintenance_allow_list',
    ]) {
      RemoteConfigService.clearOverride(key);
    }
    seedMaintenanceFromRemoteConfig();
  }
}

class _DebugMaintenanceSimViewState extends State<DebugMaintenanceSimView> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _msgCtrl;
  late final TextEditingController _etaCtrl;
  late final TextEditingController _supportCtrl;

  @override
  void initState() {
    super.initState();
    final overrides = RemoteConfigService.overrides;
    _titleCtrl = TextEditingController(
      text: overrides['maintenance_title'] as String? ?? 'Be right back',
    );
    _msgCtrl = TextEditingController(
      text:
          overrides['maintenance_message'] as String? ??
          'We are doing a quick tune-up. Try again in a few minutes.',
    );
    _etaCtrl = TextEditingController(
      text: overrides['maintenance_eta'] as String? ?? '',
    );
    _supportCtrl = TextEditingController(
      text: overrides['maintenance_support_url'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    _etaCtrl.dispose();
    _supportCtrl.dispose();
    super.dispose();
  }

  void _trigger() {
    RemoteConfigService.setOverride('maintenance_mode', true);
    RemoteConfigService.setOverride(
      'maintenance_title',
      _titleCtrl.text.trim(),
    );
    RemoteConfigService.setOverride(
      'maintenance_message',
      _msgCtrl.text.trim(),
    );
    final eta = _etaCtrl.text.trim();
    eta.isNotEmpty
        ? RemoteConfigService.setOverride('maintenance_eta', eta)
        : RemoteConfigService.clearOverride('maintenance_eta');
    final support = _supportCtrl.text.trim();
    support.isNotEmpty
        ? RemoteConfigService.setOverride('maintenance_support_url', support)
        : RemoteConfigService.clearOverride('maintenance_support_url');
    seedMaintenanceFromRemoteConfig();
    _AutoRevert.arm();
  }

  void _clear() {
    _AutoRevert.clearSim();
    context.read<MaintenanceCubit>().clearApiUnavailable();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaintenanceCubit, MaintenanceState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            _StatusHero(state: state, onClear: state.isActive ? _clear : null),
            const SizedBox(height: 14),
            _Section(
              title: 'Auto-revert',
              icon: Icons.timer_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (label, secs) in const [
                        ('15s', 15),
                        ('60s', 60),
                        ('5m', 300),
                        ('manual', 0),
                      ])
                        _Chip(
                          label: label,
                          selected: _AutoRevert.seconds == secs,
                          onTap: () =>
                              setState(() => _AutoRevert.seconds = secs),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _AutoRevert.seconds == 0
                        ? 'CAREFUL: the gate covers this overlay too — with '
                              'manual you must clear via hot restart.'
                        : 'Sim clears itself — the gate hides this overlay '
                              'while active, so the timer is your way back.',
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 10,
                      color: _AutoRevert.seconds == 0
                          ? const Color(0xFFFFA726)
                          : DebugOverlayTheme.textDim,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Scenario presets',
              icon: Icons.bolt_rounded,
              child: _TileGroup(
                children: [
                  _Tile(
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFFFA726),
                    label: 'Soft maintenance',
                    description: '~30 min ETA, generic copy',
                    onTap: () {
                      _titleCtrl.text = 'Quick tune-up';
                      _msgCtrl.text =
                          "We're tightening some bolts. Back in 30 min.";
                      _etaCtrl.text = DateTime.now()
                          .add(const Duration(minutes: 30))
                          .toUtc()
                          .toIso8601String();
                      _supportCtrl.text = '';
                      _trigger();
                      setState(() {});
                    },
                  ),
                  _Tile(
                    icon: Icons.gpp_bad_rounded,
                    color: const Color(0xFFEF5350),
                    label: 'Hard outage',
                    description: 'No ETA, support URL shown',
                    onTap: () {
                      _titleCtrl.text = 'Service interruption';
                      _msgCtrl.text =
                          "Something is off and we're investigating.";
                      _etaCtrl.text = '';
                      _supportCtrl.text = 'https://example.com/status';
                      _trigger();
                      setState(() {});
                    },
                  ),
                  _Tile(
                    icon: Icons.cloud_off_rounded,
                    color: const Color(0xFFBA68C8),
                    label: 'API 503 (unplanned)',
                    description:
                        'Interceptor path — Retry-After 60s, '
                        'gate Retry button clears it',
                    onTap: () {
                      context.read<MaintenanceCubit>().markApiUnavailable(
                        message: 'Simulated 503 from the API side.',
                        retryAfter: const Duration(seconds: 60),
                      );
                      _AutoRevert.arm();
                    },
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Custom trigger',
              icon: Icons.engineering_rounded,
              child: Column(
                children: [
                  _Field(label: 'title', controller: _titleCtrl),
                  const SizedBox(height: 8),
                  _Field(label: 'message', controller: _msgCtrl, maxLines: 2),
                  const SizedBox(height: 8),
                  _Field(
                    label: 'eta',
                    controller: _etaCtrl,
                    hint: 'ISO-8601 (e.g. 2026-05-10T14:00:00Z)',
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (final (label, mins) in const [
                          ('+15m', 15),
                          ('+1h', 60),
                          ('none', 0),
                        ])
                          _Chip(
                            label: label,
                            selected: false,
                            small: true,
                            onTap: () => setState(() {
                              _etaCtrl.text = mins == 0
                                  ? ''
                                  : DateTime.now()
                                        .add(Duration(minutes: mins))
                                        .toUtc()
                                        .toIso8601String();
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Field(
                    label: 'supportUrl',
                    controller: _supportCtrl,
                    hint: 'https://…',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _clear,
                        style: TextButton.styleFrom(
                          foregroundColor: DebugOverlayTheme.textDim,
                        ),
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      _TriggerButton(onTap: _trigger),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              'Overrides are in-memory — a full restart reseeds from real '
              'Remote Config and drops the sim.',
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 10,
                color: DebugOverlayTheme.textDimmer,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Live gate verdict — which source (RC / API) is holding it up.
class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.state, required this.onClear});

  final MaintenanceState state;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final active = state.isActive;
    final color = active ? const Color(0xFFE57373) : const Color(0xFF66BB6A);
    final sources = <String>[
      if (state.rcActive) 'remote config',
      if (state.apiActive) 'API 503',
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
            active ? Icons.engineering_rounded : Icons.check_circle_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'GATE UP' : 'GATE DOWN',
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  active
                      ? 'Held up by: ${sources.join(' + ')}'
                      : 'App renders normally.',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10.5,
                    color: DebugOverlayTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null)
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

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});

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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 11,
                color: DebugOverlayTheme.textDim,
              ),
            ),
          ),
        ),
        Expanded(
          child: DebugTextField(
            controller: controller,
            hint: hint ?? '',
            maxLines: maxLines,
            showBorder: false,
            fontSize: 11.5,
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

/// Red accent trigger — deliberately NOT the app-theme FilledButton so
/// the app's accent doesn't bleed into the dev surface.
class _TriggerButton extends StatelessWidget {
  const _TriggerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE57373);
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.engineering_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                'Trigger',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
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
    this.small = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool small;

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
          padding: EdgeInsets.symmetric(
            horizontal: small ? 9 : 12,
            vertical: small ? 4 : 6,
          ),
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
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: selected ? accent : DebugOverlayTheme.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
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
              const Icon(
                Icons.play_arrow_rounded,
                size: 15,
                color: DebugOverlayTheme.textDimmer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
