import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/update_gate/update_cubit.dart';
import '../../../core/update_gate/update_options.dart';
import '../../../core/update_gate/update_state.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_outlined_button.dart';
import '../buttons/global_text_button.dart';
import '../sheet/global_sheet.dart';

/// Persistent banner at the top of the app for soft updates. Use via
/// [UpdateOptions.softMode] = [SoftUpdateMode.banner]. Mounted by
/// [UpdateGate] automatically.
class UpdateSoftBanner extends StatelessWidget {
  const UpdateSoftBanner({required this.state, super.key});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UpdateCubit>();
    final opts = cubit.options;
    if (opts.softBannerBuilder != null) {
      return opts.softBannerBuilder!(context, state);
    }
    final strings = opts.strings;
    final st = context.statusColors;

    return Material(
      color: st.info,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${strings.softTitle} (${state.latestVersion})',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.textTheme.bodySmall?.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (opts.allowRemindLater)
                _BannerButton(
                  label: strings.softLaterButton,
                  onTap: cubit.remindLater,
                ),
              _BannerButton(
                label: strings.softUpdateButton,
                onTap: () => cubit.openStore(context),
                emphasis: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    required this.label,
    required this.onTap,
    this.emphasis = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return GlobalTextButton(
      text: label,
      onPressed: onTap,
      shrinkWidth: true,
      // Dense in-banner control — style.height 32 is defeated by the
      // default 48dp MinTouchTarget box unless we opt out.
      enforceMinTouchTarget: false,
      style: ButtonStateStyle(
        foregroundColor: Colors.white,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: TextStyle(
          fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
          fontSize: context.textTheme.bodySmall?.fontSize,
        ),
      ),
    );
  }
}

/// Modal bottom sheet for soft updates. Use via
/// [UpdateOptions.softMode] = [SoftUpdateMode.sheet]. Shown once per
/// app session (or per remind-later cooldown), driven by [UpdateGate].
class UpdateSoftSheet extends StatelessWidget {
  const UpdateSoftSheet({required this.state, super.key});

  final UpdateState state;

  static Future<void> show(BuildContext context, UpdateState state) async {
    final cubit = context.read<UpdateCubit>();
    await GlobalBottomSheet.show<void>(
      context: context,
      isDismissible: cubit.options.dismissOnTapOutside,
      enableDrag: cubit.options.dismissOnTapOutside,
      showCloseButton: false,
      content: BlocProvider.value(
        value: cubit,
        child: UpdateSoftSheet(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UpdateCubit>();
    final opts = cubit.options;
    if (opts.softSheetBuilder != null) {
      return opts.softSheetBuilder!(context, state);
    }
    final strings = opts.strings;
    final tx = context.textColors;
    final btn = context.buttonsColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    btn.primary.withValues(alpha: 0.20),
                    btn.primary.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.system_update_alt_rounded,
                color: btn.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.softTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.textTheme.titleLarge?.fontSize,
              fontWeight: FontWeight.w700,
              color: tx.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.softMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.textTheme.bodyMedium?.fontSize,
              height: 1.5,
              color: tx.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${state.currentVersion} → ${state.latestVersion}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: context.textTheme.bodySmall?.fontSize,
                color: tx.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 22),
          GlobalFilledButton(
            text: strings.softUpdateButton,
            onPressed: () {
              Navigator.of(context).pop();
              cubit.openStore(context);
            },
            style: const ButtonStateStyle(
              leading: Icon(Icons.system_update_alt_rounded),
            ),
          ),
          if (opts.allowRemindLater) ...[
            const SizedBox(height: 8),
            GlobalOutlinedButton(
              text: strings.softLaterButton,
              onPressed: () {
                Navigator.of(context).pop();
                cubit.remindLater();
              },
            ),
          ],
          if (opts.allowSkipVersion) ...[
            const SizedBox(height: 4),
            GlobalTextButton(
              text: strings.softSkipButton,
              onPressed: () {
                Navigator.of(context).pop();
                cubit.skipCurrentLatest();
              },
            ),
          ],
        ],
      ),
    );
  }
}
