import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/update_gate/update_cubit.dart';
import '../../../core/update_gate/update_state.dart';
import '../buttons/global_filled_button.dart';
import '../scrollable/global_scrollable.dart';

/// Hard fullscreen screen shown when [UpdateState.isHardRequired].
/// Self-contained — no AppBar, no back button. The only path off is
/// "Update now".
///
/// To replace the entire UI, pass `hardScreenBuilder` on
/// [UpdateOptions]. To swap just the illustration, pass
/// `illustrationBuilder`. To change copy, pass [UpdateStrings].
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({required this.state, super.key});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UpdateCubit>();
    final opts = cubit.options;
    final strings = opts.strings;
    final tx = context.textColors;
    final btn = context.buttonsColors;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: opts.barrierColor ?? theme.colorScheme.surface,
      // Plain ConstrainedBox here — UpdateGate mounts UpdateScreen
      // ABOVE BreakpointsProvider in the chain, so GlobalContainer
      // (which reads `context.breakpoints`) would assert. 480 is the
      // prose-bucket compact width; matches MaintenanceScreen's pattern.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: GlobalScrollable(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (opts.illustrationBuilder != null)
                    opts.illustrationBuilder!(context)
                  else
                    _DefaultIllustration(color: btn.primary),
                  const SizedBox(height: 28),
                  Text(
                    strings.hardTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: tx.primary,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.hardMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: tx.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _VersionRow(state: state, label: strings.versionLabel),
                  const SizedBox(height: 32),
                  GlobalFilledButton(
                    text: strings.hardButton,
                    onPressed: () => cubit.openStore(context),
                    icon: Icons.system_update_alt_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultIllustration extends StatelessWidget {
  const _DefaultIllustration({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Icon(Icons.system_update_alt_rounded, size: 56, color: color),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.state, required this.label});

  final UpdateState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final bg = context.backgroundColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg.outlineVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: tx.secondary),
          const SizedBox(width: 6),
          Text(
            '$label ${state.currentVersion} → ${state.minVersion}+',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: tx.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
