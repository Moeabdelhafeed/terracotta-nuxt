// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../data/stores/debug_overlay_prefs.dart';
import 'build_lock_gate.dart';
import 'build_lock_screen.dart';

/// Wraps the app and routes through [BuildLockScreen] when the active
/// flavor requires unlocking and no valid token is in secure storage.
///
/// Mount once near the root of the widget tree (inside `MaterialApp`'s
/// builder, above MediaQuery and routing). For prod / dev flavors and
/// for unlocked staging / uat sessions, the [child] renders unchanged.
class BuildLockGuard extends StatefulWidget {
  const BuildLockGuard({required this.child, super.key});

  final Widget child;

  @override
  State<BuildLockGuard> createState() => _BuildLockGuardState();
}

class _BuildLockGuardState extends State<BuildLockGuard> {
  final _gate = BuildLockGate();
  bool? _unlocked;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final unlocked = await _gate.isUnlocked();
    if (!mounted) return;
    setState(() => _unlocked = unlocked);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DebugOverlayPrefs.buildLockBypass,
      builder: (_, bypass, _) {
        // Debug-only escape hatch — flipping the bypass in the
        // overlay turns the guard into a passthrough so the dev can
        // iterate without retyping the password every restart.
        if (bypass) return widget.child;

        if (_unlocked == null) {
          // Brief opaque frame while the gate state resolves —
          // prevents the child from flashing before the lock screen
          // appears.
          return const ColoredBox(
            color: Colors.black,
            child: SizedBox.expand(),
          );
        }
        if (!_unlocked!) {
          return BuildLockScreen(
            gate: _gate,
            onUnlock: () => setState(() => _unlocked = true),
          );
        }
        return widget.child;
      },
    );
  }
}
