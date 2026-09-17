import 'package:flutter/material.dart';

import '../../../../core/bootstrap/bootstrap_maintenance.dart';
import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/connectivity/connectivity_state.dart';
import '../../../../core/devtools/perf_flags.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/tr.dart';
import '../../../../data/services/remote_config_service.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../dev_tool_reset.dart';
import '../dev_tool_status.dart';
import '../widgets/debug_text_field.dart';

/// Named override sets — capture the current sims/overrides as a
/// scenario ("offline QA", "demo mode", "flaky backend") and re-apply
/// the whole set with one tap later. Applying starts from a clean
/// slate ([DevToolReset.resetAll]) so scenarios don't stack.
class DebugScenariosView extends StatefulWidget {
  const DebugScenariosView({super.key});

  @override
  State<DebugScenariosView> createState() => _DebugScenariosViewState();
}

class _DebugScenariosViewState extends State<DebugScenariosView> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Snapshot every override the reset-all path knows how to clear.
  static Map<String, Object?> _captureCurrent(String name) {
    final connectivity = getIt.isRegistered<ConnectivityCubit>()
        ? getIt<ConnectivityCubit>()
        : null;
    return {
      'name': name,
      'savedAt': DateTime.now().toIso8601String(),
      'rc': Map<String, Object?>.from(RemoteConfigService.overrides),
      'netSimLatencyMs': DebugOverlayPrefs.netSimLatencyMs.value,
      'netSimFailEveryN': DebugOverlayPrefs.netSimFailEveryN.value,
      'netSimFailStatus': DebugOverlayPrefs.netSimFailStatus.value,
      'mockMode': DebugOverlayPrefs.mockMode.value,
      'buildLockBypass': DebugOverlayPrefs.buildLockBypass.value,
      'devicePreview': DebugOverlayPrefs.devicePreviewOverride.value,
      'pseudoL10n': Tr.pseudoEnabled,
      'connectivityVerdict': connectivity?.debugVerdictOverride?.name,
      'connectivityVpn': connectivity?.debugVpnOverride,
      'perfSlowAnimations': PerfFlags.slowAnimations.value,
      'perfRepaintRainbow': PerfFlags.repaintRainbow.value,
      'perfLayoutBounds': PerfFlags.layoutBounds.value,
    };
  }

  static Future<void> _apply(Map<String, Object?> s) async {
    await DevToolReset.resetAll();

    final rc = s['rc'];
    if (rc is Map) {
      for (final e in rc.entries) {
        RemoteConfigService.setOverride('${e.key}', e.value);
      }
      if (rc.isNotEmpty) seedMaintenanceFromRemoteConfig();
    }

    DebugOverlayPrefs.setNetSim(
      latencyMs: s['netSimLatencyMs'] as int? ?? 0,
      failEveryN: s['netSimFailEveryN'] as int? ?? 0,
      failStatus: s['netSimFailStatus'] as int? ?? 503,
    );
    DebugOverlayPrefs.setMockMode(s['mockMode'] as bool? ?? false);
    DebugOverlayPrefs.setBuildLockBypass(
      s['buildLockBypass'] as bool? ?? false,
    );
    DebugOverlayPrefs.setDevicePreviewOverride(s['devicePreview'] as bool?);
    Tr.setPseudo(s['pseudoL10n'] as bool? ?? false);

    if (getIt.isRegistered<ConnectivityCubit>()) {
      final cubit = getIt<ConnectivityCubit>();
      final verdict = s['connectivityVerdict'];
      if (verdict is String) {
        cubit.debugForceVerdict(
          ConnectivityVerdict.values.asNameMap()[verdict],
        );
      }
      final vpn = s['connectivityVpn'];
      if (vpn is bool) cubit.debugForceVpn(vpn);
    }

    PerfFlags.setSlowAnimations(s['perfSlowAnimations'] as bool? ?? false);
    PerfFlags.setRepaintRainbow(s['perfRepaintRainbow'] as bool? ?? false);
    PerfFlags.setLayoutBounds(s['perfLayoutBounds'] as bool? ?? false);
  }

  /// Human summary of what a snapshot flips — shown on the tile.
  static String _summarize(Map<String, Object?> s) {
    final parts = <String>[
      if (s['rc'] is Map && (s['rc']! as Map).isNotEmpty)
        '${(s['rc']! as Map).length} RC',
      if ((s['netSimLatencyMs'] as int? ?? 0) > 0 ||
          (s['netSimFailEveryN'] as int? ?? 0) > 0)
        'net sim',
      if (s['mockMode'] == true) 'mock',
      if (s['buildLockBypass'] == true) 'lock bypass',
      if (s['devicePreview'] != null) 'device preview',
      if (s['pseudoL10n'] == true) 'pseudo-l10n',
      if (s['connectivityVerdict'] != null || s['connectivityVpn'] != null)
        'connectivity',
      if (s['perfSlowAnimations'] == true ||
          s['perfRepaintRainbow'] == true ||
          s['perfLayoutBounds'] == true)
        'perf flags',
    ];
    return parts.isEmpty ? 'no overrides (clean slate)' : parts.join(' · ');
  }

  void _saveCurrent() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      GlobalToast.warning('Give the scenario a name first');
      return;
    }
    DebugOverlayPrefs.saveScenario(_captureCurrent(name));
    _nameCtrl.clear();
    FocusScope.of(context).unfocus();
    GlobalToast.info('Scenario "$name" saved');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, Object?>>>(
      valueListenable: DebugOverlayPrefs.scenarios,
      builder: (context, scenarios, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            _Section(
              title: 'Save current state',
              icon: Icons.bookmark_add_rounded,
              caption:
                  'Captures every active override — RC keys, sims, '
                  'perf flags — under one name.',
              child: Row(
                children: [
                  Expanded(
                    child: DebugTextField(
                      controller: _nameCtrl,
                      hint: 'offline QA, demo mode…',
                      showBorder: false,
                      onSubmitted: (_) => _saveCurrent(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: DebugOverlayTheme.accent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _saveCurrent,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontFamily: DebugOverlayTheme.kFont,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Saved scenarios',
              icon: Icons.bookmarks_rounded,
              caption: scenarios.isEmpty
                  ? null
                  : 'Applying resets everything first, then applies the '
                        'set — scenarios never stack.',
              child: scenarios.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DebugOverlayTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DebugOverlayTheme.border),
                      ),
                      child: Text(
                        'Nothing saved yet. Set up your overrides '
                        '(RC, sims, mock…), come back and save them '
                        'under a name.',
                        style: DebugOverlayTheme.ui.copyWith(
                          fontSize: 11,
                          color: DebugOverlayTheme.textDim,
                          height: 1.4,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: DebugOverlayTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DebugOverlayTheme.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < scenarios.length; i++) ...[
                            if (i > 0)
                              Container(
                                height: 1,
                                color: DebugOverlayTheme.border.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            _ScenarioTile(
                              scenario: scenarios[i],
                              summary: _summarize(scenarios[i]),
                              onApply: () async {
                                final name = scenarios[i]['name'];
                                await _apply(scenarios[i]);
                                GlobalToast.info('Scenario "$name" applied');
                              },
                              onOverwrite: () {
                                final name = '${scenarios[i]['name']}';
                                DebugOverlayPrefs.saveScenario(
                                  _captureCurrent(name),
                                );
                                GlobalToast.info(
                                  '"$name" overwritten with current state',
                                );
                              },
                              onDelete: () {
                                DebugOverlayPrefs.deleteScenario(
                                  '${scenarios[i]['name']}',
                                );
                                GlobalToast.info('Scenario deleted');
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            // What applying right now would capture — orientation aid.
            ListenableBuilder(
              listenable: DevToolStatus.listenable,
              builder: (_, _) {
                final active = DevToolStatus.active();
                return Text(
                  active.isEmpty
                      ? 'Currently active: nothing — saving now records a '
                            'clean slate.'
                      : 'Currently active: '
                            '${active.map((t) => t.label).join(', ')}.',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10,
                    color: DebugOverlayTheme.textDimmer,
                    height: 1.4,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.caption,
  });

  final String title;
  final IconData icon;
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

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.scenario,
    required this.summary,
    required this.onApply,
    required this.onOverwrite,
    required this.onDelete,
  });

  final Map<String, Object?> scenario;
  final String summary;
  final VoidCallback onApply;
  final VoidCallback onOverwrite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onApply,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DebugOverlayTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
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
                      '${scenario['name']}',
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      summary,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 10,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              GlobalIconButton(
                tooltip: 'Overwrite with current state',
                enforceMinTouchTarget: false,
                iconData: Icons.save_as_rounded,
                onPressed: onOverwrite,
                iconSize: 14,
                style: const ButtonStateStyle(
                  width: 28,
                  height: 28,
                  foregroundColor: DebugOverlayTheme.textDim,
                ),
              ),
              GlobalIconButton(
                tooltip: 'Delete',
                enforceMinTouchTarget: false,
                iconData: Icons.delete_outline_rounded,
                onPressed: onDelete,
                iconSize: 14,
                style: const ButtonStateStyle(
                  width: 28,
                  height: 28,
                  foregroundColor: DebugOverlayTheme.textDim,
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
