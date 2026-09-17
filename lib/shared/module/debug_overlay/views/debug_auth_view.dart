import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/devtools/network_sim.dart';
import '../../../../data/blocs/auth/auth_bloc.dart';
import '../../../../data/blocs/auth/auth_event.dart';
import '../../../../data/blocs/auth/auth_state.dart';
import '../../../../data/models/auth/user/user.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';

/// Live auth-state read-out + state-machine drivers: fake dev sign-in,
/// pending-token flow, sign-out, and a genuinely one-shot forced 401.
class DebugAuthView extends StatelessWidget {
  const DebugAuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final bloc = context.read<AuthBloc>();
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            _StateHero(state: state),
            const SizedBox(height: 14),
            if (state case AuthPending(temporaryToken: final t))
              _Section(
                title: 'Details',
                icon: Icons.badge_rounded,
                child: _Group(
                  children: [
                    _KvRow('temporaryToken', _mask(t), copyValue: t),
                  ],
                ),
              ),
            if (state case AuthAuthenticated(
              user: final u,
              token: final t,
              fcmToken: final fcm,
            ))
              _Section(
                title: 'Details',
                icon: Icons.badge_rounded,
                child: _Group(
                  children: [
                    _KvRow('user.id', '${u.id}'),
                    _KvRow('user.name', _displayName(u.firstName, u.lastName)),
                    _KvRow('user.email', u.email ?? '<none>'),
                    _KvRow('user.phone', u.phoneNumber ?? '<none>'),
                    _KvRow('token', _mask(t), copyValue: t),
                    _KvRow(
                      'fcmToken',
                      fcm.isEmpty ? '<unset>' : _mask(fcm),
                      copyValue: fcm.isEmpty ? null : fcm,
                    ),
                  ],
                ),
              ),
            _Section(
              title: 'Drive the state machine',
              icon: Icons.tune_rounded,
              child: _Group(
                children: [
                  _Tile(
                    icon: Icons.person_add_rounded,
                    color: const Color(0xFF66BB6A),
                    label: 'Sign in as dev user',
                    description:
                        'Fake AuthEvent.signedIn — test authed-only '
                        'UI without a backend',
                    onTap: state is AuthAuthenticated
                        ? null
                        : () {
                            bloc.add(
                              AuthEvent.signedIn(
                                user: const User(
                                  id: 0,
                                  firstName: 'Dev',
                                  lastName: 'User',
                                  email: 'dev@example.com',
                                ),
                                token:
                                    'debug-token-'
                                    '${DateTime.now().millisecondsSinceEpoch}',
                              ),
                            );
                            GlobalToast.info('Signed in as dev user');
                          },
                  ),
                  _Tile(
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFF64B5F6),
                    label: 'Enter pending state',
                    description:
                        'AuthEvent.pendingTokenSet — mid-flow state '
                        '(OTP screens read this)',
                    onTap: state is AuthPending
                        ? null
                        : () {
                            bloc.add(
                              AuthEvent.pendingTokenSet(
                                'debug-pending-'
                                '${DateTime.now().millisecondsSinceEpoch}',
                              ),
                            );
                            GlobalToast.info('Pending token set');
                          },
                  ),
                  _Tile(
                    icon: Icons.logout_rounded,
                    color: const Color(0xFFEF5350),
                    label: 'Sign out',
                    description: 'AuthEvent.signedOut → unauthenticated',
                    onTap: state is AuthAuthenticated || state is AuthPending
                        ? () {
                            bloc.add(const AuthEvent.signedOut());
                            GlobalToast.info('Signed out');
                          }
                        : null,
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Session expiry test',
              icon: Icons.gpp_bad_rounded,
              child: _Group(
                children: [
                  _Tile(
                    icon: Icons.gpp_bad_rounded,
                    color: const Color(0xFFFFA726),
                    label: 'Force next request 401',
                    description:
                        'One-shot network sim — fires once, then '
                        'disarms itself',
                    onTap: () {
                      NetworkSim.oneShot = true;
                      NetworkSim.resetCounter();
                      DebugOverlayPrefs.setNetSim(
                        failEveryN: 1,
                        failStatus: 401,
                      );
                      GlobalToast.warning(
                        'Next request will 401',
                        description: 'Sim disarms after it fires',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _mask(String v) {
    if (v.isEmpty) return '<empty>';
    if (v.length <= 8) return '••••';
    return '${v.substring(0, 4)}•••${v.substring(v.length - 4)}';
  }

  static String _displayName(String? first, String? last) {
    final parts = [first, last].whereType<String>().where((s) => s.isNotEmpty);
    final joined = parts.join(' ');
    return joined.isEmpty ? '<none>' : joined;
  }
}

// ─────────────────────────────────────────────────────────────

class _StateHero extends StatelessWidget {
  const _StateHero({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final (label, detail, icon, color) = switch (state) {
      AuthUnknown() => (
        'UNKNOWN',
        'Boot pending — bootstrapped event not processed yet.',
        Icons.help_outline_rounded,
        const Color(0xFFBA68C8),
      ),
      AuthUnauthenticated() => (
        'UNAUTHENTICATED',
        'No token stored.',
        Icons.lock_outline_rounded,
        DebugOverlayTheme.textDim,
      ),
      AuthPending() => (
        'PENDING',
        'Mid-flow — temporary token held, awaiting verification.',
        Icons.hourglass_top_rounded,
        const Color(0xFFFFA726),
      ),
      AuthAuthenticated(user: final u) => (
        'AUTHENTICATED',
        'Signed in as ${u.email ?? 'user #${u.id}'}.',
        Icons.verified_user_rounded,
        const Color(0xFF66BB6A),
      ),
    };
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
                  detail,
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

class _Group extends StatelessWidget {
  const _Group({required this.children});

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

class _KvRow extends StatelessWidget {
  const _KvRow(this.label, this.display, {this.copyValue});

  final String label;
  final String display;

  /// Raw value copied on tap — the DISPLAY string may be masked, so
  /// copying it would hand the dev garbage.
  final String? copyValue;

  @override
  Widget build(BuildContext context) {
    final copyable = copyValue ?? display;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: copyable));
        GlobalToast.info('$label copied');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ),
            Expanded(
              child: Text(
                display,
                style: DebugOverlayTheme.mono.copyWith(fontSize: 11),
              ),
            ),
            const Icon(
              Icons.copy_rounded,
              size: 12,
              color: DebugOverlayTheme.textDimmer,
            ),
          ],
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: disabled ? 0.45 : 1,
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
      ),
    );
  }
}
