import 'package:flutter/material.dart';

import '../../../../core/flavor/flavor_config.dart';
import '../../../../core/security/build_lock/build_lock_gate.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';

/// Build-lock control: the bypass switch, the gate's live status for
/// THIS flavor/device, and a forget-unlock action so the real gate can
/// be re-tested without the lock screen's secret gesture.
class DebugBuildLockBypassView extends StatefulWidget {
  const DebugBuildLockBypassView({super.key});

  @override
  State<DebugBuildLockBypassView> createState() =>
      _DebugBuildLockBypassViewState();
}

class _DebugBuildLockBypassViewState extends State<DebugBuildLockBypassView> {
  final _gate = BuildLockGate();
  bool? _unlocked;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final unlocked = await _gate.isUnlocked();
    if (mounted) setState(() => _unlocked = unlocked);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = FlavorConfig.maybeInstance;
    final flavor = cfg?.flavor;
    final required_ = _gate.isRequired;
    final configured =
        (cfg?.buildLockHash.isNotEmpty ?? false) &&
        (cfg?.buildLockSalt.isNotEmpty ?? false);
    return ValueListenableBuilder<bool>(
      valueListenable: DebugOverlayPrefs.buildLockBypass,
      builder: (_, on, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            if (on) const _ActiveBanner(),
            if (!required_) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: DebugOverlayTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DebugOverlayTheme.border),
                ),
                child: Text(
                  'The ${flavor?.name.toUpperCase() ?? 'current'} flavor '
                  'has no build lock — this toggle has no effect here. '
                  'It applies to staging/uat builds.',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10.5,
                    color: DebugOverlayTheme.textDim,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            // Hero switch tile.
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: DebugOverlayTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: on
                      ? const Color(0xFFE57373).withValues(alpha: 0.5)
                      : DebugOverlayTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          (on
                                  ? const Color(0xFFE57373)
                                  : DebugOverlayTheme.textDimmer)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      on ? Icons.lock_open_rounded : Icons.lock_rounded,
                      size: 16,
                      color: on
                          ? const Color(0xFFE57373)
                          : DebugOverlayTheme.textDim,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bypass build lock',
                          style: DebugOverlayTheme.ui.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Skips the staging/uat password gate so the dev '
                          'can iterate without retyping every restart.',
                          style: DebugOverlayTheme.ui.copyWith(
                            fontSize: 10.5,
                            color: DebugOverlayTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: on,
                    onChanged: DebugOverlayPrefs.setBuildLockBypass,
                    activeThumbColor: DebugOverlayTheme.accent,
                    activeTrackColor: DebugOverlayTheme.accent.withValues(
                      alpha: 0.4,
                    ),
                    inactiveThumbColor: DebugOverlayTheme.textDim,
                    inactiveTrackColor: DebugOverlayTheme.surfaceHigh,
                    trackOutlineColor: const WidgetStatePropertyAll(
                      DebugOverlayTheme.border,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Gate status.
            Row(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  size: 13,
                  color: DebugOverlayTheme.textDim,
                ),
                const SizedBox(width: 6),
                Text(
                  'GATE STATUS',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DebugOverlayTheme.textDim,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                GlobalIconButton(
                  tooltip: 'Refresh',
                  enforceMinTouchTarget: false,
                  iconData: Icons.refresh_rounded,
                  onPressed: _refresh,
                  iconSize: 14,
                  style: const ButtonStateStyle(
                    width: 28,
                    height: 28,
                    foregroundColor: DebugOverlayTheme.textDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: DebugOverlayTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DebugOverlayTheme.border),
              ),
              child: Column(
                children: [
                  _StatusRow(
                    label: 'flavor',
                    value: flavor?.name ?? '—',
                    good: null,
                  ),
                  _divider(),
                  _StatusRow(
                    label: 'lock required',
                    value: required_ ? 'yes' : 'no',
                    good: null,
                  ),
                  _divider(),
                  _StatusRow(
                    label: 'hash + salt configured',
                    value: configured ? 'yes' : 'no',
                    good: !required_ || configured,
                  ),
                  _divider(),
                  _StatusRow(
                    label: 'device unlocked',
                    value: _unlocked == null
                        ? '…'
                        : (_unlocked! ? 'yes (token stored)' : 'no'),
                    good: null,
                  ),
                ],
              ),
            ),
            if (required_ && !configured) ...[
              const SizedBox(height: 6),
              Text(
                'Required but unconfigured — the gate FAILS OPEN '
                '(bootstrap logs a warning). Set the hash/salt per '
                'docs/setup before shipping to QA.',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10,
                  color: const Color(0xFFFFA726),
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Forget-unlock action.
            Material(
              color: DebugOverlayTheme.surface,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () async {
                  await _gate.reset();
                  await _refresh();
                  GlobalToast.info(
                    'Unlock token wiped',
                    description:
                        'The lock screen shows on next launch (bypass off)',
                  );
                },
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
                          color: const Color(
                            0xFFFFA726,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.key_off_rounded,
                          size: 14,
                          color: Color(0xFFFFA726),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Forget device unlock',
                              style: DebugOverlayTheme.ui.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Wipes the stored token — re-test the real '
                              'password gate without the lock-screen gesture',
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
          ],
        );
      },
    );
  }

  static Widget _divider() => Container(
    height: 1,
    color: DebugOverlayTheme.border.withValues(alpha: 0.5),
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.good,
  });

  final String label;
  final String value;

  /// null = neutral; false tints the value amber (attention).
  final bool? good;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 11,
                color: DebugOverlayTheme.textDim,
              ),
            ),
          ),
          Text(
            value,
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: good == false
                  ? const Color(0xFFFFA726)
                  : DebugOverlayTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE57373);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Build lock bypassed',
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
