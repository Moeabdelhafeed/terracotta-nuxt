import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `ip_field_` key family — IP-address field call sites go
/// through this class.
class IpFieldStrings {
  IpFieldStrings._();

  static String get hint => Tr.t('ip_field.hint', S.current.ip_field_hint);
  static String get required =>
      Tr.t('ip_field.required', S.current.ip_field_required);
  static String get invalidIp =>
      Tr.t('ip_field.invalid_ip', S.current.ip_field_invalid_ip);
  static String get invalidHost =>
      Tr.t('ip_field.invalid_host', S.current.ip_field_invalid_host);
  static String get invalidPort =>
      Tr.t('ip_field.invalid_port', S.current.ip_field_invalid_port);
}
