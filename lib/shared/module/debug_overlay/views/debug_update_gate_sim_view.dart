import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/update_gate/update_cubit.dart';
import '../../../../core/update_gate/update_state.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_text_field.dart';

/// Update-gate simulator. Pumps synthetic min/latest versions into
/// [UpdateCubit] so devs can drive the hard/soft/up-to-date flows
/// without rebuilding to bump the package version.
///
/// One-tap presets cover the common scenarios; freeform fields handle
/// edge cases. Reset dismissals at the bottom because skipping +
/// remind-later both persist via HydratedBloc.
class DebugUpdateGateSimView extends StatefulWidget {
  const DebugUpdateGateSimView({super.key});

  @override
  State<DebugUpdateGateSimView> createState() => _DebugUpdateGateSimViewState();
}

class _DebugUpdateGateSimViewState extends State<DebugUpdateGateSimView> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _latestCtrl;
  late final TextEditingController _storeCtrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<UpdateCubit>().state;
    _minCtrl = TextEditingController(text: state.minVersion);
    _latestCtrl = TextEditingController(text: state.latestVersion);
    _storeCtrl = TextEditingController(text: state.storeUrl);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _latestCtrl.dispose();
    _storeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        final cubit = context.read<UpdateCubit>();
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            _RequirementHero(state: state),
            const SizedBox(height: 14),
            _Section(
              title: 'Presets',
              icon: Icons.bolt_rounded,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.gpp_bad_rounded,
                    color: const Color(0xFFEF5350),
                    label: 'Hard-required gate',
                    description:
                        'min = current+1.0.0 → blocks app, shows UpdateScreen',
                    onTap: () => _seed(
                      cubit,
                      min: _bump(state.currentVersion, major: 1),
                      latest: _bump(state.currentVersion, major: 1),
                      store: _storeCtrl.text,
                    ),
                  ),
                  _Divider(),
                  _ActionTile(
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFFFFA726),
                    label: 'Soft prompt available',
                    description:
                        'latest = current+0.1.0 → triggers banner / sheet',
                    onTap: () => _seed(
                      cubit,
                      min: '',
                      latest: _bump(state.currentVersion, minor: 1),
                      store: _storeCtrl.text,
                    ),
                  ),
                  _Divider(),
                  _ActionTile(
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF66BB6A),
                    label: 'Up-to-date',
                    description: 'Clear min + latest → no UI shown',
                    onTap: () => _seed(
                      cubit,
                      min: '',
                      latest: '',
                      store: _storeCtrl.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              title: 'Manual seed',
              icon: Icons.edit_rounded,
              child: Column(
                children: [
                  _Field(
                    label: 'minVersion',
                    controller: _minCtrl,
                    hint: 'e.g. 2.0.0',
                  ),
                  const SizedBox(height: 8),
                  _Field(
                    label: 'latestVersion',
                    controller: _latestCtrl,
                    hint: 'e.g. 2.1.0',
                  ),
                  const SizedBox(height: 8),
                  _Field(
                    label: 'storeUrl',
                    controller: _storeCtrl,
                    hint: 'https://…',
                  ),
                  const SizedBox(height: 10),
                  _ApplyButton(
                    onTap: () => _seed(
                      cubit,
                      min: _minCtrl.text.trim(),
                      latest: _latestCtrl.text.trim(),
                      store: _storeCtrl.text.trim(),
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Dismissals',
              icon: Icons.cleaning_services_rounded,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.layers_clear_rounded,
                    color: DebugOverlayTheme.accent,
                    label: 'Clear skipped + remind-later',
                    description:
                        state.skippedVersions.isEmpty &&
                            state.remindLaterUntil == null
                        ? 'Nothing dismissed right now'
                        : '${state.skippedVersions.length} skipped · remind-later ${state.remindLaterUntil == null ? 'off' : 'armed'}',
                    onTap: () {
                      cubit.clearDismissals();
                      GlobalToast.info(
                        'Dismissals cleared',
                        description: 'Soft prompt re-armed',
                      );
                    },
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Details',
              icon: Icons.info_outline_rounded,
              child: _CurrentState(state: state),
            ),
          ],
        );
      },
    );
  }

  void _seed(
    UpdateCubit cubit, {
    required String min,
    required String latest,
    required String store,
  }) {
    cubit.seedFromSources(
      currentVersion: cubit.state.currentVersion,
      minVersion: min,
      latestVersion: latest,
      storeUrl: store,
    );
    setState(() {
      _minCtrl.text = min;
      _latestCtrl.text = latest;
    });
    GlobalToast.info(
      'Seeded → ${cubit.state.requirement.name}',
      description:
          'min ${min.isEmpty ? '—' : min} · latest ${latest.isEmpty ? '—' : latest}',
    );
  }

  /// Naive semver bump for the presets — strips any `+build` suffix,
  /// adds [major]/[minor]/[patch] to the matching component, leaves the
  /// rest at zero. Output is always a clean `X.Y.Z`. Falls back to
  /// "1.0.0" when the input doesn't parse.
  static String _bump(
    String version, {
    int major = 0,
    int minor = 0,
    int patch = 0,
  }) {
    final stripped = version.split('+').first;
    final parts = stripped.split('.');
    int parse(int i) {
      if (i >= parts.length) return 0;
      return int.tryParse(parts[i]) ?? 0;
    }

    final ma = parse(0) + major;
    final mi = (major > 0) ? 0 : parse(1) + minor;
    final pa = (major > 0 || minor > 0) ? 0 : parse(2) + patch;
    if (parts.isEmpty || stripped.isEmpty) return '1.0.0';
    return '$ma.$mi.$pa';
  }
}

// ─────────────────────────────────────────────────────────────
// Hero + section + state read-out
// ─────────────────────────────────────────────────────────────

/// The gate's verdict at a glance — colored requirement + version line.
class _RequirementHero extends StatelessWidget {
  const _RequirementHero({required this.state});
  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (state.requirement) {
      UpdateRequirement.required => (
        const Color(0xFFEF5350),
        Icons.gpp_bad_rounded,
        'HARD REQUIRED',
      ),
      UpdateRequirement.available => (
        const Color(0xFFFFA726),
        Icons.notifications_active_rounded,
        'SOFT AVAILABLE',
      ),
      UpdateRequirement.upToDate => (
        const Color(0xFF66BB6A),
        Icons.check_circle_rounded,
        'UP TO DATE',
      ),
      UpdateRequirement.unknown => (
        DebugOverlayTheme.textDim,
        Icons.help_outline_rounded,
        'UNKNOWN',
      ),
    };
    String v(String s) => s.isEmpty ? '—' : s;
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
                  'current ${v(state.currentVersion)} · min ${v(state.minVersion)} · latest ${v(state.latestVersion)}',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10.5,
                    color: DebugOverlayTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Accent-filled apply — the app-theme FilledButton bled the app accent.
class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.black.withValues(alpha: 0.15),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.send_rounded, size: 14, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                'Apply seed',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
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

class _CurrentState extends StatelessWidget {
  const _CurrentState({required this.state});
  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _KvRow(label: 'requirement', value: state.requirement.name),
        _KvRow(label: 'currentVersion', value: _orDash(state.currentVersion)),
        _KvRow(label: 'minVersion', value: _orDash(state.minVersion)),
        _KvRow(label: 'latestVersion', value: _orDash(state.latestVersion)),
        _KvRow(label: 'storeUrl', value: _orDash(state.storeUrl)),
        _KvRow(
          label: 'skippedVersions',
          value: state.skippedVersions.isEmpty
              ? '<none>'
              : state.skippedVersions.join(', '),
        ),
        _KvRow(
          label: 'remindLaterUntil',
          value: state.remindLaterUntil?.toIso8601String() ?? '<none>',
        ),
      ],
    );
  }

  static String _orDash(String s) => s.isEmpty ? '<unset>' : s;
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 11,
              color: DebugOverlayTheme.textDim,
            ),
          ),
        ),
        Expanded(
          // Shared console field — also ends the 6px-vs-8px radius
          // drift against the maintenance sim's twin rows.
          child: DebugTextField(
            controller: controller,
            hint: hint,
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
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
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: DebugOverlayTheme.border.withValues(alpha: 0.4),
    );
  }
}
