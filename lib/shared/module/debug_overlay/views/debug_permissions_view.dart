import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, MethodChannel;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';

/// Snapshot of every permission the app cares about. Tap **Request** to
/// fire the OS prompt, or **Settings** once permanently denied (a
/// blocked permission can only be flipped there — the OS won't re-prompt).
/// Skips on web (no permissions API).
class DebugPermissionsView extends StatefulWidget {
  const DebugPermissionsView({super.key});

  @override
  State<DebugPermissionsView> createState() => _DebugPermissionsViewState();
}

class _DebugPermissionsViewState extends State<DebugPermissionsView>
    with WidgetsBindingObserver {
  static const _watched = <(Permission, String, IconData)>[
    (Permission.camera, 'Camera', Icons.photo_camera_rounded),
    (Permission.microphone, 'Microphone', Icons.mic_rounded),
    (
      Permission.locationWhenInUse,
      'Location (in use)',
      Icons.location_on_rounded,
    ),
    (
      Permission.locationAlways,
      'Location (always)',
      Icons.share_location_rounded,
    ),
    (Permission.notification, 'Notifications', Icons.notifications_rounded),
    (Permission.photos, 'Photos', Icons.photo_library_rounded),
    (Permission.contacts, 'Contacts', Icons.contacts_rounded),
    (Permission.bluetooth, 'Bluetooth', Icons.bluetooth_rounded),
  ];

  Map<Permission, PermissionStatus> _statuses = {};
  bool _loading = true;
  String _packageName = '<bundle-id>';

  /// True right after `Settings` was opened — the next app-resume
  /// re-checks statuses. `openAppSettings()` itself resolves the
  /// instant Settings LAUNCHES, not when the user comes back, so a
  /// refresh immediately after it is always stale; this flag defers
  /// the real refresh to `didChangeAppLifecycleState`.
  bool _awaitingSettingsReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageName = info.packageName);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingSettingsReturn) {
      _awaitingSettingsReturn = false;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (kIsWeb) {
      setState(() {
        _statuses = {};
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final next = <Permission, PermissionStatus>{};
    for (final t in _watched) {
      try {
        next[t.$1] = await t.$1.status;
      } catch (_) {
        // Some permissions throw on platforms that don't support them
        // (e.g. iOS reverse-geocoding-only flags). Treat as unknown.
        next[t.$1] = PermissionStatus.denied;
      }
    }
    if (!mounted) return;
    setState(() {
      _statuses = next;
      _loading = false;
    });
  }

  Future<void> _request(Permission p) async {
    await p.request();
    await _refresh();
  }

  Future<void> _openSettings() async {
    _awaitingSettingsReturn = true;
    await openAppSettings();
  }

  static const _limitedPickerChannel = MethodChannel(
    'terracotta/limited_photo_picker',
  );

  /// Limited photos on iOS re-presents the system selection sheet
  /// in-app (the one permission UI iOS allows an app to re-open).
  /// Android 14 partial access re-prompts through a plain request();
  /// anything else falls back to Settings.
  Future<void> _adjustLimited(Permission p) async {
    if (defaultTargetPlatform == TargetPlatform.iOS && p == Permission.photos) {
      try {
        final shown = await _limitedPickerChannel.invokeMethod<bool>(
          'presentLimitedLibraryPicker',
        );
        if (shown ?? false) {
          // The sheet has no completion callback surfaced here — statuses
          // can't change (still limited), but the selection can; nothing
          // to refresh.
          return;
        }
      } catch (_) {
        // Channel missing (hot restart before native rebuild) — fall through.
      }
      await _openSettings();
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _request(p);
      return;
    }
    await _openSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Center(
        child: Text(
          'Permissions inspection skipped on web.',
          style: DebugOverlayTheme.ui.copyWith(
            color: DebugOverlayTheme.textDimmer,
          ),
        ),
      );
    }
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DebugOverlayTheme.accent,
          ),
        ),
      );
    }

    final (granted, partial, denied) = _counts();
    return Column(
      children: [
        // Summary strip — stat chips + refresh, no card chrome: this
        // page is one list, so rows stand on their own tiles below.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
          child: Row(
            children: [
              _StatChip(
                count: granted,
                label: 'granted',
                color: const Color(0xFF66BB6A),
              ),
              const SizedBox(width: 6),
              _StatChip(
                count: partial,
                label: 'partial',
                color: const Color(0xFF4FC3F7),
              ),
              const SizedBox(width: 6),
              _StatChip(
                count: denied,
                label: 'denied',
                color: const Color(0xFFFFA726),
              ),
              const Spacer(),
              GlobalIconButton(
                enforceMinTouchTarget: false,
                tooltip: 'Re-check statuses',
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
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: _watched.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              if (i == _watched.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _ResetPromptsNote(packageName: _packageName),
                );
              }
              return _Row(
                icon: _watched[i].$3,
                label: _watched[i].$2,
                status: _statuses[_watched[i].$1] ?? PermissionStatus.denied,
                onRequest: () => _request(_watched[i].$1),
                onOpenSettings: _openSettings,
                onAdjust: () => _adjustLimited(_watched[i].$1),
              );
            },
          ),
        ),
      ],
    );
  }

  (int, int, int) _counts() {
    var granted = 0, partial = 0, denied = 0;
    for (final t in _watched) {
      final s = _statuses[t.$1] ?? PermissionStatus.denied;
      if (s.isGranted) {
        granted++;
      } else if (s.isLimited || s.isProvisional) {
        partial++;
      } else {
        denied++;
      }
    }
    return (granted, partial, denied);
  }
}

/// `N label` count chip for the summary strip. Dims to outline-only
/// when the count is zero so live categories pop.
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    final c = active ? color : DebugOverlayTheme.textDimmer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$count $label',
        style: DebugOverlayTheme.mono.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.status,
    required this.onRequest,
    required this.onOpenSettings,
    required this.onAdjust,
  });

  final IconData icon;
  final String label;
  final PermissionStatus status;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  /// Limited/provisional action — re-presents the system selection UI
  /// where the platform allows it (iOS limited photos), else Settings.
  final VoidCallback onAdjust;

  /// Whether a not-yet-decided permission can still be asked for
  /// in-app. `false` → the OS won't re-prompt; only Settings can flip it.
  bool get _canRequest =>
      status.isDenied && !status.isPermanentlyDenied && !status.isRestricted;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _statusLabel(status),
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (_canRequest) ...[
                const SizedBox(width: 8),
                _ActionButton(label: 'Request', onTap: onRequest),
              ] else if (status.isPermanentlyDenied) ...[
                const SizedBox(width: 8),
                _ActionButton(label: 'Settings', onTap: onOpenSettings),
              ] else if (status.isLimited || status.isProvisional) ...[
                const SizedBox(width: 8),
                _ActionButton(label: 'Adjust', onTap: onAdjust),
              ] else if (status.isGranted) ...[
                const SizedBox(width: 8),
                // No OS lets an app revoke its own grant programmatically —
                // Settings is the only truthful path; the lifecycle refresh
                // picks the change up on return.
                _ActionButton(label: 'Revoke', onTap: onOpenSettings),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Full-width hint under the header row — beside the label it
          // truncated behind the pill + action button.
          Text(
            _statusHint(status),
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 10.5,
              color: DebugOverlayTheme.textDim,
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(PermissionStatus s) {
    if (s.isGranted) return 'GRANTED';
    if (s.isLimited) return 'PARTIAL';
    if (s.isProvisional) return 'PARTIAL';
    if (s.isPermanentlyDenied) return 'BLOCKED';
    if (s.isRestricted) return 'RESTRICTED';
    if (s.isDenied) return 'DENIED';
    return s.toString().split('.').last.toUpperCase();
  }

  /// One-line meaning + next step for each state.
  static String _statusHint(PermissionStatus s) {
    if (s.isGranted) return 'Full access — Revoke opens Settings';
    if (s.isLimited) return 'Some items only — Adjust re-opens the selection';
    if (s.isProvisional) return 'Quiet delivery — Adjust to upgrade';
    if (s.isPermanentlyDenied) {
      return 'OS won\'t re-prompt — enable in Settings';
    }
    if (s.isRestricted) return 'Blocked by device policy (parental/MDM)';
    return 'Not granted — Request shows the OS prompt';
  }

  static Color _statusColor(PermissionStatus s) {
    if (s.isGranted) return const Color(0xFF66BB6A);
    // Partial access is real access, but NOT full — a distinct hue from
    // full-grant green so "some but not all" reads at a glance instead
    // of blending in as if everything were fully allowed.
    if (s.isLimited || s.isProvisional) return const Color(0xFF4FC3F7);
    if (s.isPermanentlyDenied) return const Color(0xFFEF5350);
    if (s.isRestricted) return const Color(0xFFAB47BC);
    return const Color(0xFFFFA726);
  }
}

/// Compact bordered text action — Request / Settings / Review.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dev footnote: BLOCKED is final for `request()` on both platforms —
/// but prompt state CAN be reset for testing without reinstalling.
/// Copyable commands, package name filled in live.
class _ResetPromptsNote extends StatelessWidget {
  const _ResetPromptsNote({required this.packageName});

  final String packageName;

  void _copy(String cmd) {
    Clipboard.setData(ClipboardData(text: cmd));
    GlobalToast.success('Command copied');
  }

  @override
  Widget build(BuildContext context) {
    final ios = 'xcrun simctl privacy booted reset all $packageName';
    final android =
        'adb shell pm revoke $packageName android.permission.CAMERA';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: DebugOverlayTheme.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DebugOverlayTheme.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restart_alt_rounded,
                size: 14,
                color: DebugOverlayTheme.accent,
              ),
              const SizedBox(width: 6),
              Text(
                'RESET PROMPTS (TESTING)',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: DebugOverlayTheme.accent,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'BLOCKED is final for request() — the OS never re-prompts. '
            'For testing, reset the prompt state instead of reinstalling:',
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 10.5,
              color: DebugOverlayTheme.textDim,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          _CmdRow(
            label: 'iOS Simulator',
            command: ios,
            onCopy: () => _copy(ios),
          ),
          const SizedBox(height: 6),
          _CmdRow(
            label: 'Android (per permission)',
            command: android,
            onCopy: () => _copy(android),
          ),
          const SizedBox(height: 6),
          Text(
            'Physical iPhone: no command — reinstall the app.',
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 10,
              color: DebugOverlayTheme.textDimmer,
            ),
          ),
        ],
      ),
    );
  }
}

class _CmdRow extends StatelessWidget {
  const _CmdRow({
    required this.label,
    required this.command,
    required this.onCopy,
  });

  final String label;
  final String command;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DebugOverlayTheme.ui.copyWith(
            fontSize: 9.5,
            color: DebugOverlayTheme.textDimmer,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: DebugOverlayTheme.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DebugOverlayTheme.border),
                ),
                child: Text(
                  command,
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 10,
                    color: DebugOverlayTheme.textDim,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onCopy,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: DebugOverlayTheme.textDim,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
