import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/onboarding/onboarding_redirect.dart';
import '../../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../../data/blocs/preferences/preferences_state.dart';
import '../../../../data/services/navigation_service.dart';
import '../../toast/global_toast.dart';
import '../global_debug_overlay.dart';

/// Dev panel for the onboarding gate. Three controls:
///
/// 1. **Replay now** — navigates straight into the onboarding flow and
///    closes this window, no restart round-trip.
/// 2. **Runtime override** — [OnboardingRedirect.devOverride] flips the
///    splash gate for THIS SESSION without touching persisted state.
/// 3. **Persisted flag** — `seenOnboarding` (HydratedBloc, survives
///    app kill) for real next-launch behaviour.
///
/// The outcome pill above them derives the NET effect of both knobs so
/// their interaction is never a guess.
class DebugOnboardingResetView extends StatelessWidget {
  const DebugOnboardingResetView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, state) {
        final cubit = context.read<PreferencesCubit>();
        final seen = state.seenOnboarding;
        return ValueListenableBuilder<OnboardingDevOverride>(
          valueListenable: OnboardingRedirect.devOverride,
          builder: (_, override, _) {
            final willShow = switch (override) {
              OnboardingDevOverride.forceShow => true,
              OnboardingDevOverride.forceSkip => false,
              OnboardingDevOverride.auto => !seen,
            };
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
              children: [
                _OutcomePill(
                  willShow: willShow,
                  reason: switch (override) {
                    OnboardingDevOverride.auto => 'from persisted flag',
                    _ => 'override active',
                  },
                ),
                const SizedBox(height: 12),
                _ReplayButton(onTap: () => _replayNow(context)),
                const SizedBox(height: 16),
                _FlatSection(
                  title: 'Runtime override — this session only',
                  icon: Icons.bolt_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Segmented<OnboardingDevOverride>(
                        values: OnboardingDevOverride.values,
                        current: override,
                        labelOf: (o) => o.label,
                        onSelect: (o) =>
                            OnboardingRedirect.devOverride.value = o,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${override.description}. Persisted state is left '
                        'alone — back to Auto restores the real flow.',
                        style: DebugOverlayTheme.ui.copyWith(
                          fontSize: 10.5,
                          color: DebugOverlayTheme.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                _FlatSection(
                  title: 'Persisted flag — survives app kill',
                  icon: Icons.save_rounded,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: DebugOverlayTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DebugOverlayTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          seen
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: seen
                              ? const Color(0xFF66BB6A)
                              : DebugOverlayTheme.textDim,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'seenOnboarding = $seen',
                            style: DebugOverlayTheme.mono.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _ActionButton(
                          label: seen ? 'Mark unseen' : 'Mark seen',
                          onTap: () {
                            if (seen) {
                              cubit.markOnboardingUnseen();
                              GlobalToast.success(
                                'Onboarding reset',
                                description: 'Will replay on next launch',
                              );
                            } else {
                              cubit.markOnboardingSeen();
                              GlobalToast.success('Onboarding marked seen');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
    getIt<NavigationService>().push('/onboarding');
  }
}

// ─────────────────────────────────────────────────────────────

/// Net effect of both knobs — what the gate will actually do.
class _OutcomePill extends StatelessWidget {
  const _OutcomePill({required this.willShow, required this.reason});

  final bool willShow;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final color = willShow ? DebugOverlayTheme.accent : const Color(0xFF66BB6A);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            willShow ? Icons.slideshow_rounded : Icons.skip_next_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Next launch: '),
                  TextSpan(
                    text: willShow ? 'SHOWS onboarding' : 'SKIPS onboarding',
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  TextSpan(text: ' ($reason)'),
                ],
              ),
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 11.5,
                color: DebugOverlayTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accent-filled primary action — jump into the flow right now.
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
                'Replay onboarding now',
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: DebugOverlayTheme.textDim),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DebugOverlayTheme.textDim,
                    letterSpacing: 0.8,
                  ),
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
