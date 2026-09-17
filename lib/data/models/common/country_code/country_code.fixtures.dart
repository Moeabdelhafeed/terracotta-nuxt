import 'package:flutter/foundation.dart';

import 'country_code.dart';

/// Test / skeleton fixture for [CountryCode]. Production features
/// should never import this — only tests, widget catalogs, dev tools.
@visibleForTesting
const CountryCode dummyCountryCode = CountryCode(
  code: 'US',
  name: 'United States',
  flag: '🇺🇸',
  dialCode: '+1',
);
