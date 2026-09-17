import 'package:in_app_review/in_app_review.dart';

import '../device_services.dart';

/// Native in-app review sheet (iOS `SKStoreReviewController`, Android
/// Play in-app review API).
///
/// Apple + Google both rate-limit how often the sheet can appear —
/// calling on every launch is pointless. Gate behind a session counter
/// ("after N successful checkouts") and invoke once. The OS will drop
/// duplicates silently.
class InAppReviewUtils {
  InAppReviewUtils._();

  static final InAppReview _reviewer = InAppReview.instance;

  /// True if the in-app review sheet is available on the current
  /// device (iOS 10.3+, Android with Play Services).
  static Future<bool> isAvailable() => DeviceServices.capability(
    'inAppReview',
  ).guard(_reviewer.isAvailable, fallback: false);

  /// Request the in-app review sheet. The OS decides whether to show
  /// it — there's no user-visible feedback and no error if it's
  /// suppressed.
  static Future<void> requestReview() =>
      deviceGuard('review.request', () async {
        if (!await isAvailable()) return;
        await _reviewer.requestReview();
      }, fallback: null);

  /// Fallback — open the store listing page directly. Use when
  /// [isAvailable] returns false, or when you want the full store UI.
  static Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {
    return deviceGuard(
      'review.openStoreListing',
      () => _reviewer.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: microsoftStoreId,
      ),
      fallback: null,
    );
  }
}
