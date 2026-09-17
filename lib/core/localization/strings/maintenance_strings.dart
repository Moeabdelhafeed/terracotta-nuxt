import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `maintenance_` key prefix family — maintenance page
/// fallbacks + ETA phrases.
class MaintenanceStrings {
  MaintenanceStrings._();

  static String get defaultTitle =>
      Tr.t('maintenance.default_title', S.current.maintenance_default_title);

  static String get defaultMessage => Tr.t(
    'maintenance.default_message',
    S.current.maintenance_default_message,
  );

  /// RC seed default for `maintenanceMessage` — the wording differs from
  /// [defaultMessage] (scheduled vs. generic downtime).
  static String get scheduledMessage => Tr.t(
    'maintenance.scheduled_message',
    S.current.maintenance_scheduled_message,
  );

  static String get etaAnyMoment =>
      Tr.t('maintenance.eta_any_moment', S.current.maintenance_eta_any_moment);

  static String etaHoursMinutes(int hours, int minutes) => Tr.t(
    'maintenance.eta_hours_minutes',
    S.current.maintenance_eta_hours_minutes(hours, minutes),
  );

  static String etaMinutes(int minutes) => Tr.t(
    'maintenance.eta_minutes',
    S.current.maintenance_eta_minutes(minutes),
  );

  static String etaSeconds(int seconds) => Tr.t(
    'maintenance.eta_seconds',
    S.current.maintenance_eta_seconds(seconds),
  );

  static String backEta(String eta) =>
      Tr.t('maintenance.back_eta', S.current.maintenance_back_eta(eta));

  static String retryInSeconds(int seconds) => Tr.t(
    'maintenance.retry_in_seconds',
    S.current.maintenance_retry_in_seconds(seconds),
  );
}
