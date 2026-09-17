import 'package:flutter/foundation.dart';

import '../../generated/l10n.dart';
import '../localization/tr.dart';

/// User-facing copy for the update gate. Override at mount-time so
/// product can change wording; `null` (the default) resolves to the
/// localized ARB value through [Tr] at read time — const defaults
/// can't call `Tr.t`, hence the private-field + getter shape.
@immutable
class UpdateStrings {
  const UpdateStrings({
    String? hardTitle,
    String? hardMessage,
    String? hardButton,
    String? softTitle,
    String? softMessage,
    String? softUpdateButton,
    String? softLaterButton,
    String? softSkipButton,
    String? versionLabel,
    String? unavailableTitle,
    String? unavailableMessage,
  }) : _hardTitle = hardTitle,
       _hardMessage = hardMessage,
       _hardButton = hardButton,
       _softTitle = softTitle,
       _softMessage = softMessage,
       _softUpdateButton = softUpdateButton,
       _softLaterButton = softLaterButton,
       _softSkipButton = softSkipButton,
       _versionLabel = versionLabel,
       _unavailableTitle = unavailableTitle,
       _unavailableMessage = unavailableMessage;

  final String? _hardTitle;
  final String? _hardMessage;
  final String? _hardButton;
  final String? _softTitle;
  final String? _softMessage;
  final String? _softUpdateButton;
  final String? _softLaterButton;
  final String? _softSkipButton;
  final String? _versionLabel;
  final String? _unavailableTitle;
  final String? _unavailableMessage;

  String get hardTitle =>
      _hardTitle ?? Tr.t('update.hard_title', S.current.update_hard_title);
  String get hardMessage =>
      _hardMessage ??
      Tr.t('update.hard_message', S.current.update_hard_message);
  String get hardButton =>
      _hardButton ?? Tr.t('update.hard_button', S.current.update_hard_button);
  String get softTitle =>
      _softTitle ?? Tr.t('update.soft_title', S.current.update_soft_title);
  String get softMessage =>
      _softMessage ??
      Tr.t('update.soft_message', S.current.update_soft_message);
  String get softUpdateButton =>
      _softUpdateButton ??
      Tr.t('update.soft_update_button', S.current.update_soft_update_button);
  String get softLaterButton =>
      _softLaterButton ??
      Tr.t('update.soft_later_button', S.current.update_soft_later_button);
  String get softSkipButton =>
      _softSkipButton ??
      Tr.t('update.soft_skip_button', S.current.update_soft_skip_button);
  String get versionLabel =>
      _versionLabel ??
      Tr.t('update.version_label', S.current.update_version_label);
  String get unavailableTitle =>
      _unavailableTitle ??
      Tr.t('update.unavailable_title', S.current.update_unavailable_title);
  String get unavailableMessage =>
      _unavailableMessage ??
      Tr.t('update.unavailable_message', S.current.update_unavailable_message);
}
