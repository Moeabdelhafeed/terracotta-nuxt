import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/connectivity/connectivity_config.dart';
import '../../../core/connectivity/connectivity_cubit.dart';
import '../../../core/connectivity/connectivity_state.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/connectivity_strings.dart';

/// Persistent strip surfaced above the rest of the app whenever
/// connectivity is degraded or a transition needs acknowledgement.
///
/// Banner is part of the page layout — pushes [child] down rather
/// than floating over it — and its background color extends edge-to-
/// edge so the status-bar tint matches the strip. The status-bar
/// icon brightness is overridden via [AnnotatedRegion] for legibility
/// against the strip's background.
///
/// Mount once near the root in `MaterialApp.builder`, between
/// `BuildLockGuard` and the rest of the tree (so the maintenance
/// gate still wins for outages).
///
/// Decision matrix:
/// | State                                      | Banner shown                  |
/// |--------------------------------------------|-------------------------------|
/// | Boot grace (`<bootGracePeriod`)            | Hidden                        |
/// | unknown                                    | Hidden                        |
/// | online + no VPN                            | Hidden                        |
/// | online + VPN + policy=allow                | Hidden                        |
/// | online + VPN + policy=warn                 | Soft VPN warning              |
/// | online + VPN + policy=block                | (verdict collapses to offline) |
/// | offline                                    | Offline strip + retry         |
/// | probeUntrusted                             | Hidden (treat as online)      |
/// | justRecovered (transient)                  | Success "Back online"         |
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  /// Drives both the banner's slot height (via [SizeTransition]) AND
  /// the body's MediaQuery padding lerp, so the AppBar's status-bar
  /// inset shrinks at the same rate the banner grows. Result: column
  /// total height stays constant during the transition — no flash, no
  /// sudden gap.
  late final AnimationController _ctrl;

  /// Different curves for forward vs reverse so the entry feels gentle
  /// (banner eases in, content settles) and the exit feels decisive
  /// (banner snaps shut, content jumps back). Linear feels sluggish on
  /// reverse — content drifts back instead of snapping.
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _curve = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _sync(_BannerStrip? banner) {
    final shouldShow = banner != null;
    if (shouldShow && _ctrl.status != AnimationStatus.completed) {
      _ctrl.forward();
    } else if (!shouldShow && _ctrl.status != AnimationStatus.dismissed) {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        final cubit = context.read<ConnectivityCubit>();
        final policy = cubit.config.vpnPolicy;
        final banner = _resolveBanner(
          state,
          policy,
          inBootGrace: cubit.withinBootGrace,
        );
        // Drive controller from build — safe because forward/reverse
        // are no-ops when already in target state.
        WidgetsBinding.instance.addPostFrameCallback((_) => _sync(banner));

        final mq = MediaQuery.of(context);
        final originalTop = mq.padding.top;
        final originalViewTop = mq.viewPadding.top;

        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: AnimatedBuilder(
            animation: _curve,
            builder: (_, _) {
              final t = _curve.value;
              // Padding shrinks as the banner grows. lerp(orig, 0, t).
              final paddedBody = MediaQuery(
                data: mq.copyWith(
                  padding: mq.padding.copyWith(top: originalTop * (1 - t)),
                  viewPadding: mq.viewPadding.copyWith(
                    top: originalViewTop * (1 - t),
                  ),
                ),
                child: widget.child,
              );

              return Column(
                children: [
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: t.clamp(0.0, 1.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (w, anim) =>
                            FadeTransition(opacity: anim, child: w),
                        child: banner == null
                            ? const SizedBox(width: double.infinity, height: 0)
                            : KeyedSubtree(
                                key: ValueKey(banner.kind),
                                child: banner,
                              ),
                      ),
                    ),
                  ),
                  Expanded(child: paddedBody),
                ],
              );
            },
          ),
        );
      },
    );
  }

  _BannerStrip? _resolveBanner(
    ConnectivityState s,
    VpnPolicy policy, {
    required bool inBootGrace,
  }) {
    if (s.verdict == ConnectivityVerdict.unknown) return null;

    if (s.justRecovered) {
      // Suppress the "Back online" toast during boot grace — on cold
      // start connectivity_plus often emits `[none]` before the real
      // `[wifi]` event, which trips the recovery flag for the very
      // first transition. Banner stays hidden until the real signal.
      if (inBootGrace) return null;
      return const _BannerStrip(kind: _BannerKind.recovered);
    }

    if (s.verdict == ConnectivityVerdict.offline) {
      // Suppress the offline strip during the cubit's boot grace
      // period — connectivity_plus often emits `none` on cold start
      // before the first probe lands, and we don't want a transient
      // flicker before reality is known.
      if (inBootGrace) return null;
      // VPN blocking promoted offline state — show the VPN-block strip
      // instead of the generic offline one when VPN is the cause.
      if (s.vpnDetected && policy == VpnPolicy.block) {
        return const _BannerStrip(kind: _BannerKind.vpnBlock);
      }
      return _BannerStrip(
        kind: _BannerKind.offline,
        queuedActions: s.queuedActions,
      );
    }

    // Online — only thing left is VPN warn.
    if (s.vpnDetected && policy == VpnPolicy.warn) {
      if (inBootGrace) return null;
      return const _BannerStrip(kind: _BannerKind.vpnWarn);
    }

    return null;
  }
}

// ─────────────────────────────────────────────────────────────

enum _BannerKind { offline, recovered, vpnWarn, vpnBlock }

/// Constant content height across every kind so the column doesn't
/// jump when the banner kind changes. Retry button is sized to fit
/// inside this without inflating it.
const double _kBannerContentHeight = 32;

class _BannerStrip extends StatelessWidget {
  const _BannerStrip({
    required this.kind,
    this.queuedActions = 0,
  });

  final _BannerKind kind;
  final int queuedActions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<ConnectivityCubit>();

    final palette = switch (kind) {
      _BannerKind.offline => _Palette(
        background: _bgFor(_Tone.warning, isDark),
        icon: Icons.cloud_off_rounded,
        label: queuedActions > 0
            ? ConnectivityStrings.offlineQueued(queuedActions)
            : ConnectivityStrings.offline,
        showRetry: true,
      ),
      _BannerKind.recovered => _Palette(
        background: _bgFor(_Tone.success, isDark),
        icon: Icons.cloud_done_rounded,
        label: ConnectivityStrings.backOnline,
        showRetry: false,
      ),
      _BannerKind.vpnWarn => _Palette(
        background: _bgFor(_Tone.warning, isDark),
        icon: Icons.vpn_lock_rounded,
        label: ConnectivityStrings.vpnWarning,
        showRetry: false,
      ),
      _BannerKind.vpnBlock => _Palette(
        background: _bgFor(_Tone.error, isDark),
        icon: Icons.vpn_lock_rounded,
        label: ConnectivityStrings.vpnBlocked,
        showRetry: false,
      ),
    };

    final fg = _readableForeground(palette.background);

    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: fg == Colors.white
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: fg == Colors.white
          ? Brightness.dark
          : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Material(
        color: palette.background,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: SizedBox(
              height: _kBannerContentHeight,
              child: Row(
                children: [
                  Icon(palette.icon, size: 18, color: fg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      palette.label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (palette.showRetry)
                    InkWell(
                      onTap: () => cubit.reprobe(),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          CommonStrings.retry,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pick black/white text based on perceived luminance. Avoids
  /// hard-coded white-on-yellow / black-on-red issues across themes.
  Color _readableForeground(Color bg) {
    final l = bg.computeLuminance();
    return l > 0.55 ? const Color(0xFF1F2937) : Colors.white;
  }
}

// ─────────────────────────────────────────────────────────────
// Theme-aware palette
// ─────────────────────────────────────────────────────────────

enum _Tone { success, warning, error }

/// Light variants are bright + saturated to draw attention; dark
/// variants are muted so they don't blowtorch the eyes against a dark
/// theme. Foreground stays readable in both via luminance check.
Color _bgFor(_Tone tone, bool isDark) {
  if (isDark) {
    return switch (tone) {
      _Tone.success => const Color(0xFF1B5E20),
      _Tone.warning => const Color(0xFF6D4C00),
      _Tone.error => const Color(0xFF7F1D1D),
    };
  }
  return switch (tone) {
    _Tone.success => const Color(0xFF66BB6A),
    _Tone.warning => const Color(0xFFFFA726),
    _Tone.error => const Color(0xFFEF5350),
  };
}

class _Palette {
  const _Palette({
    required this.background,
    required this.icon,
    required this.label,
    required this.showRetry,
  });
  final Color background;
  final IconData icon;
  final String label;
  final bool showRetry;
}
