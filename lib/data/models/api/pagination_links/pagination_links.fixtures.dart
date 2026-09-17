import 'package:flutter/foundation.dart';

import 'pagination_links.dart';

/// Test / skeleton fixture for [PaginationLinks]. Production features
/// should never import this — only tests, widget catalogs, dev tools.
@visibleForTesting
const PaginationLinks dummyPaginationLinks = PaginationLinks(
  first: 'https://api.example.com/page=1',
  last: 'https://api.example.com/page=10',
  prev: 'https://api.example.com/page=2',
  next: 'https://api.example.com/page=3',
);
