import 'package:url_launcher/url_launcher.dart';

import '../device_services.dart';

/// Hand a URL, phone number, email, SMS or map pin to the system.
///
/// **Every launch goes through the scheme allow-list** in
/// [DevicePolicy.urlSchemes]. `launchUrl` will hand the platform
/// whatever scheme it is given, and the strings reaching this class
/// are not all typed by a developer: a URL out of remote config, a
/// deep link, a field in an API response. `javascript:` in a WebView
/// context and `file:` reading a path off the device are the two that
/// matter, and neither is something an app ever means to open.
class LauncherUtils {
  LauncherUtils._();

  /// Whether this URL would be allowed. Useful for hiding a link
  /// rather than showing one that silently does nothing.
  static bool isAllowed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.isEmpty) return false;
    return DeviceServices.policy.allowsScheme(uri.scheme);
  }

  /// Open a URL — in the system browser, or in an in-app browser view.
  static Future<bool> openUrl(String url, {bool inApp = false}) =>
      deviceGuard('launcher.openUrl', () async {
        final uri = Uri.tryParse(url);
        if (uri == null || !_allow(uri, 'openUrl')) return false;
        if (!await canLaunchUrl(uri)) return false;
        return launchUrl(
          uri,
          mode: inApp
              ? LaunchMode.inAppBrowserView
              : LaunchMode.externalApplication,
        );
      }, fallback: false);

  /// Open the dialer with [phoneNumber] filled in.
  static Future<bool> dialPhone(String phoneNumber) => _launch(
    'launcher.dialPhone',
    Uri(scheme: 'tel', path: phoneNumber),
  );

  /// Open the SMS app.
  static Future<bool> sendSms(String phoneNumber, {String? body}) => _launch(
    'launcher.sendSms',
    Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: body == null ? null : {'body': body},
    ),
  );

  /// Open the email composer.
  static Future<bool> sendEmail({
    required String to,
    String? subject,
    String? body,
    List<String>? cc,
    List<String>? bcc,
  }) => _launch(
    'launcher.sendEmail',
    Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
        if (cc != null && cc.isNotEmpty) 'cc': cc.join(','),
        if (bcc != null && bcc.isNotEmpty) 'bcc': bcc.join(','),
      },
    ),
  );

  /// Drop a pin in the device's maps app.
  static Future<bool> openMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    final query = label != null
        ? '$latitude,$longitude($label)'
        : '$latitude,$longitude';
    return _launch(
      'launcher.openMaps',
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      external: true,
    );
  }

  /// True if the system can handle [url] AND the scheme is allowed.
  static Future<bool> canOpen(String url) => deviceGuard(
    'launcher.canOpen',
    () async {
      final uri = Uri.tryParse(url);
      if (uri == null || !DeviceServices.policy.allowsScheme(uri.scheme)) {
        return false;
      }
      return canLaunchUrl(uri);
    },
    fallback: false,
  );

  static Future<bool> _launch(
    String operation,
    Uri uri, {
    bool external = false,
  }) => deviceGuard(operation, () async {
    if (!_allow(uri, operation)) return false;
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(
      uri,
      mode: external
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );
  }, fallback: false);

  /// Refusals are LOUD. A blocked scheme is either an attack or a
  /// policy that needs widening, and both are things somebody has to
  /// see — a link that silently does nothing is the worst of the
  /// three outcomes.
  static bool _allow(Uri uri, String operation) {
    if (DeviceServices.policy.allowsScheme(uri.scheme)) return true;
    deviceWarn(
      operation,
      'blocked scheme "${uri.scheme}" — add it to DevicePolicy.urlSchemes '
      'if the app really means to open it',
    );
    return false;
  }
}
