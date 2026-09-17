import 'package:flutter/foundation.dart';

import 'language.dart';

/// Test / skeleton fixture for [Language]. Production features
/// should never import this — only tests, widget catalogs, dev tools.
@visibleForTesting
const Language dummyLanguage = Language(
  id: 1,
  locale: 'en',
  name: 'English',
  direction: 'ltr',
  flag: '🇺🇸',
  isDefault: true,
);
