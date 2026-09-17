import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `scanner_` key prefix family — `GlobalScanner`
/// permission overlay + result-sheet labels.
class ScannerStrings {
  ScannerStrings._();

  static String get cameraAccessBlocked => Tr.t(
    'scanner.camera_access_blocked',
    S.current.scanner_camera_access_blocked,
  );

  static String get cameraPermissionRequired => Tr.t(
    'scanner.camera_permission_required',
    S.current.scanner_camera_permission_required,
  );

  static String get openSettingsHint =>
      Tr.t('scanner.open_settings_hint', S.current.scanner_open_settings_hint);

  static String get allowCameraHint =>
      Tr.t('scanner.allow_camera_hint', S.current.scanner_allow_camera_hint);

  static String get openSettings =>
      Tr.t('scanner.open_settings', S.current.scanner_open_settings);

  static String get grantAccess =>
      Tr.t('scanner.grant_access', S.current.scanner_grant_access);

  static String get useThisCode =>
      Tr.t('scanner.use_this_code', S.current.scanner_use_this_code);

  static String get scanAgain =>
      Tr.t('scanner.scan_again', S.current.scanner_scan_again);

  static String get title => Tr.t('scanner.title', S.current.scanner_title);

  static String get torchOn =>
      Tr.t('scanner.torch_on', S.current.scanner_torch_on);

  static String get torchOff =>
      Tr.t('scanner.torch_off', S.current.scanner_torch_off);

  static String get flipCamera =>
      Tr.t('scanner.flip_camera', S.current.scanner_flip_camera);

  static String get zoom => Tr.t('scanner.zoom', S.current.scanner_zoom);

  static String get hint => Tr.t('scanner.hint', S.current.scanner_hint);

  static String get cameraFailed =>
      Tr.t('scanner.camera_failed', S.current.scanner_camera_failed);

  static String get cameraFailedHint =>
      Tr.t('scanner.camera_failed_hint', S.current.scanner_camera_failed_hint);

  static String get retry => Tr.t('scanner.retry', S.current.scanner_retry);

  static String get pendingCode =>
      Tr.t('scanner.pending_code', S.current.scanner_pending_code);

  static String get emptyValue =>
      Tr.t('scanner.empty_value', S.current.scanner_empty_value);

  static String get rejected =>
      Tr.t('scanner.rejected', S.current.scanner_rejected);

  static String get fromImage =>
      Tr.t('scanner.from_image', S.current.scanner_from_image);

  static String get imageNoCode =>
      Tr.t('scanner.image_no_code', S.current.scanner_image_no_code);
}
