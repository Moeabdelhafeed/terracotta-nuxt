import 'dart:async';

import '../../../core/constants/enums/app/app_role.dart';
import '../../blocs/preferences/preferences_cubit.dart';

/// Role service — plain Dart singleton over [PreferencesCubit.state.appRole].
/// Widget code that needs to rebuild on role change should prefer
/// `BlocSelector<PreferencesCubit, PreferencesState, AppRole>`.
class RoleService {
  RoleService(this._prefs);

  final PreferencesCubit _prefs;

  AppRole get appRole => _prefs.state.appRole;

  Stream<AppRole> get onRoleChanged =>
      _prefs.stream.map((s) => s.appRole).distinct();

  void setAppRole(AppRole role) => _prefs.setAppRole(role);

  void toggleAppRole() => _prefs.toggleAppRole();
}
