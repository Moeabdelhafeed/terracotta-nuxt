import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/enums/app/app_role.dart';
import '../../../core/localization/strings/preferences_strings.dart';
import '../../../core/theme/reveal_theme_switcher.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../data/blocs/preferences/preferences_state.dart';
import 'picker_item.dart';
import 'picker_options.dart';
import 'picker_shell.dart';

/// Which palette the app wears.
///
/// It had no picker: the settings page owned the only UI for it, in a
/// private pill row of its own — so a screen that wanted to offer the
/// choice anywhere else had to build one.
///
/// Like the theme picker, the change rides `RevealThemeSwitcher`
/// through the reader's own stored shape and direction. A palette
/// swap repaints as much of the screen as a theme swap does; hard-
/// cutting it while the theme animates would make the two settings
/// feel like different apps.
class AppRolePicker extends StatefulWidget {
  const AppRolePicker({
    this.options,
    this.style = const PickerStyle(),
    this.revealOnChange = true,
    super.key,
  });

  final PickerOptions? options;
  final PickerStyle style;
  final bool revealOnChange;

  static PickerOptions get _defaults => PickerOptions(
    title: PreferencesStrings.appRoleTitle,
    subtitle: PreferencesStrings.appRoleSubtitle,
    icon: Icons.palette_rounded,
  );

  static List<PickerItem<AppRole>> get _items => [
    for (final role in AppRole.values)
      PickerItem<AppRole>(
        value: role,
        label: role.label,
        icon: role == AppRole.guest
            ? Icons.person_outline_rounded
            : Icons.badge_outlined,
      ),
  ];

  @override
  State<AppRolePicker> createState() => _AppRolePickerState();
}

class _AppRolePickerState extends State<AppRolePicker> {
  Offset _origin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _apply(AppRole next) {
    final cubit = context.read<PreferencesCubit>();
    if (!widget.revealOnChange || RevealThemeSwitcher.isAnimating(context)) {
      cubit.setAppRole(next);
      return;
    }
    final strategy = RevealStrategy.fromKey(cubit.state.revealShapeKey);
    RevealThemeSwitcher.reveal(
      context,
      origin: _origin(),
      strategy: strategy,
      direction: strategy.resolveDirection(
        RevealDirection.fromName(cubit.state.revealDirectionName),
      ),
      action: () => cubit.setAppRole(next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      buildWhen: (a, b) =>
          a.appRole != b.appRole || a.language.locale != b.language.locale,
      builder: (context, prefs) => PickerShell<AppRole>(
        items: AppRolePicker._items,
        value: prefs.appRole,
        onChanged: _apply,
        options: (widget.options ?? const PickerOptions()).mergedOver(
          AppRolePicker._defaults,
        ),
        style: widget.style,
      ),
    );
  }
}
