import 'package:flutter/foundation.dart';

import '../../generated/l10n.dart';
import '../localization/tr.dart';

/// User-facing copy. Override at mount-time so product can change
/// wording; `null` (the default) resolves to the localized ARB value
/// through [Tr] at read time — const defaults can't call `Tr.t`,
/// hence the private-field + getter shape.
@immutable
class OnboardingStrings {
  const OnboardingStrings({
    String? skip,
    String? next,
    String? back,
    String? getStarted,
    String? allow,
    String? notNow,
    String? permissionDeniedHint,
  }) : _skip = skip,
       _next = next,
       _back = back,
       _getStarted = getStarted,
       _allow = allow,
       _notNow = notNow,
       _permissionDeniedHint = permissionDeniedHint;

  final String? _skip;
  final String? _next;
  final String? _back;
  final String? _getStarted;
  final String? _allow;
  final String? _notNow;
  final String? _permissionDeniedHint;

  String get skip =>
      _skip ?? Tr.t('onboarding.skip', S.current.onboarding_skip);
  String get next =>
      _next ?? Tr.t('onboarding.next', S.current.onboarding_next);
  String get back =>
      _back ?? Tr.t('onboarding.back', S.current.onboarding_back);
  String get getStarted =>
      _getStarted ??
      Tr.t('onboarding.get_started', S.current.onboarding_get_started);
  String get allow =>
      _allow ?? Tr.t('onboarding.allow', S.current.onboarding_allow);
  String get notNow =>
      _notNow ?? Tr.t('onboarding.not_now', S.current.onboarding_not_now);
  String get permissionDeniedHint =>
      _permissionDeniedHint ??
      Tr.t(
        'onboarding.permission_denied_hint',
        S.current.onboarding_permission_denied_hint,
      );
}
