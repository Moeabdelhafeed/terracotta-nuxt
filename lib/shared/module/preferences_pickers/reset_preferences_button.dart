import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/strings/preferences_strings.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../buttons/global_outlined_button.dart';
import '../dialog/global_dialog.dart';

/// Reset display preferences (theme, saturation, font scale, dynamic
/// color, reveal animation) back to defaults. Confirmation dialog
/// shown before applying.
class ResetPreferencesButton extends StatelessWidget {
  const ResetPreferencesButton({
    this.label,
    this.icon = Icons.restart_alt_rounded,
    this.confirm = true,
    super.key,
  });

  /// `null` renders the localized default.
  final String? label;
  final IconData icon;
  final bool confirm;

  Future<void> _onTap(BuildContext context) async {
    final cubit = context.read<PreferencesCubit>();
    if (!confirm) {
      cubit.resetDisplayPreferences();
      return;
    }
    final ok = await GlobalDialog.confirm(
      context: context,
      title: PreferencesStrings.resetConfirmTitle,
      message: PreferencesStrings.resetConfirmBody,
      confirmText: PreferencesStrings.resetAction,
    );
    if (ok) cubit.resetDisplayPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalOutlinedButton(
      text: label ?? PreferencesStrings.resetToDefaults,
      icon: icon,
      onPressed: () => _onTap(context),
    );
  }
}
