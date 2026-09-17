import 'package:flutter_web_plugins/url_strategy.dart';

/// Web implementation — switches the browser URL from the default hash
/// strategy (`/#/foo`) to clean paths (`/foo`). Called from `main.dart`
/// via a conditional import.
void usePathUrlStrategyIfWeb() => usePathUrlStrategy();
