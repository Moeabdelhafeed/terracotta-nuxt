import 'package:app_links/app_links.dart';

import '../../features/gift/data/pending_gift.dart';
import '../navigation/deep_link_handler.dart';
import '../navigation/go_router_config.dart';
import '../utils/loggers/logger.dart';

/// Wire `app_links` into [DeepLinkHandler] — both the cold-start URI
/// (app launched from a tap on a link) and the runtime stream (link
/// tapped while app is already open).
///
/// Universal links on iOS + Android app links are already handled by
/// GoRouter; this covers custom-scheme links (`myapp://...`) and lets
/// `DeepLinkHandler` apply rewrite rules registered elsewhere.
Future<void> wireDeepLinks() async {
  try {
    final appLinks = AppLinks();
    final initial = await appLinks.getInitialLink();
    if (initial != null) _arrive(initial);
    appLinks.uriLinkStream.listen(
      _arrive,
      onError: (Object e) => Logger.m.w('[DeepLink] stream error: $e'),
    );
  } catch (e) {
    Logger.m.w('[DeepLink] wire failed: $e');
  }
}

/// One link, resolved and routed — and PARKED first if it is a gift.
///
/// The cold-start call happens inside `bootstrap`, before the first
/// frame, and the router forces that first navigation to the splash so
/// state restoration cannot skip the splash gate. A gift link routed
/// and nothing else would be dropped there; parked, `defaultSplashNext`
/// picks it up on the way out. A link that arrives while the app is
/// already open routes normally and the parked copy is taken by the
/// screen it opens. See [PendingGift].
void _arrive(Uri uri) {
  final path = DeepLinkHandler.resolve(uri);
  if (PendingGift.tokenIn(path) case final token?) {
    PendingGift.remember(token);
  }
  DeepLinkHandler.handle(uri, GoRouterConfig.router);
}
