import 'package:flutter/foundation.dart';

import 'pagination_meta.dart';

/// Test / skeleton fixture for [PaginationMeta]. Production features
/// should never import this — only tests, widget catalogs, dev tools.
@visibleForTesting
const PaginationMeta dummyPaginationMeta = PaginationMeta(
  currentPage: 1,
  lastPage: 10,
  total: 200,
  perPage: 20,
  from: 1,
  to: 20,
);
