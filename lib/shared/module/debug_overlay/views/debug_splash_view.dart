import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/splash/splash_redirect.dart';
import '../../../../data/services/navigation_service.dart';
import '../../toast/global_toast.dart';
import '../global_debug_overlay.dart';

/// Dev panel for the splash gate. Replay the splash instantly (closes
/// this window), or force the orchestrator into hold/skip for the
/// session — debug/profile only, release reads `auto` regardless.
class DebugSplashView extends StatelessWidget {
  const DebugSplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SplashDevOverride>(
      valueListenable: SplashRedirect.devOverride,
      builder: (_, override, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            _ReplayButton(onTap: () => _replayNow(context)),
            const SizedBox(height: 6),
            Text(
              'Tip: set Force hold first to park on the splash while '
              'iterating on the hero.',
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 10,
                color: DebugOverlayTheme.textDimmer,
              ),
            ),
            const SizedBox(height: 14),
            _FlatSection(
              title: 'Runtime override — this session only',
              icon: Icons.bolt_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Segmented<SplashDevOverride>(
                    values: SplashDevOverride.values,
                    current: override,
                    labelOf: (o) => o.label,
                    onSelect: (o) => SplashRedirect.devOverride.value = o,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${override.description}. Iterate on the splash hero '
                    'without touching persisted state; release builds '
                    'ignore this.',
                    style: DebugOverlayTheme.ui.copyWith(
                      fontSize: 10.5,
                      color: DebugOverlayTheme.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static void _replayNow(BuildContext context) {
    if (!getIt.isRegistered<NavigationService>()) {
      GlobalToast.error('NavigationService unregistered');
      return;
    }
    DebugOverlayController.closeWindow();
    // go (not push): splash is the root route and re-runs its redirect
    // flow from the top of the stack.
    getIt<NavigationService>().router.go('/');
  }
}

// ─────────────────────────────────────────────────────────────

class _ReplayButton extends StatelessWidget {
  const _ReplayButton({required this.onTap});
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
          height: 38,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                size: 16,
                color: Colors.black,
              ),
              const SizedBox(width: 6),
              Text(
                'Replay splash now',
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
    return Column(
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
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.current,
    required this.labelOf,
    required this.onSelect,
  });

  final List<T> values;
  final T current;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;

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
          for (final v in values)
            Expanded(
              child: Material(
                color: v == current
                    ? accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => onSelect(v),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 30,
                    alignment: Alignment.center,
                    child: Text(
                      labelOf(v),
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: v == current
                            ? accent
                            : DebugOverlayTheme.textDim,
                      ),
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
